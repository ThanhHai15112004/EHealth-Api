<div align="center">

# 🏥 E-Health Server — Backend API

### Hệ thống Quản lý Y tế Toàn diện (Phòng khám & Bệnh viện)

**Tác giả:** Phan Thanh Hải &nbsp;|&nbsp; **Đồ án Tốt nghiệp**

[![Node.js](https://img.shields.io/badge/Node.js-22-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.9-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Express](https://img.shields.io/badge/Express-5-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![TypeORM](https://img.shields.io/badge/TypeORM-0.3-FE0803?style=for-the-badge&logo=typeorm&logoColor=white)](https://typeorm.io/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![Swagger](https://img.shields.io/badge/Swagger-API_Docs-85EA2D?style=for-the-badge&logo=swagger&logoColor=black)](https://swagger.io/)

<br/>

🔗 **Live Demo:** [https://dev.thanhhaishopwebsite.id.vn](https://dev.thanhhaishopwebsite.id.vn)

🔗 **API Docs (Swagger):** [https://dev.thanhhaishopwebsite.id.vn/api-docs](https://dev.thanhhaishopwebsite.id.vn/api-docs)

[Tổng quan](#-tổng-quan) · [Kiến trúc](#-kiến-trúc-hệ-thống) · [Phân hệ](#-các-phân-hệ-chức-năng) · [Cài đặt](#%EF%B8%8F-hướng-dẫn-cài-đặt) · [Triển khai](#-triển-khai-cicd) · [English](#e-health-server--backend-api-english)

</div>

---

## 📋 Tổng quan

**E-Health Server** là RESTful API backend của Hệ thống Quản lý Y tế Số, phục vụ toàn bộ nghiệp vụ vận hành tại phòng khám và bệnh viện vừa – nhỏ. Hệ thống được thiết kế theo **kiến trúc module hóa**, chia thành **10 phân hệ chính** với hơn **120+ API endpoints**, hỗ trợ đa vai trò (Admin, Bác sĩ, Dược sĩ, Lễ tân, Thu ngân, Bệnh nhân).

### Điểm nổi bật

- 🔐 **Phân quyền RBAC đa tầng** — Role → Permission → API Permission, kiểm soát chi tiết đến từng endpoint
- 🏗️ **Kiến trúc module hóa** — 10 phân hệ độc lập, dễ mở rộng và bảo trì
- 📊 **Monitoring & Metrics** — Prometheus metrics, audit logs, structured logging (Winston)
- ⏱️ **Background Jobs** — 7 cron jobs tự động (nhắc lịch khám, dọn session, hết hạn thanh toán, ...)
- 🔄 **Graceful Shutdown** — Xử lý tín hiệu SIGINT/SIGTERM an toàn
- 💳 **Tích hợp thanh toán** — SePay Payment Gateway với webhook xác nhận tự động
- 📧 **Email Service** — Xác thực OTP, nhắc lịch khám, thông báo qua Nodemailer
- 🔥 **Firebase Push Notification** — Thông báo real-time đến thiết bị di động
- ☁️ **Cloudinary** — Upload & quản lý ảnh/tài liệu y tế
- 📄 **API Documentation** — Swagger UI tự động sinh tài liệu từ annotations
- 🐳 **Docker-ready** — Dockerfile + Docker Compose sẵn sàng deploy
- 🧪 **Testing** — Unit tests với Jest + ts-jest

---

## 🏗 Kiến trúc hệ thống

### Tech Stack

| Hạng mục | Công nghệ |
|----------|-----------|
| **Runtime** | Node.js 22 LTS |
| **Ngôn ngữ** | TypeScript 5.9 |
| **Framework** | Express.js 5 |
| **Database** | PostgreSQL + pgvector (AI vector search) |
| **ORM** | TypeORM 0.3 |
| **Xác thực** | JWT (Access/Refresh Token) + Firebase Admin SDK |
| **Phân quyền** | RBAC (Role → Permission → API Permission) |
| **Validation** | Zod 4 |
| **API Docs** | Swagger UI Express + swagger-jsdoc |
| **File Storage** | Cloudinary + Multer (memory storage) |
| **Email** | Nodemailer (SMTP) |
| **Push Notification** | Firebase Cloud Messaging |
| **Thanh toán** | SePay Payment Gateway |
| **Logging** | Winston + Daily Rotate File + Morgan |
| **Monitoring** | Prometheus (prom-client) |
| **Cron Jobs** | node-cron |
| **Import/Export** | ExcelJS, csv-parse, xlsx |
| **Security** | Helmet, express-rate-limit, CORS, bcrypt |
| **Circuit Breaker** | Opossum |
| **Testing** | Jest + ts-jest |
| **Containerization** | Docker + Docker Compose |
| **CI/CD** | Jenkins Pipeline |

### Cấu trúc thư mục

```
E-Health_server/
├── src/
│   ├── app.ts                          # Express app configuration
│   ├── server.ts                       # Server bootstrap & graceful shutdown
│   ├── config/
│   │   ├── env.ts                      # Environment config (typed & validated)
│   │   ├── postgresdb.ts               # Database connection pool
│   │   ├── firebase.ts                 # Firebase Admin SDK
│   │   ├── logger.config.ts            # Winston logger setup
│   │   ├── metrics.ts                  # Prometheus metrics registry
│   │   ├── sepay.ts                    # SePay payment config
│   │   └── swagger.ts                  # Swagger/OpenAPI spec
│   ├── controllers/                    # Request handlers (10 modules)
│   │   ├── Core/
│   │   ├── Appointment Management/
│   │   ├── Patient Management/
│   │   ├── EMR/
│   │   ├── EHR/
│   │   ├── Billing/
│   │   ├── Medication Management/
│   │   ├── Facility Management/
│   │   ├── Remote Consultation/
│   │   └── Reports/
│   ├── services/                       # Business logic layer (10 modules)
│   ├── repository/                     # Data access layer
│   ├── models/                         # TypeORM entities (70+ models)
│   ├── routes/                         # Route definitions (120+ endpoints)
│   ├── middleware/                      # 19 middleware functions
│   │   ├── verifyAccessToken           # JWT verification
│   │   ├── authorizeRoles              # Role-based access
│   │   ├── authorizePermissions        # Permission-based access
│   │   ├── authorizeApi                # API-level permission
│   │   ├── audit                       # Audit logging
│   │   ├── rate_limit                  # Rate limiting
│   │   ├── idempotency                 # Idempotency key support
│   │   ├── metrics                     # Prometheus middleware
│   │   ├── validate                    # Zod schema validation
│   │   └── ...
│   ├── schemas/                        # Zod validation schemas
│   ├── jobs/                           # Background cron jobs (7 jobs)
│   ├── constants/                      # Enum & constant definitions
│   ├── types/                          # TypeScript type definitions
│   └── utils/                          # Utility functions
├── databases/
│   ├── migrations/                     # Database migrations
│   ├── data/                           # Seed data
│   └── structure/                      # DB schema documentation
├── Dockerfile                          # Docker image definition
├── docker-compose.yml                  # Docker Compose config
├── jest.config.js                      # Jest test config
├── tsconfig.json                       # TypeScript config
└── .env.example                        # Environment template
```

### Kiến trúc tổng thể

```
                    ┌──────────────────────────────────────────┐
                    │          Client (Browser / Mobile)        │
                    └──────────────────┬───────────────────────┘
                                       │ HTTPS
                    ┌──────────────────▼───────────────────────┐
                    │        Nginx Reverse Proxy / Cloudflare   │
                    └──────────────────┬───────────────────────┘
                                       │
           ┌───────────────────────────▼───────────────────────────┐
           │                    Express.js Server                   │
           │  ┌─────────┐ ┌──────────┐ ┌────────┐ ┌────────────┐  │
           │  │ Helmet  │ │  CORS    │ │ Morgan │ │ Rate Limit │  │
           │  └────┬────┘ └────┬─────┘ └───┬────┘ └─────┬──────┘  │
           │       └───────────┴───────────┴─────────────┘         │
           │                        │                               │
           │  ┌─────────────────────▼──────────────────────────┐   │
           │  │              Audit Middleware                    │   │
           │  └─────────────────────┬──────────────────────────┘   │
           │                        │                               │
           │  ┌─────────────────────▼──────────────────────────┐   │
           │  │           API Routes (v1) — 10 Modules          │   │
           │  │  Core │ Appointment │ Patient │ EMR │ EHR │ ... │   │
           │  └─────────────────────┬──────────────────────────┘   │
           │                        │                               │
           │  ┌─────────────────────▼──────────────────────────┐   │
           │  │     Controllers → Services → Repositories       │   │
           │  └─────────────────────┬──────────────────────────┘   │
           └────────────────────────┼──────────────────────────────┘
                                    │
              ┌─────────────────────▼─────────────────────┐
              │          PostgreSQL (+ pgvector)            │
              └────────────────────────────────────────────┘

  Tích hợp ngoài:
  ┌─────────────┐  ┌────────────┐  ┌──────────┐  ┌─────────┐
  │  Cloudinary  │  │  Firebase  │  │  SePay   │  │  SMTP   │
  │  (Storage)   │  │  (FCM)     │  │(Payment) │  │ (Email) │
  └─────────────┘  └────────────┘  └──────────┘  └─────────┘
```

---

## 📦 Các phân hệ chức năng

### 1. 🔐 Core — Hệ thống Lõi

| Tính năng | Mô tả |
|-----------|-------|
| **Xác thực (Authentication)** | Đăng ký, đăng nhập, JWT Access/Refresh Token, quên mật khẩu, xác thực OTP email |
| **Phân quyền RBAC** | Roles → Permissions → API Permissions, gán menu theo role |
| **Quản lý người dùng** | CRUD users, import/export Excel, gán vai trò, quản lý hồ sơ cá nhân |
| **Master Data** | Danh mục dùng chung (ICD-10, đơn vị đo, loại xét nghiệm, ...) |
| **Danh mục thuốc** | Quản lý thuốc, phân nhóm, hướng dẫn sử dụng |
| **Hệ thống thông báo** | Template-based notification engine, category, role-config, FCM push |
| **System Settings** | Cấu hình hệ thống, bảo mật, UI, i18n, business rules |
| **Audit Logs** | Ghi nhật ký toàn bộ thao tác người dùng |

### 2. 📅 Appointment Management — Quản lý Đặt khám

| Tính năng | Mô tả |
|-----------|-------|
| **Đặt lịch khám** | Đặt lịch online, phân bổ slot theo bác sĩ, ca trực |
| **Quản lý trạng thái** | Pending → Confirmed → Checked-in → In-progress → Completed/Cancelled |
| **Điều phối lịch khám** | Coordination giữa nhiều bộ phận |
| **Xác nhận & nhắc lịch** | Gửi reminder tự động qua email/FCM |
| **Quản lý thay đổi lịch** | Change log, lịch sử dời/hủy |
| **Bác sĩ vắng mặt** | Quản lý nghỉ phép, khóa slot tự động |
| **Ca trực – Dịch vụ** | Gán dịch vụ theo ca trực, tùy chỉnh thời lượng khám |

### 3. 👤 Patient Management — Quản lý Bệnh nhân

| Tính năng | Mô tả |
|-----------|-------|
| **Hồ sơ bệnh nhân** | Thông tin cá nhân, liên hệ, người thân, phân loại (tag) |
| **Tiền sử bệnh** | Medical history chi tiết, classification rules |
| **Bảo hiểm y tế** | Quản lý BHYT, nhà cung cấp bảo hiểm, phạm vi bảo hiểm |
| **Tài liệu bệnh nhân** | Upload/quản lý tài liệu y tế (hình ảnh, PDF) |
| **Patient Profile (Portal)** | Bệnh nhân tự quản lý hồ sơ, xem lịch sử |

### 4. 📋 EMR — Bệnh án Điện tử

| Tính năng | Mô tả |
|-----------|-------|
| **Medical Record** | Hồ sơ bệnh án điện tử toàn diện |
| **Encounter** | Quản lý lượt khám (đa lượt/ngày) |
| **Clinical Exam** | Khám lâm sàng, ghi nhận triệu chứng |
| **Diagnosis** | Chẩn đoán (ICD-10), chẩn đoán sơ bộ/xác định |
| **Prescription** | Kê đơn thuốc điện tử, tương tác thuốc |
| **Medical Order** | Y lệnh (xét nghiệm, chẩn đoán hình ảnh, thủ thuật) |
| **Medical Sign-off** | Xác nhận/phê duyệt bệnh án (bác sĩ ký) |
| **Treatment Progress** | Theo dõi tiến trình điều trị |

### 5. 🏥 EHR — Hồ sơ Sức khỏe Điện tử

| Tính năng | Mô tả |
|-----------|-------|
| **Health Profile** | Hồ sơ sức khỏe tổng quát (tiểu sử, dị ứng, ...) |
| **Vital Signs** | Dấu hiệu sinh tồn (huyết áp, nhịp tim, SpO2, ...) |
| **Clinical Results** | Kết quả cận lâm sàng |
| **Medical History (EHR)** | Tổng hợp tiền sử bệnh từ nhiều nguồn |
| **Medication Treatment** | Lịch sử dùng thuốc |
| **Health Timeline** | Dòng thời gian sức khỏe bệnh nhân |
| **Data Integration** | Tích hợp dữ liệu từ hệ thống ngoài |

### 6. 💊 Medication Management — Quản lý Dược phẩm

| Tính năng | Mô tả |
|-----------|-------|
| **Kho thuốc (Warehouse)** | Quản lý nhiều kho, phân quyền theo kho |
| **Nhập kho (Stock In)** | Nhập thuốc từ nhà cung cấp, quản lý lô hàng |
| **Xuất kho (Stock Out)** | Xuất thuốc cho bệnh nhân/phòng khám |
| **Tồn kho (Inventory)** | Theo dõi tồn kho real-time, cảnh báo hết hàng |
| **Phát thuốc (Dispensing)** | Dược sĩ kiểm tra đơn thuốc & phát thuốc |
| **Danh mục thuốc** | Drug categories, nhà cung cấp (Suppliers) |
| **Hướng dẫn sử dụng** | Med Instructions template |

### 7. 🏢 Facility Management — Quản lý Cơ sở Y tế

| Tính năng | Mô tả |
|-----------|-------|
| **Chi nhánh (Branch)** | Quản lý mạng lưới chi nhánh |
| **Cơ sở (Facility)** | Thông tin cơ sở y tế, trạng thái hoạt động |
| **Khoa/Phòng (Department)** | Phân chia khoa phòng, liên kết chuyên khoa |
| **Chuyên khoa (Specialty)** | Danh mục chuyên khoa, dịch vụ theo chuyên khoa |
| **Phòng khám (Medical Room)** | Quản lý phòng khám, bảo trì phòng |
| **Giường bệnh (Bed)** | Quản lý giường nội trú |
| **Thiết bị y tế (Equipment)** | Quản lý thiết bị, bảo trì, hiệu chuẩn |
| **Dịch vụ y tế (Service)** | Danh mục dịch vụ, dịch vụ theo bác sĩ |
| **Ca trực (Shift)** | Quản lý ca trực, đổi ca (Shift Swap) |
| **Lịch nhân viên** | Staff Schedule, Doctor Availability |
| **Giờ hoạt động** | Operating Hours, Closed Days, Holidays |
| **Nghỉ phép (Leave)** | Đơn nghỉ phép nhân viên |
| **Chứng chỉ hành nghề** | License management, cảnh báo hết hạn |
| **Booking Config** | Cấu hình slot đặt lịch theo cơ sở |

### 8. 💰 Billing — Viện phí & Thanh toán

| Tính năng | Mô tả |
|-----------|-------|
| **Hóa đơn (Invoices)** | Tạo/quản lý hóa đơn viện phí |
| **Bảng giá (Pricing)** | Quản lý bảng giá dịch vụ |
| **Chính sách giá** | Pricing Policies (ưu đãi, BHYT, ...) |
| **Thanh toán online** | SePay Payment Gateway + QR Code |
| **Thanh toán offline** | Thu tiền mặt, xác thực thu ngân |
| **Hoàn tiền (Refund)** | Xử lý hoàn tiền |
| **Đối soát (Reconciliation)** | Đối soát tài chính cuối ngày |
| **Chứng từ (Document)** | Quản lý chứng từ kế toán |
| **Cashier Auth** | Xác thực riêng cho thu ngân (mở/đóng ca) |

### 9. 📹 Remote Consultation — Khám chữa bệnh Từ xa

| Tính năng | Mô tả |
|-----------|-------|
| **Tele-Booking** | Đặt lịch khám online/video call |
| **Tele-Room** | Phòng khám ảo |
| **Tele-Config** | Cấu hình hệ thống telemedicine |
| **Tele-Consultation Type** | Loại hình tư vấn (video, chat, phone) |
| **Tele-Medical Chat** | Chat y tế giữa bác sĩ và bệnh nhân |
| **Tele-Prescription** | Kê đơn thuốc từ xa |
| **Tele-Result** | Kết quả khám từ xa |
| **Tele-Follow-up** | Tái khám từ xa |
| **Tele-Quality** | Đánh giá chất lượng dịch vụ telemedicine |

### 10. 📊 Reports — Báo cáo & Thống kê

| Tính năng | Mô tả |
|-----------|-------|
| **Dashboard thống kê** | Tổng hợp dữ liệu hoạt động |
| **Báo cáo tùy chỉnh** | Export báo cáo theo tiêu chí |

---

## ⏰ Background Jobs (Cron Jobs)

| Job | Mô tả | Tần suất |
|-----|-------|----------|
| `SessionCleanup` | Dọn dẹp session hết hạn | Định kỳ |
| `AppointmentReminder` | Gửi nhắc lịch khám qua email/FCM | Trước giờ hẹn |
| `NoShowDetection` | Phát hiện bệnh nhân không đến khám | Sau giờ hẹn |
| `AppointmentNoShow` | Đánh dấu trạng thái No-Show | Tự động |
| `AutoApproveAppointment` | Tự động duyệt lịch khám chờ | Định kỳ |
| `PaymentOrderExpiry` | Hủy đơn thanh toán quá hạn | Định kỳ |
| `StalePendingDepositCleanup` | Dọn giao dịch cọc treo | Định kỳ |

---

## 🔒 Bảo mật

- **Helmet** — HTTP security headers
- **CORS** — Kiểm soát origin, cho phép credentials
- **Rate Limiting** — Giới hạn request/IP trên tất cả /api routes
- **JWT Access/Refresh Token** — Access token ngắn hạn, refresh token tái cấp
- **Bcrypt** — Hash mật khẩu
- **Zod Validation** — Validate input ở tầng schema
- **Idempotency Key** — Tránh duplicate request (tạo đơn, thanh toán)
- **Webhook Verification** — Xác thực webhook SePay bằng HMAC
- **Audit Trail** — Ghi nhật ký mọi thao tác
- **Data Encryption** — Mã hóa dữ liệu nhạy cảm at-rest (key rotation support)
- **Trust Proxy** — Đọc IP thật qua X-Forwarded-For

---

## ⚙️ Hướng dẫn Cài đặt

### Yêu cầu hệ thống

| Yêu cầu | Phiên bản |
|----------|-----------|
| Node.js | ≥ 22.x (LTS) |
| npm | ≥ 11.x |
| PostgreSQL | ≥ 15 |

### 1. Clone & Cài đặt

```bash
git clone https://github.com/PTH-Group-Inc/EHealth-Api.git
cd E-Health_server
npm install
```

### 2. Cấu hình môi trường

Copy file `.env.example` và điều chỉnh:

```bash
cp .env.example .env
```

Các biến môi trường cần thiết:

```env
# Server
NODE_ENV=development
PORT=3000

# Database (PostgreSQL)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ehealthdatabase
DB_USER=postgres
DB_PASSWORD=your_db_password

# JWT (BẮT BUỘC thay đổi trong production!)
JWT_ACCESS_SECRET=your_secure_access_secret
JWT_REFRESH_SECRET=your_secure_refresh_secret

# Frontend URL (CORS)
FRONTEND_URL=http://localhost:3001

# Email (SMTP)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password

# Cloudinary (File upload)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Firebase (Push notification)
FIREBASE_SERVICE_ACCOUNT='{ ... }'

# SePay (Payment gateway)
SEPAY_MERCHANT_ID=your_merchant_id
SEPAY_API_KEY=your_api_key
SEPAY_WEBHOOK_SECRET=your_secret
```

### 3. Khởi tạo Database

```bash
# TypeORM sẽ tự đồng bộ schema trong môi trường development
# Với production, chạy migration:
npm run typeorm migration:run
```

### 4. Chạy Development

```bash
npm run dev
# → Server khởi chạy tại http://localhost:3000
# → API Docs: http://localhost:3000/api-docs
```

### 5. Build & Production

```bash
npm run build
npm run start:prod
```

### Available Scripts

| Lệnh | Mô tả |
|-------|--------|
| `npm run dev` | Chạy dev server (hot-reload với ts-node-dev) |
| `npm run build` | Compile TypeScript → JavaScript |
| `npm run start:prod` | Chạy production (NODE_ENV=production) |
| `npm run start:dev` | Chạy build + development env |
| `npm run test` | Chạy unit tests (Jest) |

---

## 🐳 Docker Deployment

### Build & Run với Docker

```bash
# Build image
docker build -t ehealth-server .

# Chạy container
docker run -d \
  --name ehealth-api \
  -p 3000:3000 \
  --env-file .env \
  ehealth-server
```

### Docker Compose

```bash
docker-compose up -d
```

File `docker-compose.yml` đã cấu hình sẵn:
- Container backend (port 3000)
- Kết nối network PostgreSQL external

---

## 🚀 Triển khai CI/CD

### Jenkins Pipeline

Dự án sử dụng **Jenkins** để tự động hóa quy trình CI/CD, deploy lên server production.

#### Jenkinsfile (Declarative Pipeline)

```groovy
pipeline {
    agent any

    environment {
        NVM_DIR = "${HOME}/.nvm"
        NODE_VERSION = '22'
        APP_DIR = '/var/www/EHealth/E-Health_server'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: '<repository-url>',
                    credentialsId: 'github-credentials'
            }
        }

        stage('Setup Node.js') {
            steps {
                sh '''
                    export NVM_DIR="$HOME/.nvm"
                    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                    nvm install ${NODE_VERSION}
                    nvm use ${NODE_VERSION}
                    node -v && npm -v
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    export NVM_DIR="$HOME/.nvm"
                    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                    nvm use ${NODE_VERSION}
                    cd ${APP_DIR}
                    npm ci
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    export NVM_DIR="$HOME/.nvm"
                    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                    nvm use ${NODE_VERSION}
                    cd ${APP_DIR}
                    npm run test || true
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''
                    export NVM_DIR="$HOME/.nvm"
                    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                    nvm use ${NODE_VERSION}
                    cd ${APP_DIR}
                    npm run build
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    cd ${APP_DIR}
                    pm2 restart ehealth-server --update-env || pm2 start dist/server.js --name ehealth-server
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Backend deployed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs for details.'
        }
    }
}
```

#### Jenkins Shell Script (Đơn giản)

Nếu Jenkins job chạy shell trực tiếp:

```bash
#!/bin/bash
set -e

cd /var/www/EHealth/E-Health_server

# Activate Node.js
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 22
nvm use 22

echo "Node: $(node -v) | npm: $(npm -v)"

# Install, test, build
npm ci
npm run test || true
npm run build

# Restart server
pm2 restart ehealth-server --update-env || pm2 start dist/server.js --name ehealth-server

echo "✅ Deploy complete!"
```

### Sơ đồ CI/CD

```
  Git Push (main)
       │
       ▼
  ┌─────────┐     ┌──────────┐     ┌───────┐     ┌─────────┐     ┌────────┐
  │ Checkout │ ──▶ │ Install  │ ──▶ │ Test  │ ──▶ │  Build  │ ──▶ │ Deploy │
  │          │     │ npm ci   │     │ Jest  │     │ tsc     │     │ PM2    │
  └─────────┘     └──────────┘     └───────┘     └─────────┘     └────────┘
                                                                       │
                                                                       ▼
                                                              🌐 Production
                                                    dev.thanhhaishopwebsite.id.vn
```

---

## 🌐 Deployment Architecture

```
                        ┌──────────────────────┐
                        │   Cloudflare (CDN)    │
                        │   SSL Termination     │
                        └──────────┬───────────┘
                                   │
                        ┌──────────▼───────────┐
                        │  Nginx Reverse Proxy  │
                        │  dev.thanhhaishopweb  │
                        │  site.id.vn           │
                        └──────────┬───────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                              │
          ┌─────────▼─────────┐         ┌──────────▼──────────┐
          │  Next.js Frontend  │         │  Express.js Backend  │
          │  (Port 3001)       │         │  (Port 3000)         │
          │  PM2 managed       │         │  PM2 managed         │
          └────────────────────┘         └──────────┬───────────┘
                                                    │
                                         ┌──────────▼───────────┐
                                         │  PostgreSQL Database  │
                                         │  (Docker container)   │
                                         └──────────────────────┘
```

---

<br/><br/>
<hr/>
<br/><br/>

<div align="center">

# E-Health Server — Backend API [English]

### Comprehensive Healthcare Management System (Clinic & Hospital)

**Author:** Phan Thanh Hải &nbsp;|&nbsp; **Graduation Thesis Project**

🔗 **Live Demo:** [https://dev.thanhhaishopwebsite.id.vn](https://dev.thanhhaishopwebsite.id.vn)

</div>

---

## 📋 Overview

**E-Health Server** is the RESTful API backend of a Digital Healthcare Management System, designed to handle all operational workflows in small-to-medium clinics and hospitals. Built with a **modular architecture**, it consists of **10 core modules** with **120+ API endpoints**, supporting multiple roles (Admin, Doctor, Pharmacist, Receptionist, Cashier, Patient).

### Key Highlights

- 🔐 **Multi-layer RBAC** — Role → Permission → API Permission, granular control per endpoint
- 🏗️ **Modular Architecture** — 10 independent modules, easy to scale and maintain
- 📊 **Monitoring & Metrics** — Prometheus metrics, audit logs, structured logging (Winston)
- ⏱️ **Background Jobs** — 7 automated cron jobs (appointment reminders, session cleanup, payment expiry, ...)
- 🔄 **Graceful Shutdown** — Safe handling of SIGINT/SIGTERM signals
- 💳 **Payment Integration** — SePay Payment Gateway with automatic webhook verification
- 📧 **Email Service** — OTP verification, appointment reminders via Nodemailer
- 🔥 **Firebase Push Notifications** — Real-time notifications to mobile devices
- ☁️ **Cloudinary** — Upload & manage medical images/documents
- 📄 **Auto API Docs** — Swagger UI auto-generated from annotations
- 🐳 **Docker-ready** — Dockerfile + Docker Compose included
- 🧪 **Testing** — Unit tests with Jest + ts-jest

---

## 📦 Core Modules

| # | Module | Description |
|---|--------|-------------|
| 1 | **Core** | Authentication (JWT + Firebase), RBAC, user management, master data, notifications, system settings, audit logs |
| 2 | **Appointment Management** | Online booking, slot allocation, status workflow, reminders, doctor absence, shift-service mapping |
| 3 | **Patient Management** | Patient profiles, medical history, insurance, documents, contacts, classification |
| 4 | **EMR** | Electronic medical records, encounters, clinical exams, diagnosis (ICD-10), prescriptions, medical orders, sign-off |
| 5 | **EHR** | Health profiles, vital signs, clinical results, medication history, health timeline, data integration |
| 6 | **Medication Management** | Warehouse, stock in/out, inventory tracking, dispensing, drug categories, suppliers |
| 7 | **Facility Management** | Branches, departments, specialties, rooms, beds, equipment, shifts, schedules, operating hours, licenses |
| 8 | **Billing** | Invoices, pricing, pricing policies, online/offline payments, refunds, reconciliation, cashier auth |
| 9 | **Remote Consultation** | Telemedicine booking, virtual rooms, tele-chat, tele-prescriptions, quality assessment |
| 10 | **Reports** | Dashboard statistics, custom reports |

---

## 🛠 Tech Stack

| Category | Technology |
|----------|-----------|
| **Runtime** | Node.js 22 LTS |
| **Language** | TypeScript 5.9 |
| **Framework** | Express.js 5 |
| **Database** | PostgreSQL + pgvector (AI vector search) |
| **ORM** | TypeORM 0.3 |
| **Auth** | JWT (Access/Refresh Token) + Firebase Admin SDK |
| **Validation** | Zod 4 |
| **API Docs** | Swagger UI Express |
| **Storage** | Cloudinary + Multer |
| **Email** | Nodemailer |
| **Push Notifications** | Firebase Cloud Messaging |
| **Payment** | SePay Payment Gateway |
| **Logging** | Winston + Morgan |
| **Monitoring** | Prometheus (prom-client) |
| **Security** | Helmet, express-rate-limit, bcrypt, CORS |
| **Testing** | Jest + ts-jest |
| **CI/CD** | Jenkins + Docker |

---

## ⚙️ Quick Start

```bash
# 1. Clone & install
git clone <repository-url>
cd E-Health_server
npm install

# 2. Configure environment
cp .env.example .env
# Edit .env with your settings

# 3. Start development
npm run dev
# → API: http://localhost:3000
# → Docs: http://localhost:3000/api-docs
```

### Docker

```bash
docker-compose up -d
```

### Jenkins CI/CD

```bash
cd /var/www/EHealth/E-Health_server
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 22 && nvm use 22
npm ci && npm run build
pm2 restart ehealth-server --update-env || pm2 start dist/server.js --name ehealth-server
```

---

## 📄 License

This project is developed as a **graduation thesis project**.

---

<div align="center">

**Built with ❤️ using Node.js, TypeScript, Express.js & PostgreSQL**

</div>
