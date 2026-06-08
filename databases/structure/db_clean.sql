-- *********************************************************************
-- MODULE 1: CORE SYSTEM & PHÂN QUYỀN (AUTH, RBAC, SETTINGS)
-- *********************************************************************

-- Bảng tài khoản người dùng (Xác thực)
CREATE TABLE users (
    users_id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE, BANNED
    last_login_at TIMESTAMP,
    failed_login_count INT DEFAULT 0,
    locked_until TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL -- Soft Delete
);

-- Partial Indexes for User Soft Delete
CREATE UNIQUE INDEX users_email_key ON users (email) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX users_phone_number_key ON users (phone_number) WHERE phone_number IS NOT NULL AND deleted_at IS NULL;

-- Bảng hồ sơ người dùng
CREATE TABLE user_profiles (
    user_profiles_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    dob DATE,
    gender VARCHAR(20), -- MALE, FEMALE, OTHER (Master Data)
    identity_card_number VARCHAR(50) UNIQUE, -- CMND/CCCD/Passport
    avatar_url TEXT,
    address TEXT,
    preferences JSONB DEFAULT '{}', -- Cài đặt cá nhân (ngôn ngữ, theme)
    signature_url TEXT, -- Chữ ký số của bác sĩ/nhân viên
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE
);

-- *********************************************************************
-- QUẢN LÝ BẢO MẬT & PHIÊN ĐĂNG NHẬP (SECURITY & SESSIONS)
-- *********************************************************************

-- Bảng Đặt lại mật khẩu
CREATE TABLE password_resets (
    password_resets_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    reset_token VARCHAR(255) NOT NULL,
    expired_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE
);

-- Bảng Phiên đăng nhập (Session Management)
CREATE TABLE user_sessions (
    user_sessions_id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    refresh_token_hash VARCHAR(512) NOT NULL,
    device_id VARCHAR(255),
    device_name VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expired_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE
);

-- Bảng Xác minh tài khoản (Email verification)
CREATE TABLE account_verifications (
    account_verifications_id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    verify_token_hash VARCHAR(255) NOT NULL,
    expired_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE
);

-- Index tối ưu truy vấn Auth/Session
CREATE INDEX idx_password_resets_token ON password_resets(reset_token);
CREATE INDEX idx_user_sessions_user_device ON user_sessions(user_id, device_id);
CREATE INDEX idx_user_sessions_refresh_token ON user_sessions(refresh_token_hash);
CREATE INDEX idx_account_verif_token ON account_verifications(verify_token_hash);

-- *********************************************************************
-- QUẢN LÝ VAI TRÒ & PHÂN QUYỀN (RBAC)
-- *********************************************************************

-- Bảng Vai trò
CREATE TABLE roles (
    roles_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL, -- ADMIN, DOCTOR, NURSE, PATIENT
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE, -- TRUE: Không cho admin sửa/xóa
    status VARCHAR(50) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Bảng Quyền hạn
CREATE TABLE permissions (
    permissions_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(100) UNIQUE NOT NULL, -- PATIENT_CREATE, EMR_VIEW
    module VARCHAR(100) NOT NULL, -- PATIENT_MANAGEMENT, EMR
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Bảng N/N: Vai trò - Quyền hạn
CREATE TABLE role_permissions (
    role_id VARCHAR(50) NOT NULL,
    permission_id VARCHAR(50) NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(roles_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(permissions_id) ON DELETE CASCADE
);

-- Bảng Danh mục Menu giao diện
CREATE TABLE menus (
    menus_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    url VARCHAR(255),
    icon VARCHAR(100),
    parent_id VARCHAR(50), -- Menu đa cấp (Nested)
    sort_order INT DEFAULT 0,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES menus(menus_id) ON DELETE SET NULL
);

-- Bảng N/N: Vai trò - Menu
CREATE TABLE role_menus (
    role_id VARCHAR(50) NOT NULL,
    menu_id VARCHAR(50) NOT NULL,
    PRIMARY KEY (role_id, menu_id),
    FOREIGN KEY (role_id) REFERENCES roles(roles_id) ON DELETE CASCADE,
    FOREIGN KEY (menu_id) REFERENCES menus(menus_id) ON DELETE CASCADE
);

-- Bảng Danh mục API Endpoint
CREATE TABLE api_permissions (
    api_id VARCHAR(50) PRIMARY KEY,
    method VARCHAR(10) NOT NULL, -- GET, POST, PUT, DELETE
    endpoint VARCHAR(255) NOT NULL,
    description TEXT,
    module VARCHAR(50),
    status VARCHAR(50) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE(method, endpoint)
);

-- Bảng N/N: Vai trò - API Permission
CREATE TABLE role_api_permissions (
    role_id VARCHAR(50) NOT NULL,
    api_id VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id, api_id),
    FOREIGN KEY (role_id) REFERENCES roles(roles_id) ON DELETE CASCADE,
    FOREIGN KEY (api_id) REFERENCES api_permissions(api_id) ON DELETE CASCADE
);

-- Bảng vai trò hiệu lực của người dùng (mỗi user tối đa 1 vai trò)
CREATE TABLE user_roles (
    user_id VARCHAR(50) NOT NULL,
    role_id VARCHAR(50) NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(roles_id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX idx_user_roles_unique_user ON user_roles(user_id);

-- *********************************************************************
-- DANH MỤC NỀN (MASTER DATA)
-- *********************************************************************

-- Nhóm danh mục
CREATE TABLE master_data_categories (
    master_data_categories_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL, -- ETHNICITY, RELIGION, CITY
    name VARCHAR(100) NOT NULL,
    description TEXT,
    deleted_at TIMESTAMP NULL
);

-- Giá trị chi tiết của danh mục
CREATE TABLE master_data_items (
    master_data_items_id VARCHAR(50) PRIMARY KEY,
    category_code VARCHAR(50) NOT NULL,
    code VARCHAR(50) NOT NULL,
    value VARCHAR(255) NOT NULL,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (category_code) REFERENCES master_data_categories(code) ON DELETE CASCADE,
    UNIQUE (category_code, code)
);

-- *********************************************************************
-- CẤU HÌNH HỆ THỐNG & THÔNG BÁO (SETTINGS & NOTIFICATIONS)
-- *********************************************************************

-- Cấu hình hệ thống linh hoạt
CREATE TABLE system_settings (
    system_settings_id VARCHAR(50) PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value JSON NOT NULL,
    module VARCHAR(100) DEFAULT 'GENERAL',
    description TEXT,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    updated_by VARCHAR(50) REFERENCES users(users_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Phân quyền chỉnh sửa cấu hình theo module
CREATE TABLE system_config_permissions (
    id VARCHAR(50) PRIMARY KEY,
    role_code VARCHAR(50) NOT NULL,
    module VARCHAR(100) NOT NULL,
    updated_by VARCHAR(50) REFERENCES users(users_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (role_code, module)
);

-- Danh mục loại thông báo (Notification Categories)
CREATE TABLE notification_categories (
    notification_categories_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

-- Mẫu thông báo (Notification Templates)
CREATE TABLE notification_templates (
    notification_templates_id VARCHAR(50) PRIMARY KEY,
    category_id VARCHAR(50) NOT NULL,
    code VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    title_template VARCHAR(255) NOT NULL, -- Template tiêu đề (có placeholder)
    body_inapp TEXT NOT NULL, -- Template nội dung In-App
    body_email TEXT, -- Template nội dung Email
    body_push TEXT, -- Template nội dung Push Notification
    is_system BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    FOREIGN KEY (category_id) REFERENCES notification_categories(notification_categories_id)
);

-- Cấu hình gửi thông báo theo vai trò
CREATE TABLE notification_role_configs (
    notification_role_configs_id VARCHAR(50) PRIMARY KEY,
    role_id VARCHAR(50) NOT NULL,
    category_id VARCHAR(50) NOT NULL,
    allow_inapp BOOLEAN DEFAULT TRUE,
    allow_email BOOLEAN DEFAULT FALSE,
    allow_push BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(roles_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES notification_categories(notification_categories_id) ON DELETE CASCADE
);

-- Thông báo của từng người dùng
CREATE TABLE user_notifications (
    user_notifications_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    template_id VARCHAR(50), -- Có thể NULL nếu thông báo ad-hoc
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    data_payload JSONB, -- Dữ liệu đính kèm (link, reference_id)
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES notification_templates(notification_templates_id)
);

-- Bảng FCM Token cho Push Notification
CREATE TABLE user_fcm_tokens (
    token_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    fcm_token TEXT NOT NULL UNIQUE,
    device_name VARCHAR(100),
    last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE
);

-- *********************************************************************
-- NHẬT KÝ HỆ THỐNG (AUDIT & LOGGING)
-- *********************************************************************

-- Nhật ký hành động hệ thống (Audit Trail)
CREATE TABLE audit_logs (
    log_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50),
    action_type VARCHAR(50) NOT NULL, -- CREATE, UPDATE, DELETE, LOGIN
    module_name VARCHAR(100) NOT NULL, -- Tên module bị tác động
    target_id VARCHAR(100), -- ID bản ghi bị tác động
    old_value JSONB,
    new_value JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE SET NULL
);

-- *********************************************************************
-- MODULE 2: QUAN LY BENH NHAN (PATIENT MANAGEMENT)
-- *********************************************************************

-- Bang Benh nhan (Core Patient Data)
-- Luu y: Trong db hien tai, patients dung UUID cho id va co the KHONG lien ket voi users
-- (account_id la VARCHAR(255) nullable). Day la thiet ke cho benh nhan vang lai/chua co tai khoan.
CREATE TABLE patients (
    id VARCHAR(50) PRIMARY KEY,
    patient_code VARCHAR(30) UNIQUE NOT NULL, -- Ma so benh nhan (MRN)
    account_id VARCHAR(255), -- Lien ket voi users (nullable: benh nhan vang lai)
    full_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    phone_number VARCHAR(20),
    email VARCHAR(100),
    id_card_number VARCHAR(50), -- CMND/CCCD
    address TEXT,
    province_id INT,
    district_id INT,
    ward_id INT,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    avatar_url JSONB DEFAULT '[]'::jsonb,
    has_insurance BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

-- Bang Loai quan he (Relation Types) - Danh muc chuan
CREATE TABLE relation_types (
    relation_types_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

-- Bang Nguoi than & Lien he khan cap (Patient Contacts/Relations)
CREATE TABLE patient_contacts (
    patient_contacts_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) NOT NULL,
    relation_type_id VARCHAR(50) NOT NULL, -- Lien ket voi bang relation_types
    contact_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    address TEXT,
    is_emergency_contact BOOLEAN DEFAULT FALSE,
    is_legal_representative BOOLEAN DEFAULT FALSE, -- Nguoi dai dien phap ly
    medical_decision_note TEXT, -- Ghi chu quyen quyet dinh y te
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (relation_type_id) REFERENCES relation_types(relation_types_id)
);

-- Nha cung cap Bao hiem (moved here to resolve FK dependency)
CREATE TABLE insurance_providers (
    insurance_providers_id VARCHAR(50) PRIMARY KEY,
    provider_code VARCHAR(50) UNIQUE NOT NULL,
    provider_name VARCHAR(255) NOT NULL,
    insurance_type VARCHAR(50) NOT NULL, -- STATE, PRIVATE
    contact_phone VARCHAR(50),
    contact_email VARCHAR(100),
    address TEXT,
    support_notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Pham vi bao hiem (Insurance Coverages)
CREATE TABLE insurance_coverages (
    insurance_coverages_id VARCHAR(50) PRIMARY KEY,
    coverage_name VARCHAR(255) NOT NULL,
    provider_id VARCHAR(50) NOT NULL,
    coverage_percent DECIMAL(5,2) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (provider_id) REFERENCES insurance_providers(insurance_providers_id) ON DELETE CASCADE
);

-- Bang Bao hiem benh nhan
CREATE TABLE patient_insurances (
    patient_insurances_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) NOT NULL,
    insurance_type VARCHAR(50) NOT NULL, -- STATE (BHYT), PRIVATE
    insurance_number VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    coverage_percent INT,
    is_primary BOOLEAN DEFAULT TRUE,
    document_url TEXT,
    provider_id VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (provider_id) REFERENCES insurance_providers(insurance_providers_id)
);

-- Bang Tien su benh ly (Medical History)
CREATE TABLE patient_medical_histories (
    patient_medical_histories_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) NOT NULL,
    condition_code VARCHAR(20), -- Ma ICD-10
    condition_name VARCHAR(255) NOT NULL,
    history_type VARCHAR(50) NOT NULL, -- PERSONAL, FAMILY
    diagnosis_date DATE,
    status VARCHAR(50) DEFAULT 'ACTIVE', -- ACTIVE, RESOLVED
    notes TEXT,
    reported_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (reported_by) REFERENCES users(users_id) ON DELETE SET NULL
);

-- Bang Di ung & Tac dung phu (Allergies) - Cuc ky quan trong khi ke don
CREATE TABLE patient_allergies (
    patient_allergies_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) NOT NULL,
    allergen_type VARCHAR(50), -- DRUG, FOOD, ENVIRONMENT
    allergen_name VARCHAR(255) NOT NULL,
    reaction TEXT,
    severity VARCHAR(50), -- MILD, MODERATE, SEVERE
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE
);

-- Bang danh sach cac The (Tags)
CREATE TABLE tags (
    tags_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL, -- VIP, CHRONIC_CARE, HIGH_RISK
    name VARCHAR(100) NOT NULL,
    color_hex VARCHAR(10) DEFAULT '#000000',
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

-- Bang lien ket Benh nhan - The
CREATE TABLE patient_tags (
    patient_tags_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) NOT NULL,
    tag_id VARCHAR(50) NOT NULL,
    assigned_by VARCHAR(50),
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(tags_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(users_id) ON DELETE SET NULL
);

-- Bang Quy tac phan loai benh nhan tu dong
CREATE TABLE patient_classification_rules (
    rule_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    criteria_type VARCHAR(50) NOT NULL, -- AGE, VISIT_COUNT, DIAGNOSIS_CODE
    criteria_operator VARCHAR(10) NOT NULL, -- >, <, =, >=, <=, CONTAINS
    criteria_value VARCHAR(255) NOT NULL,
    target_tag_id VARCHAR(50) NOT NULL, -- Tag se duoc gan tu dong
    timeframe_days INT, -- Khoan thoi gian xet (vd: 90 ngay gan nhat)
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    FOREIGN KEY (target_tag_id) REFERENCES tags(tags_id)
);

-- Bang Loai tai lieu (Document Types)
CREATE TABLE document_types (
    document_type_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

-- Bang Ho so dinh kem benh nhan (Patient Documents)
CREATE TABLE patient_documents (
    patient_documents_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) NOT NULL,
    document_type_id VARCHAR(50),
    document_type VARCHAR(50), -- LAB_RESULT, EXTERNAL_EMR, CONSENT_FORM (legacy)
    title VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_format VARCHAR(20),
    file_size_bytes BIGINT,
    notes TEXT,
    version_number INT DEFAULT 1,
    uploaded_by VARCHAR(50),
    uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (document_type_id) REFERENCES document_types(document_type_id),
    FOREIGN KEY (uploaded_by) REFERENCES users(users_id) ON DELETE SET NULL
);

-- Bang Phien ban tai lieu (Document Versions)
CREATE TABLE patient_document_versions (
    version_id VARCHAR(50) PRIMARY KEY,
    document_id VARCHAR(50) NOT NULL,
    version_number INT NOT NULL,
    file_url TEXT NOT NULL,
    file_format VARCHAR(20),
    file_size_bytes BIGINT,
    uploaded_by VARCHAR(50),
    uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (document_id) REFERENCES patient_documents(patient_documents_id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(users_id) ON DELETE SET NULL
);

-- *********************************************************************
-- MODULE 3: QUAN LY CO SO Y TE (FACILITY MANAGEMENT - MULTI-CLINIC)
-- *********************************************************************

-- Co so y te (Healthcare Facilities) - Bang goc (Root)
CREATE TABLE facilities (
    facilities_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    tax_code VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    website VARCHAR(255),
    logo_url TEXT,
    headquarters_address TEXT,
    status VARCHAR(50) DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE, SUSPENDED
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Gio hoat dong cua co so (Operation Hours)
CREATE TABLE facility_operation_hours (
    operation_hours_id VARCHAR(50) PRIMARY KEY,
    facility_id VARCHAR(50) NOT NULL,
    day_of_week INT NOT NULL, -- 0 (CN) -> 6 (T7)
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    is_closed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE CASCADE,
    UNIQUE(facility_id, day_of_week)
);

-- Ngay dong cua dinh ky (Facility Closed Days) - vd: CN hang tuan, Chieu T7
CREATE TABLE facility_closed_days (
    closed_day_id VARCHAR(50) PRIMARY KEY,
    facility_id VARCHAR(50) NOT NULL,
    day_of_week INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE CASCADE
);

-- Ngay le / ngay nghi dac biet (Facility Holidays)
CREATE TABLE facility_holidays (
    holiday_id VARCHAR(50) PRIMARY KEY,
    facility_id VARCHAR(50) NOT NULL,
    holiday_date DATE NOT NULL,
    title VARCHAR(255) NOT NULL,
    is_closed BOOLEAN DEFAULT TRUE,
    special_open_time TIME, -- Gio mo cua dac biet (neu khong dong hoan toan)
    special_close_time TIME,
    description TEXT,
    is_recurring BOOLEAN DEFAULT FALSE, -- Lap lai hang nam (vd: Tet, 30/4)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE CASCADE
);

-- Chi nhanh (Branches) thuoc Co so y te
CREATE TABLE branches (
    branches_id VARCHAR(50) PRIMARY KEY,
    facility_id VARCHAR(50) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(20),
    status VARCHAR(50) DEFAULT 'ACTIVE',
    established_date DATE,
    logo_url TEXT,
    deleted_at TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE CASCADE
);

-- Phong ban / Chuyen khoa (Departments) thuoc Chi nhanh
CREATE TABLE departments (
    departments_id VARCHAR(50) PRIMARY KEY,
    branch_id VARCHAR(50) NOT NULL,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    group_type VARCHAR(20) DEFAULT 'CLINICAL', -- CLINICAL (Lam sang) | PARACLINICAL (Can lam sang)
    logo_url TEXT,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    deleted_at TIMESTAMP,
    FOREIGN KEY (branch_id) REFERENCES branches(branches_id) ON DELETE CASCADE,
    UNIQUE(branch_id, code)
);

-- Phong kham / Phong chuc nang (Medical Rooms) thuoc Phong ban
CREATE TABLE medical_rooms (
    medical_rooms_id VARCHAR(50) PRIMARY KEY,
    department_id VARCHAR(50),
    branch_id VARCHAR(50) NOT NULL,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    room_type VARCHAR(50), -- CONSULTATION, LAB, IMAGING, OPERATING
    capacity INT DEFAULT 1,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    current_appointment_id VARCHAR(50),
    current_patient_id VARCHAR(50),
    room_status VARCHAR(30) DEFAULT 'AVAILABLE', -- AVAILABLE, IN_USE, MAINTENANCE
    deleted_at TIMESTAMPTZ,
    FOREIGN KEY (department_id) REFERENCES departments(departments_id) ON DELETE SET NULL,
    FOREIGN KEY (branch_id) REFERENCES branches(branches_id) ON DELETE CASCADE,
    UNIQUE(department_id, code)
);



-- Quan ly nhan su y te (Gan Staff vao Chi nhanh/Khoa)
CREATE TABLE user_branch_dept (
    user_branch_dept_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    branch_id VARCHAR(50) NOT NULL,
    department_id VARCHAR(50),
    role_title VARCHAR(100), -- Truong khoa, Bac si dieu tri
    status VARCHAR(50) DEFAULT 'ACTIVE',
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(branches_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments(departments_id) ON DELETE SET NULL,
    UNIQUE(user_id, branch_id)
);

-- Bang cap, chung chi hanh nghe (User Licenses)
CREATE TABLE user_licenses (
    licenses_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    license_type VARCHAR(100) NOT NULL,
    license_number VARCHAR(100) NOT NULL UNIQUE,
    issue_date DATE NOT NULL,
    expiry_date DATE,
    issued_by VARCHAR(255),
    document_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE
);

-- Cau hinh dat lich (Booking Configurations) - theo co so + chi nhanh
CREATE TABLE booking_configurations (
    config_id VARCHAR(50) PRIMARY KEY,
    facility_id VARCHAR(50) NOT NULL,
    branch_id VARCHAR(50) NOT NULL,
    max_patients_per_slot INT,
    buffer_duration INT, -- Thoi gian dem giua 2 slot (phut)
    advance_booking_days INT, -- Dat truoc toi da bao nhieu ngay
    minimum_booking_hours INT, -- Dat truoc toi thieu bao nhieu gio
    cancellation_allowed_hours INT, -- Huy truoc bao nhieu gio
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(branches_id) ON DELETE CASCADE
);

-- *********************************************************************
-- MODULE 4: LICH LAM VIEC & DAT LICH KHAM (SCHEDULING & APPOINTMENTS)
-- *********************************************************************

-- Chuyen khoa (Specialties) - Master Data
CREATE TABLE specialties (
    specialties_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    logo_url TEXT,
    deleted_at TIMESTAMP
);

-- Thong tin chuyen mon Bac si
CREATE TABLE doctors (
    doctors_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL UNIQUE,
    specialty_id VARCHAR(50) NOT NULL,
    title VARCHAR(100), -- GS, TS, BS.CKII
    biography TEXT,
    consultation_fee DECIMAL(12,2),
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE,
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialties_id)
);

-- Ca lam viec (Shifts) - Danh muc ca kham chuan
CREATE TABLE shifts (
    shifts_id VARCHAR(50) PRIMARY KEY,
    facility_id VARCHAR(50) NOT NULL, -- Co so y te so huu ca lam viec
    code VARCHAR(50) NOT NULL, -- MORNING, AFTERNOON, NIGHT
    name VARCHAR(100) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE CASCADE,
    UNIQUE (facility_id, code) -- Moi co so chi co 1 ca voi cung code
);

-- Lich lam viec cua NHAN VIEN (Staff Schedules) - Tong quat cho moi loai nhan su
-- Lien ket voi: users, medical_rooms, shifts
CREATE TABLE staff_schedules (
    staff_schedules_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    medical_room_id VARCHAR(50) NOT NULL,
    shift_id VARCHAR(50) NOT NULL,
    working_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_leave BOOLEAN DEFAULT FALSE,
    leave_reason TEXT,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE,
    FOREIGN KEY (medical_room_id) REFERENCES medical_rooms(medical_rooms_id) ON DELETE CASCADE,
    FOREIGN KEY (shift_id) REFERENCES shifts(shifts_id)
);


-- Khung gio kham (Appointment Slots) - Gan voi Ca lam viec (shifts)
-- He thong tu dong sinh slot dua tren cau hinh (vd: moi slot 15 phut)
CREATE TABLE appointment_slots (
    slot_id VARCHAR(50) PRIMARY KEY,
    shift_id VARCHAR(50) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shift_id) REFERENCES shifts(shifts_id) ON DELETE CASCADE
);


-- Lich hen kham (Appointments)
-- Luu y: doctor_id va slot_id deu NULLABLE de ho tro benh nhan dat lich chua chon bac si/slot
CREATE TABLE appointments (
    appointments_id VARCHAR(50) PRIMARY KEY,
    appointment_code VARCHAR(50) UNIQUE NOT NULL, -- Ma tra cuu (vd: APP-20260305-123)
    patient_id VARCHAR(50) NOT NULL,
    doctor_id VARCHAR(50), -- Nullable: benh nhan chua chon bac si
    slot_id VARCHAR(50), -- Nullable: dat lich chua chon slot cu the
    room_id VARCHAR(50), -- Phong kham
    facility_service_id VARCHAR(50), -- Dich vu kham
    specialty_id VARCHAR(50), -- Chuyen khoa (luu de dam bao du lieu khi chua co BS)
    appointment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    booking_channel VARCHAR(50) NOT NULL, -- APP, WEB, HOTLINE, DIRECT_CLINIC, ZALO
    reason_for_visit TEXT,
    symptoms_notes TEXT,
    status VARCHAR(50) DEFAULT 'PENDING',
    -- PENDING, CONFIRMED, CHECKED_IN, CANCELLED, NO_SHOW, COMPLETED
    priority VARCHAR(20) DEFAULT 'NORMAL', -- NORMAL, URGENT, VIP
    queue_number INT,
    check_in_method VARCHAR(20), -- QR, MANUAL, KIOSK
    qr_token VARCHAR(100) UNIQUE,
    qr_token_expires_at TIMESTAMPTZ,
    is_late BOOLEAN DEFAULT FALSE,
    late_minutes INT DEFAULT 0,
    checked_in_at TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ,
    confirmed_by VARCHAR(50),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    cancelled_by VARCHAR(50),
    reschedule_count INT DEFAULT 0,
    last_rescheduled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctors_id) ON DELETE SET NULL,
    FOREIGN KEY (slot_id) REFERENCES appointment_slots(slot_id) ON DELETE SET NULL,
    FOREIGN KEY (room_id) REFERENCES medical_rooms(medical_rooms_id) ON DELETE SET NULL,
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialties_id) ON DELETE SET NULL
    -- FK facility_service_id -> facility_services: deferred (bang tao o Module 7)
);




-- Nhat ky thay doi lich kham (Appointment Audit Trail)
CREATE TABLE appointment_audit_logs (
    appointment_audit_logs_id VARCHAR(50) PRIMARY KEY,
    appointment_id VARCHAR(50) NOT NULL,
    changed_by VARCHAR(50),
    old_status VARCHAR(50),
    new_status VARCHAR(50),
    action_note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointments_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(users_id) ON DELETE SET NULL
);

-- Yeu cau doi ca (Shift Swaps) giua cac nhan vien
CREATE TABLE shift_swaps (
    swap_id VARCHAR(50) PRIMARY KEY,
    requester_schedule_id VARCHAR(50) NOT NULL,
    target_schedule_id VARCHAR(50) NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    approver_id VARCHAR(50),
    approver_note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    FOREIGN KEY (requester_schedule_id) REFERENCES staff_schedules(staff_schedules_id),
    FOREIGN KEY (target_schedule_id) REFERENCES staff_schedules(staff_schedules_id),
    FOREIGN KEY (approver_id) REFERENCES users(users_id)
);

-- Yeu cau nghi phep (Leave Requests)
CREATE TABLE leave_requests (
    leave_requests_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING',
    approver_id VARCHAR(50),
    approver_note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE,
    FOREIGN KEY (approver_id) REFERENCES users(users_id)
);

-- *********************************************************************
-- MODULE 5: KHAM BENH & HO SO BENH AN (EMR - Electronic Medical Records)
-- *********************************************************************

-- Luot kham / Benh an (Encounters)
CREATE TABLE encounters (
    encounters_id VARCHAR(50) PRIMARY KEY,
    appointment_id VARCHAR(50),
    patient_id VARCHAR(50) NOT NULL,
    doctor_id VARCHAR(50) NOT NULL,
    room_id VARCHAR(50) NOT NULL,
    encounter_type VARCHAR(50) DEFAULT 'OUTPATIENT', -- OUTPATIENT, INPATIENT, EMERGENCY, TELEMED
    visit_number INT DEFAULT 1,
    start_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMPTZ,
    status VARCHAR(50) DEFAULT 'IN_PROGRESS',
    -- IN_PROGRESS, WAITING_FOR_RESULTS, COMPLETED, CLOSED
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointments_id),
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctors_id),
    FOREIGN KEY (room_id) REFERENCES medical_rooms(medical_rooms_id)
);


-- Migration: Tạo bảng liên kết Khoa ↔ Chuyên khoa
-- Mục đích: Phân phòng đúng khoa khi đặt lịch (VD: BN Nhi → Phòng Nhi)
CREATE TABLE IF NOT EXISTS department_specialties (
    department_specialty_id VARCHAR(50) PRIMARY KEY,
    department_id VARCHAR(50) NOT NULL,
    specialty_id VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES departments(departments_id) ON DELETE CASCADE,
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialties_id) ON DELETE CASCADE,
    UNIQUE(department_id, specialty_id)
);


-- Kham Lam sang & Sinh hieu (Clinical Examination & Vital Signs)
CREATE TABLE clinical_examinations (
    clinical_examinations_id VARCHAR(50) PRIMARY KEY,
    encounter_id VARCHAR(50) NOT NULL UNIQUE,
    -- Sinh hieu (Vital Signs)
    pulse INT,
    blood_pressure_systolic INT,
    blood_pressure_diastolic INT,
    temperature DECIMAL(4,2),
    respiratory_rate INT,
    spo2 INT,
    weight DECIMAL(5,2),
    height DECIMAL(5,2),
    bmi DECIMAL(4,2),
    -- Kham lam sang
    chief_complaint TEXT,
    medical_history_notes TEXT,
    physical_examination TEXT,
    recorded_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id) ON DELETE CASCADE,
    FOREIGN KEY (recorded_by) REFERENCES users(users_id)
);

-- Chan doan Y khoa (Encounter Diagnoses)
CREATE TABLE encounter_diagnoses (
    encounter_diagnoses_id VARCHAR(50) PRIMARY KEY,
    encounter_id VARCHAR(50) NOT NULL,
    icd10_code VARCHAR(20) NOT NULL,
    diagnosis_name VARCHAR(255) NOT NULL,
    diagnosis_type VARCHAR(50) DEFAULT 'PRIMARY', -- PRIMARY, SECONDARY, PRELIMINARY, FINAL
    notes TEXT,
    diagnosed_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id) ON DELETE CASCADE,
    FOREIGN KEY (diagnosed_by) REFERENCES users(users_id)
);

-- Chi dinh Dich vu Can lam sang (Medical Orders)
CREATE TABLE medical_orders (
    medical_orders_id VARCHAR(50) PRIMARY KEY,
    encounter_id VARCHAR(50) NOT NULL,
    service_code VARCHAR(50) NOT NULL,
    service_name VARCHAR(255) NOT NULL,
    clinical_indicator TEXT,
    priority VARCHAR(50) DEFAULT 'ROUTINE', -- ROUTINE, URGENT
    status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, IN_PROGRESS, COMPLETED, CANCELLED
    ordered_by VARCHAR(50) NOT NULL,
    ordered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id) ON DELETE CASCADE,
    FOREIGN KEY (ordered_by) REFERENCES users(users_id)
);

-- Ket qua Can lam sang (Medical Order Results)
CREATE TABLE medical_order_results (
    medical_order_results_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL UNIQUE,
    result_summary TEXT,
    result_details JSON,
    attachment_urls JSON,
    performed_by VARCHAR(50),
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES medical_orders(medical_orders_id) ON DELETE CASCADE,
    FOREIGN KEY (performed_by) REFERENCES users(users_id)
);

-- Ky so & Khoa Benh an (EMR Digital Signatures)
CREATE TABLE emr_signatures (
    emr_signatures_id VARCHAR(50) PRIMARY KEY,
    encounter_id VARCHAR(50) NOT NULL UNIQUE,
    signed_by VARCHAR(50) NOT NULL,
    signature_hash VARCHAR(255) NOT NULL,
    certificate_serial VARCHAR(100),
    signed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    client_ip VARCHAR(45),
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id) ON DELETE CASCADE,
    FOREIGN KEY (signed_by) REFERENCES users(users_id)
);

-- *********************************************************************
-- MODULE 6: KE DON & QUAN LY THUOC (PRESCRIPTIONS & PHARMACY)
-- *********************************************************************

-- Phan nhom thuoc (Drug Categories)
CREATE TABLE drug_categories (
    drug_categories_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    deleted_at TIMESTAMP
);

-- Danh muc Thuoc (Master Drugs)
CREATE TABLE drugs (
    drugs_id VARCHAR(50) PRIMARY KEY,
    drug_code VARCHAR(50) UNIQUE NOT NULL,
    national_drug_code VARCHAR(100), -- Ma thuoc Quoc gia (DQG)
    brand_name VARCHAR(255) NOT NULL,
    active_ingredients TEXT NOT NULL,
    category_id VARCHAR(50),
    route_of_administration VARCHAR(50), -- ORAL, INJECTION, TOPICAL
    dispensing_unit VARCHAR(20) NOT NULL, -- Vien, Lo, Tuyp
    is_prescription_only BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES drug_categories(drug_categories_id)
);

-- Tương tác thuốc (Drug Interactions)
CREATE TABLE drug_interactions (
    drug_interactions_id VARCHAR(50) PRIMARY KEY,
    drug_id_1 VARCHAR(50) NOT NULL,
    drug_id_2 VARCHAR(50) NOT NULL,
    severity VARCHAR(50) NOT NULL, -- SEVERE, MODERATE, MILD
    interaction_type VARCHAR(100),
    description TEXT,
    clinical_effect TEXT,
    recommendation TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (drug_id_1) REFERENCES drugs(drugs_id) ON DELETE CASCADE,
    FOREIGN KEY (drug_id_2) REFERENCES drugs(drugs_id) ON DELETE CASCADE,
    UNIQUE (drug_id_1, drug_id_2)
);

-- Don thuoc (Prescriptions Header)
CREATE TABLE prescriptions (
    prescriptions_id VARCHAR(50) PRIMARY KEY,
    prescription_code VARCHAR(50) UNIQUE NOT NULL,
    encounter_id VARCHAR(50) NOT NULL,
    doctor_id VARCHAR(50) NOT NULL,
    patient_id VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'DRAFT', -- DRAFT, PRESCRIBED, DISPENSED, CANCELLED
    clinical_diagnosis TEXT,
    doctor_notes TEXT,
    prescribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES users(users_id)
);

-- Chi tiet Don thuoc (Prescription Details)
CREATE TABLE prescription_details (
    prescription_details_id VARCHAR(50) PRIMARY KEY,
    prescription_id VARCHAR(50) NOT NULL,
    drug_id VARCHAR(50) NOT NULL,
    quantity INT NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    duration_days INT,
    usage_instruction TEXT,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescriptions_id) ON DELETE CASCADE,
    FOREIGN KEY (drug_id) REFERENCES drugs(drugs_id)
);

-- Ton kho thuoc (Pharmacy Inventory)
CREATE TABLE pharmacy_inventory (
    pharmacy_inventory_id VARCHAR(50) PRIMARY KEY,
    drug_id VARCHAR(50) NOT NULL,
    batch_number VARCHAR(100) NOT NULL,
    expiry_date DATE NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    unit_cost DECIMAL(12,2),
    unit_price DECIMAL(12,2),
    location_bin VARCHAR(50),
    FOREIGN KEY (drug_id) REFERENCES drugs(drugs_id) ON DELETE CASCADE,
    UNIQUE (drug_id, batch_number)
);

-- Phieu xuat / Cap phat thuoc (Drug Dispense Orders)
CREATE TABLE drug_dispense_orders (
    drug_dispense_orders_id VARCHAR(50) PRIMARY KEY,
    prescription_id VARCHAR(50) NOT NULL UNIQUE,
    pharmacist_id VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'COMPLETED',
    dispensed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescriptions_id),
    FOREIGN KEY (pharmacist_id) REFERENCES users(users_id)
);

-- Chi tiet Cap phat & Tru kho (Drug Dispense Details)
CREATE TABLE drug_dispense_details (
    drug_dispense_details_id VARCHAR(50) PRIMARY KEY,
    dispense_order_id VARCHAR(50) NOT NULL,
    prescription_detail_id VARCHAR(50) NOT NULL,
    inventory_id VARCHAR(50) NOT NULL,
    dispensed_quantity INT NOT NULL,
    FOREIGN KEY (dispense_order_id) REFERENCES drug_dispense_orders(drug_dispense_orders_id) ON DELETE CASCADE,
    FOREIGN KEY (prescription_detail_id) REFERENCES prescription_details(prescription_details_id),
    FOREIGN KEY (inventory_id) REFERENCES pharmacy_inventory(pharmacy_inventory_id)
);

-- *********************************************************************
-- MODULE 7: DICH VU Y TE & BAO HIEM (MEDICAL SERVICES & INSURANCE)
-- *********************************************************************

-- Nhom dich vu
CREATE TABLE service_categories (
    service_categories_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

-- Danh muc Dich vu Chuan (Master Services)
CREATE TABLE services (
    services_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    service_group VARCHAR(50), -- KHAM, XN, CDHA, THUTHUAT
    service_type VARCHAR(50), -- CLINICAL, LABORATORY, RADIOLOGY, PROCEDURE
    insurance_code VARCHAR(100), -- Ma dich vu BHYT quoc gia
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Dich vu tai Co so (Facility Services) - Bang gia rieng moi co so
CREATE TABLE facility_services (
    facility_services_id VARCHAR(50) PRIMARY KEY,
    facility_id VARCHAR(50) NOT NULL,
    service_id VARCHAR(50) NOT NULL,
    department_id VARCHAR(50), -- Map DV vao chuyen khoa cu the
    base_price DECIMAL(12,2) NOT NULL, -- Gia dich vu (VND)
    insurance_price DECIMAL(12,2), -- Gia BHYT chi tra
    vip_price DECIMAL(12,2) DEFAULT 0, -- Gia VIP
    estimated_duration_minutes INT DEFAULT 15,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(services_id),
    FOREIGN KEY (department_id) REFERENCES departments(departments_id) ON DELETE SET NULL,
    UNIQUE (facility_id, service_id)
);

-- Deferred FK: appointments.facility_service_id (bang appointments tao truoc o Module 4)
ALTER TABLE appointments
    ADD CONSTRAINT fk_appointments_facility_service
    FOREIGN KEY (facility_service_id) REFERENCES facility_services(facility_services_id) ON DELETE SET NULL;

-- Lien ket Chuyen khoa - Dich vu
CREATE TABLE specialty_services (
    specialty_id VARCHAR(50) NOT NULL,
    service_id VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (specialty_id, service_id),
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialties_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(services_id) ON DELETE CASCADE
);

-- Lien ket Bac si - Dich vu co so
CREATE TABLE doctor_services (
    doctor_id VARCHAR(50) NOT NULL,
    facility_service_id VARCHAR(50) NOT NULL,
    is_primary BOOLEAN DEFAULT TRUE,
    assigned_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (doctor_id, facility_service_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctors_id) ON DELETE CASCADE,
    FOREIGN KEY (facility_service_id) REFERENCES facility_services(facility_services_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(users_id) ON DELETE SET NULL
);

-- (insurance_providers va insurance_coverages da duoc di chuyen len Module 2)

-- Khuyen mai (Promotions)
CREATE TABLE promotions (
    promotions_id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    discount_type VARCHAR(20) NOT NULL, -- PERCENTAGE, FIXED_AMOUNT
    discount_value DECIMAL(12,2) NOT NULL,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- *********************************************************************
-- MODULE 8: THANH TOAN & THU NGAN (BILLING & CASHIER)
-- *********************************************************************

-- Hoa don tong (Invoices)
CREATE TABLE invoices (
    invoices_id VARCHAR(50) PRIMARY KEY,
    invoice_code VARCHAR(50) UNIQUE NOT NULL,
    patient_id VARCHAR(50) NOT NULL,
    encounter_id VARCHAR(50),
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    insurance_amount DECIMAL(12,2) DEFAULT 0,
    net_amount DECIMAL(12,2) NOT NULL,
    paid_amount DECIMAL(12,2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'UNPAID', -- UNPAID, PARTIAL, PAID, CANCELLED
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id) ON DELETE SET NULL
);

-- Chi tiet Hoa don (Invoice Details)
CREATE TABLE invoice_details (
    invoice_details_id VARCHAR(50) PRIMARY KEY,
    invoice_id VARCHAR(50) NOT NULL,
    reference_type VARCHAR(50) NOT NULL, -- CONSULTATION, LAB_ORDER, DRUG
    reference_id VARCHAR(50) NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoices_id) ON DELETE CASCADE
);

-- Giao dich Thanh toan (Payment Transactions)
CREATE TABLE payment_transactions (
    payment_transactions_id VARCHAR(50) PRIMARY KEY,
    transaction_code VARCHAR(100) UNIQUE NOT NULL,
    invoice_id VARCHAR(50) NOT NULL,
    transaction_type VARCHAR(50) DEFAULT 'PAYMENT', -- PAYMENT, REFUND
    payment_method VARCHAR(50) NOT NULL, -- CASH, CREDIT_CARD, VNPAY, MOMO
    amount DECIMAL(12,2) NOT NULL,
    gateway_transaction_id VARCHAR(255),
    gateway_response JSON,
    status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, SUCCESS, FAILED, REFUNDED
    cashier_id VARCHAR(50),
    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoices_id),
    FOREIGN KEY (cashier_id) REFERENCES users(users_id)
);

-- Ca lam viec Thu ngan (Cashier Shifts)
CREATE TABLE cashier_shifts (
    cashier_shifts_id VARCHAR(50) PRIMARY KEY,
    cashier_id VARCHAR(50) NOT NULL,
    shift_start TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    shift_end TIMESTAMP,
    opening_balance DECIMAL(12,2) NOT NULL,
    system_calculated_balance DECIMAL(12,2) DEFAULT 0,
    actual_closing_balance DECIMAL(12,2),
    status VARCHAR(50) DEFAULT 'OPEN', -- OPEN, CLOSED, DISCREPANCY
    notes TEXT,
    FOREIGN KEY (cashier_id) REFERENCES users(users_id)
);

-- *********************************************************************
-- MODULE 9: HO SO SUC KHOE DIEN TU (EHR - Electronic Health Records)
-- *********************************************************************

-- Dong thoi gian suc khoe (Health Timeline Events)
CREATE TABLE health_timeline_events (
    health_timeline_events_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) NOT NULL,
    event_date TIMESTAMP NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- ENCOUNTER, LAB_RESULT, PRESCRIPTION, VACCINATION
    title VARCHAR(255) NOT NULL,
    summary TEXT,
    reference_id VARCHAR(50), -- ID tro ve bang goc
    reference_table VARCHAR(50), -- Ten bang goc (encounters, prescriptions)
    source_system VARCHAR(100) DEFAULT 'INTERNAL_HIS',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_timeline_patient_date ON health_timeline_events(patient_id, event_date DESC);

-- Chi so suc khoe lien tuc (Health Metrics)
CREATE TABLE patient_health_metrics (
    patient_health_metrics_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) NOT NULL,
    metric_code VARCHAR(50) NOT NULL, -- BLOOD_PRESSURE, BLOOD_SUGAR, HEART_RATE
    metric_name VARCHAR(100) NOT NULL,
    metric_value JSON NOT NULL,
    unit VARCHAR(20) NOT NULL, -- mmHg, mg/dL, bpm, kg
    measured_at TIMESTAMP NOT NULL,
    source_type VARCHAR(50) DEFAULT 'SELF_REPORTED', -- SELF_REPORTED, CLINIC, DEVICE
    device_info VARCHAR(255)
);

-- Dong bo du lieu ben ngoai (External Health Records)
CREATE TABLE external_health_records (
    external_health_records_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) NOT NULL,
    provider_name VARCHAR(255) NOT NULL,
    integration_protocol VARCHAR(50), -- REST_API, HL7_FHIR, SOAP
    data_type VARCHAR(50), -- VACCINE_CERT, LAB_HISTORY
    raw_payload JSONB NOT NULL,
    sync_status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, PROCESSED, FAILED
    synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Quyen truy cap & Chia se ho so (EHR Access Control)
CREATE TABLE ehr_access_grants (
    ehr_access_grants_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) NOT NULL,
    granted_to_user_id VARCHAR(50) NOT NULL,
    access_level VARCHAR(50) DEFAULT 'READ_ONLY', -- READ_ONLY, FULL_ACCESS
    allowed_modules JSON, -- ["LAB_RESULTS", "PRESCRIPTIONS"]
    valid_from TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP, -- NULL = vinh vien
    status VARCHAR(50) DEFAULT 'ACTIVE', -- ACTIVE, REVOKED
    granted_by VARCHAR(50),
    FOREIGN KEY (granted_to_user_id) REFERENCES users(users_id) ON DELETE CASCADE
);

-- *********************************************************************
-- MODULE 10: TU VAN & KHAM TU XA (TELEMEDICINE)
-- *********************************************************************

-- Phong kham truc tuyen (Virtual Consultation Room)
CREATE TABLE tele_consultations (
    tele_consultations_id VARCHAR(50) PRIMARY KEY,
    encounter_id VARCHAR(50) NOT NULL UNIQUE,
    platform VARCHAR(50) DEFAULT 'AGORA', -- ZOOM, AGORA, STRINGEE
    meeting_id VARCHAR(100),
    meeting_password VARCHAR(100),
    host_url TEXT,
    join_url TEXT NOT NULL,
    recording_url TEXT,
    recording_duration INT, -- Thoi luong (giay)
    call_status VARCHAR(50) DEFAULT 'SCHEDULED', -- SCHEDULED, ONGOING, COMPLETED, MISSED
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id) ON DELETE CASCADE
);

-- Tin nhan truc tuyen (Tele Messages / Chat)
CREATE TABLE tele_messages (
    tele_messages_id VARCHAR(50) PRIMARY KEY,
    tele_consultation_id VARCHAR(50) NOT NULL,
    sender_id VARCHAR(50) NOT NULL,
    sender_type VARCHAR(50), -- DOCTOR, PATIENT, SYSTEM
    message_type VARCHAR(50) DEFAULT 'TEXT', -- TEXT, IMAGE, FILE_PDF
    content TEXT,
    file_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tele_consultation_id) REFERENCES tele_consultations(tele_consultations_id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(users_id) ON DELETE CASCADE
);

CREATE INDEX idx_tele_messages_time ON tele_messages(tele_consultation_id, sent_at ASC);

-- Danh gia chat luong dich vu (Tele Feedbacks)
CREATE TABLE tele_feedbacks (
    tele_feedbacks_id VARCHAR(50) PRIMARY KEY,
    tele_consultation_id VARCHAR(50) NOT NULL UNIQUE,
    patient_id VARCHAR(50) NOT NULL,
    doctor_rating INT CHECK (doctor_rating >= 1 AND doctor_rating <= 5),
    doctor_feedback TEXT,
    tech_rating INT CHECK (tech_rating >= 1 AND tech_rating <= 5),
    tech_feedback TEXT,
    tech_issues_tags JSON, -- ["AUDIO_ISSUE", "DISCONNECTED"]
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tele_consultation_id) REFERENCES tele_consultations(tele_consultations_id) ON DELETE CASCADE
);

-- *********************************************************************
-- MODULE 11: TRANG THIET BI & GIUONG BENH (EQUIPMENT & BED MANAGEMENT)
-- *********************************************************************

-- Trang thiet bi y te (Medical Equipments)
CREATE TABLE medical_equipments (
    equipment_id VARCHAR(50) PRIMARY KEY,
    facility_id VARCHAR(50) NOT NULL,
    branch_id VARCHAR(50) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    serial_number VARCHAR(100),
    manufacturer VARCHAR(100),
    manufacturing_date DATE,
    purchase_date DATE,
    warranty_expiration DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, MAINTENANCE, BROKEN, RETIRED
    current_room_id VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(branches_id) ON DELETE CASCADE,
    FOREIGN KEY (current_room_id) REFERENCES medical_rooms(medical_rooms_id) ON DELETE SET NULL
);

-- Nhat ky bao tri (Equipment Maintenance Logs)
CREATE TABLE equipment_maintenance_logs (
    log_id VARCHAR(50) PRIMARY KEY,
    equipment_id VARCHAR(50) NOT NULL,
    maintenance_date DATE NOT NULL,
    maintenance_type VARCHAR(20) NOT NULL, -- SCHEDULED, EMERGENCY, CALIBRATION
    description TEXT,
    performed_by VARCHAR(255),
    cost DECIMAL(15,2) DEFAULT 0.00,
    next_maintenance_date DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (equipment_id) REFERENCES medical_equipments(equipment_id) ON DELETE CASCADE
);

-- Giuong benh (Beds)
CREATE TABLE beds (
    bed_id VARCHAR(50) PRIMARY KEY,
    facility_id VARCHAR(50) NOT NULL,
    branch_id VARCHAR(50) NOT NULL,
    department_id VARCHAR(50),
    room_id VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'STANDARD', -- STANDARD, ICU, EMERGENCY
    status VARCHAR(20) NOT NULL DEFAULT 'EMPTY', -- EMPTY, OCCUPIED, CLEANING, BROKEN
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(branches_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments(departments_id) ON DELETE SET NULL,
    FOREIGN KEY (room_id) REFERENCES medical_rooms(medical_rooms_id) ON DELETE SET NULL
);


--Khoá khung giờ không khả dụng (Locked Slots)
-- Bảng cho phép khoá slot theo ngày cụ thể (không phải disable vĩnh viễn)
CREATE TABLE locked_slots (
    locked_slot_id VARCHAR(50) PRIMARY KEY,
    slot_id VARCHAR(50) NOT NULL,
    locked_date DATE NOT NULL,
    lock_reason TEXT,
    locked_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    FOREIGN KEY (slot_id) REFERENCES appointment_slots(slot_id) ON DELETE CASCADE,
    FOREIGN KEY (locked_by) REFERENCES users(users_id) ON DELETE SET NULL,
    UNIQUE(slot_id, locked_date)
);


-- =====================================================================
-- Phân biệt ca khám theo dịch vụ (Shift-Service Mapping)
-- Bảng liên kết N-N giữa shifts và facility_services
-- =====================================================================

CREATE TABLE shift_services (
    shift_service_id VARCHAR(50) PRIMARY KEY,
    shift_id VARCHAR(50) NOT NULL,
    facility_service_id VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shift_id) REFERENCES shifts(shifts_id) ON DELETE CASCADE,
    FOREIGN KEY (facility_service_id) REFERENCES facility_services(facility_services_id) ON DELETE CASCADE,
    UNIQUE(shift_id, facility_service_id)
);


-- =====================================================================
-- – Doctor Absence (Vắng đột xuất bác sĩ)
-- Bảng lưu trữ lịch vắng đột xuất của bác sĩ=

CREATE TABLE doctor_absences (
    absence_id VARCHAR(50) PRIMARY KEY,
    doctor_id VARCHAR(50) NOT NULL,
    absence_date DATE NOT NULL,
    shift_id VARCHAR(50),                    
    absence_type VARCHAR(50) NOT NULL,       
    reason TEXT,
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctors_id) ON DELETE CASCADE,
    FOREIGN KEY (shift_id) REFERENCES shifts(shifts_id),
    FOREIGN KEY (created_by) REFERENCES users(users_id) ON DELETE SET NULL
);


-- =====================================================================
-- Room-Service Mapping (Phân loại phòng theo dịch vụ)

CREATE TABLE room_services (
    room_id VARCHAR(50) NOT NULL,
    facility_service_id VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (room_id, facility_service_id),
    FOREIGN KEY (room_id) REFERENCES medical_rooms(medical_rooms_id) ON DELETE CASCADE,
    FOREIGN KEY (facility_service_id) REFERENCES facility_services(facility_services_id) ON DELETE CASCADE
);

-- =====================================================================
-- Room Maintenance Schedules (Khoá phòng bảo trì)

CREATE TABLE room_maintenance_schedules (
    maintenance_id VARCHAR(50) PRIMARY KEY,
    room_id VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    FOREIGN KEY (room_id) REFERENCES medical_rooms(medical_rooms_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(users_id) ON DELETE SET NULL,
    CHECK (end_date >= start_date)
);


-- 2. Bảng tracking nhắc lịch
CREATE TABLE IF NOT EXISTS appointment_reminders (
    reminder_id VARCHAR(50) PRIMARY KEY,
    appointment_id VARCHAR(50) NOT NULL,
    reminder_type VARCHAR(20) NOT NULL,     -- AUTO | MANUAL
    channel VARCHAR(20) NOT NULL,           -- INAPP | EMAIL | PUSH
    sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    sent_by VARCHAR(50) NULL,               -- NULL nếu AUTO (cron job)
    trigger_source VARCHAR(50) NOT NULL,    -- CRON_JOB | STAFF_MANUAL
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointments_id) ON DELETE CASCADE,
    FOREIGN KEY (sent_by) REFERENCES users(users_id) ON DELETE SET NULL
);



-- 1. Bảng mới: appointment_change_logs — lưu lịch sử dời/hủy
CREATE TABLE IF NOT EXISTS appointment_change_logs (
    id VARCHAR(50) PRIMARY KEY,
    appointment_id VARCHAR(50) NOT NULL REFERENCES appointments(appointments_id) ON DELETE CASCADE,
    change_type VARCHAR(20) NOT NULL, -- RESCHEDULE / CANCEL
    old_date DATE,
    old_slot_id VARCHAR(50),
    new_date DATE,
    new_slot_id VARCHAR(50),
    reason TEXT,
    changed_by VARCHAR(50),
    policy_checked BOOLEAN DEFAULT FALSE,
    policy_result VARCHAR(30), -- ALLOWED / LATE_CANCEL / BLOCKED
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_change_logs_appointment ON appointment_change_logs(appointment_id);
CREATE INDEX IF NOT EXISTS idx_change_logs_type ON appointment_change_logs(change_type);
CREATE INDEX IF NOT EXISTS idx_change_logs_created ON appointment_change_logs(created_at DESC);

-- 2. Bảng mới: appointment_coordination_logs
CREATE TABLE IF NOT EXISTS appointment_coordination_logs (
    id VARCHAR(50) PRIMARY KEY,
    appointment_id VARCHAR(50) NOT NULL REFERENCES appointments(appointments_id) ON DELETE CASCADE,
    action_type VARCHAR(30) NOT NULL, -- REASSIGN_DOCTOR / SET_PRIORITY / AUTO_ASSIGN
    old_value TEXT,
    new_value TEXT,
    reason TEXT,
    performed_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);



-- 1. Kế hoạch điều trị
CREATE TABLE treatment_plans (
    treatment_plans_id VARCHAR(50) PRIMARY KEY,
    plan_code VARCHAR(50) UNIQUE NOT NULL,
    patient_id VARCHAR(50) NOT NULL,
    primary_diagnosis_code VARCHAR(20) NOT NULL,
    primary_diagnosis_name VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    goals TEXT,
    start_date DATE NOT NULL,
    expected_end_date DATE,
    actual_end_date DATE,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    created_by VARCHAR(50) NOT NULL,
    created_encounter_id VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(users_id),
    FOREIGN KEY (created_encounter_id) REFERENCES encounters(encounters_id)
);

CREATE INDEX idx_tp_patient ON treatment_plans(patient_id);
CREATE INDEX idx_tp_status ON treatment_plans(status);
CREATE INDEX idx_tp_diagnosis ON treatment_plans(primary_diagnosis_code);

-- 2. Ghi nhận diễn tiến
CREATE TABLE treatment_progress_notes (
    treatment_progress_notes_id VARCHAR(50) PRIMARY KEY,
    plan_id VARCHAR(50) NOT NULL,
    encounter_id VARCHAR(50),
    note_type VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    content TEXT NOT NULL,
    severity VARCHAR(20) DEFAULT 'NORMAL',
    recorded_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES treatment_plans(treatment_plans_id) ON DELETE CASCADE,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id),
    FOREIGN KEY (recorded_by) REFERENCES users(users_id)
);

CREATE INDEX idx_tpn_plan ON treatment_progress_notes(plan_id);
CREATE INDEX idx_tpn_encounter ON treatment_progress_notes(encounter_id);
CREATE INDEX idx_tpn_type ON treatment_progress_notes(note_type);

-- 3. Liên kết chuỗi tái khám
CREATE TABLE encounter_follow_up_links (
    encounter_follow_up_links_id VARCHAR(50) PRIMARY KEY,
    plan_id VARCHAR(50) NOT NULL,
    previous_encounter_id VARCHAR(50) NOT NULL,
    follow_up_encounter_id VARCHAR(50) NOT NULL,
    follow_up_reason TEXT,
    scheduled_date DATE,
    actual_date DATE,
    notes TEXT,
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES treatment_plans(treatment_plans_id) ON DELETE CASCADE,
    FOREIGN KEY (previous_encounter_id) REFERENCES encounters(encounters_id),
    FOREIGN KEY (follow_up_encounter_id) REFERENCES encounters(encounters_id),
    FOREIGN KEY (created_by) REFERENCES users(users_id),
    UNIQUE(previous_encounter_id, follow_up_encounter_id)
);

-- =====================================================================
-- MODULE 4.5: KÊ ĐƠN THUỐC (PRESCRIPTION MANAGEMENT)
-- Bổ sung cột cho bảng prescriptions & prescription_details
-- =====================================================================

-- 1. UNIQUE constraint: 1 encounter = 1 đơn thuốc
ALTER TABLE prescriptions
    ADD CONSTRAINT uq_prescriptions_encounter UNIQUE (encounter_id);

-- 2. Liên kết chẩn đoán chính
ALTER TABLE prescriptions
    ADD COLUMN primary_diagnosis_id VARCHAR(50) NULL
        REFERENCES encounter_diagnoses(encounter_diagnoses_id) ON DELETE SET NULL;

-- 3. Timestamps quản lý vòng đời
ALTER TABLE prescriptions
    ADD COLUMN updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN cancelled_at TIMESTAMPTZ NULL,
    ADD COLUMN cancelled_reason TEXT NULL;

-- 4. Index tối ưu truy vấn
CREATE INDEX idx_prescriptions_status ON prescriptions(status);
CREATE INDEX idx_prescriptions_doctor ON prescriptions(doctor_id);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);

-- =====================================================================
-- PRESCRIPTION DETAILS — Bổ sung cột
-- =====================================================================

-- 1. Đường dùng thuốc + ghi chú BS
ALTER TABLE prescription_details
    ADD COLUMN route_of_administration VARCHAR(50) NULL,
    ADD COLUMN notes TEXT NULL;

-- 2. Sắp xếp + soft delete
ALTER TABLE prescription_details
    ADD COLUMN sort_order INT DEFAULT 0,
    ADD COLUMN is_active BOOLEAN DEFAULT TRUE;

-- 3. Timestamps
ALTER TABLE prescription_details
    ADD COLUMN created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Index cho tìm kiếm dòng thuốc theo đơn
CREATE INDEX idx_prescription_details_prescription ON prescription_details(prescription_id);
CREATE INDEX idx_prescription_details_drug ON prescription_details(drug_id);



-- *********************************************************************
-- PERFORMANCE INDEXES
-- *********************************************************************

-- Patient Module
CREATE INDEX idx_patients_code ON patients(patient_code);
CREATE INDEX idx_patients_phone ON patients(phone_number) WHERE phone_number IS NOT NULL;
CREATE INDEX idx_patients_status ON patients(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_patient_contacts_patient ON patient_contacts(patient_id);
CREATE INDEX idx_patient_insurances_patient ON patient_insurances(patient_id);
CREATE INDEX idx_patient_tags_patient ON patient_tags(patient_id);
CREATE INDEX idx_patient_tags_tag ON patient_tags(tag_id);
CREATE INDEX idx_patient_documents_patient ON patient_documents(patient_id);

-- Facility Module
CREATE INDEX idx_departments_branch ON departments(branch_id);
CREATE INDEX idx_departments_group ON departments(group_type);
CREATE INDEX idx_medical_rooms_branch ON medical_rooms(branch_id);
CREATE INDEX idx_medical_rooms_dept ON medical_rooms(department_id);
CREATE INDEX idx_medical_rooms_status ON medical_rooms(status) WHERE deleted_at IS NULL;

-- Scheduling & Appointments
CREATE INDEX idx_staff_schedules_user_date ON staff_schedules(user_id, working_date);
CREATE INDEX idx_staff_schedules_room ON staff_schedules(medical_room_id);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointment_slots_shift ON appointment_slots(shift_id);
CREATE INDEX idx_doctor_absences_doctor_date ON doctor_absences(doctor_id, absence_date);
CREATE INDEX idx_locked_slots_date ON locked_slots(slot_id, locked_date);

-- EMR Module
CREATE INDEX idx_encounters_patient ON encounters(patient_id);
CREATE INDEX idx_encounters_doctor ON encounters(doctor_id);
CREATE INDEX idx_encounters_status ON encounters(status);
CREATE INDEX idx_encounter_diagnoses_encounter ON encounter_diagnoses(encounter_id);
CREATE INDEX idx_encounter_diagnoses_icd ON encounter_diagnoses(icd10_code);
CREATE INDEX idx_medical_orders_encounter ON medical_orders(encounter_id);

-- Pharmacy Module
CREATE INDEX idx_drugs_category ON drugs(category_id);
CREATE INDEX idx_prescriptions_encounter ON prescriptions(encounter_id);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX idx_pharmacy_inventory_drug ON pharmacy_inventory(drug_id);
CREATE INDEX idx_pharmacy_inventory_expiry ON pharmacy_inventory(expiry_date);

-- Billing Module
CREATE INDEX idx_invoices_patient ON invoices(patient_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_payment_transactions_invoice ON payment_transactions(invoice_id);

-- Audit & Notifications
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_module ON audit_logs(module_name);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);
CREATE INDEX idx_user_notifications_user ON user_notifications(user_id);
CREATE INDEX idx_user_notifications_read ON user_notifications(is_read) WHERE is_read = FALSE;




-- 1. Bảng warehouses
CREATE TABLE IF NOT EXISTS warehouses (
    warehouse_id     VARCHAR(50) PRIMARY KEY,
    branch_id        VARCHAR(50) NOT NULL,
    code             VARCHAR(50) NOT NULL,
    name             VARCHAR(100) NOT NULL,
    warehouse_type   VARCHAR(20) DEFAULT 'MAIN',  -- MAIN | SECONDARY
    address          TEXT,
    is_active        BOOLEAN DEFAULT TRUE,
    created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (branch_id) REFERENCES branches(branches_id) ON DELETE CASCADE,
    UNIQUE(branch_id, code)
    pharmacy_inventory
);

-- 2. Gắn pharmacy_inventory vào kho
ALTER TABLE pharmacy_inventory
    ADD COLUMN IF NOT EXISTS warehouse_id VARCHAR(50) REFERENCES warehouses(warehouse_id);



-- 1. Kế hoạch điều trị
CREATE TABLE treatment_plans (
    treatment_plans_id VARCHAR(50) PRIMARY KEY,
    plan_code VARCHAR(50) UNIQUE NOT NULL,
    patient_id VARCHAR(50) NOT NULL,
    primary_diagnosis_code VARCHAR(20) NOT NULL,
    primary_diagnosis_name VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    goals TEXT,
    start_date DATE NOT NULL,
    expected_end_date DATE,
    actual_end_date DATE,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    created_by VARCHAR(50) NOT NULL,
    created_encounter_id VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(users_id),
    FOREIGN KEY (created_encounter_id) REFERENCES encounters(encounters_id)
);

CREATE INDEX idx_tp_patient ON treatment_plans(patient_id);
CREATE INDEX idx_tp_status ON treatment_plans(status);
CREATE INDEX idx_tp_diagnosis ON treatment_plans(primary_diagnosis_code);

-- 2. Ghi nhận diễn tiến
CREATE TABLE treatment_progress_notes (
    treatment_progress_notes_id VARCHAR(50) PRIMARY KEY,
    plan_id VARCHAR(50) NOT NULL,
    encounter_id VARCHAR(50),
    note_type VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    content TEXT NOT NULL,
    severity VARCHAR(20) DEFAULT 'NORMAL',
    recorded_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES treatment_plans(treatment_plans_id) ON DELETE CASCADE,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id),
    FOREIGN KEY (recorded_by) REFERENCES users(users_id)
);

CREATE INDEX idx_tpn_plan ON treatment_progress_notes(plan_id);
CREATE INDEX idx_tpn_encounter ON treatment_progress_notes(encounter_id);
CREATE INDEX idx_tpn_type ON treatment_progress_notes(note_type);

-- 3. Liên kết chuỗi tái khám
CREATE TABLE encounter_follow_up_links (
    encounter_follow_up_links_id VARCHAR(50) PRIMARY KEY,
    plan_id VARCHAR(50) NOT NULL,
    previous_encounter_id VARCHAR(50) NOT NULL,
    follow_up_encounter_id VARCHAR(50) NOT NULL,
    follow_up_reason TEXT,
    scheduled_date DATE,
    actual_date DATE,
    notes TEXT,
    created_by VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES treatment_plans(treatment_plans_id) ON DELETE CASCADE,
    FOREIGN KEY (previous_encounter_id) REFERENCES encounters(encounters_id),
    FOREIGN KEY (follow_up_encounter_id) REFERENCES encounters(encounters_id),
    FOREIGN KEY (created_by) REFERENCES users(users_id),
    UNIQUE(previous_encounter_id, follow_up_encounter_id)
);




-- 1. Phiếu xuất kho
CREATE TABLE IF NOT EXISTS stock_out_orders (
    stock_out_order_id   VARCHAR(50) PRIMARY KEY,
    order_code           VARCHAR(50) UNIQUE NOT NULL,
    warehouse_id         VARCHAR(50) NOT NULL,
    reason_type          VARCHAR(30) NOT NULL,
    supplier_id          VARCHAR(50),
    dest_warehouse_id    VARCHAR(50),
    created_by           VARCHAR(50) NOT NULL,
    status               VARCHAR(20) DEFAULT 'DRAFT',
    notes                TEXT,
    total_quantity       INT DEFAULT 0,
    confirmed_at         TIMESTAMPTZ,
    confirmed_by         VARCHAR(50),
    cancelled_at         TIMESTAMPTZ,
    cancelled_reason     TEXT,
    created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
    FOREIGN KEY (dest_warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (created_by) REFERENCES users(users_id),
    FOREIGN KEY (confirmed_by) REFERENCES users(users_id)
);

-- 2. Chi tiết xuất kho
CREATE TABLE IF NOT EXISTS stock_out_details (
    stock_out_detail_id  VARCHAR(50) PRIMARY KEY,
    stock_out_order_id   VARCHAR(50) NOT NULL,
    inventory_id         VARCHAR(50) NOT NULL,
    drug_id              VARCHAR(50) NOT NULL,
    batch_number         VARCHAR(100) NOT NULL,
    quantity             INT NOT NULL,
    reason_note          TEXT,
    created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (stock_out_order_id) REFERENCES stock_out_orders(stock_out_order_id) ON DELETE CASCADE,
    FOREIGN KEY (inventory_id) REFERENCES pharmacy_inventory(pharmacy_inventory_id),
    FOREIGN KEY (drug_id) REFERENCES drugs(drugs_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_stock_out_orders_warehouse ON stock_out_orders(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_stock_out_orders_status ON stock_out_orders(status);
CREATE INDEX IF NOT EXISTS idx_stock_out_orders_reason ON stock_out_orders(reason_type);
CREATE INDEX IF NOT EXISTS idx_stock_out_details_order ON stock_out_details(stock_out_order_id);



-- 1. UNIQUE constraint: 1 encounter = 1 đơn thuốc
ALTER TABLE prescriptions
    ADD CONSTRAINT uq_prescriptions_encounter UNIQUE (encounter_id);

-- 2. Liên kết chẩn đoán chính
ALTER TABLE prescriptions
    ADD COLUMN primary_diagnosis_id VARCHAR(50) NULL
        REFERENCES encounter_diagnoses(encounter_diagnoses_id) ON DELETE SET NULL;

-- 3. Timestamps quản lý vòng đời
ALTER TABLE prescriptions
    ADD COLUMN updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN cancelled_at TIMESTAMPTZ NULL,
    ADD COLUMN cancelled_reason TEXT NULL;

-- 4. Index tối ưu truy vấn
CREATE INDEX idx_prescriptions_status ON prescriptions(status);
CREATE INDEX idx_prescriptions_doctor ON prescriptions(doctor_id);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);



-- 1. Bảng metadata EHR — 1:1 với patients
-- Lưu ghi chú tổng hợp, mức rủi ro, thời điểm BS review gần nhất
CREATE TABLE IF NOT EXISTS ehr_health_profiles (
    ehr_profile_id       VARCHAR(50) PRIMARY KEY,
    patient_id           VARCHAR(50) NOT NULL UNIQUE,
    risk_level           VARCHAR(20) DEFAULT 'LOW',       -- LOW, MODERATE, HIGH, CRITICAL
    ehr_notes            TEXT,                              -- Ghi chú tổng hợp của BS
    last_reviewed_by     VARCHAR(50),                       -- BS xem xét gần nhất
    last_reviewed_at     TIMESTAMPTZ,
    created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (last_reviewed_by) REFERENCES users(users_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_ehr_profiles_patient ON ehr_health_profiles(patient_id);
CREATE INDEX IF NOT EXISTS idx_ehr_profiles_risk ON ehr_health_profiles(risk_level);

-- 2. Bảng cảnh báo y tế thủ công
-- Cảnh báo TỰ ĐỘNG được tính runtime (không lưu DB), chỉ cảnh báo THỦ CÔNG lưu ở đây
CREATE TABLE IF NOT EXISTS ehr_health_alerts (
    alert_id             VARCHAR(50) PRIMARY KEY,
    patient_id           VARCHAR(50) NOT NULL,
    alert_type           VARCHAR(50) NOT NULL,              -- MANUAL_NOTE, DRUG_WARNING, CONDITION_NOTE
    severity             VARCHAR(20) DEFAULT 'INFO',        -- INFO, WARNING, CRITICAL
    title                VARCHAR(255) NOT NULL,
    description          TEXT,
    created_by           VARCHAR(50) NOT NULL,
    is_active            BOOLEAN DEFAULT TRUE,
    created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at           TIMESTAMPTZ,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(users_id) ON DELETE SET NULL
);


-- Bảng events thủ công trên timeline
CREATE TABLE IF NOT EXISTS health_timeline_events (
    event_id             VARCHAR(50) PRIMARY KEY,
    patient_id           VARCHAR(50) NOT NULL,
    event_type           VARCHAR(50) NOT NULL,        -- MANUAL_NOTE, EXTERNAL_VISIT, EXTERNAL_LAB, EXTERNAL_PROCEDURE
    event_time           TIMESTAMPTZ NOT NULL,
    title                VARCHAR(255) NOT NULL,
    description          TEXT,
    metadata             JSONB,                        -- Dữ liệu bổ sung tùy loại event
    created_by           VARCHAR(50) NOT NULL,
    created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at           TIMESTAMPTZ,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(users_id) ON DELETE SET NULL
);



-- 1. Bảng mới: Yếu tố nguy cơ
CREATE TABLE IF NOT EXISTS patient_risk_factors (
    risk_factor_id       VARCHAR(50) PRIMARY KEY,
    patient_id           VARCHAR(50) NOT NULL,
    factor_type          VARCHAR(50) NOT NULL,        -- SMOKING, ALCOHOL, OCCUPATION, LIFESTYLE, GENETIC, OTHER
    severity             VARCHAR(20) DEFAULT 'LOW',   -- LOW, MODERATE, HIGH
    details              TEXT NOT NULL,
    start_date           DATE,
    end_date             DATE,
    is_active            BOOLEAN DEFAULT TRUE,
    recorded_by          VARCHAR(50),
    created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at           TIMESTAMPTZ,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (recorded_by) REFERENCES users(users_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_prf_patient ON patient_risk_factors(patient_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_prf_type ON patient_risk_factors(factor_type) WHERE deleted_at IS NULL;

-- 2. Bảng mới: Tình trạng đặc biệt
CREATE TABLE IF NOT EXISTS patient_special_conditions (
    special_condition_id VARCHAR(50) PRIMARY KEY,
    patient_id           VARCHAR(50) NOT NULL,
    condition_type       VARCHAR(50) NOT NULL,        -- PREGNANCY, DISABILITY, IMPLANT, TRANSPLANT, INFECTIOUS, MENTAL_HEALTH, OTHER
    description          TEXT NOT NULL,
    start_date           DATE,
    end_date             DATE,
    is_active            BOOLEAN DEFAULT TRUE,
    recorded_by          VARCHAR(50),
    created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at           TIMESTAMPTZ,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (recorded_by) REFERENCES users(users_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_psc_patient ON patient_special_conditions(patient_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_psc_type ON patient_special_conditions(condition_type) WHERE deleted_at IS NULL;

-- 3. Bổ sung cột cho patient_medical_histories (tiền sử bệnh)
ALTER TABLE patient_medical_histories
    ADD COLUMN IF NOT EXISTS relationship VARCHAR(50),       -- FATHER, MOTHER, SIBLING... (chỉ dùng khi history_type=FAMILY)
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_pmh_patient ON patient_medical_histories(patient_id);
CREATE INDEX IF NOT EXISTS idx_pmh_type ON patient_medical_histories(history_type);

-- 4. Bổ sung cột cho patient_allergies (dị ứng)
ALTER TABLE patient_allergies
    ADD COLUMN IF NOT EXISTS reported_by VARCHAR(50) REFERENCES users(users_id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_pa_patient ON patient_allergies(patient_id);
CREATE INDEX IF NOT EXISTS idx_pa_type ON patient_allergies(allergen_type);




-- 1. Bảng mới: Theo dõi tuân thủ dùng thuốc
CREATE TABLE IF NOT EXISTS ehr_medication_adherence (
    adherence_id             VARCHAR(50) PRIMARY KEY,
    patient_id               VARCHAR(50) NOT NULL,
    prescription_detail_id   VARCHAR(50) NOT NULL,
    adherence_date           DATE NOT NULL,
    taken                    BOOLEAN NOT NULL DEFAULT TRUE,
    skip_reason              TEXT,
    recorded_by              VARCHAR(50),
    created_at               TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (prescription_detail_id) REFERENCES prescription_details(prescription_details_id) ON DELETE CASCADE,
    FOREIGN KEY (recorded_by) REFERENCES users(users_id) ON DELETE SET NULL
);



-- 1. Bảng mới: Ngưỡng tham chiếu chuẩn hóa
CREATE TABLE IF NOT EXISTS vital_reference_ranges (
    range_id         VARCHAR(50) PRIMARY KEY,
    metric_code      VARCHAR(50) NOT NULL,
    metric_name      VARCHAR(100) NOT NULL,
    unit             VARCHAR(20) NOT NULL,
    normal_min       DECIMAL(10,2),
    normal_max       DECIMAL(10,2),
    warning_min      DECIMAL(10,2),
    warning_max      DECIMAL(10,2),
    critical_min     DECIMAL(10,2),
    critical_max     DECIMAL(10,2),
    age_group        VARCHAR(20) DEFAULT 'ADULT',
    gender           VARCHAR(10) DEFAULT 'ALL',
    is_active        BOOLEAN DEFAULT TRUE
);




-- 1. Quản lý nguồn dữ liệu
CREATE TABLE IF NOT EXISTS ehr_data_sources (
    source_id          VARCHAR(50) PRIMARY KEY,
    source_name        VARCHAR(255) NOT NULL,
    source_type        VARCHAR(50) NOT NULL,
    protocol           VARCHAR(50) DEFAULT 'MANUAL',
    endpoint_url       VARCHAR(500),
    api_key_encrypted  TEXT,
    contact_info       VARCHAR(255),
    description        TEXT,
    is_active          BOOLEAN DEFAULT TRUE,
    created_by         VARCHAR(50),
    created_at         TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_eds_type ON ehr_data_sources(source_type);
CREATE INDEX IF NOT EXISTS idx_eds_active ON ehr_data_sources(is_active);

-- 2. Log đồng bộ thiết bị y tế
CREATE TABLE IF NOT EXISTS ehr_device_sync_log (
    sync_log_id        VARCHAR(50) PRIMARY KEY,
    patient_id         VARCHAR(50) NOT NULL,
    source_id          VARCHAR(50),
    device_name        VARCHAR(255) NOT NULL,
    device_type        VARCHAR(50),
    sync_time          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    records_synced     INT DEFAULT 0,
    status             VARCHAR(50) DEFAULT 'SUCCESS',
    error_message      TEXT,
    synced_by          VARCHAR(50),
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (source_id) REFERENCES ehr_data_sources(source_id),
    FOREIGN KEY (synced_by) REFERENCES users(users_id)
);




-- 1. Chính sách giá linh hoạt theo đối tượng bệnh nhân
-- Mỗi dịch vụ cơ sở có thể có NHIỀU chính sách giá cho các đối tượng khác nhau
CREATE TABLE IF NOT EXISTS service_price_policies (
    policy_id            VARCHAR(50) PRIMARY KEY,
    facility_service_id  VARCHAR(50) NOT NULL,
    patient_type         VARCHAR(50) NOT NULL,           -- STANDARD, INSURANCE, VIP, EMPLOYEE, CHILD, ELDERLY
    price                DECIMAL(12,2) NOT NULL,
    currency             VARCHAR(10) DEFAULT 'VND',
    description          TEXT,
    effective_from       DATE NOT NULL,
    effective_to         DATE,                           -- NULL = vô thời hạn
    is_active            BOOLEAN DEFAULT TRUE,
    created_by           VARCHAR(50) NOT NULL,
    created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_service_id) REFERENCES facility_services(facility_services_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(users_id),
    UNIQUE(facility_service_id, patient_type, effective_from)
);

-- 2. Giá theo chuyên khoa
-- Cùng 1 dịch vụ cơ sở, chuyên khoa khác nhau có thể áp dụng giá khác nhau
CREATE TABLE IF NOT EXISTS facility_service_specialty_prices (
    specialty_price_id   VARCHAR(50) PRIMARY KEY,
    facility_service_id  VARCHAR(50) NOT NULL,
    specialty_id         VARCHAR(50) NOT NULL,
    patient_type         VARCHAR(50) DEFAULT 'STANDARD',
    price                DECIMAL(12,2) NOT NULL,
    effective_from       DATE NOT NULL,
    effective_to         DATE,
    is_active            BOOLEAN DEFAULT TRUE,
    created_by           VARCHAR(50) NOT NULL,
    created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_service_id) REFERENCES facility_services(facility_services_id) ON DELETE CASCADE,
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialties_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(users_id),
    UNIQUE(facility_service_id, specialty_id, patient_type, effective_from)
);

-- 3. Lịch sử thay đổi giá (Audit Trail)
CREATE TABLE IF NOT EXISTS service_price_history (
    history_id           VARCHAR(50) PRIMARY KEY,
    facility_service_id  VARCHAR(50) NOT NULL,
    change_type          VARCHAR(20) NOT NULL,            -- CREATE, UPDATE, DELETE
    change_source        VARCHAR(50) NOT NULL,            -- PRICE_POLICY, SPECIALTY_PRICE, FACILITY_SERVICE
    reference_id         VARCHAR(50) NOT NULL,            -- ID bản ghi bị thay đổi
    patient_type         VARCHAR(50),
    specialty_id         VARCHAR(50),
    old_price            DECIMAL(12,2),
    new_price            DECIMAL(12,2),
    old_effective_from   DATE,
    new_effective_from   DATE,
    old_effective_to     DATE,
    new_effective_to     DATE,
    reason               TEXT,
    changed_by           VARCHAR(50) NOT NULL,
    changed_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_service_id) REFERENCES facility_services(facility_services_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(users_id)
);



-- =====================================================================
-- 1. ALTER bảng invoices — bổ sung cột
-- =====================================================================
ALTER TABLE invoices
    ADD COLUMN IF NOT EXISTS facility_id      VARCHAR(50),
    ADD COLUMN IF NOT EXISTS notes            TEXT,
    ADD COLUMN IF NOT EXISTS cancelled_reason TEXT,
    ADD COLUMN IF NOT EXISTS cancelled_by     VARCHAR(50),
    ADD COLUMN IF NOT EXISTS cancelled_at     TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS updated_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- FK facility_id → facilities
DO $$ BEGIN
    ALTER TABLE invoices
        ADD CONSTRAINT fk_invoices_facility
        FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- FK cancelled_by → users
DO $$ BEGIN
    ALTER TABLE invoices
        ADD CONSTRAINT fk_invoices_cancelled_by
        FOREIGN KEY (cancelled_by) REFERENCES users(users_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =====================================================================
-- 2. ALTER bảng invoice_details — bổ sung cột
-- =====================================================================
ALTER TABLE invoice_details
    ADD COLUMN IF NOT EXISTS discount_amount   DECIMAL(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS insurance_covered  DECIMAL(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS patient_pays       DECIMAL(12,2),
    ADD COLUMN IF NOT EXISTS notes              TEXT;

-- =====================================================================
-- 3. ALTER bảng payment_transactions — bổ sung cột
-- =====================================================================
ALTER TABLE payment_transactions
    ADD COLUMN IF NOT EXISTS notes         TEXT,
    ADD COLUMN IF NOT EXISTS refund_reason TEXT,
    ADD COLUMN IF NOT EXISTS created_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- =====================================================================
-- 4. Bảng mới: invoice_insurance_claims
-- Lưu thông tin claim BHYT cho từng hóa đơn
-- =====================================================================
CREATE TABLE IF NOT EXISTS invoice_insurance_claims (
    claim_id               VARCHAR(50) PRIMARY KEY,
    invoice_id             VARCHAR(50) NOT NULL,
    patient_insurance_id   VARCHAR(50) NOT NULL,
    coverage_percent       DECIMAL(5,2) NOT NULL,
    total_claimable        DECIMAL(12,2) NOT NULL DEFAULT 0,
    approved_amount        DECIMAL(12,2) DEFAULT 0,
    claim_status           VARCHAR(50) DEFAULT 'PENDING',  -- PENDING, APPROVED, REJECTED, PARTIAL
    submitted_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    processed_at           TIMESTAMPTZ,
    notes                  TEXT,
    created_by             VARCHAR(50),
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoices_id) ON DELETE CASCADE,
    FOREIGN KEY (patient_insurance_id) REFERENCES patient_insurances(patient_insurances_id),
    FOREIGN KEY (created_by) REFERENCES users(users_id),
    UNIQUE(invoice_id)
);



-- 1. BẢNG LỆNH THANH TOÁN QR (Payment Orders)
CREATE TABLE IF NOT EXISTS payment_orders (
    payment_orders_id       VARCHAR(50) PRIMARY KEY,
    order_code              VARCHAR(100) UNIQUE NOT NULL,
    invoice_id              VARCHAR(50) NOT NULL,
    amount                  DECIMAL(12,2) NOT NULL,
    description             VARCHAR(500),
    qr_code_url             TEXT,
    payment_url             TEXT,
    gateway_order_id        VARCHAR(255),
    status                  VARCHAR(30) DEFAULT 'PENDING',
    expires_at              TIMESTAMPTZ NOT NULL,
    paid_at                 TIMESTAMPTZ,
    gateway_transaction_id  VARCHAR(255),
    gateway_response        JSONB,
    created_by              VARCHAR(50),
    created_at              TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoices_id),
    FOREIGN KEY (created_by) REFERENCES users(users_id)
);

-- 2. BẢNG CẤU HÌNH CỔNG THANH TOÁN (Payment Gateway Config)
CREATE TABLE IF NOT EXISTS payment_gateway_config (
    config_id               VARCHAR(50) PRIMARY KEY,
    gateway_name            VARCHAR(50) UNIQUE NOT NULL,
    merchant_id             VARCHAR(255),
    api_key                 VARCHAR(500),
    secret_key              VARCHAR(500),
    webhook_secret          VARCHAR(500),
    environment             VARCHAR(20) DEFAULT 'SANDBOX',
    bank_account_number     VARCHAR(50),
    bank_name               VARCHAR(100),
    account_holder          VARCHAR(255),
    va_account              VARCHAR(50),
    is_active               BOOLEAN DEFAULT TRUE,
    config_data             JSONB,
    created_at              TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- =====================================================================
-- 1. Bảng mới: pos_terminals — Quản lý thiết bị POS/máy quẹt thẻ
-- =====================================================================
CREATE TABLE IF NOT EXISTS pos_terminals (
    terminal_id          VARCHAR(50) PRIMARY KEY,
    terminal_code        VARCHAR(50) UNIQUE NOT NULL,
    terminal_name        VARCHAR(100) NOT NULL,
    terminal_type        VARCHAR(30) DEFAULT 'COMBO',       -- CARD_READER | QR_SCANNER | COMBO
    brand                VARCHAR(100),
    model                VARCHAR(100),
    serial_number        VARCHAR(100),
    location_description VARCHAR(255),
    branch_id            VARCHAR(50) NOT NULL,
    is_active            BOOLEAN DEFAULT TRUE,
    created_by           VARCHAR(50),
    created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (branch_id) REFERENCES branches(branches_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_pos_terminals_branch ON pos_terminals(branch_id);
CREATE INDEX IF NOT EXISTS idx_pos_terminals_active ON pos_terminals(is_active) WHERE is_active = TRUE;

-- =====================================================================
-- 2. ALTER bảng payment_transactions — bổ sung thông tin POS & VOID
-- =====================================================================
ALTER TABLE payment_transactions
    ADD COLUMN IF NOT EXISTS terminal_id    VARCHAR(50),
    ADD COLUMN IF NOT EXISTS shift_id       VARCHAR(50),
    ADD COLUMN IF NOT EXISTS approval_code  VARCHAR(100),
    ADD COLUMN IF NOT EXISTS card_last_four VARCHAR(4),
    ADD COLUMN IF NOT EXISTS card_brand     VARCHAR(50),
    ADD COLUMN IF NOT EXISTS voided_at      TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS voided_by      VARCHAR(50),
    ADD COLUMN IF NOT EXISTS void_reason    TEXT;

-- FK terminal_id → pos_terminals
DO $$ BEGIN
    ALTER TABLE payment_transactions
        ADD CONSTRAINT fk_payment_trans_terminal
        FOREIGN KEY (terminal_id) REFERENCES pos_terminals(terminal_id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- FK shift_id → cashier_shifts
DO $$ BEGIN
    ALTER TABLE payment_transactions
        ADD CONSTRAINT fk_payment_trans_shift
        FOREIGN KEY (shift_id) REFERENCES cashier_shifts(cashier_shifts_id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- FK voided_by → users
DO $$ BEGIN
    ALTER TABLE payment_transactions
        ADD CONSTRAINT fk_payment_trans_voided_by
        FOREIGN KEY (voided_by) REFERENCES users(users_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_payment_trans_shift ON payment_transactions(shift_id);
CREATE INDEX IF NOT EXISTS idx_payment_trans_terminal ON payment_transactions(terminal_id);
CREATE INDEX IF NOT EXISTS idx_payment_trans_voided ON payment_transactions(voided_at) WHERE voided_at IS NOT NULL;

-- =====================================================================
-- 3. ALTER bảng cashier_shifts — bổ sung thông tin chi nhánh & thống kê
-- =====================================================================
ALTER TABLE cashier_shifts
    ADD COLUMN IF NOT EXISTS branch_id                VARCHAR(50),
    ADD COLUMN IF NOT EXISTS facility_id              VARCHAR(50),
    ADD COLUMN IF NOT EXISTS total_cash_payments      DECIMAL(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_card_payments      DECIMAL(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_transfer_payments  DECIMAL(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_refunds            DECIMAL(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_voids              DECIMAL(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS transaction_count        INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS closed_by                VARCHAR(50);

-- FK branch_id → branches
DO $$ BEGIN
    ALTER TABLE cashier_shifts
        ADD CONSTRAINT fk_cashier_shifts_branch
        FOREIGN KEY (branch_id) REFERENCES branches(branches_id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- FK facility_id → facilities
DO $$ BEGIN
    ALTER TABLE cashier_shifts
        ADD CONSTRAINT fk_cashier_shifts_facility
        FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- FK closed_by → users
DO $$ BEGIN
    ALTER TABLE cashier_shifts
        ADD CONSTRAINT fk_cashier_shifts_closed_by
        FOREIGN KEY (closed_by) REFERENCES users(users_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_cashier_shifts_branch ON cashier_shifts(branch_id);
CREATE INDEX IF NOT EXISTS idx_cashier_shifts_facility ON cashier_shifts(facility_id);

-- =====================================================================
-- 4. Bảng mới: payment_receipts — Biên lai thanh toán
-- =====================================================================
CREATE TABLE IF NOT EXISTS payment_receipts (
    receipt_id                 VARCHAR(50) PRIMARY KEY,
    receipt_number             VARCHAR(100) UNIQUE NOT NULL,      -- RCP-YYYYMMDD-XXXX
    payment_transaction_id     VARCHAR(50) NOT NULL,
    invoice_id                 VARCHAR(50) NOT NULL,
    patient_id                 VARCHAR(50) NOT NULL,
    -- Snapshot thông tin tại thời điểm in
    patient_name               VARCHAR(255) NOT NULL,
    patient_code               VARCHAR(50),
    facility_name              VARCHAR(255),
    facility_address           TEXT,
    cashier_name               VARCHAR(255) NOT NULL,
    cashier_id                 VARCHAR(50) NOT NULL,
    items_snapshot             JSONB NOT NULL,                     -- [{item_name, qty, unit_price, subtotal, discount, insurance}]
    total_amount               DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount            DECIMAL(12,2) DEFAULT 0,
    insurance_amount           DECIMAL(12,2) DEFAULT 0,
    net_amount                 DECIMAL(12,2) NOT NULL DEFAULT 0,
    paid_amount                DECIMAL(12,2) NOT NULL DEFAULT 0,
    payment_method             VARCHAR(50) NOT NULL,
    change_amount              DECIMAL(12,2) DEFAULT 0,           -- Tiền thừa
    receipt_type               VARCHAR(20) DEFAULT 'PAYMENT',     -- PAYMENT | REFUND | VOID
    printed_at                 TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reprint_count              INT DEFAULT 0,
    voided_at                  TIMESTAMPTZ,
    voided_by                  VARCHAR(50),
    void_reason                TEXT,
    shift_id                   VARCHAR(50),
    created_at                 TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (payment_transaction_id) REFERENCES payment_transactions(payment_transactions_id),
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoices_id),
    FOREIGN KEY (patient_id) REFERENCES patients(id),
    FOREIGN KEY (cashier_id) REFERENCES users(users_id),
    FOREIGN KEY (voided_by) REFERENCES users(users_id),
    FOREIGN KEY (shift_id) REFERENCES cashier_shifts(cashier_shifts_id)
);

CREATE INDEX IF NOT EXISTS idx_receipts_transaction ON payment_receipts(payment_transaction_id);
CREATE INDEX IF NOT EXISTS idx_receipts_invoice ON payment_receipts(invoice_id);
CREATE INDEX IF NOT EXISTS idx_receipts_shift ON payment_receipts(shift_id);
CREATE INDEX IF NOT EXISTS idx_receipts_number ON payment_receipts(receipt_number);
CREATE INDEX IF NOT EXISTS idx_receipts_type ON payment_receipts(receipt_type);

-- =====================================================================
-- 5. Bảng mới: shift_cash_denominations — Mệnh giá tiền khi đóng ca
-- =====================================================================
CREATE TABLE IF NOT EXISTS shift_cash_denominations (
    denomination_id      VARCHAR(50) PRIMARY KEY,
    shift_id             VARCHAR(50) NOT NULL,
    denomination_value   INT NOT NULL,                  -- 500000, 200000, 100000, ...
    quantity             INT NOT NULL DEFAULT 0,
    subtotal             DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shift_id) REFERENCES cashier_shifts(cashier_shifts_id) ON DELETE CASCADE,
    UNIQUE(shift_id, denomination_value)
);


-- =====================================================================
-- 1. Bảng mới: e_invoice_config — Cấu hình phát hành HĐĐT theo cơ sở
-- =====================================================================
CREATE TABLE IF NOT EXISTS e_invoice_config (
    config_id              VARCHAR(50) PRIMARY KEY,
    facility_id            VARCHAR(50) NOT NULL,
    seller_name            VARCHAR(255) NOT NULL,
    seller_tax_code        VARCHAR(20) NOT NULL,
    seller_address         TEXT,
    seller_phone           VARCHAR(20),
    seller_bank_account    VARCHAR(50),
    seller_bank_name       VARCHAR(100),
    invoice_template       VARCHAR(20) DEFAULT '1C24TAA',    -- Ký hiệu mẫu số
    invoice_series         VARCHAR(20) DEFAULT 'C24TAA',     -- Ký hiệu hóa đơn
    current_number         INT DEFAULT 0,                     -- Số HĐ hiện tại (auto-increment)
    tax_rate_default       DECIMAL(5,2) DEFAULT 0,            -- Thuế suất mặc định: 0, 5, 8, 10
    currency_default       VARCHAR(10) DEFAULT 'VND',
    is_active              BOOLEAN DEFAULT TRUE,
    created_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(users_id),
    UNIQUE(facility_id)
);

-- =====================================================================
-- 2. Bảng mới: e_invoices — Hóa đơn điện tử chính thức
-- =====================================================================
CREATE TABLE IF NOT EXISTS e_invoices (
    e_invoice_id           VARCHAR(50) PRIMARY KEY,
    e_invoice_number       VARCHAR(20) NOT NULL,              -- Số HĐĐT liên tục: 00000001
    invoice_template       VARCHAR(20) NOT NULL,              -- Ký hiệu mẫu: 1C24TAA
    invoice_series         VARCHAR(20) NOT NULL,              -- Ký hiệu HĐ: C24TAA
    lookup_code            VARCHAR(50),                       -- Mã tra cứu CQT
    invoice_id             VARCHAR(50),                       -- Liên kết HĐ nội bộ (Module 9.2)
    payment_transaction_id VARCHAR(50),                       -- Giao dịch thanh toán
    invoice_type           VARCHAR(20) DEFAULT 'SALES',       -- SALES | VAT
    -- Bên bán (snapshot)
    seller_name            VARCHAR(255) NOT NULL,
    seller_tax_code        VARCHAR(20) NOT NULL,
    seller_address         TEXT,
    seller_phone           VARCHAR(20),
    seller_bank_account    VARCHAR(50),
    seller_bank_name       VARCHAR(100),
    -- Bên mua (snapshot)
    buyer_name             VARCHAR(255),
    buyer_tax_code         VARCHAR(20),
    buyer_address          TEXT,
    buyer_email            VARCHAR(255),
    buyer_type             VARCHAR(20) DEFAULT 'INDIVIDUAL',  -- INDIVIDUAL | COMPANY
    -- Tài chính
    total_before_tax       DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax_rate               DECIMAL(5,2) DEFAULT 0,
    tax_amount             DECIMAL(12,2) DEFAULT 0,
    total_after_tax        DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount        DECIMAL(12,2) DEFAULT 0,
    payment_method_text    VARCHAR(100),                       -- "Tiền mặt", "Chuyển khoản"...
    amount_in_words        TEXT,                               -- Số tiền bằng chữ
    -- Trạng thái & ký số
    status                 VARCHAR(20) DEFAULT 'DRAFT',        -- DRAFT|ISSUED|SIGNED|SENT|CANCELLED|REPLACED|ADJUSTED
    signed_at              TIMESTAMPTZ,
    signed_by              VARCHAR(50),
    cancelled_at           TIMESTAMPTZ,
    cancelled_by           VARCHAR(50),
    cancel_reason          TEXT,
    replaced_by_id         VARCHAR(50),                        -- HĐĐT thay thế
    adjustment_for_id      VARCHAR(50),                        -- HĐĐT gốc (nếu là HĐ điều chỉnh)
    adjustment_type        VARCHAR(20),                        -- INCREASE | DECREASE
    -- Metadata
    notes                  TEXT,
    currency               VARCHAR(10) DEFAULT 'VND',
    facility_id            VARCHAR(50),
    branch_id              VARCHAR(50),
    issued_at              TIMESTAMPTZ,
    created_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoices_id) ON DELETE SET NULL,
    FOREIGN KEY (payment_transaction_id) REFERENCES payment_transactions(payment_transactions_id) ON DELETE SET NULL,
    FOREIGN KEY (signed_by) REFERENCES users(users_id),
    FOREIGN KEY (cancelled_by) REFERENCES users(users_id),
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE SET NULL,
    FOREIGN KEY (branch_id) REFERENCES branches(branches_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_einvoice_number ON e_invoices(e_invoice_number);
CREATE INDEX IF NOT EXISTS idx_einvoice_lookup ON e_invoices(lookup_code);
CREATE INDEX IF NOT EXISTS idx_einvoice_invoice ON e_invoices(invoice_id);
CREATE INDEX IF NOT EXISTS idx_einvoice_status ON e_invoices(status);
CREATE INDEX IF NOT EXISTS idx_einvoice_type ON e_invoices(invoice_type);
CREATE INDEX IF NOT EXISTS idx_einvoice_facility ON e_invoices(facility_id);
CREATE INDEX IF NOT EXISTS idx_einvoice_created ON e_invoices(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_einvoice_buyer_tax ON e_invoices(buyer_tax_code) WHERE buyer_tax_code IS NOT NULL;

-- =====================================================================
-- 3. Bảng mới: e_invoice_items — Chi tiết dòng hàng trên HĐĐT
-- =====================================================================
CREATE TABLE IF NOT EXISTS e_invoice_items (
    item_id                VARCHAR(50) PRIMARY KEY,
    e_invoice_id           VARCHAR(50) NOT NULL,
    line_number            INT NOT NULL,                       -- STT dòng: 1, 2, 3...
    item_name              VARCHAR(255) NOT NULL,
    unit                   VARCHAR(50),                        -- "Lần", "Viên", "Hộp"...
    quantity               INT NOT NULL DEFAULT 1,
    unit_price             DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount        DECIMAL(12,2) DEFAULT 0,
    amount_before_tax      DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax_rate               DECIMAL(5,2) DEFAULT 0,
    tax_amount             DECIMAL(12,2) DEFAULT 0,
    amount_after_tax       DECIMAL(12,2) NOT NULL DEFAULT 0,
    reference_type         VARCHAR(50),                        -- CONSULTATION | LAB_ORDER | DRUG
    reference_id           VARCHAR(50),
    notes                  TEXT,
    FOREIGN KEY (e_invoice_id) REFERENCES e_invoices(e_invoice_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_einvoice_items_einv ON e_invoice_items(e_invoice_id);

-- =====================================================================
-- 4. Bảng mới: billing_documents — Lưu trữ chứng từ thanh toán
-- =====================================================================
CREATE TABLE IF NOT EXISTS billing_documents (
    document_id            VARCHAR(50) PRIMARY KEY,
    document_code          VARCHAR(100) UNIQUE NOT NULL,       -- DOC-YYYYMMDD-XXXX
    document_type          VARCHAR(30) NOT NULL,               -- E_INVOICE_PDF|RECEIPT_SCAN|VAT_PAPER|BANK_SLIP|REFUND_PROOF|OTHER
    document_name          VARCHAR(255) NOT NULL,
    file_url               TEXT NOT NULL,
    file_size              INT,                                -- bytes
    mime_type              VARCHAR(100),
    -- Liên kết
    invoice_id             VARCHAR(50),
    e_invoice_id           VARCHAR(50),
    payment_transaction_id VARCHAR(50),
    -- Metadata
    description            TEXT,
    tags                   JSONB DEFAULT '[]',                  -- ["scan", "vat", "urgent"]
    uploaded_by            VARCHAR(50),
    upload_source          VARCHAR(20) DEFAULT 'MANUAL',       -- MANUAL | AUTO_GENERATED
    is_archived            BOOLEAN DEFAULT FALSE,
    archived_at            TIMESTAMPTZ,
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoices_id) ON DELETE SET NULL,
    FOREIGN KEY (e_invoice_id) REFERENCES e_invoices(e_invoice_id) ON DELETE SET NULL,
    FOREIGN KEY (payment_transaction_id) REFERENCES payment_transactions(payment_transactions_id) ON DELETE SET NULL,
    FOREIGN KEY (uploaded_by) REFERENCES users(users_id)
);


-- =====================================================================
-- 1. reconciliation_sessions — Phiên đối soát
-- =====================================================================
CREATE TABLE IF NOT EXISTS reconciliation_sessions (
    session_id             VARCHAR(50) PRIMARY KEY,
    session_code           VARCHAR(100) UNIQUE NOT NULL,       -- REC-YYYYMMDD-XXXX
    reconciliation_type    VARCHAR(30) NOT NULL,               -- ONLINE | CASHIER_SHIFT | DAILY_SETTLEMENT
    reconcile_date         DATE NOT NULL,
    facility_id            VARCHAR(50),
    -- Tổng kết
    total_system_amount    DECIMAL(15,2) DEFAULT 0,
    total_external_amount  DECIMAL(15,2) DEFAULT 0,
    discrepancy_amount     DECIMAL(15,2) DEFAULT 0,
    total_transactions_matched   INT DEFAULT 0,
    total_transactions_unmatched INT DEFAULT 0,
    -- Trạng thái
    status                 VARCHAR(20) DEFAULT 'PENDING',      -- PENDING|REVIEWED|APPROVED|REJECTED|CLOSED
    notes                  TEXT,
    reviewed_by            VARCHAR(50),
    reviewed_at            TIMESTAMPTZ,
    approved_by            VARCHAR(50),
    approved_at            TIMESTAMPTZ,
    reject_reason          TEXT,
    -- Liên kết tùy loại
    shift_id               VARCHAR(50),                        -- Nếu type = CASHIER_SHIFT
    gateway_name           VARCHAR(50),                        -- Nếu type = ONLINE
    -- Metadata
    created_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE SET NULL,
    FOREIGN KEY (shift_id) REFERENCES cashier_shifts(cashier_shifts_id) ON DELETE SET NULL,
    FOREIGN KEY (reviewed_by) REFERENCES users(users_id),
    FOREIGN KEY (approved_by) REFERENCES users(users_id),
    FOREIGN KEY (created_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_recon_type ON reconciliation_sessions(reconciliation_type);
CREATE INDEX IF NOT EXISTS idx_recon_date ON reconciliation_sessions(reconcile_date DESC);
CREATE INDEX IF NOT EXISTS idx_recon_status ON reconciliation_sessions(status);
CREATE INDEX IF NOT EXISTS idx_recon_facility ON reconciliation_sessions(facility_id);
CREATE INDEX IF NOT EXISTS idx_recon_shift ON reconciliation_sessions(shift_id) WHERE shift_id IS NOT NULL;

-- =====================================================================
-- 2. reconciliation_items — Chi tiết từng dòng đối soát
-- =====================================================================
CREATE TABLE IF NOT EXISTS reconciliation_items (
    item_id                VARCHAR(50) PRIMARY KEY,
    session_id             VARCHAR(50) NOT NULL,
    match_status           VARCHAR(30) NOT NULL,               -- MATCHED|SYSTEM_ONLY|EXTERNAL_ONLY|AMOUNT_MISMATCH
    -- Bên system
    system_transaction_id  VARCHAR(50),
    system_transaction_code VARCHAR(100),
    system_amount          DECIMAL(15,2),
    system_method          VARCHAR(50),
    system_date            TIMESTAMPTZ,
    -- Bên external
    external_reference     VARCHAR(255),
    external_amount        DECIMAL(15,2),
    external_date          TIMESTAMPTZ,
    external_raw           JSONB,                              -- Raw data từ bank/gateway
    -- Chênh lệch
    discrepancy_amount     DECIMAL(15,2) DEFAULT 0,
    discrepancy_reason     TEXT,
    resolution_status      VARCHAR(20) DEFAULT 'UNRESOLVED',   -- UNRESOLVED|RESOLVED|WRITTEN_OFF
    resolved_by            VARCHAR(50),
    resolved_at            TIMESTAMPTZ,
    resolution_notes       TEXT,
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES reconciliation_sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (system_transaction_id) REFERENCES payment_transactions(payment_transactions_id) ON DELETE SET NULL,
    FOREIGN KEY (resolved_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_recon_item_session ON reconciliation_items(session_id);
CREATE INDEX IF NOT EXISTS idx_recon_item_match ON reconciliation_items(match_status);
CREATE INDEX IF NOT EXISTS idx_recon_item_resolution ON reconciliation_items(resolution_status) WHERE resolution_status = 'UNRESOLVED';

-- =====================================================================
-- 3. settlement_reports — Phiếu quyết toán
-- =====================================================================
CREATE TABLE IF NOT EXISTS settlement_reports (
    report_id              VARCHAR(50) PRIMARY KEY,
    report_code            VARCHAR(100) UNIQUE NOT NULL,       -- STL-YYYYMMDD-XXXX
    report_type            VARCHAR(20) NOT NULL,               -- DAILY|WEEKLY|MONTHLY|CUSTOM
    period_start           DATE NOT NULL,
    period_end             DATE NOT NULL,
    facility_id            VARCHAR(50),
    -- Tổng kết tài chính
    total_revenue          DECIMAL(15,2) DEFAULT 0,
    total_cash             DECIMAL(15,2) DEFAULT 0,
    total_card             DECIMAL(15,2) DEFAULT 0,
    total_transfer         DECIMAL(15,2) DEFAULT 0,
    total_online           DECIMAL(15,2) DEFAULT 0,
    total_refunds          DECIMAL(15,2) DEFAULT 0,
    total_voids            DECIMAL(15,2) DEFAULT 0,
    net_revenue            DECIMAL(15,2) DEFAULT 0,
    total_discrepancies    INT DEFAULT 0,
    unresolved_discrepancies INT DEFAULT 0,
    -- Quyết toán
    status                 VARCHAR(20) DEFAULT 'DRAFT',        -- DRAFT|SUBMITTED|APPROVED|REJECTED
    submitted_by           VARCHAR(50),
    submitted_at           TIMESTAMPTZ,
    approved_by            VARCHAR(50),
    approved_at            TIMESTAMPTZ,
    reject_reason          TEXT,
    notes                  TEXT,
    export_data            JSONB,                              -- Snapshot data quyết toán đầy đủ
    -- Metadata
    created_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE SET NULL,
    FOREIGN KEY (submitted_by) REFERENCES users(users_id),
    FOREIGN KEY (approved_by) REFERENCES users(users_id),
    FOREIGN KEY (created_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_settlement_type ON settlement_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_settlement_period ON settlement_reports(period_start DESC, period_end DESC);
CREATE INDEX IF NOT EXISTS idx_settlement_status ON settlement_reports(status);
CREATE INDEX IF NOT EXISTS idx_settlement_facility ON settlement_reports(facility_id);




-- =====================================================================
-- 1. refund_requests — Yêu cầu hoàn tiền (có phê duyệt)
-- =====================================================================
CREATE TABLE IF NOT EXISTS refund_requests (
    request_id             VARCHAR(50) PRIMARY KEY,
    request_code           VARCHAR(100) UNIQUE NOT NULL,       -- RFD-YYYYMMDD-XXXX
    transaction_id         VARCHAR(50) NOT NULL,               -- GD gốc cần hoàn
    invoice_id             VARCHAR(50) NOT NULL,
    patient_id             VARCHAR(50),
    -- Loại & số tiền
    refund_type            VARCHAR(20) NOT NULL,               -- FULL | PARTIAL
    original_amount        DECIMAL(15,2) NOT NULL,             -- Số tiền GD gốc
    refund_amount          DECIMAL(15,2) NOT NULL,             -- Số tiền hoàn
    refund_method          VARCHAR(50) NOT NULL,               -- CASH | CREDIT_CARD | BANK_TRANSFER
    -- Lý do
    reason_category        VARCHAR(50) NOT NULL,               -- OVERCHARGE | SERVICE_CANCELLED | ...
    reason_detail          TEXT,
    evidence_urls          JSONB,                              -- URLs bằng chứng
    -- Workflow
    status                 VARCHAR(20) DEFAULT 'PENDING',      -- PENDING|APPROVED|REJECTED|PROCESSING|COMPLETED|FAILED|CANCELLED
    requested_by           VARCHAR(50),
    requested_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    approved_by            VARCHAR(50),
    approved_at            TIMESTAMPTZ,
    rejected_by            VARCHAR(50),
    rejected_at            TIMESTAMPTZ,
    reject_reason          TEXT,
    processed_by           VARCHAR(50),
    processed_at           TIMESTAMPTZ,
    completed_at           TIMESTAMPTZ,
    -- Hoàn tiền — kết quả
    refund_transaction_id  VARCHAR(50),                        -- ID txn REFUND mới tạo
    gateway_refund_id      VARCHAR(255),                       -- ID hoàn trên gateway (nếu online)
    -- Metadata
    notes                  TEXT,
    facility_id            VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transaction_id) REFERENCES payment_transactions(payment_transactions_id),
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoices_id),
    FOREIGN KEY (patient_id) REFERENCES patients(patients_id) ON DELETE SET NULL,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE SET NULL,
    FOREIGN KEY (requested_by) REFERENCES users(users_id),
    FOREIGN KEY (approved_by) REFERENCES users(users_id),
    FOREIGN KEY (rejected_by) REFERENCES users(users_id),
    FOREIGN KEY (processed_by) REFERENCES users(users_id),
    FOREIGN KEY (refund_transaction_id) REFERENCES payment_transactions(payment_transactions_id)
);

CREATE INDEX IF NOT EXISTS idx_refund_status ON refund_requests(status);
CREATE INDEX IF NOT EXISTS idx_refund_txn ON refund_requests(transaction_id);
CREATE INDEX IF NOT EXISTS idx_refund_invoice ON refund_requests(invoice_id);
CREATE INDEX IF NOT EXISTS idx_refund_patient ON refund_requests(patient_id);
CREATE INDEX IF NOT EXISTS idx_refund_date ON refund_requests(requested_at DESC);
CREATE INDEX IF NOT EXISTS idx_refund_pending ON refund_requests(status) WHERE status = 'PENDING';

-- =====================================================================
-- 2. transaction_adjustments — Điều chỉnh giao dịch
-- =====================================================================
CREATE TABLE IF NOT EXISTS transaction_adjustments (
    adjustment_id          VARCHAR(50) PRIMARY KEY,
    adjustment_code        VARCHAR(100) UNIQUE NOT NULL,       -- ADJ-YYYYMMDD-XXXX
    original_transaction_id VARCHAR(50) NOT NULL,
    invoice_id             VARCHAR(50) NOT NULL,
    -- Loại điều chỉnh
    adjustment_type        VARCHAR(30) NOT NULL,               -- OVERCHARGE|UNDERCHARGE|WRONG_METHOD|DUPLICATE|OTHER
    adjustment_amount      DECIMAL(15,2) NOT NULL,             -- + = cần thu thêm, - = cần hoàn
    description            TEXT NOT NULL,
    -- GD bù/hoàn
    corrective_transaction_id VARCHAR(50),                     -- GD mới tạo để điều chỉnh
    -- Workflow
    status                 VARCHAR(20) DEFAULT 'PENDING',      -- PENDING|APPROVED|APPLIED|REJECTED
    requested_by           VARCHAR(50),
    requested_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    approved_by            VARCHAR(50),
    approved_at            TIMESTAMPTZ,
    applied_by             VARCHAR(50),
    applied_at             TIMESTAMPTZ,
    reject_reason          TEXT,
    notes                  TEXT,
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (original_transaction_id) REFERENCES payment_transactions(payment_transactions_id),
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoices_id),
    FOREIGN KEY (corrective_transaction_id) REFERENCES payment_transactions(payment_transactions_id),
    FOREIGN KEY (requested_by) REFERENCES users(users_id),
    FOREIGN KEY (approved_by) REFERENCES users(users_id),
    FOREIGN KEY (applied_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_adj_status ON transaction_adjustments(status);
CREATE INDEX IF NOT EXISTS idx_adj_txn ON transaction_adjustments(original_transaction_id);
CREATE INDEX IF NOT EXISTS idx_adj_invoice ON transaction_adjustments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_adj_date ON transaction_adjustments(requested_at DESC);


-- =====================================================================
-- 1. discount_policies — Chính sách giảm giá
-- =====================================================================
CREATE TABLE IF NOT EXISTS discount_policies (
    discount_id            VARCHAR(50) PRIMARY KEY,
    discount_code          VARCHAR(100) UNIQUE NOT NULL,       -- DSC-YYYYMMDD-XXXX
    name                   VARCHAR(255) NOT NULL,
    description            TEXT,
    -- Loại giảm giá
    discount_type          VARCHAR(20) NOT NULL,               -- PERCENTAGE | FIXED_AMOUNT
    discount_value         DECIMAL(15,2) NOT NULL,             -- % hoặc VND
    max_discount_amount    DECIMAL(15,2),                      -- Giới hạn nếu PERCENTAGE
    min_order_amount       DECIMAL(15,2) DEFAULT 0,            -- Đơn tối thiểu
    -- Phạm vi áp dụng
    apply_to               VARCHAR(30) DEFAULT 'ALL_SERVICES', -- ALL_SERVICES | SPECIFIC_SERVICES | SERVICE_GROUP
    applicable_services    JSONB,                              -- [{facility_service_id, service_name}]
    applicable_groups      JSONB,                              -- ["CONSULTATION","LAB_ORDER","DRUG"]
    -- Đối tượng
    target_patient_types   JSONB,                              -- ["VIP","ELDERLY"] hoặc null = all
    -- Thời gian
    effective_from         DATE NOT NULL,
    effective_to           DATE,                               -- NULL = vô thời hạn
    -- Trạng thái
    is_active              BOOLEAN DEFAULT TRUE,
    priority               INT DEFAULT 0,                      -- Cao hơn áp dụng trước
    facility_id            VARCHAR(50),
    created_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_disc_active ON discount_policies(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_disc_effective ON discount_policies(effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_disc_facility ON discount_policies(facility_id);
CREATE INDEX IF NOT EXISTS idx_disc_priority ON discount_policies(priority DESC);

-- =====================================================================
-- 2. vouchers — Mã giảm giá / Coupon
-- =====================================================================
CREATE TABLE IF NOT EXISTS vouchers (
    voucher_id             VARCHAR(50) PRIMARY KEY,
    voucher_code           VARCHAR(50) UNIQUE NOT NULL,        -- VN50K, WELCOME10
    name                   VARCHAR(255) NOT NULL,
    description            TEXT,
    -- Giảm giá
    discount_type          VARCHAR(20) NOT NULL,               -- PERCENTAGE | FIXED_AMOUNT
    discount_value         DECIMAL(15,2) NOT NULL,
    max_discount_amount    DECIMAL(15,2),
    min_order_amount       DECIMAL(15,2) DEFAULT 0,
    -- Giới hạn
    max_usage              INT,                                -- Tổng lượt tối đa (null = unlimited)
    max_usage_per_patient  INT DEFAULT 1,                      -- 1 BN dùng tối đa
    current_usage          INT DEFAULT 0,
    -- Đối tượng
    target_patient_types   JSONB,                              -- null = all
    -- Thời gian
    valid_from             DATE NOT NULL,
    valid_to               DATE,
    is_active              BOOLEAN DEFAULT TRUE,
    facility_id            VARCHAR(50),
    created_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_voucher_code ON vouchers(voucher_code);
CREATE INDEX IF NOT EXISTS idx_voucher_active ON vouchers(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_voucher_valid ON vouchers(valid_from, valid_to);

-- =====================================================================
-- 3. voucher_usage — Lịch sử sử dụng voucher
-- =====================================================================
CREATE TABLE IF NOT EXISTS voucher_usage (
    usage_id               VARCHAR(50) PRIMARY KEY,
    voucher_id             VARCHAR(50) NOT NULL,
    invoice_id             VARCHAR(50) NOT NULL,
    patient_id             VARCHAR(50),
    discount_amount        DECIMAL(15,2) NOT NULL,             -- Số tiền thực giảm
    used_at                TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    used_by                VARCHAR(50),
    FOREIGN KEY (voucher_id) REFERENCES vouchers(voucher_id),
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoices_id),
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE SET NULL,
    FOREIGN KEY (used_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_vusage_voucher ON voucher_usage(voucher_id);
CREATE INDEX IF NOT EXISTS idx_vusage_patient ON voucher_usage(patient_id);
CREATE INDEX IF NOT EXISTS idx_vusage_invoice ON voucher_usage(invoice_id);

-- =====================================================================
-- 4. service_bundles — Gói dịch vụ combo
-- =====================================================================
CREATE TABLE IF NOT EXISTS service_bundles (
    bundle_id              VARCHAR(50) PRIMARY KEY,
    bundle_code            VARCHAR(100) UNIQUE NOT NULL,       -- BDL-KHAMTQ, BDL-XETNGHIEM
    name                   VARCHAR(255) NOT NULL,
    description            TEXT,
    bundle_price           DECIMAL(15,2) NOT NULL,             -- Giá gói
    original_total_price   DECIMAL(15,2) DEFAULT 0,            -- Tổng giá lẻ
    discount_percentage    DECIMAL(5,2) DEFAULT 0,             -- % tiết kiệm
    -- Thời gian
    valid_from             DATE NOT NULL,
    valid_to               DATE,
    -- Đối tượng
    target_patient_types   JSONB,
    max_purchases          INT,                                -- null = unlimited
    current_purchases      INT DEFAULT 0,
    is_active              BOOLEAN DEFAULT TRUE,
    facility_id            VARCHAR(50),
    created_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_bundle_active ON service_bundles(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_bundle_valid ON service_bundles(valid_from, valid_to);

-- =====================================================================
-- 5. service_bundle_items — Chi tiết gói dịch vụ
-- =====================================================================
CREATE TABLE IF NOT EXISTS service_bundle_items (
    item_id                VARCHAR(50) PRIMARY KEY,
    bundle_id              VARCHAR(50) NOT NULL,
    facility_service_id    VARCHAR(50) NOT NULL,
    quantity               INT DEFAULT 1,
    unit_price             DECIMAL(15,2) NOT NULL,             -- Giá lẻ
    item_price             DECIMAL(15,2) NOT NULL,             -- Giá trong gói
    notes                  TEXT,
    FOREIGN KEY (bundle_id) REFERENCES service_bundles(bundle_id) ON DELETE CASCADE,
    FOREIGN KEY (facility_service_id) REFERENCES facility_services(facility_services_id)
);


-- *********************************************************************
-- MODULE 9.9: QUẢN LÝ PHÂN QUYỀN THU NGÂN
-- (Cashier Authorization Management)
-- *********************************************************************

-- =====================================================================
-- 1. cashier_profiles — Hồ sơ thu ngân
-- =====================================================================
CREATE TABLE IF NOT EXISTS cashier_profiles (
    cashier_profile_id     VARCHAR(50) PRIMARY KEY,
    user_id                VARCHAR(50) NOT NULL UNIQUE,       -- 1 user = 1 profile
    employee_code          VARCHAR(50),                       -- Mã NV thu ngân
    branch_id              VARCHAR(50),
    facility_id            VARCHAR(50),
    -- Quyền thao tác
    can_collect_payment    BOOLEAN DEFAULT TRUE,
    can_process_refund     BOOLEAN DEFAULT FALSE,
    can_void_transaction   BOOLEAN DEFAULT FALSE,
    can_open_shift         BOOLEAN DEFAULT TRUE,
    can_close_shift        BOOLEAN DEFAULT TRUE,
    -- Trạng thái
    is_active              BOOLEAN DEFAULT TRUE,
    supervisor_id          VARCHAR(50),                       -- Quản lý trực tiếp
    notes                  TEXT,
    created_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(users_id),
    FOREIGN KEY (branch_id) REFERENCES branches(branches_id) ON DELETE SET NULL,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE SET NULL,
    FOREIGN KEY (supervisor_id) REFERENCES users(users_id),
    FOREIGN KEY (created_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_cashier_prof_user ON cashier_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_cashier_prof_branch ON cashier_profiles(branch_id);
CREATE INDEX IF NOT EXISTS idx_cashier_prof_facility ON cashier_profiles(facility_id);
CREATE INDEX IF NOT EXISTS idx_cashier_prof_active ON cashier_profiles(is_active) WHERE is_active = TRUE;

-- =====================================================================
-- 2. cashier_operation_limits — Giới hạn thao tác
-- =====================================================================
CREATE TABLE IF NOT EXISTS cashier_operation_limits (
    limit_id               VARCHAR(50) PRIMARY KEY,
    cashier_profile_id     VARCHAR(50) NOT NULL UNIQUE,
    -- Giới hạn mỗi giao dịch
    max_single_payment     DECIMAL(15,2),                     -- Max VND 1 GD thu
    max_single_refund      DECIMAL(15,2),                     -- Max VND 1 GD hoàn
    max_single_void        DECIMAL(15,2),                     -- Max VND 1 GD VOID
    -- Giới hạn mỗi ca
    max_shift_total        DECIMAL(15,2),                     -- Tổng thu trong 1 ca
    max_shift_refund_total DECIMAL(15,2),                     -- Tổng hoàn trong ca
    max_shift_void_count   INT,                               -- Số VOID trong ca
    -- Giới hạn mỗi ngày
    max_daily_total        DECIMAL(15,2),
    max_daily_refund_total DECIMAL(15,2),
    max_daily_void_count   INT,
    -- Phê duyệt
    require_approval_above DECIMAL(15,2),                     -- GD > X VND cần supervisor
    created_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cashier_profile_id) REFERENCES cashier_profiles(cashier_profile_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(users_id)
);

-- =====================================================================
-- 3. cashier_activity_logs — Nhật ký hoạt động
-- =====================================================================
CREATE TABLE IF NOT EXISTS cashier_activity_logs (
    log_id                 VARCHAR(50) PRIMARY KEY,
    cashier_profile_id     VARCHAR(50),
    user_id                VARCHAR(50) NOT NULL,
    shift_id               VARCHAR(50),
    action_type            VARCHAR(30) NOT NULL,               -- SHIFT_OPEN, SHIFT_CLOSE, SHIFT_LOCK, SHIFT_UNLOCK,
                                                               -- PAYMENT, VOID, REFUND, LIMIT_EXCEEDED,
                                                               -- FORCE_CLOSE, HANDOVER, PROFILE_UPDATE
    action_detail          JSONB,                              -- {transaction_id, amount, reason, ...}
    ip_address             VARCHAR(45),
    user_agent             TEXT,
    facility_id            VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cashier_profile_id) REFERENCES cashier_profiles(cashier_profile_id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES users(users_id),
    FOREIGN KEY (shift_id) REFERENCES cashier_shifts(cashier_shifts_id) ON DELETE SET NULL,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_cashier_log_profile ON cashier_activity_logs(cashier_profile_id);
CREATE INDEX IF NOT EXISTS idx_cashier_log_user ON cashier_activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_cashier_log_shift ON cashier_activity_logs(shift_id);
CREATE INDEX IF NOT EXISTS idx_cashier_log_action ON cashier_activity_logs(action_type);
CREATE INDEX IF NOT EXISTS idx_cashier_log_created ON cashier_activity_logs(created_at DESC);

-- =====================================================================
-- 4. ALTER cashier_shifts — Mở rộng lock/handover
-- =====================================================================
ALTER TABLE cashier_shifts
    ADD COLUMN IF NOT EXISTS locked_at     TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS locked_by     VARCHAR(50),
    ADD COLUMN IF NOT EXISTS lock_reason   TEXT,
    ADD COLUMN IF NOT EXISTS force_closed  BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS handover_to   VARCHAR(50);

DO $$ BEGIN
    ALTER TABLE cashier_shifts
        ADD CONSTRAINT fk_cashier_shifts_locked_by FOREIGN KEY (locked_by) REFERENCES users(users_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE cashier_shifts
        ADD CONSTRAINT fk_cashier_shifts_handover_to FOREIGN KEY (handover_to) REFERENCES users(users_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;



-- =====================================================================
-- 1. tele_consultation_types — Danh mục hình thức khám từ xa
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_consultation_types (
    type_id                VARCHAR(50) PRIMARY KEY,
    code                   VARCHAR(50) UNIQUE NOT NULL,            -- VIDEO, AUDIO, CHAT, HYBRID
    name                   VARCHAR(150) NOT NULL,
    description            TEXT,
    -- Platform & capabilities
    default_platform       VARCHAR(50) DEFAULT 'AGORA',            -- AGORA, ZOOM, STRINGEE, INTERNAL_CHAT
    requires_video         BOOLEAN DEFAULT FALSE,
    requires_audio         BOOLEAN DEFAULT FALSE,
    allows_file_sharing    BOOLEAN DEFAULT FALSE,
    allows_screen_sharing  BOOLEAN DEFAULT FALSE,
    -- Thời lượng mặc định (phút)
    default_duration_minutes INT DEFAULT 30,
    min_duration_minutes     INT DEFAULT 10,
    max_duration_minutes     INT DEFAULT 120,
    -- Hiển thị
    icon_url               TEXT,
    sort_order             INT DEFAULT 0,
    -- Trạng thái
    is_active              BOOLEAN DEFAULT TRUE,
    created_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at             TIMESTAMPTZ,
    FOREIGN KEY (created_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_tele_type_code ON tele_consultation_types(code);
CREATE INDEX IF NOT EXISTS idx_tele_type_active ON tele_consultation_types(is_active) WHERE is_active = TRUE AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tele_type_sort ON tele_consultation_types(sort_order ASC);

-- =====================================================================
-- 2. tele_type_specialty_config — Cấu hình hình thức theo chuyên khoa & cơ sở
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_type_specialty_config (
    config_id              VARCHAR(50) PRIMARY KEY,
    type_id                VARCHAR(50) NOT NULL,
    specialty_id           VARCHAR(50) NOT NULL,
    facility_id            VARCHAR(50) NOT NULL,
    -- Liên kết dịch vụ cơ sở (optional, để tận dụng hệ thống giá Module 9)
    facility_service_id    VARCHAR(50),
    -- Bật/tắt
    is_enabled             BOOLEAN DEFAULT TRUE,
    -- Platform override
    allowed_platforms      JSONB DEFAULT '["AGORA"]',              -- ["AGORA","ZOOM"]
    -- Thời lượng override (nếu null thì dùng default từ type)
    min_duration_minutes   INT,
    max_duration_minutes   INT,
    default_duration_minutes INT,
    -- Giá dịch vụ
    base_price             DECIMAL(12,2) DEFAULT 0,                -- Giá cơ bản (VND)
    insurance_price        DECIMAL(12,2),                          -- Giá BHYT chi trả
    vip_price              DECIMAL(12,2),                          -- Giá VIP
    -- Quy định đặt lịch
    max_patients_per_slot  INT DEFAULT 1,
    advance_booking_days   INT DEFAULT 30,                         -- Đặt trước tối đa N ngày
    cancellation_hours     INT DEFAULT 2,                          -- Hủy trước N giờ
    -- Ghi hình
    auto_record            BOOLEAN DEFAULT FALSE,
    -- Hiển thị
    priority               INT DEFAULT 0,
    notes                  TEXT,
    -- Trạng thái
    is_active              BOOLEAN DEFAULT TRUE,
    created_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at             TIMESTAMPTZ,
    -- FK
    FOREIGN KEY (type_id) REFERENCES tele_consultation_types(type_id) ON DELETE CASCADE,
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialties_id) ON DELETE CASCADE,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE CASCADE,
    FOREIGN KEY (facility_service_id) REFERENCES facility_services(facility_services_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(users_id),
    -- 1 loại + 1 CK + 1 CS = 1 config duy nhất
    UNIQUE(type_id, specialty_id, facility_id)
);

CREATE INDEX IF NOT EXISTS idx_tsc_type ON tele_type_specialty_config(type_id);
CREATE INDEX IF NOT EXISTS idx_tsc_specialty ON tele_type_specialty_config(specialty_id);
CREATE INDEX IF NOT EXISTS idx_tsc_facility ON tele_type_specialty_config(facility_id);
CREATE INDEX IF NOT EXISTS idx_tsc_enabled ON tele_type_specialty_config(is_enabled) WHERE is_enabled = TRUE AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tsc_service ON tele_type_specialty_config(facility_service_id) WHERE facility_service_id IS NOT NULL;

-- =====================================================================
-- 3. ALTER tele_consultations — Bổ sung liên kết loại hình
-- =====================================================================
ALTER TABLE tele_consultations
    ADD COLUMN IF NOT EXISTS consultation_type_id VARCHAR(50),
    ADD COLUMN IF NOT EXISTS specialty_config_id  VARCHAR(50);

DO $$ BEGIN
    ALTER TABLE tele_consultations
        ADD CONSTRAINT fk_tele_consultation_type FOREIGN KEY (consultation_type_id) REFERENCES tele_consultation_types(type_id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE tele_consultations
        ADD CONSTRAINT fk_tele_specialty_config FOREIGN KEY (specialty_config_id) REFERENCES tele_type_specialty_config(config_id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_tele_consult_type ON tele_consultations(consultation_type_id) WHERE consultation_type_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tele_consult_config ON tele_consultations(specialty_config_id) WHERE specialty_config_id IS NOT NULL;





-- =====================================================================
-- 1. tele_booking_sessions — Phiên đặt lịch từ xa
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_booking_sessions (
    session_id             VARCHAR(50) PRIMARY KEY,
    session_code           VARCHAR(50) UNIQUE NOT NULL,            -- TBS-YYYYMMDD-XXXX
    patient_id             VARCHAR(50) NOT NULL,
    specialty_id           VARCHAR(50) NOT NULL,
    facility_id            VARCHAR(50) NOT NULL,
    -- Liên kết Module 8.1
    type_id                VARCHAR(50) NOT NULL,                   -- Hình thức (VIDEO/AUDIO/CHAT/HYBRID)
    config_id              VARCHAR(50),                            -- Config chuyên khoa (giá, thời lượng)
    -- BS & Lịch
    doctor_id              VARCHAR(50),                            -- BS được chọn/gán
    appointment_id         VARCHAR(50),                            -- Appointment được tạo sau xác nhận
    tele_consultation_id   VARCHAR(50),                            -- Phiên tư vấn được tạo
    invoice_id             VARCHAR(50),                            -- Hóa đơn thanh toán trước
    -- Thông tin lịch
    booking_date           DATE NOT NULL,
    booking_start_time     TIME,
    booking_end_time       TIME,
    duration_minutes       INT DEFAULT 30,
    slot_id                VARCHAR(50),                            -- Slot appointment (nếu dùng)
    shift_id               VARCHAR(50),                            -- Ca khám
    -- Platform & giá
    platform               VARCHAR(50) DEFAULT 'AGORA',
    price_amount           DECIMAL(12,2) DEFAULT 0,
    price_type             VARCHAR(20) DEFAULT 'BASE',             -- BASE, INSURANCE, VIP
    -- Trạng thái
    status                 VARCHAR(30) DEFAULT 'DRAFT',            -- DRAFT, PENDING_PAYMENT, PAYMENT_COMPLETED, CONFIRMED, CANCELLED, EXPIRED
    payment_required       BOOLEAN DEFAULT FALSE,
    payment_status         VARCHAR(30) DEFAULT 'UNPAID',           -- UNPAID, PAID, REFUNDED
    -- Ghi chú
    reason_for_visit       TEXT,
    symptoms_notes         TEXT,
    patient_notes          TEXT,
    cancellation_reason    TEXT,
    cancelled_by           VARCHAR(50),
    cancelled_at           TIMESTAMPTZ,
    confirmed_at           TIMESTAMPTZ,
    confirmed_by           VARCHAR(50),
    expires_at             TIMESTAMPTZ,                            -- Hết hạn chờ thanh toán
    -- Audit
    created_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- FK
    FOREIGN KEY (patient_id) REFERENCES patients(id),
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialties_id),
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id),
    FOREIGN KEY (type_id) REFERENCES tele_consultation_types(type_id),
    FOREIGN KEY (config_id) REFERENCES tele_type_specialty_config(config_id) ON DELETE SET NULL,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctors_id) ON DELETE SET NULL,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointments_id) ON DELETE SET NULL,
    FOREIGN KEY (tele_consultation_id) REFERENCES tele_consultations(tele_consultations_id) ON DELETE SET NULL,
    FOREIGN KEY (slot_id) REFERENCES appointment_slots(slot_id) ON DELETE SET NULL,
    FOREIGN KEY (shift_id) REFERENCES shifts(shifts_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(users_id),
    FOREIGN KEY (cancelled_by) REFERENCES users(users_id),
    FOREIGN KEY (confirmed_by) REFERENCES users(users_id)
);

CREATE INDEX IF NOT EXISTS idx_tbs_patient ON tele_booking_sessions(patient_id);
CREATE INDEX IF NOT EXISTS idx_tbs_doctor ON tele_booking_sessions(doctor_id) WHERE doctor_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tbs_specialty ON tele_booking_sessions(specialty_id);
CREATE INDEX IF NOT EXISTS idx_tbs_facility ON tele_booking_sessions(facility_id);
CREATE INDEX IF NOT EXISTS idx_tbs_type ON tele_booking_sessions(type_id);
CREATE INDEX IF NOT EXISTS idx_tbs_status ON tele_booking_sessions(status);
CREATE INDEX IF NOT EXISTS idx_tbs_date ON tele_booking_sessions(booking_date);
CREATE INDEX IF NOT EXISTS idx_tbs_appointment ON tele_booking_sessions(appointment_id) WHERE appointment_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tbs_code ON tele_booking_sessions(session_code);
CREATE INDEX IF NOT EXISTS idx_tbs_expires ON tele_booking_sessions(expires_at) WHERE status = 'PENDING_PAYMENT';

-- =====================================================================
-- 2. ALTER appointments — Bổ sung flag teleconsultation
-- =====================================================================
ALTER TABLE appointments
    ADD COLUMN IF NOT EXISTS is_teleconsultation BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS tele_booking_session_id VARCHAR(50);

DO $$ BEGIN
    ALTER TABLE appointments
        ADD CONSTRAINT fk_apt_tele_booking_session FOREIGN KEY (tele_booking_session_id) REFERENCES tele_booking_sessions(session_id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_apt_tele ON appointments(is_teleconsultation) WHERE is_teleconsultation = TRUE;
CREATE INDEX IF NOT EXISTS idx_apt_tele_session ON appointments(tele_booking_session_id) WHERE tele_booking_session_id IS NOT NULL;

-- =====================================================================
-- 3. ALTER tele_consultations — Liên kết ngược booking & appointment
-- =====================================================================
ALTER TABLE tele_consultations
    ADD COLUMN IF NOT EXISTS booking_session_id VARCHAR(50),
    ADD COLUMN IF NOT EXISTS appointment_id VARCHAR(50);

DO $$ BEGIN
    ALTER TABLE tele_consultations
        ADD CONSTRAINT fk_tele_booking_session FOREIGN KEY (booking_session_id) REFERENCES tele_booking_sessions(session_id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE tele_consultations
        ADD CONSTRAINT fk_tele_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointments_id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_tele_consult_booking ON tele_consultations(booking_session_id) WHERE booking_session_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tele_consult_appointment ON tele_consultations(appointment_id) WHERE appointment_id IS NOT NULL;



-- =====================================================================
-- 1. tele_room_participants — Người tham gia phòng khám
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_room_participants (
    participant_id         VARCHAR(50) PRIMARY KEY,
    tele_consultation_id   VARCHAR(50) NOT NULL,
    user_id                VARCHAR(50) NOT NULL,
    participant_role       VARCHAR(20) DEFAULT 'GUEST',            -- HOST, GUEST, OBSERVER
    join_time              TIMESTAMPTZ,
    leave_time             TIMESTAMPTZ,
    duration_seconds       INT DEFAULT 0,
    is_video_on            BOOLEAN DEFAULT FALSE,
    is_audio_on            BOOLEAN DEFAULT FALSE,
    is_screen_sharing      BOOLEAN DEFAULT FALSE,
    connection_quality     VARCHAR(20) DEFAULT 'GOOD',             -- EXCELLENT, GOOD, FAIR, POOR
    device_info            JSONB,                                  -- {browser, os, ip_hash}
    room_token             VARCHAR(255),
    token_expires_at       TIMESTAMPTZ,
    status                 VARCHAR(20) DEFAULT 'WAITING',          -- WAITING, IN_ROOM, LEFT, KICKED
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tele_consultation_id) REFERENCES tele_consultations(tele_consultations_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_trp_consultation ON tele_room_participants(tele_consultation_id);
CREATE INDEX IF NOT EXISTS idx_trp_user ON tele_room_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_trp_status ON tele_room_participants(status);
CREATE INDEX IF NOT EXISTS idx_trp_token ON tele_room_participants(room_token) WHERE room_token IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_trp_unique_active ON tele_room_participants(tele_consultation_id, user_id) WHERE status IN ('WAITING','IN_ROOM');

-- =====================================================================
-- 2. tele_room_events — Activity log phòng khám
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_room_events (
    event_id               VARCHAR(50) PRIMARY KEY,
    tele_consultation_id   VARCHAR(50) NOT NULL,
    user_id                VARCHAR(50),
    event_type             VARCHAR(50) NOT NULL,
    -- JOIN, LEAVE, VIDEO_ON, VIDEO_OFF, AUDIO_ON, AUDIO_OFF,
    -- SCREEN_SHARE_START, SCREEN_SHARE_STOP, FILE_SHARED,
    -- ROOM_OPENED, ROOM_CLOSED, NETWORK_ISSUE, RECONNECTED, KICKED
    event_data             JSONB,
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tele_consultation_id) REFERENCES tele_consultations(tele_consultations_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_tre_consultation ON tele_room_events(tele_consultation_id);
CREATE INDEX IF NOT EXISTS idx_tre_type ON tele_room_events(event_type);
CREATE INDEX IF NOT EXISTS idx_tre_time ON tele_room_events(tele_consultation_id, created_at ASC);

-- =====================================================================
-- 3. tele_shared_files — Tài liệu chia sẻ trong phiên
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_shared_files (
    file_id                VARCHAR(50) PRIMARY KEY,
    tele_consultation_id   VARCHAR(50) NOT NULL,
    uploaded_by            VARCHAR(50) NOT NULL,
    file_name              VARCHAR(255) NOT NULL,
    file_url               TEXT NOT NULL,
    file_type              VARCHAR(50) DEFAULT 'DOCUMENT',         -- IMAGE, PDF, DOCUMENT, LAB_RESULT, PRESCRIPTION
    file_size              INT,                                    -- bytes
    mime_type              VARCHAR(100),
    thumbnail_url          TEXT,
    description            TEXT,
    is_medical_record      BOOLEAN DEFAULT FALSE,
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tele_consultation_id) REFERENCES tele_consultations(tele_consultations_id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(users_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_tsf_consultation ON tele_shared_files(tele_consultation_id);
CREATE INDEX IF NOT EXISTS idx_tsf_uploader ON tele_shared_files(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_tsf_type ON tele_shared_files(file_type);

-- =====================================================================
-- 4. ALTER tele_consultations — Bổ sung quản lý phòng
-- =====================================================================
ALTER TABLE tele_consultations
    ADD COLUMN IF NOT EXISTS room_status VARCHAR(30) DEFAULT 'SCHEDULED',
    ADD COLUMN IF NOT EXISTS room_opened_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS room_opened_by VARCHAR(50),
    ADD COLUMN IF NOT EXISTS room_closed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS total_duration_seconds INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS participant_count INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS has_video BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS has_audio BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS has_chat BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS has_file_sharing BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS network_issues_count INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS ended_reason VARCHAR(50);

DO $$ BEGIN
    ALTER TABLE tele_consultations
        ADD CONSTRAINT fk_tele_room_opened_by FOREIGN KEY (room_opened_by) REFERENCES users(users_id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_tele_room_status ON tele_consultations(room_status);
CREATE INDEX IF NOT EXISTS idx_tele_room_active ON tele_consultations(room_status) WHERE room_status IN ('WAITING','ONGOING');



-- =====================================================================
-- 1. medical_conversations — Cuộc hội thoại y tế
-- =====================================================================
CREATE TABLE IF NOT EXISTS medical_conversations (
    conversation_id        VARCHAR(50) PRIMARY KEY,
    patient_id             VARCHAR(50) NOT NULL,
    doctor_id              VARCHAR(50) NOT NULL,
    specialty_id           VARCHAR(50),
    appointment_id         VARCHAR(50),
    encounter_id           VARCHAR(50),
    subject                VARCHAR(255),
    status                 VARCHAR(20) DEFAULT 'ACTIVE',           -- ACTIVE, CLOSED, ARCHIVED
    priority               VARCHAR(20) DEFAULT 'NORMAL',           -- NORMAL, URGENT, FOLLOW_UP
    last_message_at        TIMESTAMPTZ,
    last_message_preview   TEXT,
    unread_count_patient   INT DEFAULT 0,
    unread_count_doctor    INT DEFAULT 0,
    is_patient_initiated   BOOLEAN DEFAULT FALSE,
    closed_at              TIMESTAMPTZ,
    closed_by              VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctors_id) ON DELETE CASCADE,
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialties_id) ON DELETE SET NULL,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointments_id) ON DELETE SET NULL,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id) ON DELETE SET NULL,
    FOREIGN KEY (closed_by) REFERENCES users(users_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_mc_patient ON medical_conversations(patient_id);
CREATE INDEX IF NOT EXISTS idx_mc_doctor ON medical_conversations(doctor_id);
CREATE INDEX IF NOT EXISTS idx_mc_status ON medical_conversations(status);
CREATE INDEX IF NOT EXISTS idx_mc_last_msg ON medical_conversations(last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_mc_priority ON medical_conversations(priority) WHERE priority = 'URGENT';

-- =====================================================================
-- 2. medical_chat_messages — Tin nhắn y tế
-- =====================================================================
CREATE TABLE IF NOT EXISTS medical_chat_messages (
    message_id             VARCHAR(50) PRIMARY KEY,
    conversation_id        VARCHAR(50) NOT NULL,
    sender_id              VARCHAR(50) NOT NULL,
    sender_type            VARCHAR(20) NOT NULL,                   -- DOCTOR, PATIENT, SYSTEM
    message_type           VARCHAR(30) DEFAULT 'TEXT',             -- TEXT, IMAGE, FILE, LAB_RESULT, PRESCRIPTION, SYSTEM_NOTE
    content                TEXT,
    is_read                BOOLEAN DEFAULT FALSE,
    read_at                TIMESTAMPTZ,
    is_pinned              BOOLEAN DEFAULT FALSE,
    is_deleted             BOOLEAN DEFAULT FALSE,
    reply_to_id            VARCHAR(50),
    metadata               JSONB,
    sent_at                TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES medical_conversations(conversation_id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(users_id) ON DELETE CASCADE,
    FOREIGN KEY (reply_to_id) REFERENCES medical_chat_messages(message_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_mcm_conversation ON medical_chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_mcm_sent ON medical_chat_messages(conversation_id, sent_at ASC);
CREATE INDEX IF NOT EXISTS idx_mcm_pinned ON medical_chat_messages(conversation_id, is_pinned) WHERE is_pinned = TRUE;
CREATE INDEX IF NOT EXISTS idx_mcm_unread ON medical_chat_messages(conversation_id, is_read) WHERE is_read = FALSE AND is_deleted = FALSE;

-- =====================================================================
-- 3. medical_chat_attachments — File đính kèm
-- =====================================================================
CREATE TABLE IF NOT EXISTS medical_chat_attachments (
    attachment_id          VARCHAR(50) PRIMARY KEY,
    message_id             VARCHAR(50) NOT NULL,
    file_name              VARCHAR(255) NOT NULL,
    file_url               TEXT NOT NULL,
    file_type              VARCHAR(50) DEFAULT 'DOCUMENT',         -- IMAGE, PDF, LAB_RESULT, PRESCRIPTION, DOCUMENT
    file_size              INT,
    mime_type              VARCHAR(100),
    thumbnail_url          TEXT,
    is_medical_record      BOOLEAN DEFAULT FALSE,
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (message_id) REFERENCES medical_chat_messages(message_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_mca_message ON medical_chat_attachments(message_id);
CREATE INDEX IF NOT EXISTS idx_mca_medical ON medical_chat_attachments(is_medical_record) WHERE is_medical_record = TRUE;





-- =====================================================================
-- 1. tele_consultation_results — Kết quả khám từ xa
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_consultation_results (
    result_id                  VARCHAR(50) PRIMARY KEY,
    tele_consultation_id       VARCHAR(50) NOT NULL UNIQUE,
    encounter_id               VARCHAR(50),
    -- Triệu chứng BN mô tả
    chief_complaint            TEXT,
    symptom_description        TEXT,
    symptom_duration           VARCHAR(100),
    symptom_severity           VARCHAR(20),                         -- MILD, MODERATE, SEVERE
    self_reported_vitals       JSONB,                               -- {temp, pulse, bp_systolic, bp_diastolic, spo2, weight}
    -- Khám & Kết luận BS
    remote_examination_notes   TEXT,
    examination_limitations    TEXT,                                -- Giới hạn khám từ xa (bắt buộc y khoa)
    clinical_impression        TEXT,
    medical_conclusion         TEXT,
    conclusion_type            VARCHAR(30) DEFAULT 'PRELIMINARY',   -- PRELIMINARY, FINAL
    -- Tư vấn điều trị
    treatment_plan             TEXT,
    treatment_advice           TEXT,
    lifestyle_recommendations  TEXT,
    medication_notes           TEXT,
    referral_needed            BOOLEAN DEFAULT FALSE,
    referral_reason            TEXT,
    referral_specialty         VARCHAR(50),
    -- Follow-up
    follow_up_needed           BOOLEAN DEFAULT FALSE,
    follow_up_date             DATE,
    follow_up_notes            TEXT,
    follow_up_type             VARCHAR(20),                         -- TELECONSULTATION, IN_PERSON
    -- Ký xác nhận
    is_signed                  BOOLEAN DEFAULT FALSE,
    signed_at                  TIMESTAMPTZ,
    signed_by                  VARCHAR(50),
    signature_notes            TEXT,
    -- Metadata
    status                     VARCHAR(20) DEFAULT 'DRAFT',         -- DRAFT, COMPLETED, SIGNED
    created_by                 VARCHAR(50),
    created_at                 TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at                 TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tele_consultation_id) REFERENCES tele_consultations(tele_consultations_id) ON DELETE CASCADE,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id) ON DELETE SET NULL,
    FOREIGN KEY (signed_by) REFERENCES users(users_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(users_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_tcr_consultation ON tele_consultation_results(tele_consultation_id);
CREATE INDEX IF NOT EXISTS idx_tcr_encounter ON tele_consultation_results(encounter_id) WHERE encounter_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tcr_status ON tele_consultation_results(status);
CREATE INDEX IF NOT EXISTS idx_tcr_unsigned ON tele_consultation_results(is_signed) WHERE is_signed = FALSE AND status = 'COMPLETED';
CREATE INDEX IF NOT EXISTS idx_tcr_followup ON tele_consultation_results(follow_up_needed, follow_up_date) WHERE follow_up_needed = TRUE;

-- =====================================================================
-- 2. ALTER tele_consultations — Bổ sung trạng thái kết quả
-- =====================================================================
ALTER TABLE tele_consultations
    ADD COLUMN IF NOT EXISTS has_result BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS result_status VARCHAR(20);





-- =====================================================================
-- 1. tele_prescriptions — Đơn thuốc từ xa (bổ sung cho prescriptions)
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_prescriptions (
    tele_prescription_id         VARCHAR(50) PRIMARY KEY,
    prescription_id              VARCHAR(50) NOT NULL UNIQUE,
    tele_consultation_id         VARCHAR(50) NOT NULL,
    encounter_id                 VARCHAR(50),
    -- Kiểm soát từ xa
    is_remote_prescription       BOOLEAN DEFAULT TRUE,
    remote_restrictions_checked  BOOLEAN DEFAULT FALSE,
    restriction_notes            TEXT,
    -- Gửi đơn cho BN
    delivery_method              VARCHAR(30),                        -- PICKUP, DELIVERY, DIGITAL
    delivery_address             TEXT,
    delivery_phone               VARCHAR(20),
    delivery_notes               TEXT,
    sent_to_patient              BOOLEAN DEFAULT FALSE,
    sent_at                      TIMESTAMPTZ,
    -- Pháp lý
    legal_disclaimer             TEXT,
    doctor_confirmed_identity    BOOLEAN DEFAULT FALSE,
    -- Chỉ định kèm
    has_lab_orders               BOOLEAN DEFAULT FALSE,
    has_referral                 BOOLEAN DEFAULT FALSE,
    referral_notes               TEXT,
    -- Đồng bộ kho
    pharmacy_notes               TEXT,
    stock_checked                BOOLEAN DEFAULT FALSE,
    stock_check_result           JSONB,
    -- Metadata
    created_at                   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at                   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescriptions_id) ON DELETE CASCADE,
    FOREIGN KEY (tele_consultation_id) REFERENCES tele_consultations(tele_consultations_id) ON DELETE CASCADE,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_tp_prescription ON tele_prescriptions(prescription_id);
CREATE INDEX IF NOT EXISTS idx_tp_consultation ON tele_prescriptions(tele_consultation_id);
CREATE INDEX IF NOT EXISTS idx_tp_encounter ON tele_prescriptions(encounter_id);
CREATE INDEX IF NOT EXISTS idx_tp_sent ON tele_prescriptions(sent_to_patient) WHERE sent_to_patient = FALSE;

-- =====================================================================
-- 2. tele_drug_restrictions — Danh mục thuốc hạn chế kê từ xa
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_drug_restrictions (
    restriction_id               VARCHAR(50) PRIMARY KEY,
    drug_id                      VARCHAR(50) NOT NULL,
    restriction_type             VARCHAR(50) NOT NULL,               -- BANNED, REQUIRES_IN_PERSON, QUANTITY_LIMITED
    max_quantity                 INT,                                -- Giới hạn SL (nếu QUANTITY_LIMITED)
    reason                       TEXT NOT NULL,
    legal_reference              TEXT,                               -- Tham chiếu văn bản pháp luật
    is_active                    BOOLEAN DEFAULT TRUE,
    created_at                   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (drug_id) REFERENCES drugs(drugs_id) ON DELETE CASCADE,
    UNIQUE (drug_id)
);

CREATE INDEX IF NOT EXISTS idx_tdr_drug ON tele_drug_restrictions(drug_id);
CREATE INDEX IF NOT EXISTS idx_tdr_active ON tele_drug_restrictions(is_active) WHERE is_active = TRUE;




-- =====================================================================
-- 1. tele_follow_up_plans — Kế hoạch theo dõi
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_follow_up_plans (
    plan_id                    VARCHAR(50) PRIMARY KEY,
    tele_consultation_id       VARCHAR(50) NOT NULL,
    patient_id                 VARCHAR(50) NOT NULL,
    doctor_id                  VARCHAR(50) NOT NULL,
    encounter_id               VARCHAR(50),
    -- Kế hoạch
    plan_type                  VARCHAR(30) NOT NULL,                 -- MEDICATION_MONITOR, SYMPTOM_TRACK, POST_PROCEDURE, CHRONIC_CARE
    description                TEXT,
    instructions               TEXT,
    monitoring_items           JSONB,                                -- ["Nhiệt độ","Huyết áp","Đường huyết"]
    frequency                  VARCHAR(50) DEFAULT 'WEEKLY',        -- DAILY, WEEKLY, BI_WEEKLY, MONTHLY
    start_date                 DATE NOT NULL,
    end_date                   DATE,
    -- Tái khám
    next_follow_up_date        DATE,
    follow_up_type             VARCHAR(20),                          -- TELECONSULTATION, IN_PERSON
    follow_up_booking_id       VARCHAR(50),
    reminder_sent              BOOLEAN DEFAULT FALSE,
    reminder_sent_at           TIMESTAMPTZ,
    -- Kết quả
    status                     VARCHAR(30) DEFAULT 'ACTIVE',        -- ACTIVE, COMPLETED, CONVERTED_IN_PERSON, CANCELLED
    outcome                    TEXT,
    outcome_rating             VARCHAR(20),                          -- IMPROVED, STABLE, WORSENED, RESOLVED
    completed_at               TIMESTAMPTZ,
    converted_reason           TEXT,
    -- Metadata
    created_at                 TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at                 TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tele_consultation_id) REFERENCES tele_consultations(tele_consultations_id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctors_id) ON DELETE CASCADE,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounters_id) ON DELETE SET NULL,
    FOREIGN KEY (follow_up_booking_id) REFERENCES tele_booking_sessions(session_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_tfp_consultation ON tele_follow_up_plans(tele_consultation_id);
CREATE INDEX IF NOT EXISTS idx_tfp_patient ON tele_follow_up_plans(patient_id);
CREATE INDEX IF NOT EXISTS idx_tfp_doctor ON tele_follow_up_plans(doctor_id);
CREATE INDEX IF NOT EXISTS idx_tfp_status ON tele_follow_up_plans(status);
CREATE INDEX IF NOT EXISTS idx_tfp_upcoming ON tele_follow_up_plans(next_follow_up_date) WHERE status = 'ACTIVE' AND next_follow_up_date IS NOT NULL;

-- =====================================================================
-- 2. tele_health_updates — Diễn biến sức khỏe BN
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_health_updates (
    update_id                  VARCHAR(50) PRIMARY KEY,
    plan_id                    VARCHAR(50) NOT NULL,
    reported_by                VARCHAR(50) NOT NULL,
    reporter_type              VARCHAR(20) NOT NULL,                 -- PATIENT, DOCTOR
    update_type                VARCHAR(30) NOT NULL,                 -- SYMPTOM_UPDATE, VITAL_SIGNS, MEDICATION_RESPONSE, SIDE_EFFECT, GENERAL_NOTE
    content                    TEXT,
    vital_data                 JSONB,                                -- {temp, pulse, bp_systolic, bp_diastolic, spo2, weight}
    severity_level             VARCHAR(20) DEFAULT 'NORMAL',        -- NORMAL, MILD, MODERATE, SEVERE, CRITICAL
    attachments                JSONB,                                -- [{file_name, file_url}]
    doctor_response            TEXT,
    responded_at               TIMESTAMPTZ,
    requires_attention         BOOLEAN DEFAULT FALSE,
    created_at                 TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES tele_follow_up_plans(plan_id) ON DELETE CASCADE,
    FOREIGN KEY (reported_by) REFERENCES users(users_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_thu_plan ON tele_health_updates(plan_id);
CREATE INDEX IF NOT EXISTS idx_thu_attention ON tele_health_updates(requires_attention) WHERE requires_attention = TRUE AND doctor_response IS NULL;
CREATE INDEX IF NOT EXISTS idx_thu_severity ON tele_health_updates(severity_level) WHERE severity_level IN ('SEVERE','CRITICAL');




-- =====================================================================
-- 1. tele_quality_reviews — Đánh giá chi tiết chất lượng
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_quality_reviews (
    review_id                  VARCHAR(50) PRIMARY KEY,
    tele_consultation_id       VARCHAR(50) NOT NULL UNIQUE,
    patient_id                 VARCHAR(50) NOT NULL,
    doctor_id                  VARCHAR(50) NOT NULL,
    -- Đánh giá BS (1-5)
    doctor_professionalism     INT CHECK (doctor_professionalism >= 1 AND doctor_professionalism <= 5),
    doctor_communication       INT CHECK (doctor_communication >= 1 AND doctor_communication <= 5),
    doctor_knowledge           INT CHECK (doctor_knowledge >= 1 AND doctor_knowledge <= 5),
    doctor_empathy             INT CHECK (doctor_empathy >= 1 AND doctor_empathy <= 5),
    doctor_overall             INT CHECK (doctor_overall >= 1 AND doctor_overall <= 5),
    doctor_comment             TEXT,
    -- Trải nghiệm BN
    ease_of_use                INT CHECK (ease_of_use >= 1 AND ease_of_use <= 5),
    waiting_time_rating        INT CHECK (waiting_time_rating >= 1 AND waiting_time_rating <= 5),
    overall_satisfaction       INT CHECK (overall_satisfaction >= 1 AND overall_satisfaction <= 5),
    would_recommend            BOOLEAN DEFAULT TRUE,
    patient_comment            TEXT,
    -- Chất lượng kết nối
    video_quality              INT CHECK (video_quality >= 1 AND video_quality <= 5),
    audio_quality              INT CHECK (audio_quality >= 1 AND audio_quality <= 5),
    connection_stability       INT CHECK (connection_stability >= 1 AND connection_stability <= 5),
    tech_issues                JSONB,                                -- ["AUDIO_LAG","VIDEO_FREEZE","DISCONNECTED"]
    -- Metadata
    is_anonymous               BOOLEAN DEFAULT FALSE,
    created_at                 TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tele_consultation_id) REFERENCES tele_consultations(tele_consultations_id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES users(users_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES users(users_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_tqr_consultation ON tele_quality_reviews(tele_consultation_id);
CREATE INDEX IF NOT EXISTS idx_tqr_doctor ON tele_quality_reviews(doctor_id);
CREATE INDEX IF NOT EXISTS idx_tqr_patient ON tele_quality_reviews(patient_id);
CREATE INDEX IF NOT EXISTS idx_tqr_satisfaction ON tele_quality_reviews(overall_satisfaction);

-- =====================================================================
-- 2. tele_quality_alerts — Cảnh báo chất lượng
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_quality_alerts (
    alert_id                   VARCHAR(50) PRIMARY KEY,
    alert_type                 VARCHAR(30) NOT NULL,                 -- LOW_RATING, TECH_ISSUE, HIGH_CANCEL_RATE, PATIENT_COMPLAINT
    severity                   VARCHAR(20) NOT NULL DEFAULT 'WARNING', -- WARNING, CRITICAL
    target_type                VARCHAR(20) NOT NULL,                 -- DOCTOR, SYSTEM, PLATFORM
    target_id                  VARCHAR(50),                          -- doctor_id hoặc null (system-wide)
    title                      VARCHAR(200) NOT NULL,
    description                TEXT,
    metrics_snapshot           JSONB,                                -- {avg_rating, total_reviews, cancel_rate}
    status                     VARCHAR(20) DEFAULT 'OPEN',          -- OPEN, ACKNOWLEDGED, RESOLVED, DISMISSED
    resolved_by                VARCHAR(50),
    resolution_notes           TEXT,
    resolved_at                TIMESTAMPTZ,
    created_at                 TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (resolved_by) REFERENCES users(users_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_tqa_status ON tele_quality_alerts(status);
CREATE INDEX IF NOT EXISTS idx_tqa_type ON tele_quality_alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_tqa_target ON tele_quality_alerts(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_tqa_open ON tele_quality_alerts(status) WHERE status = 'OPEN';





-- =====================================================================
-- 1. tele_system_configs — Cấu hình hệ thống (key-value)
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_system_configs (
    config_id              VARCHAR(50) PRIMARY KEY,
    config_key             VARCHAR(100) UNIQUE NOT NULL,
    config_value           TEXT NOT NULL,
    config_type            VARCHAR(20) NOT NULL DEFAULT 'STRING',   -- STRING, INTEGER, BOOLEAN, JSON
    category               VARCHAR(50) NOT NULL,                    -- PLATFORM, SECURITY, USAGE_LIMIT, OPERATION, SLA
    description            TEXT,
    is_editable            BOOLEAN DEFAULT TRUE,
    updated_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (updated_by) REFERENCES users(users_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_tsc_key ON tele_system_configs(config_key);
CREATE INDEX IF NOT EXISTS idx_tsc_category ON tele_system_configs(category);

-- =====================================================================
-- 2. tele_service_pricing — Chi phí dịch vụ khám từ xa
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_service_pricing (
    pricing_id             VARCHAR(50) PRIMARY KEY,
    type_id                VARCHAR(50) NOT NULL,
    specialty_id           VARCHAR(50),
    facility_id            VARCHAR(50),
    base_price             DECIMAL(15,2) NOT NULL DEFAULT 0,
    currency               VARCHAR(10) DEFAULT 'VND',
    discount_percent       DECIMAL(5,2) DEFAULT 0,
    effective_from         DATE NOT NULL,
    effective_to           DATE,
    is_active              BOOLEAN DEFAULT TRUE,
    created_by             VARCHAR(50),
    updated_by             VARCHAR(50),
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (type_id) REFERENCES tele_consultation_types(type_id) ON DELETE CASCADE,
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialties_id) ON DELETE SET NULL,
    FOREIGN KEY (facility_id) REFERENCES facilities(facilities_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(users_id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(users_id) ON DELETE SET NULL,
    UNIQUE (type_id, specialty_id, facility_id, effective_from)
);

CREATE INDEX IF NOT EXISTS idx_tsp_type ON tele_service_pricing(type_id);
CREATE INDEX IF NOT EXISTS idx_tsp_active ON tele_service_pricing(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_tsp_effective ON tele_service_pricing(effective_from, effective_to);

-- =====================================================================
-- 3. tele_config_audit_log — Lịch sử thay đổi config
-- =====================================================================
CREATE TABLE IF NOT EXISTS tele_config_audit_log (
    log_id                 VARCHAR(50) PRIMARY KEY,
    config_key             VARCHAR(100) NOT NULL,
    old_value              TEXT,
    new_value              TEXT,
    changed_by             VARCHAR(50),
    changed_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (changed_by) REFERENCES users(users_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_tcal_key ON tele_config_audit_log(config_key);
CREATE INDEX IF NOT EXISTS idx_tcal_time ON tele_config_audit_log(changed_at DESC);



-- =====================================================================
-- 1. ai_chat_sessions — Phiên hội thoại AI tư vấn sức khỏe
-- Mỗi phiên là 1 lượt bệnh nhân trao đổi với AI về triệu chứng.
-- AI sẽ hỏi chi tiết, sau đó gợi ý chuyên khoa + mức độ ưu tiên.
-- =====================================================================
CREATE TABLE IF NOT EXISTS ai_chat_sessions (
    session_id              VARCHAR(50) PRIMARY KEY,
    session_code            VARCHAR(50) UNIQUE NOT NULL,        -- AIC-YYYYMMDD-XXXX
    patient_id              VARCHAR(50),                        -- Liên kết bệnh nhân (nullable: khách vãng lai)
    user_id                 VARCHAR(50),                        -- User đăng nhập hiện tại

    -- Kết quả phân tích AI
    suggested_specialty_id  VARCHAR(50),                        -- Chuyên khoa AI gợi ý (FK → specialties)
    suggested_specialty_name VARCHAR(150),                      -- Tên chuyên khoa (snapshot)
    suggested_priority      VARCHAR(20),                        -- NORMAL | SOON | URGENT
    symptoms_summary        TEXT,                               -- AI tóm tắt triệu chứng BN
    ai_conclusion           TEXT,                               -- Kết luận/gợi ý cuối cùng của AI

    -- Trạng thái phiên
    status                  VARCHAR(20) DEFAULT 'ACTIVE',       -- ACTIVE | COMPLETED | EXPIRED
    message_count           INT DEFAULT 0,                      -- Tổng số tin nhắn trong phiên

    -- Liên kết đặt lịch (nếu BN quyết định đặt lịch từ gợi ý AI)
    appointment_id          VARCHAR(50),                        -- FK → appointments

    -- Audit
    created_at              TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at            TIMESTAMPTZ,

    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES users(users_id) ON DELETE SET NULL,
    FOREIGN KEY (suggested_specialty_id) REFERENCES specialties(specialties_id) ON DELETE SET NULL,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointments_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_acs_user ON ai_chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_acs_patient ON ai_chat_sessions(patient_id) WHERE patient_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_acs_status ON ai_chat_sessions(status);
CREATE INDEX IF NOT EXISTS idx_acs_created ON ai_chat_sessions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_acs_specialty ON ai_chat_sessions(suggested_specialty_id) WHERE suggested_specialty_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_acs_code ON ai_chat_sessions(session_code);

-- =====================================================================
-- 2. ai_chat_messages — Tin nhắn trong phiên hội thoại AI
-- Lưu toàn bộ lịch sử chat giữa BN và AI (multi-turn).
-- Mỗi tin nhắn ASSISTANT có thể kèm analysis_data (JSON) chứa
-- kết quả phân tích triệu chứng, gợi ý chuyên khoa, câu hỏi tiếp.
-- =====================================================================
CREATE TABLE IF NOT EXISTS ai_chat_messages (
    message_id       VARCHAR(50) PRIMARY KEY,
    session_id       VARCHAR(50) NOT NULL,
    role             VARCHAR(10) NOT NULL,                      -- USER | ASSISTANT | SYSTEM
    content          TEXT NOT NULL,                             -- Nội dung tin nhắn

    -- Metadata AI (chỉ cho role = ASSISTANT)
    model_used       VARCHAR(50),                               -- gemini-2.0-flash, gpt-4o...
    tokens_used      INT DEFAULT 0,                            -- Số token tiêu thụ
    response_time_ms INT DEFAULT 0,                            -- Thời gian phản hồi (ms)

    -- Kết quả phân tích (chỉ cho role = ASSISTANT, dạng JSON)
    -- {is_complete, follow_up_questions, suggested_specialty_code, priority, symptoms_collected, should_suggest_booking}
    analysis_data    JSONB,

    -- Audit
    created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (session_id) REFERENCES ai_chat_sessions(session_id) ON DELETE CASCADE
);

-- *********************************************************************
-- MODULE 7.1 — CẢI THIỆN AI HEALTH CHAT
-- Conversation State Machine + Server-side Symptom Tracking
-- *********************************************************************

-- =====================================================================
-- 1. Thêm cột conversation_state JSONB vào ai_chat_sessions
-- Lưu trữ trạng thái hội thoại (phase, chủ đề đã khóa, triệu chứng
-- đã thu thập phía server) để kiểm soát flow và chống lạc đề.
-- =====================================================================
ALTER TABLE ai_chat_sessions
    ADD COLUMN IF NOT EXISTS conversation_state JSONB DEFAULT '{
        "phase": "GREETING",
        "locked_specialty_group": null,
        "symptoms_collected": [],
        "symptoms_excluded": [],
        "questions_asked": 0,
        "discovery_complete": false,
        "conversation_summary": null
    }';

-- Index cho truy vấn theo phase (debug/thống kê)
CREATE INDEX IF NOT EXISTS idx_acs_phase
    ON ai_chat_sessions ((conversation_state->>'phase'));


-- *********************************************************************
-- MODULE 7.1 — AI CHAT FEEDBACK LOOP
-- Thu thập phản hồi đánh giá chất lượng từ user cho mỗi tin nhắn AI.
-- Dùng để phân tích và cải thiện prompt AI theo thời gian.
-- *********************************************************************

-- Thêm cột feedback vào bảng tin nhắn
ALTER TABLE ai_chat_messages
    ADD COLUMN IF NOT EXISTS user_feedback VARCHAR(10),   -- GOOD | BAD
    ADD COLUMN IF NOT EXISTS feedback_note TEXT;           -- Ghi chú tùy chọn

-- Index hỗ trợ thống kê feedback (chỉ index các tin nhắn đã có feedback)
CREATE INDEX IF NOT EXISTS idx_acm_feedback
    ON ai_chat_messages (user_feedback)
    WHERE user_feedback IS NOT NULL;


-- Migration: Tạo VIEW thống kê token usage hàng ngày
-- Aggregate từ dữ liệu có sẵn trong ai_chat_messages (không cần table mới)

CREATE OR REPLACE VIEW ai_token_usage_daily AS
SELECT 
    DATE(created_at) AS usage_date,
    model_used,
    COUNT(*) AS total_messages,
    SUM(tokens_used) AS total_tokens,
    AVG(response_time_ms)::INTEGER AS avg_response_ms
FROM ai_chat_messages 
WHERE role = 'ASSISTANT'
GROUP BY DATE(created_at), model_used
ORDER BY usage_date DESC;
