-- =====================================================================
-- SEED DATA: DEMO COMPLETE — ADMIN PROMOTIONS, E-INVOICES & PORTAL PAGES
-- =====================================================================
-- Idempotent: ON CONFLICT DO NOTHING. Có thể chạy lại nhiều lần.
-- Modules được seed:
--   1. discount_policies   (5 rows)  → /admin/promotions tab Discounts
--   2. vouchers            (5 rows)  → /admin/promotions tab Vouchers
--   3. service_bundles     (3 rows)  → /admin/promotions tab Bundles
--   4. service_bundle_items                (FK của bundles)
--   5. e_invoice_config    (1 row)  → cấu hình HĐĐT cho facility
--   6. e_invoices          (10 rows) → /admin/e-invoices
--   7. e_invoice_items     (~14 rows)→ chi tiết HĐĐT
--   8. leave_requests      (5 rows)  → /portal/doctor/leaves
--   9. drug_dispense_orders(4 rows)  → /portal/pharmacist/dispensing
--  10. treatment_plans     (4 rows)  → /portal/doctor/treatment-plans
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 1. DISCOUNT POLICIES (Chính sách giảm giá)
-- ---------------------------------------------------------------------
INSERT INTO discount_policies (
    discount_id, discount_code, name, description,
    discount_type, discount_value, max_discount_amount, min_order_amount,
    apply_to, effective_from, effective_to, is_active, priority,
    facility_id, created_by
) VALUES
('DSC_DEMO_001', 'TET2026', 'Khuyến mãi Tết Bính Ngọ 2026',
 'Giảm 15% cho tất cả dịch vụ khám chữa bệnh dịp Tết',
 'PERCENT', 15, 500000, 200000,
 'ALL_SERVICES', '2026-01-15', '2026-02-28', TRUE, 10,
 'FAC_EHEALTH', 'USR_ADMIN_01'),
('DSC_DEMO_002', 'HEALTH_DAY', 'Ngày Sức Khoẻ Toàn Dân',
 'Giảm 10% toàn bộ dịch vụ trong ngày 27/2',
 'PERCENT', 10, 300000, 100000,
 'ALL_SERVICES', '2026-02-27', '2026-02-27', TRUE, 5,
 'FAC_EHEALTH', 'USR_ADMIN_01'),
('DSC_DEMO_003', 'SENIOR_60', 'Ưu đãi người cao tuổi 60+',
 'Giảm 20% cho bệnh nhân từ 60 tuổi trở lên',
 'PERCENT', 20, 1000000, 0,
 'ALL_SERVICES', '2026-01-01', '2026-12-31', TRUE, 8,
 'FAC_EHEALTH', 'USR_ADMIN_01'),
('DSC_DEMO_004', 'NEW_PATIENT', 'Khách hàng mới',
 'Giảm 100.000đ cho khách hàng đăng ký lần đầu',
 'AMOUNT', 100000, NULL, 300000,
 'ALL_SERVICES', '2026-01-01', '2026-12-31', TRUE, 3,
 'FAC_EHEALTH', 'USR_ADMIN_01'),
('DSC_DEMO_005', 'WEEKEND_OFF', 'Giảm giá cuối tuần',
 'Giảm 5% cho lịch khám T7, CN',
 'PERCENT', 5, 200000, 100000,
 'ALL_SERVICES', '2026-01-01', '2026-06-30', TRUE, 2,
 'FAC_EHEALTH', 'USR_ADMIN_01')
ON CONFLICT (discount_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 2. VOUCHERS (Voucher giảm giá)
-- ---------------------------------------------------------------------
INSERT INTO vouchers (
    voucher_id, voucher_code, name, description,
    discount_type, discount_value, max_discount_amount, min_order_amount,
    max_usage, max_usage_per_patient, current_usage,
    valid_from, valid_to, is_active, facility_id, created_by
) VALUES
('VCH_DEMO_001', 'WELCOME50K', 'Voucher chào mừng 50K',
 'Giảm 50.000đ cho đơn từ 200.000đ. Áp dụng 1 lần/bệnh nhân.',
 'AMOUNT', 50000, NULL, 200000,
 500, 1, 12,
 '2026-01-01', '2026-12-31', TRUE, 'FAC_EHEALTH', 'USR_ADMIN_01'),
('VCH_DEMO_002', 'TEAM30', 'Voucher gia đình giảm 30%',
 'Giảm 30% cho lần khám tiếp theo trong gia đình',
 'PERCENT', 30, 500000, 150000,
 200, 2, 6,
 '2026-02-01', '2026-06-30', TRUE, 'FAC_EHEALTH', 'USR_ADMIN_01'),
('VCH_DEMO_003', 'VIP200K', 'Voucher VIP 200K',
 'Khách VIP nhận 200.000đ giảm trực tiếp',
 'AMOUNT', 200000, NULL, 800000,
 100, 1, 4,
 '2026-01-01', '2026-12-31', TRUE, 'FAC_EHEALTH', 'USR_ADMIN_01'),
('VCH_DEMO_004', 'BACK2HEALTH', 'Tái khám 15%',
 'Giảm 15% cho lần tái khám trong vòng 30 ngày',
 'PERCENT', 15, 300000, 100000,
 NULL, 1, 22,
 '2026-01-01', '2026-12-31', TRUE, 'FAC_EHEALTH', 'USR_ADMIN_01'),
('VCH_DEMO_005', 'KIDS50', 'Voucher trẻ em',
 'Giảm 50.000đ cho dịch vụ nhi khoa',
 'AMOUNT', 50000, NULL, 100000,
 300, 3, 18,
 '2026-01-01', '2026-12-31', TRUE, 'FAC_EHEALTH', 'USR_ADMIN_01')
ON CONFLICT (voucher_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 3. SERVICE BUNDLES (Gói dịch vụ combo)
-- ---------------------------------------------------------------------
INSERT INTO service_bundles (
    bundle_id, bundle_code, name, description,
    bundle_price, original_total_price, discount_percentage,
    valid_from, valid_to, max_purchases, current_purchases,
    is_active, facility_id, created_by
) VALUES
('BUN_DEMO_001', 'HEALTH_CHECK_BASIC', 'Gói khám sức khoẻ cơ bản',
 'Khám tổng quát + xét nghiệm máu + nước tiểu + X-Quang',
 1200000, 1500000, 20,
 '2026-01-01', '2026-12-31', 1000, 45,
 TRUE, 'FAC_EHEALTH', 'USR_ADMIN_01'),
('BUN_DEMO_002', 'HEALTH_CHECK_PREMIUM', 'Gói khám sức khoẻ cao cấp',
 'Khám tổng quát + đầy đủ xét nghiệm + nội soi + siêu âm + tim mạch',
 3500000, 4800000, 27,
 '2026-01-01', '2026-12-31', 500, 18,
 TRUE, 'FAC_EHEALTH', 'USR_ADMIN_01'),
('BUN_DEMO_003', 'PRENATAL_PACKAGE', 'Gói khám thai trọn gói',
 'Khám thai 6 lần + xét nghiệm sàng lọc + siêu âm 4D',
 4500000, 5800000, 22,
 '2026-01-01', '2026-12-31', 200, 9,
 TRUE, 'FAC_EHEALTH', 'USR_ADMIN_01')
ON CONFLICT (bundle_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 4. SERVICE BUNDLE ITEMS (Chi tiết dịch vụ trong gói)
--    Map vào facility_services có sẵn: FS_PT_05, FS_PT_02, FS_PT_01, FS_PT_03, FS_PT_04
-- ---------------------------------------------------------------------
INSERT INTO service_bundle_items (item_id, bundle_id, facility_service_id, quantity, unit_price, item_price, notes) VALUES
('BIT_DEMO_001_1', 'BUN_DEMO_001', 'FS_PT_01', 1, 8000000, 800000, 'Khám tổng quát'),
('BIT_DEMO_001_2', 'BUN_DEMO_001', 'FS_PT_03', 1, 7000000, 400000, 'Xét nghiệm cơ bản'),
('BIT_DEMO_002_1', 'BUN_DEMO_002', 'FS_PT_02', 1, 10000000, 1500000, 'Khám chuyên sâu'),
('BIT_DEMO_002_2', 'BUN_DEMO_002', 'FS_PT_04', 1, 6000000, 1000000, 'Nội soi'),
('BIT_DEMO_002_3', 'BUN_DEMO_002', 'FS_PT_05', 1, 12000000, 1000000, 'Tim mạch'),
('BIT_DEMO_003_1', 'BUN_DEMO_003', 'FS_PT_01', 6, 8000000, 3000000, 'Khám thai định kỳ'),
('BIT_DEMO_003_2', 'BUN_DEMO_003', 'FS_PT_03', 2, 7000000, 1500000, 'Siêu âm + sàng lọc')
ON CONFLICT (item_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 5. E-INVOICE CONFIG
-- ---------------------------------------------------------------------
INSERT INTO e_invoice_config (
    config_id, facility_id, seller_name, seller_tax_code, seller_address,
    seller_phone, seller_bank_account, seller_bank_name,
    invoice_template, invoice_series, current_number,
    tax_rate_default, currency_default, is_active, created_by
) VALUES
('EIC_DEMO_001', 'FAC_EHEALTH',
 'PHÒNG KHÁM ĐA KHOA E-HEALTH', '0312345678',
 '123 Nguyễn Văn Cừ, Phường 4, Quận 5, TP.HCM',
 '02838335678', '0123456789012', 'Vietcombank — CN HCM',
 '1C26TAA', 'C26TAA', 10,
 8, 'VND', TRUE, 'USR_ADMIN_01')
ON CONFLICT (config_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 6. E-INVOICES (Hoá đơn điện tử)
-- ---------------------------------------------------------------------
INSERT INTO e_invoices (
    e_invoice_id, e_invoice_number, invoice_template, invoice_series, lookup_code,
    invoice_id, invoice_type, seller_name, seller_tax_code, seller_address, seller_phone,
    buyer_name, buyer_tax_code, buyer_address, buyer_email, buyer_type,
    total_before_tax, tax_rate, tax_amount, total_after_tax, discount_amount,
    payment_method_text, amount_in_words, status, signed_at, signed_by,
    notes, currency, facility_id, issued_at, created_by, created_at
) VALUES
('EIV_DEMO_001', 'C26TAA-00000001', '1C26TAA', 'C26TAA', 'LK001ABCXYZ',
 'INV_SEED_0001', 'SALES',
 'PHÒNG KHÁM ĐA KHOA E-HEALTH', '0312345678', '123 Nguyễn Văn Cừ, P.4, Q.5, TP.HCM', '02838335678',
 'Dương Chí Nam', NULL, '334 Nguyễn Trãi, Q. Phú Nhuận, TP.HCM', 'duongchinam@gmail.com', 'INDIVIDUAL',
 396535, 8, 31723, 428258, 0,
 'Tiền mặt', 'Bốn trăm hai mươi tám ngàn hai trăm năm mươi tám đồng',
 'ISSUED', '2026-05-10 10:30:00+07', 'USR_ADMIN_01',
 NULL, 'VND', 'FAC_EHEALTH', '2026-05-10 10:30:00+07', 'USR_ADMIN_01', '2026-05-10 10:25:00+07'),

('EIV_DEMO_002', 'C26TAA-00000002', '1C26TAA', 'C26TAA', 'LK002DEFGHI',
 'INV_SEED_0002', 'SALES',
 'PHÒNG KHÁM ĐA KHOA E-HEALTH', '0312345678', '123 Nguyễn Văn Cừ, P.4, Q.5, TP.HCM', '02838335678',
 'Dương Chí Nam', NULL, '334 Nguyễn Trãi, Q. Phú Nhuận, TP.HCM', 'duongchinam@gmail.com', 'INDIVIDUAL',
 426835, 8, 34147, 460982, 0,
 'Chuyển khoản', 'Bốn trăm sáu mươi ngàn chín trăm tám mươi hai đồng',
 'ISSUED', '2026-05-11 09:00:00+07', 'USR_ADMIN_01',
 NULL, 'VND', 'FAC_EHEALTH', '2026-05-11 09:00:00+07', 'USR_ADMIN_01', '2026-05-11 08:55:00+07'),

('EIV_DEMO_003', 'C26TAA-00000003', '1C26TAA', 'C26TAA', 'LK003JKLMNO',
 NULL, 'SALES',
 'PHÒNG KHÁM ĐA KHOA E-HEALTH', '0312345678', '123 Nguyễn Văn Cừ, P.4, Q.5, TP.HCM', '02838335678',
 'CÔNG TY TNHH ABC HEALTH', '0345678901', '15 Lê Lợi, Q.1, TP.HCM', 'admin@abchealth.vn', 'COMPANY',
 2500000, 8, 200000, 2700000, 0,
 'Chuyển khoản', 'Hai triệu bảy trăm ngàn đồng',
 'ISSUED', '2026-05-12 14:20:00+07', 'USR_ADMIN_01',
 'Hoá đơn dịch vụ khám sức khoẻ định kỳ cho nhân viên', 'VND', 'FAC_EHEALTH', '2026-05-12 14:20:00+07', 'USR_ADMIN_01', '2026-05-12 14:15:00+07'),

('EIV_DEMO_004', 'C26TAA-00000004', '1C26TAA', 'C26TAA', 'LK004PQRSTU',
 NULL, 'SALES',
 'PHÒNG KHÁM ĐA KHOA E-HEALTH', '0312345678', '123 Nguyễn Văn Cừ, P.4, Q.5, TP.HCM', '02838335678',
 'Trần Thị Lan', NULL, '88 Trần Hưng Đạo, Q.1, TP.HCM', 'tranlan@gmail.com', 'INDIVIDUAL',
 1389000, 8, 111000, 1500000, 50000,
 'Thẻ ngân hàng', 'Một triệu năm trăm ngàn đồng',
 'ISSUED', '2026-05-13 11:00:00+07', 'USR_ADMIN_01',
 NULL, 'VND', 'FAC_EHEALTH', '2026-05-13 11:00:00+07', 'USR_ADMIN_01', '2026-05-13 10:55:00+07'),

('EIV_DEMO_005', 'C26TAA-00000005', '1C26TAA', 'C26TAA', 'LK005VWXYZA',
 NULL, 'SALES',
 'PHÒNG KHÁM ĐA KHOA E-HEALTH', '0312345678', '123 Nguyễn Văn Cừ, P.4, Q.5, TP.HCM', '02838335678',
 'Nguyễn Văn Hùng', NULL, '12 Võ Văn Tần, Q.3, TP.HCM', NULL, 'INDIVIDUAL',
 555556, 8, 44444, 600000, 0,
 'Tiền mặt', 'Sáu trăm ngàn đồng',
 'ISSUED', '2026-05-14 09:15:00+07', 'USR_ADMIN_01',
 NULL, 'VND', 'FAC_EHEALTH', '2026-05-14 09:15:00+07', 'USR_ADMIN_01', '2026-05-14 09:10:00+07'),

('EIV_DEMO_006', 'C26TAA-00000006', '1C26TAA', 'C26TAA', NULL,
 NULL, 'SALES',
 'PHÒNG KHÁM ĐA KHOA E-HEALTH', '0312345678', '123 Nguyễn Văn Cừ, P.4, Q.5, TP.HCM', '02838335678',
 'Phạm Thị Mai', NULL, '45 Hai Bà Trưng, Q.1, TP.HCM', NULL, 'INDIVIDUAL',
 277778, 8, 22222, 300000, 0,
 'Tiền mặt', 'Ba trăm ngàn đồng',
 'DRAFT', NULL, NULL,
 'Chưa phát hành', 'VND', 'FAC_EHEALTH', NULL, 'USR_ADMIN_01', '2026-05-15 16:00:00+07'),

('EIV_DEMO_007', 'C26TAA-00000007', '1C26TAA', 'C26TAA', NULL,
 NULL, 'SALES',
 'PHÒNG KHÁM ĐA KHOA E-HEALTH', '0312345678', '123 Nguyễn Văn Cừ, P.4, Q.5, TP.HCM', '02838335678',
 'Lê Văn Cường', NULL, '67 Pasteur, Q.3, TP.HCM', 'lecuong@gmail.com', 'INDIVIDUAL',
 925926, 8, 74074, 1000000, 0,
 'Chuyển khoản', 'Một triệu đồng',
 'DRAFT', NULL, NULL,
 NULL, 'VND', 'FAC_EHEALTH', NULL, 'USR_ADMIN_01', '2026-05-16 10:00:00+07'),

('EIV_DEMO_008', 'C26TAA-00000008', '1C26TAA', 'C26TAA', 'LK008CDEFGH',
 NULL, 'SALES',
 'PHÒNG KHÁM ĐA KHOA E-HEALTH', '0312345678', '123 Nguyễn Văn Cừ, P.4, Q.5, TP.HCM', '02838335678',
 'Vũ Thị Hoa', NULL, '99 Nguyễn Du, Q.1, TP.HCM', 'vuhoa@gmail.com', 'INDIVIDUAL',
 740741, 8, 59259, 800000, 0,
 'Ví điện tử', 'Tám trăm ngàn đồng',
 'CANCELLED', '2026-05-17 08:30:00+07', 'USR_ADMIN_01',
 'Khách yêu cầu huỷ', 'VND', 'FAC_EHEALTH', '2026-05-17 08:30:00+07', 'USR_ADMIN_01', '2026-05-17 08:25:00+07'),

('EIV_DEMO_009', 'C26TAA-00000009', '1C26TAA', 'C26TAA', 'LK009IJKLMN',
 NULL, 'SALES',
 'PHÒNG KHÁM ĐA KHOA E-HEALTH', '0312345678', '123 Nguyễn Văn Cừ, P.4, Q.5, TP.HCM', '02838335678',
 'CTY TNHH MTV BẢO HIỂM SỨC KHOẺ', '0399887766', '1 Tôn Đức Thắng, Q.1, TP.HCM', 'bh@health.vn', 'COMPANY',
 4629630, 8, 370370, 5000000, 0,
 'Chuyển khoản', 'Năm triệu đồng',
 'ISSUED', '2026-05-18 13:00:00+07', 'USR_ADMIN_01',
 'Hoá đơn dịch vụ tập thể tháng 5/2026', 'VND', 'FAC_EHEALTH', '2026-05-18 13:00:00+07', 'USR_ADMIN_01', '2026-05-18 12:55:00+07'),

('EIV_DEMO_010', 'C26TAA-00000010', '1C26TAA', 'C26TAA', 'LK010OPQRST',
 NULL, 'SALES',
 'PHÒNG KHÁM ĐA KHOA E-HEALTH', '0312345678', '123 Nguyễn Văn Cừ, P.4, Q.5, TP.HCM', '02838335678',
 'Hoàng Văn Tâm', NULL, '23 Cách Mạng Tháng 8, Q.10, TP.HCM', NULL, 'INDIVIDUAL',
 416667, 8, 33333, 450000, 0,
 'Tiền mặt', 'Bốn trăm năm mươi ngàn đồng',
 'ISSUED', '2026-05-19 09:45:00+07', 'USR_ADMIN_01',
 NULL, 'VND', 'FAC_EHEALTH', '2026-05-19 09:45:00+07', 'USR_ADMIN_01', '2026-05-19 09:40:00+07')
ON CONFLICT (e_invoice_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 7. E-INVOICE ITEMS
-- ---------------------------------------------------------------------
INSERT INTO e_invoice_items (item_id, e_invoice_id, line_number, item_name, unit, quantity, unit_price, discount_amount, amount_before_tax, tax_rate, tax_amount, amount_after_tax) VALUES
('EII_001_1', 'EIV_DEMO_001', 1, 'Khám nội tổng quát', 'Lần', 1, 200000, 0, 200000, 8, 16000, 216000),
('EII_001_2', 'EIV_DEMO_001', 2, 'Xét nghiệm máu cơ bản', 'Lần', 1, 196535, 0, 196535, 8, 15723, 212258),
('EII_002_1', 'EIV_DEMO_002', 1, 'Khám chuyên khoa tim mạch', 'Lần', 1, 426835, 0, 426835, 8, 34147, 460982),
('EII_003_1', 'EIV_DEMO_003', 1, 'Gói khám sức khoẻ định kỳ', 'Gói', 5, 500000, 0, 2500000, 8, 200000, 2700000),
('EII_004_1', 'EIV_DEMO_004', 1, 'Gói khám sức khoẻ cơ bản', 'Gói', 1, 1389000, 50000, 1389000, 8, 111000, 1500000),
('EII_005_1', 'EIV_DEMO_005', 1, 'Siêu âm bụng tổng quát', 'Lần', 1, 350000, 0, 350000, 8, 28000, 378000),
('EII_005_2', 'EIV_DEMO_005', 2, 'Khám tổng quát', 'Lần', 1, 205556, 0, 205556, 8, 16444, 222000),
('EII_006_1', 'EIV_DEMO_006', 1, 'Khám da liễu', 'Lần', 1, 277778, 0, 277778, 8, 22222, 300000),
('EII_007_1', 'EIV_DEMO_007', 1, 'Nội soi dạ dày', 'Lần', 1, 925926, 0, 925926, 8, 74074, 1000000),
('EII_008_1', 'EIV_DEMO_008', 1, 'Khám sản khoa', 'Lần', 1, 740741, 0, 740741, 8, 59259, 800000),
('EII_009_1', 'EIV_DEMO_009', 1, 'Khám sức khoẻ tập thể', 'Người', 10, 462963, 0, 4629630, 8, 370370, 5000000),
('EII_010_1', 'EIV_DEMO_010', 1, 'Khám da liễu + cận lâm sàng', 'Lần', 1, 416667, 0, 416667, 8, 33333, 450000)
ON CONFLICT (item_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 8. LEAVE REQUESTS (Đơn nghỉ phép bác sĩ)
-- ---------------------------------------------------------------------
INSERT INTO leave_requests (leave_requests_id, user_id, start_date, end_date, reason, status, approver_id, approver_note) VALUES
('LRQ_DEMO_001', 'USR_DOC_01', '2026-05-22', '2026-05-24', 'Nghỉ phép năm — du lịch gia đình',          'APPROVED', 'USR_ADMIN_01', 'Đã sắp xếp lịch thay thế'),
('LRQ_DEMO_002', 'USR_DOC_03', '2026-05-25', '2026-05-25', 'Đi tập huấn chuyên môn tại BV ĐH Y Dược',  'APPROVED', 'USR_ADMIN_01', NULL),
('LRQ_DEMO_003', 'USR_DOC_05', '2026-05-28', '2026-05-30', 'Việc gia đình quan trọng',                  'PENDING',  NULL,            NULL),
('LRQ_DEMO_004', 'USR_DOC_07', '2026-06-01', '2026-06-03', 'Tham dự hội thảo y khoa quốc gia',         'PENDING',  NULL,            NULL),
('LRQ_DEMO_005', 'USR_DOC_02', '2026-05-15', '2026-05-15', 'Khám sức khoẻ định kỳ',                     'REJECTED', 'USR_ADMIN_01', 'Trùng lịch khám đông, đề nghị đổi ngày khác')
ON CONFLICT (leave_requests_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 9. DRUG DISPENSE ORDERS (Phiếu cấp phát thuốc)
-- ---------------------------------------------------------------------
INSERT INTO drug_dispense_orders (drug_dispense_orders_id, prescription_id, pharmacist_id, status, dispensed_at, dispense_code, notes) VALUES
('DDO_DEMO_001', 'RX_SEED_0001', 'USR_PHA_01', 'COMPLETED', '2026-05-15 09:30:00', 'PXT-2026-0001', 'Đã cấp phát đủ thuốc, dặn dò uống đúng giờ'),
('DDO_DEMO_002', 'RX_SEED_0002', 'USR_PHA_02', 'COMPLETED', '2026-05-16 10:15:00', 'PXT-2026-0002', 'Bệnh nhân nhận đủ thuốc'),
('DDO_DEMO_003', 'RX_SEED_0003', 'USR_PHA_03', 'COMPLETED', '2026-05-17 14:00:00', 'PXT-2026-0003', NULL),
('DDO_DEMO_004', 'RX_SEED_0004', 'USR_PHA_01', 'PENDING',   '2026-05-19 08:00:00', 'PXT-2026-0004', 'Chờ xác nhận BHYT')
ON CONFLICT (drug_dispense_orders_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 10. TREATMENT PLANS (Kế hoạch điều trị)
-- ---------------------------------------------------------------------
INSERT INTO treatment_plans (
    treatment_plans_id, plan_code, patient_id, primary_diagnosis_code, primary_diagnosis_name,
    title, description, goals, start_date, expected_end_date, status, created_by
) VALUES
('TPL_DEMO_001', 'TP-2026-001', 'PAT_SEED_1001', 'I10', 'Tăng huyết áp vô căn',
 'Điều trị tăng huyết áp cho bệnh nhân Dương Chí Nam',
 'Phác đồ kiểm soát HA 3 tháng: thuốc + thay đổi lối sống + theo dõi định kỳ',
 'Đưa HA về dưới 130/80 mmHg, giảm cân 5kg, tăng vận động 30ph/ngày',
 '2026-05-01', '2026-08-01', 'ACTIVE', 'USR_DOC_01'),

('TPL_DEMO_002', 'TP-2026-002', 'PAT_SEED_1002', 'E11', 'Đái tháo đường type 2',
 'Điều trị đái tháo đường type 2 cho bệnh nhân Hoàng Bích Châu',
 'Kiểm soát đường huyết bằng metformin + chế độ ăn + tập luyện. Tái khám 4 tuần/lần',
 'HbA1c dưới 7%, đường huyết đói dưới 130 mg/dL trong 3 tháng',
 '2026-04-15', '2026-10-15', 'ACTIVE', 'USR_DOC_02'),

('TPL_DEMO_003', 'TP-2026-003', 'PAT_SEED_1004', 'J45', 'Hen phế quản',
 'Điều trị hen phế quản cho bệnh nhân Trần Thị Mai',
 'Sử dụng thuốc xịt dự phòng + cắt cơn. Tránh tác nhân kích thích',
 'Giảm tần suất cơn hen từ 3 lần/tuần xuống dưới 1 lần/tuần',
 '2026-05-10', '2026-09-10', 'ACTIVE', 'USR_DOC_05'),

('TPL_DEMO_004', 'TP-2026-004', 'PAT_SEED_1001', 'M54', 'Đau lưng',
 'Vật lý trị liệu đau lưng mạn tính',
 '12 buổi VLTL kết hợp tư vấn tư thế làm việc',
 'Hết đau lưng khi ngồi lâu, cải thiện vận động cột sống',
 '2026-03-01', '2026-05-01', 'COMPLETED', 'USR_DOC_03')
ON CONFLICT (treatment_plans_id) DO NOTHING;

COMMIT;

-- =====================================================================
-- VERIFY counts sau khi seed
-- =====================================================================
\echo '=== POST-SEED COUNTS ==='
SELECT 'discount_policies'       AS table_name, COUNT(*) FROM discount_policies
UNION ALL SELECT 'vouchers',              COUNT(*) FROM vouchers
UNION ALL SELECT 'service_bundles',       COUNT(*) FROM service_bundles
UNION ALL SELECT 'service_bundle_items',  COUNT(*) FROM service_bundle_items
UNION ALL SELECT 'e_invoice_config',      COUNT(*) FROM e_invoice_config
UNION ALL SELECT 'e_invoices',            COUNT(*) FROM e_invoices
UNION ALL SELECT 'e_invoice_items',       COUNT(*) FROM e_invoice_items
UNION ALL SELECT 'leave_requests',        COUNT(*) FROM leave_requests
UNION ALL SELECT 'drug_dispense_orders',  COUNT(*) FROM drug_dispense_orders
UNION ALL SELECT 'treatment_plans',       COUNT(*) FROM treatment_plans;
