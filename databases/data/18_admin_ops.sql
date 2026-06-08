-- =====================================================================
-- SEED DATA: 18_admin_ops.sql
-- =====================================================================
-- Demo dữ liệu vận hành cho Admin Portal (4 bảng):
--   1. room_maintenance_schedules  (10 rows) — lịch bảo trì phòng khám
--   2. equipment_maintenance_logs  (15 rows) — nhật ký bảo trì thiết bị
--   3. cashier_shifts              (8 rows)  — ca thu ngân (14 ngày gần nhất)
--   4. ehr_health_alerts           (20 rows) — cảnh báo y tế thủ công EHR
--
-- Idempotent: ON CONFLICT DO NOTHING — có thể chạy lại nhiều lần.
-- Span: dữ liệu trải dài 60 ngày gần nhất.
--
-- Dependencies (thứ tự chạy):
--   - 01_core_roles_users.sql   (USR_ADMIN_01, USR_STF_01..05)
--   - 03_facilities.sql         (medical_rooms — ROOM_*)
--   - 07_patients.sql / demo patients (PAT_SEED_1001..1020 cho EHR alerts)
--   - 09_equipments_beds.sql    (medical_equipments — EQ_*)
--
-- Note: Schema verified against databases/structure/db_clean.sql
--   - room_maintenance_schedules:  PK maintenance_id, columns start_date/end_date/reason/created_by
--   - equipment_maintenance_logs:  PK log_id, columns maintenance_date/maintenance_type/cost/next_maintenance_date
--   - cashier_shifts:              PK cashier_shifts_id, columns shift_start/shift_end/opening_balance/system_calculated_balance/actual_closing_balance
--   - ehr_health_alerts:           PK alert_id, columns alert_type/severity/title/description/created_by/is_active
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 1. ROOM_MAINTENANCE_SCHEDULES (10 rows)
--    Mix loại: vệ sinh khử khuẩn / bảo trì định kỳ / sửa chữa
--    Span: -45 ngày .. +14 ngày so với hôm nay
-- ---------------------------------------------------------------------
INSERT INTO room_maintenance_schedules (
    maintenance_id, room_id, start_date, end_date, reason, created_by, created_at
) VALUES
('RMS_DEMO_001', 'ROOM_KB_03',     CURRENT_DATE - INTERVAL '45 days', CURRENT_DATE - INTERVAL '45 days', 'Vệ sinh khử khuẩn định kỳ phòng đo sinh hiệu (tháng 4)', 'USR_ADMIN_01', NOW() - INTERVAL '50 days'),
('RMS_DEMO_002', 'ROOM_NGOAI_03',  CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE - INTERVAL '29 days', 'Bảo trì định kỳ phòng mổ — kiểm tra hệ thống khí y tế và đèn mổ', 'USR_ADMIN_01', NOW() - INTERVAL '35 days'),
('RMS_DEMO_003', 'ROOM_ICU_01',    CURRENT_DATE - INTERVAL '21 days', CURRENT_DATE - INTERVAL '21 days', 'Vệ sinh khử khuẩn phòng hồi sức ICU sau ca xuất viện', 'USR_STF_01',   NOW() - INTERVAL '22 days'),
('RMS_DEMO_004', 'ROOM_XN_01',     CURRENT_DATE - INTERVAL '14 days', CURRENT_DATE - INTERVAL '13 days', 'Sửa chữa hệ thống thoát nước phòng xét nghiệm', 'USR_ADMIN_01', NOW() - INTERVAL '15 days'),
('RMS_DEMO_005', 'ROOM_CC_02',     CURRENT_DATE - INTERVAL '7 days',  CURRENT_DATE - INTERVAL '7 days',  'Vệ sinh sâu phòng cấp cứu — khử khuẩn tổng thể', 'USR_STF_02',   NOW() - INTERVAL '8 days'),
('RMS_DEMO_006', 'ROOM_SAN_03',    CURRENT_DATE - INTERVAL '3 days',  CURRENT_DATE - INTERVAL '3 days',  'Bảo trì giường sanh và thay drap khử khuẩn', 'USR_STF_01',   NOW() - INTERVAL '4 days'),
('RMS_DEMO_007', 'ROOM_NHI_03',    CURRENT_DATE,                       CURRENT_DATE,                       'Vệ sinh phòng tiêm chủng đầu tuần', 'USR_STF_03',   NOW() - INTERVAL '1 day'),
('RMS_DEMO_008', 'ROOM_KB_01',     CURRENT_DATE + INTERVAL '3 days',  CURRENT_DATE + INTERVAL '3 days',  'Lịch vệ sinh khử khuẩn định kỳ phòng khám tổng quát', 'USR_ADMIN_01', NOW()),
('RMS_DEMO_009', 'ROOM_NOI_02',    CURRENT_DATE + INTERVAL '7 days',  CURRENT_DATE + INTERVAL '8 days',  'Bảo trì điều hòa và sơn lại tường phòng điều trị nội trú', 'USR_ADMIN_01', NOW()),
('RMS_DEMO_010', 'ROOM_ICU_04',    CURRENT_DATE + INTERVAL '14 days', CURRENT_DATE + INTERVAL '15 days', 'Bảo trì định kỳ phòng thiết bị hồi sức — hiệu chuẩn monitor và máy thở', 'USR_ADMIN_01', NOW())
ON CONFLICT (maintenance_id) DO NOTHING;


-- ---------------------------------------------------------------------
-- 2. EQUIPMENT_MAINTENANCE_LOGS (15 rows)
--    Mix maintenance_type: SCHEDULED / EMERGENCY / CALIBRATION
--    Span: -55 ngày .. -2 ngày
-- ---------------------------------------------------------------------
INSERT INTO equipment_maintenance_logs (
    log_id, equipment_id, maintenance_date, maintenance_type, description,
    performed_by, cost, next_maintenance_date, created_at, updated_at
) VALUES
('EML_DEMO_001', 'EQ_KB_01',    CURRENT_DATE - INTERVAL '55 days', 'CALIBRATION', 'Hiệu chuẩn máy đo huyết áp Omron HEM-7156 — kiểm tra sai số ±2mmHg theo TCVN', 'KS. Nguyễn Văn Bình - Tech Service Omron', 500000,   CURRENT_DATE + INTERVAL '125 days', NOW() - INTERVAL '55 days', NOW() - INTERVAL '55 days'),
('EML_DEMO_002', 'EQ_KB_04',    CURRENT_DATE - INTERVAL '50 days', 'SCHEDULED',   'Bảo trì định kỳ máy đo SpO2 Beurer — thay pin và làm sạch cảm biến', 'NV Kỹ thuật nội bộ - Trần Văn Cường', 200000,   CURRENT_DATE + INTERVAL '130 days', NOW() - INTERVAL '50 days', NOW() - INTERVAL '50 days'),
('EML_DEMO_003', 'EQ_NOI_01',   CURRENT_DATE - INTERVAL '45 days', 'CALIBRATION', 'Hiệu chuẩn máy điện tim Nihon Kohden ECG-1350 — kiểm định 12 chuyển đạo', 'Cty TNHH Hiệu chuẩn Y tế Sài Gòn', 1500000,  CURRENT_DATE + INTERVAL '135 days', NOW() - INTERVAL '45 days', NOW() - INTERVAL '45 days'),
('EML_DEMO_004', 'EQ_NOI_02',   CURRENT_DATE - INTERVAL '40 days', 'SCHEDULED',   'Bảo trì định kỳ máy siêu âm tim Philips CX50 — vệ sinh đầu dò và update firmware', 'KS. Lê Quốc Anh - Philips Vietnam',     3000000,  CURRENT_DATE + INTERVAL '140 days', NOW() - INTERVAL '40 days', NOW() - INTERVAL '40 days'),
('EML_DEMO_005', 'EQ_NOI_03',   CURRENT_DATE - INTERVAL '35 days', 'EMERGENCY',   'Sửa khẩn cấp monitor Mindray iPM 10 — màn hình LCD chập chờn, thay cable LVDS', 'KS. Phạm Văn Đức - Mindray Service',    850000,   CURRENT_DATE + INTERVAL '90 days',  NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days'),
('EML_DEMO_006', 'EQ_NOI_05',   CURRENT_DATE - INTERVAL '30 days', 'CALIBRATION', 'Hiệu chuẩn máy bơm tiêm điện Terumo TE-SS800 — kiểm tra tốc độ và sai số liều', 'Cty Hiệu chuẩn Terumo VN',              600000,   CURRENT_DATE + INTERVAL '150 days', NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days'),
('EML_DEMO_007', 'EQ_NGOAI_01', CURRENT_DATE - INTERVAL '28 days', 'SCHEDULED',   'Bảo trì bàn mổ thủy lực OT-300 — bơm thêm dầu thủy lực, vệ sinh khớp', 'NV Kỹ thuật nội bộ - Trần Văn Cường', 400000,   CURRENT_DATE + INTERVAL '152 days', NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days'),
('EML_DEMO_008', 'EQ_NGOAI_03', CURRENT_DATE - INTERVAL '25 days', 'CALIBRATION', 'Hiệu chuẩn máy gây mê Drager Fabius Plus XL — kiểm định bộ trộn khí và áp lực', 'Drager Vietnam Service Team',           4500000,  CURRENT_DATE + INTERVAL '155 days', NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days'),
('EML_DEMO_009', 'EQ_SAN_01',   CURRENT_DATE - INTERVAL '21 days', 'SCHEDULED',   'Bảo trì máy siêu âm thai 4D Voluson E10 — vệ sinh đầu dò, gel coupling', 'KS. Võ Thị Hà - GE Healthcare',         2200000,  CURRENT_DATE + INTERVAL '159 days', NOW() - INTERVAL '21 days', NOW() - INTERVAL '21 days'),
('EML_DEMO_010', 'EQ_SAN_04',   CURRENT_DATE - INTERVAL '18 days', 'EMERGENCY',   'Sửa khẩn cấp lồng ấp Atom Dual Incu i — quạt tuần hoàn kêu to bất thường, thay quạt mới', 'KS. Đỗ Văn Khoa - Atom Service',        1200000,  CURRENT_DATE + INTERVAL '90 days',  NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days'),
('EML_DEMO_011', 'EQ_NHI_04',   CURRENT_DATE - INTERVAL '14 days', 'SCHEDULED',   'Bảo trì tủ lạnh bảo quản vaccine Haier HYC-68 — kiểm tra cảm biến nhiệt độ, gas R134a', 'KS. Trần Văn Cường - nội bộ',           350000,   CURRENT_DATE + INTERVAL '166 days', NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days'),
('EML_DEMO_012', 'EQ_NHI_03',   CURRENT_DATE - INTERVAL '10 days', 'CALIBRATION', 'Hiệu chuẩn monitor nhi khoa Mindray iMEC 10 — đảm bảo độ chính xác chỉ số SpO2/HR', 'Mindray Service Vietnam',               700000,   CURRENT_DATE + INTERVAL '170 days', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
('EML_DEMO_013', 'EQ_KB_03',    CURRENT_DATE - INTERVAL '7 days',  'SCHEDULED',   'Bảo trì cân sức khỏe điện tử Tanita BC-730 — hiệu chuẩn lại trọng lượng chuẩn', 'NV Kỹ thuật nội bộ - Phạm Văn Đức',     150000,   CURRENT_DATE + INTERVAL '83 days',  NOW() - INTERVAL '7 days',  NOW() - INTERVAL '7 days'),
('EML_DEMO_014', 'EQ_KB_02',    CURRENT_DATE - INTERVAL '5 days',  'CALIBRATION', 'Hiệu chuẩn nhiệt kế hồng ngoại Microlife NC 200 — sai số ±0.2°C theo chuẩn ASTM', 'Cty Hiệu chuẩn Y tế Sài Gòn',           250000,   CURRENT_DATE + INTERVAL '180 days', NOW() - INTERVAL '5 days',  NOW() - INTERVAL '5 days'),
('EML_DEMO_015', 'EQ_NOI_06',   CURRENT_DATE - INTERVAL '2 days',  'EMERGENCY',   'Sửa khẩn cấp máy đo đường huyết Accu-Chek Guide — không đọc được test strip lot mới', 'Roche Diagnostics Service',             320000,   CURRENT_DATE + INTERVAL '90 days',  NOW() - INTERVAL '2 days',  NOW() - INTERVAL '2 days')
ON CONFLICT (log_id) DO NOTHING;


-- ---------------------------------------------------------------------
-- 3. CASHIER_SHIFTS (8 rows)
--    Mix status: CLOSED (đã đóng ca) / OPEN (đang mở) / DISCREPANCY (lệch quỹ)
--    Span: -14 ngày .. hôm nay
--    Cashier user: USR_STF_01..05 (5 nhân viên lễ tân)
-- ---------------------------------------------------------------------
INSERT INTO cashier_shifts (
    cashier_shifts_id, cashier_id, shift_start, shift_end,
    opening_balance, system_calculated_balance, actual_closing_balance,
    status, notes
) VALUES
('CS_DEMO_001', 'USR_STF_01', NOW() - INTERVAL '14 days' - INTERVAL '8 hours', NOW() - INTERVAL '14 days', 2000000.00, 3500000.00, 3500000.00, 'CLOSED',      'Ca sáng — đối quỹ khớp, không phát sinh chênh lệch'),
('CS_DEMO_002', 'USR_STF_02', NOW() - INTERVAL '12 days' - INTERVAL '8 hours', NOW() - INTERVAL '12 days', 2000000.00, 4200000.00, 4150000.00, 'DISCREPANCY', 'Ca chiều — phát hiện chênh lệch -50,000đ, đang rà soát hóa đơn'),
('CS_DEMO_003', 'USR_STF_03', NOW() - INTERVAL '10 days' - INTERVAL '8 hours', NOW() - INTERVAL '10 days', 2000000.00, 5100000.00, 5100000.00, 'CLOSED',      'Ca sáng — lượng khách đông, hoàn tất bàn giao đầy đủ'),
('CS_DEMO_004', 'USR_STF_04', NOW() - INTERVAL '7 days'  - INTERVAL '8 hours', NOW() - INTERVAL '7 days',  2000000.00, 3850000.00, 3850000.00, 'CLOSED',      'Ca chiều — đối quỹ khớp, đã nộp két ngân hàng cuối ngày'),
('CS_DEMO_005', 'USR_STF_05', NOW() - INTERVAL '5 days'  - INTERVAL '8 hours', NOW() - INTERVAL '5 days',  2000000.00, 4750000.00, 4720000.00, 'DISCREPANCY', 'Ca chiều — lệch -30,000đ, nghi nhầm trả tiền lẻ'),
('CS_DEMO_006', 'USR_STF_01', NOW() - INTERVAL '3 days'  - INTERVAL '8 hours', NOW() - INTERVAL '3 days',  2000000.00, 4400000.00, 4400000.00, 'CLOSED',      'Ca sáng — đối quỹ khớp'),
('CS_DEMO_007', 'USR_STF_02', NOW() - INTERVAL '1 day'   - INTERVAL '8 hours', NOW() - INTERVAL '1 day',   2000000.00, 5300000.00, 5300000.00, 'CLOSED',      'Ca cuối tuần — doanh thu cao, bàn giao đầy đủ'),
('CS_DEMO_008', 'USR_STF_03', NOW() - INTERVAL '2 hours',                       NULL,                       2000000.00, 1250000.00, NULL,       'OPEN',        'Ca đang mở — chưa kết thúc ca')
ON CONFLICT (cashier_shifts_id) DO NOTHING;


-- ---------------------------------------------------------------------
-- 4. EHR_HEALTH_ALERTS (20 rows)
--    Mix alert_type: MANUAL_NOTE / DRUG_WARNING / CONDITION_NOTE
--    Mix severity:   INFO / WARNING / CRITICAL
--    Span: -45 ngày .. -1 ngày
--    Patient FK: PAT_SEED_1001..1020 (theo convention demo seed hiện hữu)
-- ---------------------------------------------------------------------
INSERT INTO ehr_health_alerts (
    alert_id, patient_id, alert_type, severity, title, description,
    created_by, is_active, created_at, updated_at
) VALUES
('EHA_DEMO_001', 'PAT_SEED_1001', 'CONDITION_NOTE', 'WARNING',  'Huyết áp tăng bất thường',           'Huyết áp đo lần gần nhất 152/98 mmHg, vượt ngưỡng. Khuyến cáo tái khám trong 7 ngày.',                  'USR_DOC_01', TRUE,  NOW() - INTERVAL '45 days', NOW() - INTERVAL '45 days'),
('EHA_DEMO_002', 'PAT_SEED_1002', 'DRUG_WARNING',   'CRITICAL', 'Dị ứng Penicillin',                  'Bệnh nhân có tiền sử dị ứng nặng với nhóm Penicillin (nổi mề đay toàn thân năm 2022). KHÔNG kê đơn.', 'USR_DOC_02', TRUE,  NOW() - INTERVAL '40 days', NOW() - INTERVAL '40 days'),
('EHA_DEMO_003', 'PAT_SEED_1003', 'CONDITION_NOTE', 'INFO',     'Tiền sử tiểu đường type 2',         'Bệnh nhân được chẩn đoán đái tháo đường type 2 từ năm 2021, đang dùng Metformin 500mg x 2/ngày.',     'USR_DOC_03', TRUE,  NOW() - INTERVAL '38 days', NOW() - INTERVAL '38 days'),
('EHA_DEMO_004', 'PAT_SEED_1004', 'MANUAL_NOTE',    'INFO',     'Lưu ý lịch tái khám',                'Bệnh nhân cần tái khám định kỳ mỗi 3 tháng để theo dõi chức năng gan sau điều trị viêm gan B.',         'USR_DOC_04', TRUE,  NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days'),
('EHA_DEMO_005', 'PAT_SEED_1005', 'CONDITION_NOTE', 'CRITICAL', 'Tiền sử nhồi máu cơ tim',           'Nhồi máu cơ tim trước vách năm 2023, đã đặt stent LAD. Đang dùng Aspirin + Clopidogrel.',              'USR_DOC_05', TRUE,  NOW() - INTERVAL '32 days', NOW() - INTERVAL '32 days'),
('EHA_DEMO_006', 'PAT_SEED_1006', 'DRUG_WARNING',   'WARNING',  'Tương tác Warfarin – NSAID',         'Bệnh nhân đang dùng Warfarin chống đông. Tránh kê NSAID (Ibuprofen, Diclofenac) — nguy cơ xuất huyết.', 'USR_DOC_06', TRUE,  NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days'),
('EHA_DEMO_007', 'PAT_SEED_1007', 'CONDITION_NOTE', 'WARNING',  'Suy thận mạn giai đoạn 3',           'eGFR 42 mL/min/1.73m². Điều chỉnh liều thuốc thải qua thận.',                                            'USR_DOC_07', TRUE,  NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days'),
('EHA_DEMO_008', 'PAT_SEED_1008', 'MANUAL_NOTE',    'INFO',     'Bệnh nhân hay quên uống thuốc',     'Người nhà cho biết bệnh nhân hay bỏ liều thuốc huyết áp. Cần tư vấn tuân thủ điều trị.',                'USR_DOC_08', TRUE,  NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days'),
('EHA_DEMO_009', 'PAT_SEED_1009', 'DRUG_WARNING',   'CRITICAL', 'Dị ứng Sulfa (Cotrim)',              'Phản ứng phản vệ với Cotrimoxazol năm 2020. Tránh tuyệt đối nhóm Sulfonamide.',                          'USR_DOC_09', TRUE,  NOW() - INTERVAL '22 days', NOW() - INTERVAL '22 days'),
('EHA_DEMO_010', 'PAT_SEED_1010', 'CONDITION_NOTE', 'WARNING',  'Đường huyết khó kiểm soát',          'HbA1c gần nhất 9.2%, vẫn cao dù dùng đủ thuốc. Cân nhắc thêm insulin nền.',                              'USR_DOC_10', TRUE,  NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days'),
('EHA_DEMO_011', 'PAT_SEED_1011', 'MANUAL_NOTE',    'INFO',     'Yêu cầu phòng riêng khi nhập viện', 'Bệnh nhân và gia đình yêu cầu phòng riêng có máy lạnh khi cần nhập viện. Ghi chú khi xếp giường.',     'USR_STF_01', TRUE,  NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days'),
('EHA_DEMO_012', 'PAT_SEED_1012', 'CONDITION_NOTE', 'CRITICAL', 'Hen phế quản nặng',                  'Tiền sử nhập cấp cứu 3 lần năm 2024 vì cơn hen cấp. Luôn mang theo Salbutamol xịt.',                    'USR_DOC_01', TRUE,  NOW() - INTERVAL '16 days', NOW() - INTERVAL '16 days'),
('EHA_DEMO_013', 'PAT_SEED_1013', 'DRUG_WARNING',   'WARNING',  'Suy giảm chức năng gan',             'ALT/AST tăng nhẹ kéo dài. Tránh Paracetamol liều cao và Statin.',                                        'USR_DOC_02', TRUE,  NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days'),
('EHA_DEMO_014', 'PAT_SEED_1014', 'CONDITION_NOTE', 'INFO',     'Đang mang thai 24 tuần',             'Thai kỳ 24 tuần, theo dõi định kỳ tại Khoa Sản. Lưu ý chống chỉ định thuốc nhóm B/X.',                  'USR_DOC_06', TRUE,  NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days'),
('EHA_DEMO_015', 'PAT_SEED_1015', 'MANUAL_NOTE',    'INFO',     'Bệnh nhân khiếm thính',              'Bệnh nhân khiếm thính bên trái, giao tiếp ưu tiên đứng phía phải. Có thể cần phiên dịch viên ký hiệu.',  'USR_STF_02', TRUE,  NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
('EHA_DEMO_016', 'PAT_SEED_1016', 'CONDITION_NOTE', 'WARNING',  'Rung nhĩ kịch phát',                 'EKG ghi nhận rung nhĩ không đều. Đang dùng Apixaban 5mg x 2/ngày chống đông.',                          'USR_DOC_05', TRUE,  NOW() - INTERVAL '8 days',  NOW() - INTERVAL '8 days'),
('EHA_DEMO_017', 'PAT_SEED_1017', 'DRUG_WARNING',   'CRITICAL', 'Dị ứng Cephalosporin chéo',          'Phản ứng phản vệ với Ceftriaxone tháng 3/2025. Tránh nhóm beta-lactam (kể cả Penicillin).',             'USR_DOC_03', TRUE,  NOW() - INTERVAL '6 days',  NOW() - INTERVAL '6 days'),
('EHA_DEMO_018', 'PAT_SEED_1018', 'CONDITION_NOTE', 'INFO',     'Tăng cholesterol máu',               'LDL-C 168 mg/dL. Khuyến cáo điều chỉnh chế độ ăn và xem xét Statin liều thấp.',                          'USR_DOC_07', TRUE,  NOW() - INTERVAL '5 days',  NOW() - INTERVAL '5 days'),
('EHA_DEMO_019', 'PAT_SEED_1019', 'MANUAL_NOTE',    'WARNING',  'Tiền sử trầm cảm',                   'Bệnh nhân từng có ý định tự sát năm 2023, đang theo dõi tâm lý ngoại trú. Tiếp cận cẩn trọng.',          'USR_DOC_09', TRUE,  NOW() - INTERVAL '3 days',  NOW() - INTERVAL '3 days'),
('EHA_DEMO_020', 'PAT_SEED_1020', 'DRUG_WARNING',   'WARNING',  'Suy thận — chỉnh liều kháng sinh',   'Creatinine 1.8 mg/dL (CrCl ~45). Cần điều chỉnh liều kháng sinh thải qua thận (Vancomycin, Aminoglycoside).', 'USR_DOC_10', TRUE,  NOW() - INTERVAL '1 day',   NOW() - INTERVAL '1 day')
ON CONFLICT (alert_id) DO NOTHING;


COMMIT;

-- =====================================================================
-- POST-SEED COUNTS (để verify nhanh)
-- =====================================================================
SELECT '=== POST-SEED COUNTS (18_admin_ops) ===' AS info;
SELECT 'room_maintenance_schedules' AS table_name, COUNT(*) AS row_count FROM room_maintenance_schedules WHERE maintenance_id LIKE 'RMS_DEMO_%'
UNION ALL
SELECT 'equipment_maintenance_logs',                COUNT(*)             FROM equipment_maintenance_logs WHERE log_id LIKE 'EML_DEMO_%'
UNION ALL
SELECT 'cashier_shifts',                            COUNT(*)             FROM cashier_shifts             WHERE cashier_shifts_id LIKE 'CS_DEMO_%'
UNION ALL
SELECT 'ehr_health_alerts',                         COUNT(*)             FROM ehr_health_alerts          WHERE alert_id LIKE 'EHA_DEMO_%';
