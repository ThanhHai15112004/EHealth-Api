-- =====================================================================
-- 16_billing.sql
-- =====================================================================
-- Demo data: 40 invoices + 120 invoice_details + 30 payment_orders +
--            30 payment_transactions + 5 refund_requests
-- Span last 90 days. Idempotent (ON CONFLICT PK DO NOTHING).
-- Dependencies: 01_core_roles_users (USR_STF_*/USR_ADMIN_01),
--               03_facilities (FAC_EHEALTH),
--               06_services (SVC_*) — tham chiếu mềm qua reference_id,
--               07_patients (PAT_016..055),
--               13_appointments_encounters (ENC_DEMO_001..030).
-- Lưu ý: invoices.appointment_id luôn = NULL để tránh phụ thuộc cứng vào
--        appointments (APT_DEMO_*) từ 13. Liên kết appointment được giữ
--        gián tiếp qua encounters.appointment_id.
-- Lưu ý FK schema:
--   invoices.patient_id          -> patients(id)
--   invoices.encounter_id        -> encounters(encounters_id) (nullable)
--   invoices.appointment_id      -> appointments(appointments_id) (nullable)
--   invoices.facility_id         -> facilities(facilities_id) (nullable)
--   invoices.created_by          -> users(users_id)
--   invoice_details.invoice_id   -> invoices(invoices_id)
--   payment_orders.invoice_id    -> invoices(invoices_id)
--   payment_orders.created_by    -> users(users_id)
--   payment_transactions.invoice_id -> invoices(invoices_id)
--   refund_requests.transaction_id -> payment_transactions(payment_transactions_id)
--   refund_requests.invoice_id   -> invoices(invoices_id)
--   refund_requests.patient_id   -> patients(id)
-- =====================================================================

BEGIN;

-- *********************************************************************
-- 1. INVOICES (40 hoá đơn)
--    Status mix:  20 PAID, 5 PARTIAL, 10 UNPAID, 3 REFUNDED, 2 CANCELLED
--    Span: 90 ngày gần nhất.
--    Reuse ENC_DEMO_001..030 cho 30 hoá đơn đầu (FK encounter),
--    10 hoá đơn còn lại encounter_id = NULL (vd: thuốc OTC, gói khám).
-- *********************************************************************
INSERT INTO invoices (
    invoices_id, invoice_code, patient_id, encounter_id,
    total_amount, discount_amount, insurance_amount, net_amount, paid_amount,
    status, created_by, created_at, facility_id, notes,
    cancelled_reason, cancelled_by, cancelled_at, updated_at,
    appointment_id, invoice_type
) VALUES
-- ===== 20 PAID invoices (đã thanh toán đủ) =====
('INV_DEMO_001','INV-DEMO-2026-00001','PAT_016','ENC_DEMO_001', 850000, 0,       0, 850000, 850000,'PAID','USR_STF_01',NOW() - INTERVAL '20 day',  'FAC_EHEALTH','Khám tổng quát + CBC + X-quang',NULL,NULL,NULL,NOW() - INTERVAL '20 day',  NULL,'ENCOUNTER'),
('INV_DEMO_002','INV-DEMO-2026-00002','PAT_017','ENC_DEMO_002', 720000, 20000,   0, 700000, 700000,'PAID','USR_STF_01',NOW() - INTERVAL '19 day',  'FAC_EHEALTH','Khám nội + sinh hoá',NULL,NULL,NULL,NOW() - INTERVAL '19 day',  NULL,'ENCOUNTER'),
('INV_DEMO_003','INV-DEMO-2026-00003','PAT_018','ENC_DEMO_003',1250000, 50000,       0,1200000,1200000,'PAID','USR_STF_02',NOW() - INTERVAL '18 day',  'FAC_EHEALTH','Gói khám sức khoẻ',NULL,NULL,NULL,NOW() - INTERVAL '18 day',  NULL,'ENCOUNTER'),
('INV_DEMO_004','INV-DEMO-2026-00004','PAT_019','ENC_DEMO_004', 480000, 0,       0, 480000, 480000,'PAID','USR_STF_02',NOW() - INTERVAL '17 day',  'FAC_EHEALTH','Khám ngoại + tiểu phẫu',NULL,NULL,NULL,NOW() - INTERVAL '17 day',  NULL,'ENCOUNTER'),
('INV_DEMO_005','INV-DEMO-2026-00005','PAT_020','ENC_DEMO_005', 960000, 0,  300000, 660000, 660000,'PAID','USR_STF_03',NOW() - INTERVAL '16 day',  'FAC_EHEALTH','Khám sản — BHYT chi trả 30%',NULL,NULL,NULL,NOW() - INTERVAL '16 day',  NULL,'ENCOUNTER'),
('INV_DEMO_006','INV-DEMO-2026-00006','PAT_021','ENC_DEMO_006', 350000, 0,       0, 350000, 350000,'PAID','USR_STF_01',NOW() - INTERVAL '15 day',  'FAC_EHEALTH','Khám nhi + thuốc kê đơn',NULL,NULL,NULL,NOW() - INTERVAL '15 day',  NULL,'ENCOUNTER'),
('INV_DEMO_007','INV-DEMO-2026-00007','PAT_022','ENC_DEMO_007',2100000, 100000,      0,2000000,2000000,'PAID','USR_STF_03',NOW() - INTERVAL '14 day',  'FAC_EHEALTH','Siêu âm tim + ECG + tư vấn',NULL,NULL,NULL,NOW() - INTERVAL '14 day',  NULL,'ENCOUNTER'),
('INV_DEMO_008','INV-DEMO-2026-00008','PAT_023','ENC_DEMO_008', 530000, 0,       0, 530000, 530000,'PAID','USR_STF_02',NOW() - INTERVAL '13 day',  'FAC_EHEALTH','Khám tổng quát + CBC',NULL,NULL,NULL,NOW() - INTERVAL '13 day',  NULL,'ENCOUNTER'),
('INV_DEMO_009','INV-DEMO-2026-00009','PAT_024','ENC_DEMO_009', 680000, 30000,      0, 650000, 650000,'PAID','USR_STF_04',NOW() - INTERVAL '12 day',  'FAC_EHEALTH','Tái khám + lipid panel',NULL,NULL,NULL,NOW() - INTERVAL '12 day',  NULL,'ENCOUNTER'),
('INV_DEMO_010','INV-DEMO-2026-00010','PAT_025','ENC_DEMO_010',1850000, 50000,      0,1800000,1800000,'PAID','USR_STF_04',NOW() - INTERVAL '11 day',  'FAC_EHEALTH','Gói khám SK định kỳ',NULL,NULL,NULL,NOW() - INTERVAL '11 day',  NULL,'ENCOUNTER'),
('INV_DEMO_011','INV-DEMO-2026-00011','PAT_026','ENC_DEMO_011', 420000, 0,       0, 420000, 420000,'PAID','USR_STF_05',NOW() - INTERVAL '10 day',  'FAC_EHEALTH','Khám nội + xét nghiệm Glucose',NULL,NULL,NULL,NOW() - INTERVAL '10 day',  NULL,'ENCOUNTER'),
('INV_DEMO_012','INV-DEMO-2026-00012','PAT_027','ENC_DEMO_012',1100000, 0,  250000, 850000, 850000,'PAID','USR_STF_01',NOW() - INTERVAL '9 day',   'FAC_EHEALTH','Khám tim mạch — BHYT',NULL,NULL,NULL,NOW() - INTERVAL '9 day',   NULL,'ENCOUNTER'),
('INV_DEMO_013','INV-DEMO-2026-00013','PAT_028','ENC_DEMO_013', 290000, 0,       0, 290000, 290000,'PAID','USR_STF_02',NOW() - INTERVAL '8 day',   'FAC_EHEALTH','Khám tái khám + CBC',NULL,NULL,NULL,NOW() - INTERVAL '8 day',   NULL,'ENCOUNTER'),
('INV_DEMO_014','INV-DEMO-2026-00014','PAT_029','ENC_DEMO_014',1650000, 50000,      0,1600000,1600000,'PAID','USR_STF_03',NOW() - INTERVAL '7 day',   'FAC_EHEALTH','Tiểu phẫu + thuốc',NULL,NULL,NULL,NOW() - INTERVAL '7 day',   NULL,'ENCOUNTER'),
('INV_DEMO_015','INV-DEMO-2026-00015','PAT_030','ENC_DEMO_015', 580000, 0,       0, 580000, 580000,'PAID','USR_STF_04',NOW() - INTERVAL '6 day',   'FAC_EHEALTH','Khám sản phụ khoa',NULL,NULL,NULL,NOW() - INTERVAL '6 day',   NULL,'ENCOUNTER'),
('INV_DEMO_016','INV-DEMO-2026-00016','PAT_031','ENC_DEMO_016', 760000, 0,       0, 760000, 760000,'PAID','USR_STF_05',NOW() - INTERVAL '5 day',   'FAC_EHEALTH','Khám nội + ECG',NULL,NULL,NULL,NOW() - INTERVAL '5 day',   NULL,'ENCOUNTER'),
('INV_DEMO_017','INV-DEMO-2026-00017','PAT_032','ENC_DEMO_017', 950000, 0,       0, 950000, 950000,'PAID','USR_STF_01',NOW() - INTERVAL '4 day',   'FAC_EHEALTH','Khám ngoại + X-quang',NULL,NULL,NULL,NOW() - INTERVAL '4 day',   NULL,'ENCOUNTER'),
('INV_DEMO_018','INV-DEMO-2026-00018','PAT_033','ENC_DEMO_018', 410000, 10000,   0, 400000, 400000,'PAID','USR_STF_02',NOW() - INTERVAL '3 day',   'FAC_EHEALTH','Khám tổng quát + thuốc',NULL,NULL,NULL,NOW() - INTERVAL '3 day',   NULL,'ENCOUNTER'),
('INV_DEMO_019','INV-DEMO-2026-00019','PAT_034','ENC_DEMO_019',1380000, 0,  200000,1180000,1180000,'PAID','USR_STF_03',NOW() - INTERVAL '2 day',   'FAC_EHEALTH','Siêu âm bụng + lipid + thuốc',NULL,NULL,NULL,NOW() - INTERVAL '2 day',   NULL,'ENCOUNTER'),
('INV_DEMO_020','INV-DEMO-2026-00020','PAT_035','ENC_DEMO_020', 320000, 0,       0, 320000, 320000,'PAID','USR_STF_04',NOW() - INTERVAL '1 day',   'FAC_EHEALTH','Khám nhi + CBC',NULL,NULL,NULL,NOW() - INTERVAL '1 day',   NULL,'ENCOUNTER'),
-- ===== 5 PARTIAL invoices (thanh toán một phần) =====
('INV_DEMO_021','INV-DEMO-2026-00021','PAT_036','ENC_DEMO_021',1850000, 0,       0,1850000, 900000,'PARTIAL','USR_STF_05',NOW() - INTERVAL '25 day',  'FAC_EHEALTH','Tiểu phẫu — đặt cọc 900k',NULL,NULL,NULL,NOW() - INTERVAL '25 day',  NULL,'ENCOUNTER'),
('INV_DEMO_022','INV-DEMO-2026-00022','PAT_037','ENC_DEMO_022',2400000, 0,       0,2400000,1000000,'PARTIAL','USR_STF_01',NOW() - INTERVAL '22 day',  'FAC_EHEALTH','Gói khám SK — trả góp',NULL,NULL,NULL,NOW() - INTERVAL '22 day',  NULL,'ENCOUNTER'),
('INV_DEMO_023','INV-DEMO-2026-00023','PAT_038','ENC_DEMO_023', 980000, 0,       0, 980000, 500000,'PARTIAL','USR_STF_02',NOW() - INTERVAL '18 day',  'FAC_EHEALTH','Khám nội + nội soi — đặt cọc',NULL,NULL,NULL,NOW() - INTERVAL '18 day',  NULL,'ENCOUNTER'),
('INV_DEMO_024','INV-DEMO-2026-00024','PAT_039','ENC_DEMO_024',1600000, 0,       0,1600000, 800000,'PARTIAL','USR_STF_03',NOW() - INTERVAL '12 day',  'FAC_EHEALTH','Khám tổng quát + CT scan — trả 50%',NULL,NULL,NULL,NOW() - INTERVAL '12 day',  NULL,'ENCOUNTER'),
('INV_DEMO_025','INV-DEMO-2026-00025','PAT_040','ENC_DEMO_025', 750000, 0,       0, 750000, 300000,'PARTIAL','USR_STF_04',NOW() - INTERVAL '6 day',   'FAC_EHEALTH','Khám PHCN — chuỗi 10 buổi, ứng 3 buổi',NULL,NULL,NULL,NOW() - INTERVAL '6 day',   NULL,'ENCOUNTER'),
-- ===== 10 UNPAID invoices (chờ thanh toán) =====
('INV_DEMO_026','INV-DEMO-2026-00026','PAT_041','ENC_DEMO_026', 350000, 0,       0, 350000, 0,'UNPAID','USR_STF_05',NOW() - INTERVAL '3 day',   'FAC_EHEALTH','Khám tổng quát — chờ thanh toán',NULL,NULL,NULL,NOW() - INTERVAL '3 day',   NULL,'ENCOUNTER'),
('INV_DEMO_027','INV-DEMO-2026-00027','PAT_042','ENC_DEMO_027', 280000, 0,       0, 280000, 0,'UNPAID','USR_STF_01',NOW() - INTERVAL '2 day',   'FAC_EHEALTH','Khám nhi — chờ thanh toán',NULL,NULL,NULL,NOW() - INTERVAL '2 day',   NULL,'ENCOUNTER'),
('INV_DEMO_028','INV-DEMO-2026-00028','PAT_043','ENC_DEMO_028', 520000, 0,       0, 520000, 0,'UNPAID','USR_STF_02',NOW() - INTERVAL '1 day' - INTERVAL '6 hour','FAC_EHEALTH','Khám nội — chờ TT',NULL,NULL,NULL,NOW() - INTERVAL '1 day' - INTERVAL '6 hour',NULL,'ENCOUNTER'),
('INV_DEMO_029','INV-DEMO-2026-00029','PAT_044','ENC_DEMO_029', 890000, 0,       0, 890000, 0,'UNPAID','USR_STF_03',NOW() - INTERVAL '1 day' - INTERVAL '3 hour','FAC_EHEALTH','Khám ngoại + CBC',NULL,NULL,NULL,NOW() - INTERVAL '1 day' - INTERVAL '3 hour',NULL,'ENCOUNTER'),
('INV_DEMO_030','INV-DEMO-2026-00030','PAT_045','ENC_DEMO_030', 240000, 0,       0, 240000, 0,'UNPAID','USR_STF_04',NOW() - INTERVAL '8 hour', 'FAC_EHEALTH','Khám tái khám',NULL,NULL,NULL,NOW() - INTERVAL '8 hour', NULL,'ENCOUNTER'),
('INV_DEMO_031','INV-DEMO-2026-00031','PAT_046',NULL,            150000, 0,       0, 150000, 0,'UNPAID','USR_STF_05',NOW() - INTERVAL '5 hour', 'FAC_EHEALTH','Thuốc OTC — chờ TT',NULL,NULL,NULL,NOW() - INTERVAL '5 hour', NULL,'PHARMACY'),
('INV_DEMO_032','INV-DEMO-2026-00032','PAT_047',NULL,            180000, 0,       0, 180000, 0,'UNPAID','USR_STF_01',NOW() - INTERVAL '4 hour', 'FAC_EHEALTH','Thuốc OTC — chờ TT',NULL,NULL,NULL,NOW() - INTERVAL '4 hour', NULL,'PHARMACY'),
('INV_DEMO_033','INV-DEMO-2026-00033','PAT_048',NULL,            420000, 0,       0, 420000, 0,'UNPAID','USR_STF_02',NOW() - INTERVAL '3 hour', 'FAC_EHEALTH','Vật tư y tế OTC',NULL,NULL,NULL,NOW() - INTERVAL '3 hour', NULL,'PHARMACY'),
('INV_DEMO_034','INV-DEMO-2026-00034','PAT_049',NULL,            760000, 0,       0, 760000, 0,'UNPAID','USR_STF_03',NOW() - INTERVAL '2 hour', 'FAC_EHEALTH','Gói khám SK đăng ký online',NULL,NULL,NULL,NOW() - INTERVAL '2 hour', NULL,'PACKAGE'),
('INV_DEMO_035','INV-DEMO-2026-00035','PAT_050',NULL,            330000, 0,       0, 330000, 0,'UNPAID','USR_STF_04',NOW() - INTERVAL '1 hour', 'FAC_EHEALTH','Thuốc kê đơn — chờ phát',NULL,NULL,NULL,NOW() - INTERVAL '1 hour', NULL,'PHARMACY'),
-- ===== 3 REFUNDED invoices (đã hoàn tiền — PAID rồi REFUNDED) =====
('INV_DEMO_036','INV-DEMO-2026-00036','PAT_051',NULL,            500000, 0,       0, 500000, 500000,'REFUNDED','USR_STF_05',NOW() - INTERVAL '40 day',  'FAC_EHEALTH','Đã hoàn — huỷ lịch cận giờ',NULL,NULL,NULL,NOW() - INTERVAL '38 day',  NULL,'PACKAGE'),
('INV_DEMO_037','INV-DEMO-2026-00037','PAT_052',NULL,            850000, 0,       0, 850000, 850000,'REFUNDED','USR_STF_01',NOW() - INTERVAL '55 day',  'FAC_EHEALTH','Đã hoàn — phát hiện thu nhầm dịch vụ',NULL,NULL,NULL,NOW() - INTERVAL '53 day',  NULL,'ENCOUNTER'),
('INV_DEMO_038','INV-DEMO-2026-00038','PAT_053',NULL,           1200000, 0,       0,1200000,1200000,'REFUNDED','USR_STF_02',NOW() - INTERVAL '70 day',  'FAC_EHEALTH','Đã hoàn — BHYT chi trả lại',NULL,NULL,NULL,NOW() - INTERVAL '67 day',  NULL,'ENCOUNTER'),
-- ===== 2 CANCELLED invoices (huỷ hoá đơn, chưa thu) =====
('INV_DEMO_039','INV-DEMO-2026-00039','PAT_054',NULL,            260000, 0,       0, 260000, 0,'CANCELLED','USR_STF_03',NOW() - INTERVAL '30 day',  'FAC_EHEALTH','Huỷ — bệnh nhân không đến','Bệnh nhân không đến khám sau 1 giờ','USR_ADMIN_01',NOW() - INTERVAL '30 day' + INTERVAL '2 hour',NOW() - INTERVAL '30 day' + INTERVAL '2 hour',NULL,'ENCOUNTER'),
('INV_DEMO_040','INV-DEMO-2026-00040','PAT_055',NULL,            580000, 0,       0, 580000, 0,'CANCELLED','USR_STF_04',NOW() - INTERVAL '85 day',  'FAC_EHEALTH','Huỷ — lập sai BN','Lập nhầm hồ sơ bệnh nhân','USR_ADMIN_01',NOW() - INTERVAL '85 day' + INTERVAL '30 minute',NOW() - INTERVAL '85 day' + INTERVAL '30 minute',NULL,'ENCOUNTER')
ON CONFLICT (invoices_id) DO NOTHING;


-- *********************************************************************
-- 2. INVOICE_DETAILS (~120 dòng — bình quân 3 dòng/hoá đơn)
--    reference_type: CONSULTATION | LAB_ORDER | RADIOLOGY | PROCEDURE | DRUG | PACKAGE
--    reference_id: tham chiếu services_id (SVC_*) hoặc tự sinh
-- *********************************************************************
INSERT INTO invoice_details (
    invoice_details_id, invoice_id, reference_type, reference_id,
    item_name, quantity, unit_price, subtotal,
    discount_amount, insurance_covered, patient_pays, notes
) VALUES
-- INV_DEMO_001 (850k = 250+150+200+150+100): khám tổng quát + CBC + X-quang + thuốc
('INVD_DEMO_001','INV_DEMO_001','CONSULTATION','SVC_KB_01','Khám tổng quát',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_002','INV_DEMO_001','LAB_ORDER',   'SVC_XN_01','Xét nghiệm công thức máu (CBC)',1, 150000, 150000, 0, 0, 150000,NULL),
('INVD_DEMO_003','INV_DEMO_001','RADIOLOGY',   'SVC_CDHA_01','X-quang phổi thẳng',1, 200000, 200000, 0, 0, 200000,NULL),
('INVD_DEMO_004','INV_DEMO_001','DRUG',        'DRG_PCM_500','Paracetamol 500mg — 10 viên',1, 100000, 100000, 0, 0, 100000,NULL),
('INVD_DEMO_005','INV_DEMO_001','DRUG',        'DRG_VITC_500','Vitamin C 500mg — 10 viên',1, 150000, 150000, 0, 0, 150000,NULL),
-- INV_DEMO_002 (720k): khám nội + sinh hoá
('INVD_DEMO_006','INV_DEMO_002','CONSULTATION','SVC_KB_02','Khám nội khoa',1, 300000, 300000, 20000, 0, 280000,'Discount 20k'),
('INVD_DEMO_007','INV_DEMO_002','LAB_ORDER',   'SVC_XN_02','Xét nghiệm sinh hoá máu 18 chỉ số',1, 350000, 350000, 0, 0, 350000,NULL),
('INVD_DEMO_008','INV_DEMO_002','LAB_ORDER',   'SVC_XN_03','Tổng phân tích nước tiểu',1,  70000,  70000, 0, 0,  70000,NULL),
-- INV_DEMO_003 (1.25M = 1.2M after disc): gói khám SK
('INVD_DEMO_009','INV_DEMO_003','PACKAGE',     'SVC_KB_08','Gói khám sức khoẻ tổng quát',1, 800000, 800000, 50000, 0, 750000,'Khuyến mãi 50k'),
('INVD_DEMO_010','INV_DEMO_003','LAB_ORDER',   'SVC_XN_07','Bộ mỡ máu (Lipid)',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_011','INV_DEMO_003','RADIOLOGY',   'SVC_CDHA_02','Siêu âm ổ bụng tổng quát',1, 200000, 200000, 0, 0, 200000,NULL),
-- INV_DEMO_004 (480k): khám ngoại + tiểu phẫu
('INVD_DEMO_012','INV_DEMO_004','CONSULTATION','SVC_KB_03','Khám ngoại khoa',1, 280000, 280000, 0, 0, 280000,NULL),
('INVD_DEMO_013','INV_DEMO_004','PROCEDURE',   'SVC_TT_01','Tiểu phẫu — khâu vết thương nhỏ',1, 200000, 200000, 0, 0, 200000,NULL),
-- INV_DEMO_005 (960k - 300 BH = 660k thực thu): khám sản — BHYT
('INVD_DEMO_014','INV_DEMO_005','CONSULTATION','SVC_KB_04','Khám sản phụ khoa',1, 350000, 350000, 0, 100000, 250000,'BHYT 30%'),
('INVD_DEMO_015','INV_DEMO_005','RADIOLOGY',   'SVC_CDHA_03','Siêu âm thai 2D',1, 250000, 250000, 0,  80000, 170000,'BHYT 30%'),
('INVD_DEMO_016','INV_DEMO_005','LAB_ORDER',   'SVC_XN_05','Glucose máu',1, 100000, 100000, 0,  30000,  70000,'BHYT 30%'),
('INVD_DEMO_017','INV_DEMO_005','DRUG',        'DRG_FE_FOLIC','Sắt + Folic 30 viên',1, 260000, 260000, 0,  90000, 170000,'BHYT 30%'),
-- INV_DEMO_006 (350k): khám nhi + thuốc
('INVD_DEMO_018','INV_DEMO_006','CONSULTATION','SVC_KB_05','Khám nhi khoa',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_019','INV_DEMO_006','DRUG',        'DRG_AUGMENTIN','Augmentin 250mg sirô',1, 100000, 100000, 0, 0, 100000,NULL),
-- INV_DEMO_007 (2.1M - 100k = 2M): siêu âm tim + ECG + tư vấn
('INVD_DEMO_020','INV_DEMO_007','CONSULTATION','SVC_KB_02','Khám nội khoa (tim mạch)',1, 400000, 400000, 0, 0, 400000,NULL),
('INVD_DEMO_021','INV_DEMO_007','RADIOLOGY',   'SVC_CDHA_05','Siêu âm tim qua thành ngực',1, 800000, 800000,100000, 0, 700000,'Discount 100k'),
('INVD_DEMO_022','INV_DEMO_007','PROCEDURE',   'SVC_TT_02','Điện tâm đồ (ECG)',1, 150000, 150000, 0, 0, 150000,NULL),
('INVD_DEMO_023','INV_DEMO_007','LAB_ORDER',   'SVC_XN_07','Bộ mỡ máu (Lipid)',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_024','INV_DEMO_007','DRUG',        'DRG_AMLO','Amlodipine 5mg — 30 viên',1, 500000, 500000, 0, 0, 500000,NULL),
-- INV_DEMO_008 (530k): khám tổng quát + CBC
('INVD_DEMO_025','INV_DEMO_008','CONSULTATION','SVC_KB_01','Khám tổng quát',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_026','INV_DEMO_008','LAB_ORDER',   'SVC_XN_01','Công thức máu (CBC)',1, 150000, 150000, 0, 0, 150000,NULL),
('INVD_DEMO_027','INV_DEMO_008','LAB_ORDER',   'SVC_XN_03','Tổng phân tích nước tiểu',1,  70000,  70000, 0, 0,  70000,NULL),
('INVD_DEMO_028','INV_DEMO_008','DRUG',        'DRG_PCM_500','Paracetamol 500mg',1,  60000,  60000, 0, 0,  60000,NULL),
-- INV_DEMO_009 (680k - 30k = 650k): tái khám + lipid
('INVD_DEMO_029','INV_DEMO_009','CONSULTATION','SVC_KB_07','Khám tái khám',1, 180000, 180000, 30000, 0, 150000,'Discount 30k'),
('INVD_DEMO_030','INV_DEMO_009','LAB_ORDER',   'SVC_XN_07','Bộ mỡ máu (Lipid)',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_031','INV_DEMO_009','DRUG',        'DRG_ATORVA','Atorvastatin 20mg — 30 viên',1, 250000, 250000, 0, 0, 250000,NULL),
-- INV_DEMO_010 (1.85M - 50k = 1.8M): gói khám SK định kỳ
('INVD_DEMO_032','INV_DEMO_010','PACKAGE',     'SVC_KB_08','Gói khám SK định kỳ — VIP',1,1200000,1200000, 50000, 0,1150000,'Discount 50k'),
('INVD_DEMO_033','INV_DEMO_010','LAB_ORDER',   'SVC_XN_06','Xét nghiệm HbA1c',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_034','INV_DEMO_010','RADIOLOGY',   'SVC_CDHA_06','CT scan ngực',1, 400000, 400000, 0, 0, 400000,NULL),
-- INV_DEMO_011 (420k): khám nội + Glucose
('INVD_DEMO_035','INV_DEMO_011','CONSULTATION','SVC_KB_02','Khám nội khoa',1, 300000, 300000, 0, 0, 300000,NULL),
('INVD_DEMO_036','INV_DEMO_011','LAB_ORDER',   'SVC_XN_05','Glucose máu lúc đói',1, 120000, 120000, 0, 0, 120000,NULL),
-- INV_DEMO_012 (1.1M - 250 BH = 850k): khám tim mạch BHYT
('INVD_DEMO_037','INV_DEMO_012','CONSULTATION','SVC_KB_02','Khám nội khoa (tim mạch)',1, 350000, 350000, 0, 80000, 270000,'BHYT'),
('INVD_DEMO_038','INV_DEMO_012','PROCEDURE',   'SVC_TT_02','Điện tâm đồ (ECG)',1, 150000, 150000, 0, 40000, 110000,'BHYT'),
('INVD_DEMO_039','INV_DEMO_012','RADIOLOGY',   'SVC_CDHA_05','Siêu âm tim qua thành ngực',1, 600000, 600000, 0,130000, 470000,'BHYT'),
-- INV_DEMO_013 (290k): khám tái khám + CBC
('INVD_DEMO_040','INV_DEMO_013','CONSULTATION','SVC_KB_07','Khám tái khám',1, 180000, 180000, 0, 0, 180000,NULL),
('INVD_DEMO_041','INV_DEMO_013','LAB_ORDER',   'SVC_XN_01','Công thức máu (CBC)',1, 110000, 110000, 0, 0, 110000,NULL),
-- INV_DEMO_014 (1.65M - 50k = 1.6M): tiểu phẫu + thuốc
('INVD_DEMO_042','INV_DEMO_014','CONSULTATION','SVC_KB_03','Khám ngoại',1, 280000, 280000, 0, 0, 280000,NULL),
('INVD_DEMO_043','INV_DEMO_014','PROCEDURE',   'SVC_TT_03','Tiểu phẫu — cắt nốt ruồi',1,1000000,1000000, 50000, 0, 950000,'Discount 50k'),
('INVD_DEMO_044','INV_DEMO_014','DRUG',        'DRG_KS_AMOX','Amoxicillin 500mg — 15 viên',1, 200000, 200000, 0, 0, 200000,NULL),
('INVD_DEMO_045','INV_DEMO_014','DRUG',        'DRG_BANDAGE','Bộ băng gạc thay băng',1, 170000, 170000, 0, 0, 170000,NULL),
-- INV_DEMO_015 (580k): khám sản phụ khoa
('INVD_DEMO_046','INV_DEMO_015','CONSULTATION','SVC_KB_04','Khám sản phụ khoa',1, 350000, 350000, 0, 0, 350000,NULL),
('INVD_DEMO_047','INV_DEMO_015','RADIOLOGY',   'SVC_CDHA_03','Siêu âm thai 2D',1, 230000, 230000, 0, 0, 230000,NULL),
-- INV_DEMO_016 (760k): khám nội + ECG
('INVD_DEMO_048','INV_DEMO_016','CONSULTATION','SVC_KB_02','Khám nội khoa',1, 300000, 300000, 0, 0, 300000,NULL),
('INVD_DEMO_049','INV_DEMO_016','PROCEDURE',   'SVC_TT_02','Điện tâm đồ (ECG)',1, 150000, 150000, 0, 0, 150000,NULL),
('INVD_DEMO_050','INV_DEMO_016','LAB_ORDER',   'SVC_XN_07','Bộ mỡ máu (Lipid)',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_051','INV_DEMO_016','DRUG',        'DRG_AMLO','Amlodipine 5mg — 30 viên',1,  60000,  60000, 0, 0,  60000,NULL),
-- INV_DEMO_017 (950k): khám ngoại + X-quang
('INVD_DEMO_052','INV_DEMO_017','CONSULTATION','SVC_KB_03','Khám ngoại khoa',1, 280000, 280000, 0, 0, 280000,NULL),
('INVD_DEMO_053','INV_DEMO_017','RADIOLOGY',   'SVC_CDHA_01','X-quang phổi thẳng',1, 200000, 200000, 0, 0, 200000,NULL),
('INVD_DEMO_054','INV_DEMO_017','RADIOLOGY',   'SVC_CDHA_07','MRI cột sống',1, 320000, 320000, 0, 0, 320000,NULL),
('INVD_DEMO_055','INV_DEMO_017','DRUG',        'DRG_DICLO','Diclofenac 50mg — 30 viên',1, 150000, 150000, 0, 0, 150000,NULL),
-- INV_DEMO_018 (410k - 10 = 400k): khám tổng quát + thuốc
('INVD_DEMO_056','INV_DEMO_018','CONSULTATION','SVC_KB_01','Khám tổng quát',1, 250000, 250000, 10000, 0, 240000,'Discount 10k'),
('INVD_DEMO_057','INV_DEMO_018','DRUG',        'DRG_PCM_500','Paracetamol 500mg — 20 viên',1, 100000, 100000, 0, 0, 100000,NULL),
('INVD_DEMO_058','INV_DEMO_018','DRUG',        'DRG_VITC_500','Vitamin C 500mg — 10 viên',1,  60000,  60000, 0, 0,  60000,NULL),
-- INV_DEMO_019 (1.38M - 200 BH = 1.18M): siêu âm bụng + lipid + thuốc
('INVD_DEMO_059','INV_DEMO_019','CONSULTATION','SVC_KB_02','Khám nội khoa',1, 300000, 300000, 0, 50000, 250000,'BHYT'),
('INVD_DEMO_060','INV_DEMO_019','RADIOLOGY',   'SVC_CDHA_02','Siêu âm ổ bụng tổng quát',1, 280000, 280000, 0, 50000, 230000,'BHYT'),
('INVD_DEMO_061','INV_DEMO_019','LAB_ORDER',   'SVC_XN_07','Bộ mỡ máu',1, 250000, 250000, 0, 50000, 200000,'BHYT'),
('INVD_DEMO_062','INV_DEMO_019','LAB_ORDER',   'SVC_XN_08','Chức năng gan',1, 250000, 250000, 0, 50000, 200000,'BHYT'),
('INVD_DEMO_063','INV_DEMO_019','DRUG',        'DRG_OMEPRA','Omeprazole 20mg — 30 viên',1, 300000, 300000, 0, 0, 300000,NULL),
-- INV_DEMO_020 (320k): khám nhi + CBC
('INVD_DEMO_064','INV_DEMO_020','CONSULTATION','SVC_KB_05','Khám nhi khoa',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_065','INV_DEMO_020','LAB_ORDER',   'SVC_XN_01','Công thức máu (CBC)',1,  70000,  70000, 0, 0,  70000,NULL),
-- INV_DEMO_021 PARTIAL (1.85M, đã trả 900k): tiểu phẫu
('INVD_DEMO_066','INV_DEMO_021','CONSULTATION','SVC_KB_03','Khám ngoại',1, 280000, 280000, 0, 0, 280000,NULL),
('INVD_DEMO_067','INV_DEMO_021','PROCEDURE',   'SVC_PT_01','Tiểu phẫu — cắt u mỡ',1,1200000,1200000, 0, 0,1200000,NULL),
('INVD_DEMO_068','INV_DEMO_021','DRUG',        'DRG_KS_AMOX','Amoxicillin 500mg',1, 200000, 200000, 0, 0, 200000,NULL),
('INVD_DEMO_069','INV_DEMO_021','DRUG',        'DRG_BANDAGE','Băng gạc',1, 170000, 170000, 0, 0, 170000,NULL),
-- INV_DEMO_022 PARTIAL (2.4M, trả 1M): gói khám SK trả góp
('INVD_DEMO_070','INV_DEMO_022','PACKAGE',     'SVC_KB_08','Gói khám SK premium',1,1800000,1800000, 0, 0,1800000,NULL),
('INVD_DEMO_071','INV_DEMO_022','LAB_ORDER',   'SVC_XN_07','Bộ mỡ máu',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_072','INV_DEMO_022','RADIOLOGY',   'SVC_CDHA_06','CT scan ngực',1, 350000, 350000, 0, 0, 350000,NULL),
-- INV_DEMO_023 PARTIAL (980k, trả 500k): khám nội + nội soi
('INVD_DEMO_073','INV_DEMO_023','CONSULTATION','SVC_KB_02','Khám nội khoa',1, 300000, 300000, 0, 0, 300000,NULL),
('INVD_DEMO_074','INV_DEMO_023','PROCEDURE',   'SVC_TT_04','Nội soi dạ dày tá tràng',1, 600000, 600000, 0, 0, 600000,NULL),
('INVD_DEMO_075','INV_DEMO_023','DRUG',        'DRG_OMEPRA','Omeprazole 20mg',1,  80000,  80000, 0, 0,  80000,NULL),
-- INV_DEMO_024 PARTIAL (1.6M, trả 800k): khám tổng quát + CT
('INVD_DEMO_076','INV_DEMO_024','CONSULTATION','SVC_KB_01','Khám tổng quát',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_077','INV_DEMO_024','RADIOLOGY',   'SVC_CDHA_06','CT scan đầu',1, 800000, 800000, 0, 0, 800000,NULL),
('INVD_DEMO_078','INV_DEMO_024','LAB_ORDER',   'SVC_XN_02','Sinh hoá máu',1, 350000, 350000, 0, 0, 350000,NULL),
('INVD_DEMO_079','INV_DEMO_024','DRUG',        'DRG_VITB_COMP','Vitamin B complex',1, 200000, 200000, 0, 0, 200000,NULL),
-- INV_DEMO_025 PARTIAL (750k, trả 300k): PHCN chuỗi
('INVD_DEMO_080','INV_DEMO_025','PROCEDURE',   'SVC_PHCN_01','PHCN buổi 1/10 — vật lý trị liệu',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_081','INV_DEMO_025','PROCEDURE',   'SVC_PHCN_02','PHCN buổi 2/10 — sóng ngắn',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_082','INV_DEMO_025','PROCEDURE',   'SVC_PHCN_03','PHCN buổi 3/10 — kéo dãn',1, 250000, 250000, 0, 0, 250000,NULL),
-- INV_DEMO_026 UNPAID (350k): khám tổng quát
('INVD_DEMO_083','INV_DEMO_026','CONSULTATION','SVC_KB_01','Khám tổng quát',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_084','INV_DEMO_026','LAB_ORDER',   'SVC_XN_01','Công thức máu',1, 100000, 100000, 0, 0, 100000,NULL),
-- INV_DEMO_027 UNPAID (280k): khám nhi
('INVD_DEMO_085','INV_DEMO_027','CONSULTATION','SVC_KB_05','Khám nhi khoa',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_086','INV_DEMO_027','DRUG',        'DRG_AUGMENTIN','Augmentin sirô',1,  30000,  30000, 0, 0,  30000,NULL),
-- INV_DEMO_028 UNPAID (520k): khám nội
('INVD_DEMO_087','INV_DEMO_028','CONSULTATION','SVC_KB_02','Khám nội khoa',1, 300000, 300000, 0, 0, 300000,NULL),
('INVD_DEMO_088','INV_DEMO_028','LAB_ORDER',   'SVC_XN_05','Glucose máu',1, 120000, 120000, 0, 0, 120000,NULL),
('INVD_DEMO_089','INV_DEMO_028','LAB_ORDER',   'SVC_XN_03','Tổng phân tích nước tiểu',1, 100000, 100000, 0, 0, 100000,NULL),
-- INV_DEMO_029 UNPAID (890k): khám ngoại + CBC
('INVD_DEMO_090','INV_DEMO_029','CONSULTATION','SVC_KB_03','Khám ngoại khoa',1, 280000, 280000, 0, 0, 280000,NULL),
('INVD_DEMO_091','INV_DEMO_029','RADIOLOGY',   'SVC_CDHA_01','X-quang chi dưới',1, 200000, 200000, 0, 0, 200000,NULL),
('INVD_DEMO_092','INV_DEMO_029','PROCEDURE',   'SVC_TT_05','Bó bột cổ chân',1, 350000, 350000, 0, 0, 350000,NULL),
('INVD_DEMO_093','INV_DEMO_029','DRUG',        'DRG_DICLO','Diclofenac 50mg',1,  60000,  60000, 0, 0,  60000,NULL),
-- INV_DEMO_030 UNPAID (240k): khám tái khám
('INVD_DEMO_094','INV_DEMO_030','CONSULTATION','SVC_KB_07','Khám tái khám',1, 180000, 180000, 0, 0, 180000,NULL),
('INVD_DEMO_095','INV_DEMO_030','DRUG',        'DRG_PCM_500','Paracetamol 500mg',1,  60000,  60000, 0, 0,  60000,NULL),
-- INV_DEMO_031 UNPAID (150k): thuốc OTC
('INVD_DEMO_096','INV_DEMO_031','DRUG',        'DRG_PCM_500','Paracetamol 500mg — 20 viên',2,  50000, 100000, 0, 0, 100000,NULL),
('INVD_DEMO_097','INV_DEMO_031','DRUG',        'DRG_VITC_500','Vitamin C 500mg — 10 viên',1,  50000,  50000, 0, 0,  50000,NULL),
-- INV_DEMO_032 UNPAID (180k): thuốc OTC
('INVD_DEMO_098','INV_DEMO_032','DRUG',        'DRG_KS_AMOX','Amoxicillin 500mg — 15 viên',1, 100000, 100000, 0, 0, 100000,NULL),
('INVD_DEMO_099','INV_DEMO_032','DRUG',        'DRG_ORS','ORS 5 gói',1,  80000,  80000, 0, 0,  80000,NULL),
-- INV_DEMO_033 UNPAID (420k): vật tư y tế
('INVD_DEMO_100','INV_DEMO_033','DRUG',        'MAT_GAZ_STERILE','Gạc tiệt trùng (hộp)',2, 100000, 200000, 0, 0, 200000,NULL),
('INVD_DEMO_101','INV_DEMO_033','DRUG',        'MAT_GLOVES','Găng tay y tế (hộp)',1, 120000, 120000, 0, 0, 120000,NULL),
('INVD_DEMO_102','INV_DEMO_033','DRUG',        'MAT_ALCOHOL','Cồn 70 độ 500ml',2,  50000, 100000, 0, 0, 100000,NULL),
-- INV_DEMO_034 UNPAID (760k): gói khám online
('INVD_DEMO_103','INV_DEMO_034','PACKAGE',     'SVC_KB_08','Gói khám SK định kỳ — cơ bản',1, 700000, 700000, 0, 0, 700000,NULL),
('INVD_DEMO_104','INV_DEMO_034','LAB_ORDER',   'SVC_XN_05','Glucose máu',1,  60000,  60000, 0, 0,  60000,NULL),
-- INV_DEMO_035 UNPAID (330k): thuốc kê đơn
('INVD_DEMO_105','INV_DEMO_035','DRUG',        'DRG_AMLO','Amlodipine 5mg — 30 viên',1, 200000, 200000, 0, 0, 200000,NULL),
('INVD_DEMO_106','INV_DEMO_035','DRUG',        'DRG_ATORVA','Atorvastatin 20mg — 30 viên',1, 130000, 130000, 0, 0, 130000,NULL),
-- INV_DEMO_036 REFUNDED (500k): huỷ lịch cận giờ — đặt cọc
('INVD_DEMO_107','INV_DEMO_036','PACKAGE',     'SVC_KB_08','Gói khám SK — đặt cọc',1, 500000, 500000, 0, 0, 500000,'Hoàn 100% do huỷ trước 1h'),
-- INV_DEMO_037 REFUNDED (850k): thu nhầm DV
('INVD_DEMO_108','INV_DEMO_037','CONSULTATION','SVC_KB_01','Khám tổng quát',1, 250000, 250000, 0, 0, 250000,NULL),
('INVD_DEMO_109','INV_DEMO_037','RADIOLOGY',   'SVC_CDHA_06','CT scan ngực — thu nhầm',1, 400000, 400000, 0, 0, 400000,'Đã hoàn — không thực hiện'),
('INVD_DEMO_110','INV_DEMO_037','LAB_ORDER',   'SVC_XN_07','Bộ mỡ máu',1, 200000, 200000, 0, 0, 200000,NULL),
-- INV_DEMO_038 REFUNDED (1.2M): BHYT chi trả lại
('INVD_DEMO_111','INV_DEMO_038','CONSULTATION','SVC_KB_02','Khám nội khoa',1, 300000, 300000, 0, 0, 300000,NULL),
('INVD_DEMO_112','INV_DEMO_038','RADIOLOGY',   'SVC_CDHA_05','Siêu âm tim',1, 600000, 600000, 0, 0, 600000,NULL),
('INVD_DEMO_113','INV_DEMO_038','LAB_ORDER',   'SVC_XN_02','Sinh hoá máu',1, 300000, 300000, 0, 0, 300000,NULL),
-- INV_DEMO_039 CANCELLED (260k): bệnh nhân không đến
('INVD_DEMO_114','INV_DEMO_039','CONSULTATION','SVC_KB_01','Khám tổng quát — đã huỷ',1, 260000, 260000, 0, 0, 260000,'Hoá đơn bị huỷ'),
-- INV_DEMO_040 CANCELLED (580k): lập nhầm BN
('INVD_DEMO_115','INV_DEMO_040','CONSULTATION','SVC_KB_02','Khám nội khoa — đã huỷ',1, 300000, 300000, 0, 0, 300000,'Lập nhầm hồ sơ'),
('INVD_DEMO_116','INV_DEMO_040','LAB_ORDER',   'SVC_XN_01','CBC — đã huỷ',1, 100000, 100000, 0, 0, 100000,'Lập nhầm hồ sơ'),
('INVD_DEMO_117','INV_DEMO_040','RADIOLOGY',   'SVC_CDHA_01','X-quang — đã huỷ',1, 180000, 180000, 0, 0, 180000,'Lập nhầm hồ sơ'),
-- Vài dòng phụ để đủ 120
('INVD_DEMO_118','INV_DEMO_001','DRUG',        'DRG_LORATA','Loratadine 10mg — 10 viên',1, 100000, 100000, 0, 0, 100000,NULL),
('INVD_DEMO_119','INV_DEMO_010','LAB_ORDER',   'SVC_XN_09','Chức năng thận',1, 200000, 200000, 0, 0, 200000,NULL),
('INVD_DEMO_120','INV_DEMO_022','RADIOLOGY',   'SVC_CDHA_02','Siêu âm ổ bụng',1,  0,  0, 0, 0, 0,'Đính kèm gói')
ON CONFLICT (invoice_details_id) DO NOTHING;


-- *********************************************************************
-- 3. PAYMENT_ORDERS (30 — cho 20 PAID + 5 PARTIAL + 3 REFUNDED + 2 thêm)
--    status: COMPLETED (PAID), PENDING/PAID (PARTIAL), COMPLETED (REFUNDED), EXPIRED
-- *********************************************************************
INSERT INTO payment_orders (
    payment_orders_id, order_code, invoice_id, amount, description,
    qr_code_url, payment_url, gateway_order_id, status,
    expires_at, paid_at, gateway_transaction_id, gateway_response,
    created_by, created_at, updated_at
) VALUES
-- 20 PAYMENT_ORDERS cho PAID invoices
('PO_DEMO_001','PO-DEMO-2026-00001','INV_DEMO_001', 850000,'Thanh toán INV-2026-00001',NULL,NULL,'GW20260001','COMPLETED',NOW() - INTERVAL '20 day' + INTERVAL '30 minute',NOW() - INTERVAL '20 day' + INTERVAL '10 minute','GTXN20260001',NULL,'USR_STF_01',NOW() - INTERVAL '20 day',NOW() - INTERVAL '20 day' + INTERVAL '10 minute'),
('PO_DEMO_002','PO-DEMO-2026-00002','INV_DEMO_002', 700000,'Thanh toán INV-2026-00002',NULL,'https://pay.vnpay.vn/pay/PO-2026-00002','GW20260002','COMPLETED',NOW() - INTERVAL '19 day' + INTERVAL '30 minute',NOW() - INTERVAL '19 day' + INTERVAL '8 minute','GTXN20260002',NULL,'USR_STF_01',NOW() - INTERVAL '19 day',NOW() - INTERVAL '19 day' + INTERVAL '8 minute'),
('PO_DEMO_003','PO-DEMO-2026-00003','INV_DEMO_003',1200000,'Thanh toán INV-2026-00003',NULL,'https://pay.momo.vn/pay/PO-2026-00003','GW20260003','COMPLETED',NOW() - INTERVAL '18 day' + INTERVAL '30 minute',NOW() - INTERVAL '18 day' + INTERVAL '5 minute','GTXN20260003',NULL,'USR_STF_02',NOW() - INTERVAL '18 day',NOW() - INTERVAL '18 day' + INTERVAL '5 minute'),
('PO_DEMO_004','PO-DEMO-2026-00004','INV_DEMO_004', 480000,'Thanh toán INV-2026-00004',NULL,NULL,'GW20260004','COMPLETED',NOW() - INTERVAL '17 day' + INTERVAL '30 minute',NOW() - INTERVAL '17 day' + INTERVAL '12 minute','GTXN20260004',NULL,'USR_STF_02',NOW() - INTERVAL '17 day',NOW() - INTERVAL '17 day' + INTERVAL '12 minute'),
('PO_DEMO_005','PO-DEMO-2026-00005','INV_DEMO_005', 660000,'Thanh toán INV-2026-00005 (sau BHYT)',NULL,NULL,'GW20260005','COMPLETED',NOW() - INTERVAL '16 day' + INTERVAL '30 minute',NOW() - INTERVAL '16 day' + INTERVAL '7 minute','GTXN20260005',NULL,'USR_STF_03',NOW() - INTERVAL '16 day',NOW() - INTERVAL '16 day' + INTERVAL '7 minute'),
('PO_DEMO_006','PO-DEMO-2026-00006','INV_DEMO_006', 350000,'Thanh toán INV-2026-00006',NULL,NULL,'GW20260006','COMPLETED',NOW() - INTERVAL '15 day' + INTERVAL '30 minute',NOW() - INTERVAL '15 day' + INTERVAL '15 minute','GTXN20260006',NULL,'USR_STF_01',NOW() - INTERVAL '15 day',NOW() - INTERVAL '15 day' + INTERVAL '15 minute'),
('PO_DEMO_007','PO-DEMO-2026-00007','INV_DEMO_007',2000000,'Thanh toán INV-2026-00007',NULL,'https://pay.vnpay.vn/pay/PO-2026-00007','GW20260007','COMPLETED',NOW() - INTERVAL '14 day' + INTERVAL '30 minute',NOW() - INTERVAL '14 day' + INTERVAL '6 minute','GTXN20260007',NULL,'USR_STF_03',NOW() - INTERVAL '14 day',NOW() - INTERVAL '14 day' + INTERVAL '6 minute'),
('PO_DEMO_008','PO-DEMO-2026-00008','INV_DEMO_008', 530000,'Thanh toán INV-2026-00008',NULL,NULL,'GW20260008','COMPLETED',NOW() - INTERVAL '13 day' + INTERVAL '30 minute',NOW() - INTERVAL '13 day' + INTERVAL '20 minute','GTXN20260008',NULL,'USR_STF_02',NOW() - INTERVAL '13 day',NOW() - INTERVAL '13 day' + INTERVAL '20 minute'),
('PO_DEMO_009','PO-DEMO-2026-00009','INV_DEMO_009', 650000,'Thanh toán INV-2026-00009',NULL,'https://pay.zalopay.vn/pay/PO-2026-00009','GW20260009','COMPLETED',NOW() - INTERVAL '12 day' + INTERVAL '30 minute',NOW() - INTERVAL '12 day' + INTERVAL '4 minute','GTXN20260009',NULL,'USR_STF_04',NOW() - INTERVAL '12 day',NOW() - INTERVAL '12 day' + INTERVAL '4 minute'),
('PO_DEMO_010','PO-DEMO-2026-00010','INV_DEMO_010',1800000,'Thanh toán INV-2026-00010',NULL,'https://pay.vnpay.vn/pay/PO-2026-00010','GW20260010','COMPLETED',NOW() - INTERVAL '11 day' + INTERVAL '30 minute',NOW() - INTERVAL '11 day' + INTERVAL '11 minute','GTXN20260010',NULL,'USR_STF_04',NOW() - INTERVAL '11 day',NOW() - INTERVAL '11 day' + INTERVAL '11 minute'),
('PO_DEMO_011','PO-DEMO-2026-00011','INV_DEMO_011', 420000,'Thanh toán INV-2026-00011',NULL,NULL,'GW20260011','COMPLETED',NOW() - INTERVAL '10 day' + INTERVAL '30 minute',NOW() - INTERVAL '10 day' + INTERVAL '9 minute','GTXN20260011',NULL,'USR_STF_05',NOW() - INTERVAL '10 day',NOW() - INTERVAL '10 day' + INTERVAL '9 minute'),
('PO_DEMO_012','PO-DEMO-2026-00012','INV_DEMO_012', 850000,'Thanh toán INV-2026-00012 (sau BHYT)',NULL,NULL,'GW20260012','COMPLETED',NOW() - INTERVAL '9 day' + INTERVAL '30 minute',NOW() - INTERVAL '9 day' + INTERVAL '13 minute','GTXN20260012',NULL,'USR_STF_01',NOW() - INTERVAL '9 day',NOW() - INTERVAL '9 day' + INTERVAL '13 minute'),
('PO_DEMO_013','PO-DEMO-2026-00013','INV_DEMO_013', 290000,'Thanh toán INV-2026-00013',NULL,NULL,'GW20260013','COMPLETED',NOW() - INTERVAL '8 day' + INTERVAL '30 minute',NOW() - INTERVAL '8 day' + INTERVAL '6 minute','GTXN20260013',NULL,'USR_STF_02',NOW() - INTERVAL '8 day',NOW() - INTERVAL '8 day' + INTERVAL '6 minute'),
('PO_DEMO_014','PO-DEMO-2026-00014','INV_DEMO_014',1600000,'Thanh toán INV-2026-00014',NULL,'https://pay.momo.vn/pay/PO-2026-00014','GW20260014','COMPLETED',NOW() - INTERVAL '7 day' + INTERVAL '30 minute',NOW() - INTERVAL '7 day' + INTERVAL '8 minute','GTXN20260014',NULL,'USR_STF_03',NOW() - INTERVAL '7 day',NOW() - INTERVAL '7 day' + INTERVAL '8 minute'),
('PO_DEMO_015','PO-DEMO-2026-00015','INV_DEMO_015', 580000,'Thanh toán INV-2026-00015',NULL,NULL,'GW20260015','COMPLETED',NOW() - INTERVAL '6 day' + INTERVAL '30 minute',NOW() - INTERVAL '6 day' + INTERVAL '10 minute','GTXN20260015',NULL,'USR_STF_04',NOW() - INTERVAL '6 day',NOW() - INTERVAL '6 day' + INTERVAL '10 minute'),
('PO_DEMO_016','PO-DEMO-2026-00016','INV_DEMO_016', 760000,'Thanh toán INV-2026-00016',NULL,'https://pay.vnpay.vn/pay/PO-2026-00016','GW20260016','COMPLETED',NOW() - INTERVAL '5 day' + INTERVAL '30 minute',NOW() - INTERVAL '5 day' + INTERVAL '5 minute','GTXN20260016',NULL,'USR_STF_05',NOW() - INTERVAL '5 day',NOW() - INTERVAL '5 day' + INTERVAL '5 minute'),
('PO_DEMO_017','PO-DEMO-2026-00017','INV_DEMO_017', 950000,'Thanh toán INV-2026-00017',NULL,NULL,'GW20260017','COMPLETED',NOW() - INTERVAL '4 day' + INTERVAL '30 minute',NOW() - INTERVAL '4 day' + INTERVAL '14 minute','GTXN20260017',NULL,'USR_STF_01',NOW() - INTERVAL '4 day',NOW() - INTERVAL '4 day' + INTERVAL '14 minute'),
('PO_DEMO_018','PO-DEMO-2026-00018','INV_DEMO_018', 400000,'Thanh toán INV-2026-00018',NULL,NULL,'GW20260018','COMPLETED',NOW() - INTERVAL '3 day' + INTERVAL '30 minute',NOW() - INTERVAL '3 day' + INTERVAL '7 minute','GTXN20260018',NULL,'USR_STF_02',NOW() - INTERVAL '3 day',NOW() - INTERVAL '3 day' + INTERVAL '7 minute'),
('PO_DEMO_019','PO-DEMO-2026-00019','INV_DEMO_019',1180000,'Thanh toán INV-2026-00019 (sau BHYT)',NULL,'https://pay.vnpay.vn/pay/PO-2026-00019','GW20260019','COMPLETED',NOW() - INTERVAL '2 day' + INTERVAL '30 minute',NOW() - INTERVAL '2 day' + INTERVAL '6 minute','GTXN20260019',NULL,'USR_STF_03',NOW() - INTERVAL '2 day',NOW() - INTERVAL '2 day' + INTERVAL '6 minute'),
('PO_DEMO_020','PO-DEMO-2026-00020','INV_DEMO_020', 320000,'Thanh toán INV-2026-00020',NULL,NULL,'GW20260020','COMPLETED',NOW() - INTERVAL '1 day' + INTERVAL '30 minute',NOW() - INTERVAL '1 day' + INTERVAL '8 minute','GTXN20260020',NULL,'USR_STF_04',NOW() - INTERVAL '1 day',NOW() - INTERVAL '1 day' + INTERVAL '8 minute'),
-- 5 PAYMENT_ORDERS cho PARTIAL invoices (chỉ ghi nhận lần thanh toán đầu)
('PO_DEMO_021','PO-DEMO-2026-00021','INV_DEMO_021', 900000,'Đặt cọc INV-2026-00021',NULL,NULL,'GW20260021','COMPLETED',NOW() - INTERVAL '25 day' + INTERVAL '1 hour',NOW() - INTERVAL '25 day' + INTERVAL '12 minute','GTXN20260021',NULL,'USR_STF_05',NOW() - INTERVAL '25 day',NOW() - INTERVAL '25 day' + INTERVAL '12 minute'),
('PO_DEMO_022','PO-DEMO-2026-00022','INV_DEMO_022',1000000,'Trả góp INV-2026-00022 đợt 1',NULL,'https://pay.vnpay.vn/pay/PO-2026-00022','GW20260022','COMPLETED',NOW() - INTERVAL '22 day' + INTERVAL '1 hour',NOW() - INTERVAL '22 day' + INTERVAL '9 minute','GTXN20260022',NULL,'USR_STF_01',NOW() - INTERVAL '22 day',NOW() - INTERVAL '22 day' + INTERVAL '9 minute'),
('PO_DEMO_023','PO-DEMO-2026-00023','INV_DEMO_023', 500000,'Đặt cọc INV-2026-00023',NULL,NULL,'GW20260023','COMPLETED',NOW() - INTERVAL '18 day' + INTERVAL '1 hour',NOW() - INTERVAL '18 day' + INTERVAL '15 minute','GTXN20260023',NULL,'USR_STF_02',NOW() - INTERVAL '18 day',NOW() - INTERVAL '18 day' + INTERVAL '15 minute'),
('PO_DEMO_024','PO-DEMO-2026-00024','INV_DEMO_024', 800000,'Trả 50% INV-2026-00024',NULL,'https://pay.momo.vn/pay/PO-2026-00024','GW20260024','COMPLETED',NOW() - INTERVAL '12 day' + INTERVAL '1 hour',NOW() - INTERVAL '12 day' + INTERVAL '11 minute','GTXN20260024',NULL,'USR_STF_03',NOW() - INTERVAL '12 day',NOW() - INTERVAL '12 day' + INTERVAL '11 minute'),
('PO_DEMO_025','PO-DEMO-2026-00025','INV_DEMO_025', 300000,'Ứng tiền PHCN 3 buổi (INV-2026-00025)',NULL,NULL,'GW20260025','COMPLETED',NOW() - INTERVAL '6 day' + INTERVAL '1 hour',NOW() - INTERVAL '6 day' + INTERVAL '20 minute','GTXN20260025',NULL,'USR_STF_04',NOW() - INTERVAL '6 day',NOW() - INTERVAL '6 day' + INTERVAL '20 minute'),
-- 3 PAYMENT_ORDERS cho REFUNDED invoices (lúc đầu thanh toán đủ, sau mới hoàn)
('PO_DEMO_026','PO-DEMO-2026-00026','INV_DEMO_036', 500000,'Thanh toán INV-2026-00036',NULL,'https://pay.vnpay.vn/pay/PO-2026-00026','GW20260026','COMPLETED',NOW() - INTERVAL '40 day' + INTERVAL '30 minute',NOW() - INTERVAL '40 day' + INTERVAL '6 minute','GTXN20260026',NULL,'USR_STF_05',NOW() - INTERVAL '40 day',NOW() - INTERVAL '40 day' + INTERVAL '6 minute'),
('PO_DEMO_027','PO-DEMO-2026-00027','INV_DEMO_037', 850000,'Thanh toán INV-2026-00037',NULL,NULL,'GW20260027','COMPLETED',NOW() - INTERVAL '55 day' + INTERVAL '30 minute',NOW() - INTERVAL '55 day' + INTERVAL '12 minute','GTXN20260027',NULL,'USR_STF_01',NOW() - INTERVAL '55 day',NOW() - INTERVAL '55 day' + INTERVAL '12 minute'),
('PO_DEMO_028','PO-DEMO-2026-00028','INV_DEMO_038',1200000,'Thanh toán INV-2026-00038',NULL,'https://pay.momo.vn/pay/PO-2026-00028','GW20260028','COMPLETED',NOW() - INTERVAL '70 day' + INTERVAL '30 minute',NOW() - INTERVAL '70 day' + INTERVAL '7 minute','GTXN20260028',NULL,'USR_STF_02',NOW() - INTERVAL '70 day',NOW() - INTERVAL '70 day' + INTERVAL '7 minute'),
-- 2 PAYMENT_ORDERS EXPIRED/PENDING cho UNPAID invoices (QR đã tạo nhưng hết hạn)
('PO_DEMO_029','PO-DEMO-2026-00029','INV_DEMO_028', 520000,'QR thanh toán INV-2026-00028 (hết hạn)',NULL,'https://pay.vnpay.vn/pay/PO-2026-00029','GW20260029','EXPIRED',NOW() - INTERVAL '1 day' - INTERVAL '4 hour',NULL,NULL,NULL,'USR_STF_02',NOW() - INTERVAL '1 day' - INTERVAL '6 hour',NOW() - INTERVAL '1 day' - INTERVAL '4 hour'),
('PO_DEMO_030','PO-DEMO-2026-00030','INV_DEMO_034', 760000,'QR thanh toán INV-2026-00034',NULL,'https://pay.vnpay.vn/pay/PO-2026-00030','GW20260030','PENDING',NOW() + INTERVAL '1 hour',NULL,NULL,NULL,'USR_STF_03',NOW() - INTERVAL '2 hour',NOW() - INTERVAL '2 hour')
ON CONFLICT (payment_orders_id) DO NOTHING;


-- *********************************************************************
-- 4. PAYMENT_TRANSACTIONS (30 — một giao dịch per payment_order COMPLETED)
--    payment_method mix: 12 CASH, 8 VNPAY, 4 MOMO, 2 ZALOPAY, 2 INSURANCE_BHYT, 2 BANK_TRANSFER
--    status: 28 SUCCESS, 2 PENDING (tương ứng PO PENDING/EXPIRED không có txn -> bỏ qua,
--    nhưng để đủ 30 ta tạo thêm 2 PENDING txn cho 2 PO chưa SUCCESS)
-- *********************************************************************
INSERT INTO payment_transactions (
    payment_transactions_id, transaction_code, invoice_id, transaction_type,
    payment_method, amount, gateway_transaction_id, gateway_response,
    status, cashier_id, paid_at, notes, refund_reason, created_at
) VALUES
('PTX_DEMO_001','TXN20260120010001','INV_DEMO_001','PAYMENT','CASH',         850000,NULL,                NULL,'SUCCESS','USR_STF_01',NOW() - INTERVAL '20 day' + INTERVAL '10 minute','Thu tiền mặt tại quầy',NULL,NOW() - INTERVAL '20 day' + INTERVAL '10 minute'),
('PTX_DEMO_002','TXN20260121010002','INV_DEMO_002','PAYMENT','VNPAY',        700000,'VNP20260002',       '{"vnp_ResponseCode":"00","vnp_TxnRef":"VNP20260002","vnp_BankCode":"VCB"}','SUCCESS','USR_STF_01',NOW() - INTERVAL '19 day' + INTERVAL '8 minute','Thanh toán VNPay',NULL,NOW() - INTERVAL '19 day' + INTERVAL '8 minute'),
('PTX_DEMO_003','TXN20260122010003','INV_DEMO_003','PAYMENT','MOMO',        1200000,'MOMO20260003',      '{"resultCode":0,"orderId":"MOMO20260003"}','SUCCESS','USR_STF_02',NOW() - INTERVAL '18 day' + INTERVAL '5 minute','Thanh toán MoMo',NULL,NOW() - INTERVAL '18 day' + INTERVAL '5 minute'),
('PTX_DEMO_004','TXN20260123010004','INV_DEMO_004','PAYMENT','CASH',         480000,NULL,                NULL,'SUCCESS','USR_STF_02',NOW() - INTERVAL '17 day' + INTERVAL '12 minute','Thu tiền mặt',NULL,NOW() - INTERVAL '17 day' + INTERVAL '12 minute'),
('PTX_DEMO_005','TXN20260124010005','INV_DEMO_005','PAYMENT','INSURANCE_BHYT',660000,'BHYT20260005',     '{"bhyt_card":"GD4010123456789","co_pay_pct":70}','SUCCESS','USR_STF_03',NOW() - INTERVAL '16 day' + INTERVAL '7 minute','BHYT chi trả 30% + bệnh nhân nộp 70%',NULL,NOW() - INTERVAL '16 day' + INTERVAL '7 minute'),
('PTX_DEMO_006','TXN20260125010006','INV_DEMO_006','PAYMENT','CASH',         350000,NULL,                NULL,'SUCCESS','USR_STF_01',NOW() - INTERVAL '15 day' + INTERVAL '15 minute','Thu tiền mặt',NULL,NOW() - INTERVAL '15 day' + INTERVAL '15 minute'),
('PTX_DEMO_007','TXN20260126010007','INV_DEMO_007','PAYMENT','VNPAY',       2000000,'VNP20260007',       '{"vnp_ResponseCode":"00","vnp_TxnRef":"VNP20260007","vnp_BankCode":"TCB"}','SUCCESS','USR_STF_03',NOW() - INTERVAL '14 day' + INTERVAL '6 minute','Thanh toán VNPay',NULL,NOW() - INTERVAL '14 day' + INTERVAL '6 minute'),
('PTX_DEMO_008','TXN20260127010008','INV_DEMO_008','PAYMENT','CASH',         530000,NULL,                NULL,'SUCCESS','USR_STF_02',NOW() - INTERVAL '13 day' + INTERVAL '20 minute','Thu tiền mặt',NULL,NOW() - INTERVAL '13 day' + INTERVAL '20 minute'),
('PTX_DEMO_009','TXN20260128010009','INV_DEMO_009','PAYMENT','ZALOPAY',      650000,'ZLP20260009',       '{"return_code":1,"zp_trans_id":"ZLP20260009"}','SUCCESS','USR_STF_04',NOW() - INTERVAL '12 day' + INTERVAL '4 minute','Thanh toán ZaloPay',NULL,NOW() - INTERVAL '12 day' + INTERVAL '4 minute'),
('PTX_DEMO_010','TXN20260129010010','INV_DEMO_010','PAYMENT','VNPAY',       1800000,'VNP20260010',       '{"vnp_ResponseCode":"00","vnp_BankCode":"BIDV"}','SUCCESS','USR_STF_04',NOW() - INTERVAL '11 day' + INTERVAL '11 minute','Thanh toán VNPay',NULL,NOW() - INTERVAL '11 day' + INTERVAL '11 minute'),
('PTX_DEMO_011','TXN20260130010011','INV_DEMO_011','PAYMENT','CASH',         420000,NULL,                NULL,'SUCCESS','USR_STF_05',NOW() - INTERVAL '10 day' + INTERVAL '9 minute','Thu tiền mặt',NULL,NOW() - INTERVAL '10 day' + INTERVAL '9 minute'),
('PTX_DEMO_012','TXN20260131010012','INV_DEMO_012','PAYMENT','INSURANCE_BHYT',850000,'BHYT20260012',     '{"bhyt_card":"GD4010987654321","co_pay_pct":77}','SUCCESS','USR_STF_01',NOW() - INTERVAL '9 day' + INTERVAL '13 minute','BHYT chi trả + bệnh nhân nộp phần chênh',NULL,NOW() - INTERVAL '9 day' + INTERVAL '13 minute'),
('PTX_DEMO_013','TXN20260201010013','INV_DEMO_013','PAYMENT','CASH',         290000,NULL,                NULL,'SUCCESS','USR_STF_02',NOW() - INTERVAL '8 day' + INTERVAL '6 minute','Thu tiền mặt',NULL,NOW() - INTERVAL '8 day' + INTERVAL '6 minute'),
('PTX_DEMO_014','TXN20260202010014','INV_DEMO_014','PAYMENT','MOMO',        1600000,'MOMO20260014',      '{"resultCode":0,"orderId":"MOMO20260014"}','SUCCESS','USR_STF_03',NOW() - INTERVAL '7 day' + INTERVAL '8 minute','Thanh toán MoMo',NULL,NOW() - INTERVAL '7 day' + INTERVAL '8 minute'),
('PTX_DEMO_015','TXN20260203010015','INV_DEMO_015','PAYMENT','CASH',         580000,NULL,                NULL,'SUCCESS','USR_STF_04',NOW() - INTERVAL '6 day' + INTERVAL '10 minute','Thu tiền mặt',NULL,NOW() - INTERVAL '6 day' + INTERVAL '10 minute'),
('PTX_DEMO_016','TXN20260204010016','INV_DEMO_016','PAYMENT','VNPAY',        760000,'VNP20260016',       '{"vnp_ResponseCode":"00","vnp_BankCode":"VCB"}','SUCCESS','USR_STF_05',NOW() - INTERVAL '5 day' + INTERVAL '5 minute','Thanh toán VNPay',NULL,NOW() - INTERVAL '5 day' + INTERVAL '5 minute'),
('PTX_DEMO_017','TXN20260205010017','INV_DEMO_017','PAYMENT','BANK_TRANSFER',950000,'BANK20260017',      '{"bank":"VCB","accountTo":"1234567890","note":"INV-2026-00017"}','SUCCESS','USR_STF_01',NOW() - INTERVAL '4 day' + INTERVAL '14 minute','Chuyển khoản ngân hàng',NULL,NOW() - INTERVAL '4 day' + INTERVAL '14 minute'),
('PTX_DEMO_018','TXN20260206010018','INV_DEMO_018','PAYMENT','CASH',         400000,NULL,                NULL,'SUCCESS','USR_STF_02',NOW() - INTERVAL '3 day' + INTERVAL '7 minute','Thu tiền mặt',NULL,NOW() - INTERVAL '3 day' + INTERVAL '7 minute'),
('PTX_DEMO_019','TXN20260207010019','INV_DEMO_019','PAYMENT','VNPAY',       1180000,'VNP20260019',       '{"vnp_ResponseCode":"00","vnp_BankCode":"TCB"}','SUCCESS','USR_STF_03',NOW() - INTERVAL '2 day' + INTERVAL '6 minute','Thanh toán VNPay (sau BHYT)',NULL,NOW() - INTERVAL '2 day' + INTERVAL '6 minute'),
('PTX_DEMO_020','TXN20260208010020','INV_DEMO_020','PAYMENT','CASH',         320000,NULL,                NULL,'SUCCESS','USR_STF_04',NOW() - INTERVAL '1 day' + INTERVAL '8 minute','Thu tiền mặt',NULL,NOW() - INTERVAL '1 day' + INTERVAL '8 minute'),
-- PARTIAL payments
('PTX_DEMO_021','TXN20260115010021','INV_DEMO_021','PAYMENT','CASH',         900000,NULL,                NULL,'SUCCESS','USR_STF_05',NOW() - INTERVAL '25 day' + INTERVAL '12 minute','Đặt cọc tiểu phẫu (50%)',NULL,NOW() - INTERVAL '25 day' + INTERVAL '12 minute'),
('PTX_DEMO_022','TXN20260118010022','INV_DEMO_022','PAYMENT','VNPAY',       1000000,'VNP20260022',       '{"vnp_ResponseCode":"00","vnp_BankCode":"BIDV"}','SUCCESS','USR_STF_01',NOW() - INTERVAL '22 day' + INTERVAL '9 minute','Trả góp đợt 1',NULL,NOW() - INTERVAL '22 day' + INTERVAL '9 minute'),
('PTX_DEMO_023','TXN20260121010023','INV_DEMO_023','PAYMENT','CASH',         500000,NULL,                NULL,'SUCCESS','USR_STF_02',NOW() - INTERVAL '18 day' + INTERVAL '15 minute','Đặt cọc nội soi',NULL,NOW() - INTERVAL '18 day' + INTERVAL '15 minute'),
('PTX_DEMO_024','TXN20260127010024','INV_DEMO_024','PAYMENT','MOMO',         800000,'MOMO20260024',      '{"resultCode":0,"orderId":"MOMO20260024"}','SUCCESS','USR_STF_03',NOW() - INTERVAL '12 day' + INTERVAL '11 minute','Trả 50%',NULL,NOW() - INTERVAL '12 day' + INTERVAL '11 minute'),
('PTX_DEMO_025','TXN20260202010025','INV_DEMO_025','PAYMENT','CASH',         300000,NULL,                NULL,'SUCCESS','USR_STF_04',NOW() - INTERVAL '6 day' + INTERVAL '20 minute','Ứng PHCN 3 buổi',NULL,NOW() - INTERVAL '6 day' + INTERVAL '20 minute'),
-- REFUNDED original PAYMENT (sẽ được refund_requests tham chiếu)
('PTX_DEMO_026','TXN20260101010026','INV_DEMO_036','PAYMENT','VNPAY',        500000,'VNP20260026',       '{"vnp_ResponseCode":"00","vnp_BankCode":"VCB"}','REFUNDED','USR_STF_05',NOW() - INTERVAL '40 day' + INTERVAL '6 minute','Đã hoàn (huỷ trước 1h)','Hủy lịch khám phút cuối',NOW() - INTERVAL '40 day' + INTERVAL '6 minute'),
('PTX_DEMO_027','TXN20251217010027','INV_DEMO_037','PAYMENT','CASH',         850000,NULL,                NULL,'REFUNDED','USR_STF_01',NOW() - INTERVAL '55 day' + INTERVAL '12 minute','Đã hoàn 1 phần (thu nhầm CT scan)','Sai dịch vụ — không thực hiện CT scan',NOW() - INTERVAL '55 day' + INTERVAL '12 minute'),
('PTX_DEMO_028','TXN20251202010028','INV_DEMO_038','PAYMENT','MOMO',        1200000,'MOMO20260028',      '{"resultCode":0,"orderId":"MOMO20260028"}','REFUNDED','USR_STF_02',NOW() - INTERVAL '70 day' + INTERVAL '7 minute','Đã hoàn — BHYT chi trả lại','Bảo hiểm chi trả lại sau đối chiếu',NOW() - INTERVAL '70 day' + INTERVAL '7 minute'),
-- PENDING txn cho 2 invoice còn lại (chưa SUCCESS)
('PTX_DEMO_029','TXN20260218010029','INV_DEMO_028','PAYMENT','VNPAY',        520000,NULL,                NULL,'PENDING','USR_STF_02',NOW() - INTERVAL '1 day' - INTERVAL '6 hour','Chờ xác nhận từ gateway',NULL,NOW() - INTERVAL '1 day' - INTERVAL '6 hour'),
('PTX_DEMO_030','TXN20260219010030','INV_DEMO_034','PAYMENT','BANK_TRANSFER',760000,NULL,                NULL,'PENDING','USR_STF_03',NOW() - INTERVAL '2 hour','Chờ đối soát chuyển khoản',NULL,NOW() - INTERVAL '2 hour')
ON CONFLICT (payment_transactions_id) DO NOTHING;


-- *********************************************************************
-- 5. REFUND_REQUESTS (5 — cho 3 invoice REFUNDED + 2 PENDING/REJECTED)
-- *********************************************************************
INSERT INTO refund_requests (
    request_id, request_code, transaction_id, invoice_id, patient_id,
    refund_type, original_amount, refund_amount, refund_method,
    reason_category, reason_detail, evidence_urls,
    status, requested_by, requested_at,
    approved_by, approved_at, rejected_by, rejected_at, reject_reason,
    processed_by, processed_at, completed_at,
    refund_transaction_id, gateway_refund_id, notes,
    facility_id, created_at, updated_at
) VALUES
-- 1. FULL refund — huỷ trước 1h (COMPLETED)
('RR_DEMO_001','RFD-20260110-0001','PTX_DEMO_026','INV_DEMO_036','PAT_051',
 'FULL', 500000, 500000,'VNPAY',
 'SERVICE_CANCELLED','Bệnh nhân huỷ lịch khám trước giờ hẹn 90 phút theo chính sách hoàn 100%',
 '["https://cdn.ehealth.vn/refund/rr001-cancel-note.pdf"]',
 'COMPLETED','USR_STF_05',NOW() - INTERVAL '39 day',
 'USR_ADMIN_01',NOW() - INTERVAL '39 day' + INTERVAL '1 hour',NULL,NULL,NULL,
 'USR_STF_05',NOW() - INTERVAL '38 day',NOW() - INTERVAL '38 day' + INTERVAL '2 hour',
 NULL,'VNP_RFD_20260110001','Hoàn 100% qua VNPay — đã đối soát thành công',
 'FAC_EHEALTH',NOW() - INTERVAL '39 day',NOW() - INTERVAL '38 day' + INTERVAL '2 hour'),
-- 2. PARTIAL refund — thu nhầm CT scan (COMPLETED)
('RR_DEMO_002','RFD-20251220-0002','PTX_DEMO_027','INV_DEMO_037','PAT_052',
 'PARTIAL', 850000, 400000,'CASH',
 'OVERCHARGE','Thu nhầm phí CT scan ngực mà bệnh nhân không thực hiện — xác nhận qua hồ sơ điều dưỡng',
 '["https://cdn.ehealth.vn/refund/rr002-evidence.pdf","https://cdn.ehealth.vn/refund/rr002-nurse-note.jpg"]',
 'COMPLETED','USR_STF_01',NOW() - INTERVAL '54 day',
 'USR_ADMIN_01',NOW() - INTERVAL '54 day' + INTERVAL '3 hour',NULL,NULL,NULL,
 'USR_STF_01',NOW() - INTERVAL '53 day',NOW() - INTERVAL '53 day' + INTERVAL '1 hour',
 NULL,NULL,'Hoàn tiền mặt cho bệnh nhân tại quầy',
 'FAC_EHEALTH',NOW() - INTERVAL '54 day',NOW() - INTERVAL '53 day' + INTERVAL '1 hour'),
-- 3. FULL refund — BHYT chi trả lại (COMPLETED)
('RR_DEMO_003','RFD-20251205-0003','PTX_DEMO_028','INV_DEMO_038','PAT_053',
 'FULL', 1200000, 1200000,'BANK_TRANSFER',
 'INSURANCE_COVERED','Bảo hiểm chi trả lại sau khi đối chiếu hồ sơ BHYT — bệnh nhân được hoàn 100%',
 '["https://cdn.ehealth.vn/refund/rr003-bhyt-letter.pdf"]',
 'COMPLETED','USR_STF_02',NOW() - INTERVAL '69 day',
 'USR_ADMIN_01',NOW() - INTERVAL '68 day',NULL,NULL,NULL,
 'USR_STF_02',NOW() - INTERVAL '67 day',NOW() - INTERVAL '67 day' + INTERVAL '5 hour',
 NULL,'BANK_RFD_20251205003','Chuyển khoản hoàn về tài khoản bệnh nhân Vietcombank',
 'FAC_EHEALTH',NOW() - INTERVAL '69 day',NOW() - INTERVAL '67 day' + INTERVAL '5 hour'),
-- 4. PENDING refund — đang chờ duyệt
('RR_DEMO_004','RFD-20260215-0004','PTX_DEMO_007','INV_DEMO_007','PAT_022',
 'PARTIAL', 2000000, 500000,'VNPAY',
 'SERVICE_NOT_PROVIDED','Bệnh nhân yêu cầu hoàn tiền 1 hạng mục thuốc do không sử dụng — đang xác minh',
 '["https://cdn.ehealth.vn/refund/rr004-request.pdf"]',
 'PENDING','USR_STF_03',NOW() - INTERVAL '4 day',
 NULL,NULL,NULL,NULL,NULL,
 NULL,NULL,NULL,
 NULL,NULL,'Đang chờ trưởng phòng tài chính duyệt',
 'FAC_EHEALTH',NOW() - INTERVAL '4 day',NOW() - INTERVAL '4 day'),
-- 5. REJECTED refund — sai chính sách
('RR_DEMO_005','RFD-20260201-0005','PTX_DEMO_010','INV_DEMO_010','PAT_025',
 'FULL', 1800000, 1800000,'VNPAY',
 'CUSTOMER_DISSATISFIED','Bệnh nhân không hài lòng với kết quả gói khám sức khoẻ — yêu cầu hoàn 100%',
 '["https://cdn.ehealth.vn/refund/rr005-complaint.pdf"]',
 'REJECTED','USR_STF_04',NOW() - INTERVAL '8 day',
 NULL,NULL,'USR_ADMIN_01',NOW() - INTERVAL '7 day','Dịch vụ đã hoàn tất, không thuộc trường hợp hoàn theo chính sách công bố',
 NULL,NULL,NULL,
 NULL,NULL,'Từ chối — không thuộc trường hợp hoàn',
 'FAC_EHEALTH',NOW() - INTERVAL '8 day',NOW() - INTERVAL '7 day')
ON CONFLICT (request_id) DO NOTHING;

COMMIT;

-- =====================================================================
-- END 16_billing.sql
-- =====================================================================
