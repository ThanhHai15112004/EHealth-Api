-- =====================================================================
-- 20_pharmacist_dispense_today.sql
-- =====================================================================
-- Demo data ngày 2026-05-19 — Portal Dược sĩ
-- ~25 drug_dispense_orders + ~80 drug_dispense_details + 5 tele_prescriptions bổ sung
--
-- Cung cấp dữ liệu đầy đủ cho dược sĩ hôm nay:
--   * 8 PENDING   — đang chờ cấp phát (queue dược sĩ)
--   * 5 PROCESSING/READY — đang chuẩn bị thuốc
--   * 10 COMPLETED — đã cấp phát xong hôm nay
--   * 2 CANCELLED  — đã hủy
-- Phân bổ đều giữa 3 dược sĩ USR_PHA_01/02/03.
--
-- Idempotent: mọi INSERT đều kèm ON CONFLICT DO NOTHING.
-- Dependencies:
--   * 01_core_roles_users.sql           → USR_PHA_01..03 (dược sĩ), USR_DOC_01..10
--   * 01b_patient_users.sql + 07_patients.sql → PAT_026..045
--   * 08_pharmacy.sql                   → DRG_001..120, PINV_0001..0160
--   * 11_tele_demo_seed.sql             → PRS_TELE_001..003, TC_DEMO_001..003
--   * 13_appointments_encounters.sql    → ENC_DEMO_011..030
--   * structure/migrations/dispensing_management.sql → dispense_code/notes/cancelled_*
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 1. PRESCRIPTIONS — 25 đơn thuốc mới cho dược sĩ xử lý hôm nay
--    RX_SEED_0005..0029 (RX_SEED_0001..0004 đã có ở 12_demo_seed_admin_portal)
--    Link tới các encounter COMPLETED ENC_DEMO_011..030
-- ---------------------------------------------------------------------
INSERT INTO prescriptions
    (prescriptions_id, prescription_code, encounter_id, doctor_id, patient_id,
     status, clinical_diagnosis, doctor_notes, prescribed_at)
VALUES
('RX_SEED_0005', 'RX-2026-0005', 'ENC_DEMO_011', 'USR_DOC_06', 'PAT_026',
 'PRESCRIBED', 'Viêm dạ dày cấp',                    'Uống thuốc sau ăn',                '2026-05-19 07:15:00'),
('RX_SEED_0006', 'RX-2026-0006', 'ENC_DEMO_012', 'USR_DOC_07', 'PAT_027',
 'PRESCRIBED', 'Tăng huyết áp giai đoạn 1',          'Tái khám sau 1 tháng',             '2026-05-19 07:30:00'),
('RX_SEED_0007', 'RX-2026-0007', 'ENC_DEMO_013', 'USR_DOC_08', 'PAT_028',
 'PRESCRIBED', 'Đái tháo đường type 2 - kiểm soát kém','Theo dõi đường huyết',            '2026-05-19 07:45:00'),
('RX_SEED_0008', 'RX-2026-0008', 'ENC_DEMO_014', 'USR_DOC_09', 'PAT_029',
 'PRESCRIBED', 'Cảm cúm thông thường',               'Nghỉ ngơi đầy đủ',                 '2026-05-19 08:00:00'),
('RX_SEED_0009', 'RX-2026-0009', 'ENC_DEMO_015', 'USR_DOC_10', 'PAT_030',
 'PRESCRIBED', 'Viêm họng cấp',                      'Uống nhiều nước ấm',               '2026-05-19 08:15:00'),
('RX_SEED_0010', 'RX-2026-0010', 'ENC_DEMO_016', 'USR_DOC_01', 'PAT_031',
 'PRESCRIBED', 'Đau lưng mạn tính',                  'Tránh mang vác nặng',              '2026-05-19 08:30:00'),
('RX_SEED_0011', 'RX-2026-0011', 'ENC_DEMO_017', 'USR_DOC_02', 'PAT_032',
 'PRESCRIBED', 'Rối loạn lo âu',                     'Tái khám sau 2 tuần',              '2026-05-19 08:45:00'),
('RX_SEED_0012', 'RX-2026-0012', 'ENC_DEMO_018', 'USR_DOC_03', 'PAT_033',
 'PRESCRIBED', 'Hen phế quản',                       'Mang thuốc xịt theo người',         '2026-05-19 09:00:00'),
('RX_SEED_0013', 'RX-2026-0013', 'ENC_DEMO_019', 'USR_DOC_04', 'PAT_034',
 'PRESCRIBED', 'Viêm khớp dạng thấp',                'Hạn chế vận động khớp đau',        '2026-05-19 09:15:00'),
('RX_SEED_0014', 'RX-2026-0014', 'ENC_DEMO_020', 'USR_DOC_05', 'PAT_035',
 'PRESCRIBED', 'Viêm phế quản cấp',                  'Hạn chế tiếp xúc khói bụi',        '2026-05-19 09:30:00'),
('RX_SEED_0015', 'RX-2026-0015', 'ENC_DEMO_021', 'USR_DOC_06', 'PAT_036',
 'PRESCRIBED', 'Loét dạ dày tá tràng',               'Tránh đồ cay nóng',                '2026-05-19 09:45:00'),
('RX_SEED_0016', 'RX-2026-0016', 'ENC_DEMO_022', 'USR_DOC_07', 'PAT_037',
 'PRESCRIBED', 'Rối loạn lipid máu',                 'Kiêng mỡ động vật',                '2026-05-19 10:00:00'),
('RX_SEED_0017', 'RX-2026-0017', 'ENC_DEMO_023', 'USR_DOC_08', 'PAT_038',
 'PRESCRIBED', 'Đau nửa đầu Migraine',               'Tránh stress, ngủ đủ giấc',        '2026-05-19 10:15:00'),
('RX_SEED_0018', 'RX-2026-0018', 'ENC_DEMO_024', 'USR_DOC_09', 'PAT_039',
 'PRESCRIBED', 'Nhiễm trùng tiết niệu',              'Uống nhiều nước',                  '2026-05-19 10:30:00'),
('RX_SEED_0019', 'RX-2026-0019', 'ENC_DEMO_025', 'USR_DOC_10', 'PAT_040',
 'PRESCRIBED', 'Viêm xoang mạn tính',                'Rửa mũi bằng nước muối',           '2026-05-19 10:45:00'),
('RX_SEED_0020', 'RX-2026-0020', 'ENC_DEMO_026', 'USR_DOC_01', 'PAT_041',
 'PRESCRIBED', 'Suy giáp',                           'Uống thuốc trước ăn sáng 30ph',    '2026-05-19 11:00:00'),
('RX_SEED_0021', 'RX-2026-0021', 'ENC_DEMO_027', 'USR_DOC_02', 'PAT_042',
 'PRESCRIBED', 'Trào ngược dạ dày thực quản',        'Không nằm sau ăn 2 giờ',           '2026-05-19 11:15:00'),
('RX_SEED_0022', 'RX-2026-0022', 'ENC_DEMO_028', 'USR_DOC_03', 'PAT_043',
 'PRESCRIBED', 'Viêm da dị ứng',                     'Tránh tác nhân kích thích',        '2026-05-19 11:30:00'),
('RX_SEED_0023', 'RX-2026-0023', 'ENC_DEMO_029', 'USR_DOC_04', 'PAT_044',
 'PRESCRIBED', 'Bệnh phổi tắc nghẽn mạn tính',       'Bỏ thuốc lá hoàn toàn',            '2026-05-19 11:45:00'),
('RX_SEED_0024', 'RX-2026-0024', 'ENC_DEMO_030', 'USR_DOC_05', 'PAT_045',
 'PRESCRIBED', 'Đau khớp gối',                       'Chườm ấm khi đau',                 '2026-05-19 12:00:00'),
('RX_SEED_0025', 'RX-2026-0025', 'ENC_DEMO_011', 'USR_DOC_06', 'PAT_026',
 'PRESCRIBED', 'Bổ sung canxi & vitamin D',          'Uống sau ăn sáng',                 '2026-05-19 12:30:00'),
('RX_SEED_0026', 'RX-2026-0026', 'ENC_DEMO_012', 'USR_DOC_07', 'PAT_027',
 'PRESCRIBED', 'Mất ngủ mạn tính',                   'Tránh caffeine sau 16h',           '2026-05-19 13:00:00'),
('RX_SEED_0027', 'RX-2026-0027', 'ENC_DEMO_013', 'USR_DOC_08', 'PAT_028',
 'PRESCRIBED', 'Thiếu máu thiếu sắt',                'Uống với vitamin C',               '2026-05-19 13:30:00'),
('RX_SEED_0028', 'RX-2026-0028', 'ENC_DEMO_014', 'USR_DOC_09', 'PAT_029',
 'PRESCRIBED', 'Đau thần kinh toạ',                  'Vật lý trị liệu kết hợp',          '2026-05-19 14:00:00'),
('RX_SEED_0029', 'RX-2026-0029', 'ENC_DEMO_015', 'USR_DOC_10', 'PAT_030',
 'CANCELLED',  'Viêm tai giữa - đã hủy do dị ứng',   'Đổi phác đồ kháng sinh khác',      '2026-05-19 06:30:00')
ON CONFLICT (prescriptions_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 2. PRESCRIPTION_DETAILS — chi tiết thuốc trong mỗi đơn (2-3 thuốc/đơn)
--    Pattern PRSD_S05_1, PRSD_S05_2... tương ứng RX_SEED_0005
--    Mỗi detail dùng drug_id valid (DRG_001..120) — chọn theo chẩn đoán
-- ---------------------------------------------------------------------
INSERT INTO prescription_details
    (prescription_details_id, prescription_id, drug_id, quantity, dosage, frequency,
     duration_days, usage_instruction, route_of_administration)
VALUES
-- RX_SEED_0005 — Viêm dạ dày cấp
('PRSD_S05_1', 'RX_SEED_0005', 'DRG_001', 14, '500mg', '2 lần/ngày', 7, 'Uống sau ăn',                          'ORAL'),
('PRSD_S05_2', 'RX_SEED_0005', 'DRG_002', 14, '20mg',  '1 lần/ngày', 7, 'Uống trước ăn sáng 30 phút',           'ORAL'),
('PRSD_S05_3', 'RX_SEED_0005', 'DRG_005', 14, '40mg',  '2 lần/ngày', 7, 'Uống sau ăn',                          'ORAL'),
-- RX_SEED_0006 — Tăng huyết áp
('PRSD_S06_1', 'RX_SEED_0006', 'DRG_002', 30, '5mg',   '1 lần/ngày', 30, 'Uống sáng cùng giờ mỗi ngày',         'ORAL'),
('PRSD_S06_2', 'RX_SEED_0006', 'DRG_003', 30, '10mg',  '1 lần/ngày', 30, 'Uống tối trước khi ngủ',              'ORAL'),
-- RX_SEED_0007 — Đái tháo đường type 2
('PRSD_S07_1', 'RX_SEED_0007', 'DRG_004', 60, '500mg', '2 lần/ngày', 30, 'Uống sau ăn sáng và tối',             'ORAL'),
('PRSD_S07_2', 'RX_SEED_0007', 'DRG_005', 30, '50mg',  '1 lần/ngày', 30, 'Uống trước ăn sáng',                  'ORAL'),
('PRSD_S07_3', 'RX_SEED_0007', 'DRG_007', 30, '10mg',  '1 lần/ngày', 30, 'Uống tối',                            'ORAL'),
-- RX_SEED_0008 — Cảm cúm
('PRSD_S08_1', 'RX_SEED_0008', 'DRG_001', 10, '500mg', '3 lần/ngày', 5, 'Uống khi sốt >38.5°C',                 'ORAL'),
('PRSD_S08_2', 'RX_SEED_0008', 'DRG_006', 10, '10mg',  '1 lần/ngày', 5, 'Uống tối',                             'ORAL'),
-- RX_SEED_0009 — Viêm họng
('PRSD_S09_1', 'RX_SEED_0009', 'DRG_008', 14, '500mg', '2 lần/ngày', 7, 'Uống sau ăn',                          'ORAL'),
('PRSD_S09_2', 'RX_SEED_0009', 'DRG_009', 10, '200mg', '2 lần/ngày', 5, 'Uống sau ăn',                          'ORAL'),
('PRSD_S09_3', 'RX_SEED_0009', 'DRG_001', 10, '500mg', '2 lần/ngày', 5, 'Uống khi đau',                         'ORAL'),
-- RX_SEED_0010 — Đau lưng mạn
('PRSD_S10_1', 'RX_SEED_0010', 'DRG_010', 20, '75mg',  '2 lần/ngày', 10, 'Uống sau ăn',                         'ORAL'),
('PRSD_S10_2', 'RX_SEED_0010', 'DRG_011', 20, '4mg',   '2 lần/ngày', 10, 'Uống sau ăn, tránh lái xe',           'ORAL'),
-- RX_SEED_0011 — Rối loạn lo âu
('PRSD_S11_1', 'RX_SEED_0011', 'DRG_012', 30, '0.5mg', '2 lần/ngày', 15, 'Uống sáng và tối',                    'ORAL'),
('PRSD_S11_2', 'RX_SEED_0011', 'DRG_013', 30, '50mg',  '1 lần/ngày', 30, 'Uống sáng',                           'ORAL'),
-- RX_SEED_0012 — Hen phế quản
('PRSD_S12_1', 'RX_SEED_0012', 'DRG_014', 1,  '200mcg/liều', 'Khi khó thở', 30, 'Xịt 1-2 nhát khi lên cơn',     'INHALATION'),
('PRSD_S12_2', 'RX_SEED_0012', 'DRG_015', 30, '10mg',  '1 lần/ngày', 30, 'Uống tối trước ngủ',                  'ORAL'),
-- RX_SEED_0013 — Viêm khớp dạng thấp
('PRSD_S13_1', 'RX_SEED_0013', 'DRG_010', 30, '50mg',  '3 lần/ngày', 10, 'Uống sau ăn',                         'ORAL'),
('PRSD_S13_2', 'RX_SEED_0013', 'DRG_016', 30, '7.5mg', '1 lần/tuần', 30, 'Uống tối thứ Bảy',                    'ORAL'),
('PRSD_S13_3', 'RX_SEED_0013', 'DRG_017', 30, '5mg',   '1 lần/ngày', 30, 'Uống sáng',                           'ORAL'),
-- RX_SEED_0014 — Viêm phế quản cấp
('PRSD_S14_1', 'RX_SEED_0014', 'DRG_008', 14, '500mg', '2 lần/ngày', 7, 'Uống sau ăn',                          'ORAL'),
('PRSD_S14_2', 'RX_SEED_0014', 'DRG_018', 7,  '30mg',  '3 lần/ngày', 7, 'Uống sau ăn',                          'ORAL'),
-- RX_SEED_0015 — Loét dạ dày tá tràng
('PRSD_S15_1', 'RX_SEED_0015', 'DRG_002', 30, '20mg',  '2 lần/ngày', 14, 'Uống trước ăn 30 phút',               'ORAL'),
('PRSD_S15_2', 'RX_SEED_0015', 'DRG_005', 30, '40mg',  '2 lần/ngày', 14, 'Uống sau ăn',                         'ORAL'),
('PRSD_S15_3', 'RX_SEED_0015', 'DRG_019', 21, '1g',    '3 lần/ngày', 7, 'Uống sau ăn',                          'ORAL'),
-- RX_SEED_0016 — Rối loạn lipid máu
('PRSD_S16_1', 'RX_SEED_0016', 'DRG_020', 30, '20mg',  '1 lần/ngày', 30, 'Uống tối trước ngủ',                  'ORAL'),
('PRSD_S16_2', 'RX_SEED_0016', 'DRG_021', 30, '10mg',  '1 lần/ngày', 30, 'Uống cùng bữa ăn chính',              'ORAL'),
-- RX_SEED_0017 — Đau nửa đầu Migraine
('PRSD_S17_1', 'RX_SEED_0017', 'DRG_022', 6,  '50mg',  'Khi đau',    30, 'Uống ngay khi có dấu hiệu',           'ORAL'),
('PRSD_S17_2', 'RX_SEED_0017', 'DRG_001', 10, '500mg', '2 lần/ngày', 5, 'Uống khi đau',                         'ORAL'),
('PRSD_S17_3', 'RX_SEED_0017', 'DRG_011', 10, '4mg',   '1 lần/ngày', 10, 'Uống tối',                            'ORAL'),
-- RX_SEED_0018 — Nhiễm trùng tiết niệu
('PRSD_S18_1', 'RX_SEED_0018', 'DRG_023', 14, '500mg', '2 lần/ngày', 7, 'Uống sau ăn, uống nhiều nước',         'ORAL'),
('PRSD_S18_2', 'RX_SEED_0018', 'DRG_024', 14, '100mg', '2 lần/ngày', 7, 'Uống sau ăn',                          'ORAL'),
-- RX_SEED_0019 — Viêm xoang
('PRSD_S19_1', 'RX_SEED_0019', 'DRG_008', 14, '500mg', '2 lần/ngày', 7, 'Uống sau ăn',                          'ORAL'),
('PRSD_S19_2', 'RX_SEED_0019', 'DRG_025', 10, '60mg',  '2 lần/ngày', 5, 'Uống sau ăn',                          'ORAL'),
('PRSD_S19_3', 'RX_SEED_0019', 'DRG_026', 1,  '50mcg/liều', '2 lần/ngày', 30, 'Xịt mỗi mũi 2 nhát',             'NASAL'),
-- RX_SEED_0020 — Suy giáp
('PRSD_S20_1', 'RX_SEED_0020', 'DRG_027', 30, '50mcg', '1 lần/ngày', 30, 'Uống trước ăn sáng 30 phút',          'ORAL'),
-- RX_SEED_0021 — GERD
('PRSD_S21_1', 'RX_SEED_0021', 'DRG_002', 30, '40mg',  '1 lần/ngày', 30, 'Uống trước ăn sáng',                  'ORAL'),
('PRSD_S21_2', 'RX_SEED_0021', 'DRG_028', 30, '10mg',  '3 lần/ngày', 14, 'Uống trước ăn 15 phút',               'ORAL'),
-- RX_SEED_0022 — Viêm da dị ứng
('PRSD_S22_1', 'RX_SEED_0022', 'DRG_006', 14, '10mg',  '1 lần/ngày', 14, 'Uống tối',                            'ORAL'),
('PRSD_S22_2', 'RX_SEED_0022', 'DRG_029', 1,  '0.1%',  '2 lần/ngày', 14, 'Bôi lớp mỏng lên vùng da tổn thương', 'TOPICAL'),
('PRSD_S22_3', 'RX_SEED_0022', 'DRG_030', 1,  'Kem',   '2 lần/ngày', 30, 'Dưỡng ẩm sau khi tắm',                'TOPICAL'),
-- RX_SEED_0023 — COPD
('PRSD_S23_1', 'RX_SEED_0023', 'DRG_014', 1,  '200mcg/liều', '2 lần/ngày', 30, 'Xịt 2 nhát buổi sáng và tối',   'INHALATION'),
('PRSD_S23_2', 'RX_SEED_0023', 'DRG_031', 30, '300mg', '2 lần/ngày', 30, 'Uống sau ăn',                         'ORAL'),
-- RX_SEED_0024 — Đau khớp gối
('PRSD_S24_1', 'RX_SEED_0024', 'DRG_010', 20, '75mg',  '2 lần/ngày', 10, 'Uống sau ăn',                         'ORAL'),
('PRSD_S24_2', 'RX_SEED_0024', 'DRG_032', 30, '1500mg','1 lần/ngày', 30, 'Uống cùng bữa ăn',                    'ORAL'),
-- RX_SEED_0025 — Bổ sung canxi & vitamin D
('PRSD_S25_1', 'RX_SEED_0025', 'DRG_033', 60, '500mg', '2 lần/ngày', 30, 'Uống sau ăn sáng và tối',             'ORAL'),
('PRSD_S25_2', 'RX_SEED_0025', 'DRG_034', 30, '1000IU','1 lần/ngày', 30, 'Uống sau ăn sáng',                    'ORAL'),
-- RX_SEED_0026 — Mất ngủ
('PRSD_S26_1', 'RX_SEED_0026', 'DRG_012', 15, '0.25mg','Trước ngủ',  15, 'Uống 30 phút trước khi ngủ',          'ORAL'),
('PRSD_S26_2', 'RX_SEED_0026', 'DRG_013', 30, '25mg',  '1 lần/ngày', 30, 'Uống tối',                            'ORAL'),
-- RX_SEED_0027 — Thiếu máu thiếu sắt
('PRSD_S27_1', 'RX_SEED_0027', 'DRG_035', 30, '60mg',  '1 lần/ngày', 30, 'Uống cùng vitamin C, tránh sữa',      'ORAL'),
('PRSD_S27_2', 'RX_SEED_0027', 'DRG_036', 30, '5mg',   '1 lần/ngày', 30, 'Uống sáng',                           'ORAL'),
-- RX_SEED_0028 — Đau thần kinh toạ
('PRSD_S28_1', 'RX_SEED_0028', 'DRG_010', 20, '75mg',  '2 lần/ngày', 10, 'Uống sau ăn',                         'ORAL'),
('PRSD_S28_2', 'RX_SEED_0028', 'DRG_037', 30, '300mg', '3 lần/ngày', 10, 'Tăng liều từ từ',                     'ORAL'),
('PRSD_S28_3', 'RX_SEED_0028', 'DRG_038', 20, '5mg',   '2 lần/ngày', 10, 'Uống khi co cứng cơ',                 'ORAL'),
-- RX_SEED_0029 — CANCELLED (vẫn lưu detail để giữ lịch sử)
('PRSD_S29_1', 'RX_SEED_0029', 'DRG_008', 14, '500mg', '2 lần/ngày', 7, 'Đã hủy do dị ứng amoxicillin',         'ORAL')
ON CONFLICT (prescription_details_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 3. DRUG_DISPENSE_ORDERS — 25 phiếu cấp phát cho ngày 2026-05-19
--    Phân bổ trạng thái:
--      8 PENDING    (DSO_T19_001..008)
--      5 PROCESSING (DSO_T19_009..013)
--     10 COMPLETED  (DSO_T19_014..023) — 7 RX_SEED + 3 PRS_TELE
--      2 CANCELLED  (DSO_T19_024..025)
--    Phân bổ pharmacist USR_PHA_01/02/03 đều nhau.
-- ---------------------------------------------------------------------
INSERT INTO drug_dispense_orders
    (drug_dispense_orders_id, prescription_id, pharmacist_id, status,
     dispensed_at, dispense_code, notes, cancelled_at, cancelled_reason)
VALUES
-- ---- 8 PENDING (queue cấp phát hôm nay) ----
('DSO_T19_001', 'RX_SEED_0005', 'USR_PHA_01', 'PENDING',
 '2026-05-19 07:30:00', 'DSP-T19-001', 'Chờ kiểm BHYT', NULL, NULL),
('DSO_T19_002', 'RX_SEED_0006', 'USR_PHA_02', 'PENDING',
 '2026-05-19 07:45:00', 'DSP-T19-002', 'Chờ xác nhận liều dùng', NULL, NULL),
('DSO_T19_003', 'RX_SEED_0007', 'USR_PHA_03', 'PENDING',
 '2026-05-19 08:00:00', 'DSP-T19-003', 'Chờ kiểm tra tồn kho', NULL, NULL),
('DSO_T19_004', 'RX_SEED_0008', 'USR_PHA_01', 'PENDING',
 '2026-05-19 08:15:00', 'DSP-T19-004', 'Bệnh nhân đang chờ quầy 1', NULL, NULL),
('DSO_T19_005', 'RX_SEED_0009', 'USR_PHA_02', 'PENDING',
 '2026-05-19 08:30:00', 'DSP-T19-005', 'Bệnh nhân nhi - kiểm liều kỹ', NULL, NULL),
('DSO_T19_006', 'RX_SEED_0010', 'USR_PHA_03', 'PENDING',
 '2026-05-19 08:45:00', 'DSP-T19-006', NULL, NULL, NULL),
('DSO_T19_007', 'RX_SEED_0011', 'USR_PHA_01', 'PENDING',
 '2026-05-19 09:00:00', 'DSP-T19-007', 'Cần đối chiếu thuốc hướng thần', NULL, NULL),
('DSO_T19_008', 'RX_SEED_0012', 'USR_PHA_02', 'PENDING',
 '2026-05-19 09:15:00', 'DSP-T19-008', 'Hướng dẫn sử dụng bình xịt', NULL, NULL),
-- ---- 5 PROCESSING (đang chuẩn bị thuốc) ----
('DSO_T19_009', 'RX_SEED_0013', 'USR_PHA_03', 'PROCESSING',
 '2026-05-19 09:30:00', 'DSP-T19-009', 'Đang lấy thuốc từ kho', NULL, NULL),
('DSO_T19_010', 'RX_SEED_0014', 'USR_PHA_01', 'PROCESSING',
 '2026-05-19 09:45:00', 'DSP-T19-010', 'Đang chia liều kháng sinh', NULL, NULL),
('DSO_T19_011', 'RX_SEED_0015', 'USR_PHA_02', 'PROCESSING',
 '2026-05-19 10:00:00', 'DSP-T19-011', 'Chuẩn bị 3 loại thuốc', NULL, NULL),
('DSO_T19_012', 'RX_SEED_0016', 'USR_PHA_03', 'PROCESSING',
 '2026-05-19 10:15:00', 'DSP-T19-012', 'Đang đóng gói', NULL, NULL),
('DSO_T19_013', 'RX_SEED_0017', 'USR_PHA_01', 'PROCESSING',
 '2026-05-19 10:30:00', 'DSP-T19-013', 'Đang kiểm tra thuốc trị migraine', NULL, NULL),
-- ---- 10 COMPLETED (đã cấp phát xong sáng nay) ----
('DSO_T19_014', 'RX_SEED_0018', 'USR_PHA_02', 'COMPLETED',
 '2026-05-19 07:50:00', 'DSP-T19-014', 'Đã cấp phát đủ thuốc + tư vấn', NULL, NULL),
('DSO_T19_015', 'RX_SEED_0019', 'USR_PHA_03', 'COMPLETED',
 '2026-05-19 08:10:00', 'DSP-T19-015', 'Hướng dẫn dùng xịt mũi', NULL, NULL),
('DSO_T19_016', 'RX_SEED_0020', 'USR_PHA_01', 'COMPLETED',
 '2026-05-19 08:35:00', 'DSP-T19-016', 'Dặn dò uống đúng giờ', NULL, NULL),
('DSO_T19_017', 'RX_SEED_0021', 'USR_PHA_02', 'COMPLETED',
 '2026-05-19 09:00:00', 'DSP-T19-017', NULL, NULL, NULL),
('DSO_T19_018', 'RX_SEED_0022', 'USR_PHA_03', 'COMPLETED',
 '2026-05-19 09:25:00', 'DSP-T19-018', 'Hướng dẫn bôi thuốc ngoài da', NULL, NULL),
('DSO_T19_019', 'RX_SEED_0023', 'USR_PHA_01', 'COMPLETED',
 '2026-05-19 09:50:00', 'DSP-T19-019', 'Hướng dẫn dùng bình xịt COPD', NULL, NULL),
('DSO_T19_020', 'RX_SEED_0024', 'USR_PHA_02', 'COMPLETED',
 '2026-05-19 10:15:00', 'DSP-T19-020', 'Bệnh nhân lớn tuổi - hướng dẫn kỹ', NULL, NULL),
-- 3 COMPLETED cho prescriptions tele đã tồn tại
('DSO_T19_021', 'PRS_TELE_001', 'USR_PHA_03', 'COMPLETED',
 '2026-05-19 10:40:00', 'DSP-T19-021', 'Cấp phát theo đơn tele - bệnh nhân nhận tại quầy', NULL, NULL),
('DSO_T19_022', 'PRS_TELE_002', 'USR_PHA_01', 'COMPLETED',
 '2026-05-19 11:05:00', 'DSP-T19-022', 'Cấp phát theo đơn tele - giao tận nhà', NULL, NULL),
('DSO_T19_023', 'PRS_TELE_003', 'USR_PHA_02', 'COMPLETED',
 '2026-05-19 11:30:00', 'DSP-T19-023', 'Cấp phát theo đơn tele - tăng huyết áp', NULL, NULL),
-- ---- 2 CANCELLED ----
('DSO_T19_024', 'RX_SEED_0025', 'USR_PHA_03', 'CANCELLED',
 '2026-05-19 07:00:00', 'DSP-T19-024', 'Đơn hủy - bệnh nhân không đến nhận',
 '2026-05-19 12:00:00', 'Bệnh nhân không đến nhận thuốc trong 4 giờ'),
('DSO_T19_025', 'RX_SEED_0029', 'USR_PHA_01', 'CANCELLED',
 '2026-05-19 06:45:00', 'DSP-T19-025', 'Đơn hủy do bệnh nhân dị ứng kháng sinh',
 '2026-05-19 07:00:00', 'Phát hiện tiền sử dị ứng amoxicillin - bác sĩ đổi phác đồ')
ON CONFLICT (drug_dispense_orders_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 4. DRUG_DISPENSE_DETAILS — chi tiết cấp phát từng thuốc
--    Mapping inventory_id ↔ drug_id (theo 08_pharmacy.sql):
--      DRG_001 → PINV_0001/0002    DRG_020 → PINV_0027
--      DRG_002 → PINV_0003         DRG_021 → PINV_0028
--      DRG_003 → PINV_0004         DRG_022 → PINV_0029/0030
--      DRG_004 → PINV_0005/0006    DRG_023 → PINV_0031
--      DRG_005 → PINV_0007         DRG_024 → PINV_0032
--      DRG_006 → PINV_0008         DRG_025 → PINV_0033/0034
--      DRG_007 → PINV_0009/0010    DRG_026 → PINV_0035
--      DRG_008 → PINV_0011         DRG_027 → PINV_0036
--      DRG_009 → PINV_0012         DRG_028 → PINV_0037/0038
--      DRG_010 → PINV_0013/0014    DRG_029 → PINV_0039
--      DRG_011 → PINV_0015         DRG_030 → PINV_0040
--      DRG_012 → PINV_0016         DRG_031 → PINV_0041/0042
--      DRG_013 → PINV_0017/0018    DRG_032 → PINV_0043
--      DRG_014 → PINV_0019         DRG_037 → PINV_0049/0050
--      DRG_015 → PINV_0020         DRG_038 → PINV_0051
--      DRG_016 → PINV_0021/0022
--      DRG_017 → PINV_0023
--      DRG_018 → PINV_0024
--      DRG_019 → PINV_0025/0026
--    PRS_TELE_001 dùng PD_TELE_001_1 (DRG_001),
--    PRS_TELE_002 dùng PD_TELE_002_1 (DRG_001) + PD_TELE_002_2 (DRG_005),
--    PRS_TELE_003 dùng PD_TELE_003_1 (DRG_002) + PD_TELE_003_2 (DRG_003).
--
--    Lưu ý: chỉ cấp phát chi tiết cho 23 dispense orders ở trạng thái
--    PROCESSING/COMPLETED (KHÔNG bao gồm PENDING & CANCELLED — vì
--    PENDING chưa lấy thuốc, CANCELLED đã huỷ).
--    Tổng: ~55-60 detail rows.
-- ---------------------------------------------------------------------
INSERT INTO drug_dispense_details
    (drug_dispense_details_id, dispense_order_id, prescription_detail_id,
     inventory_id, dispensed_quantity)
VALUES
-- DSO_T19_009 (PROCESSING) - RX_SEED_0013 viêm khớp dạng thấp
('DSD_T19_001', 'DSO_T19_009', 'PRSD_S13_1', 'PINV_0013', 30),
('DSD_T19_002', 'DSO_T19_009', 'PRSD_S13_2', 'PINV_0021', 30),
('DSD_T19_003', 'DSO_T19_009', 'PRSD_S13_3', 'PINV_0023', 30),
-- DSO_T19_010 (PROCESSING) - RX_SEED_0014 viêm phế quản
('DSD_T19_004', 'DSO_T19_010', 'PRSD_S14_1', 'PINV_0011', 14),
('DSD_T19_005', 'DSO_T19_010', 'PRSD_S14_2', 'PINV_0024', 7),
-- DSO_T19_011 (PROCESSING) - RX_SEED_0015 loét dạ dày
('DSD_T19_006', 'DSO_T19_011', 'PRSD_S15_1', 'PINV_0003', 30),
('DSD_T19_007', 'DSO_T19_011', 'PRSD_S15_2', 'PINV_0007', 30),
('DSD_T19_008', 'DSO_T19_011', 'PRSD_S15_3', 'PINV_0025', 21),
-- DSO_T19_012 (PROCESSING) - RX_SEED_0016 rối loạn lipid
('DSD_T19_009', 'DSO_T19_012', 'PRSD_S16_1', 'PINV_0027', 30),
('DSD_T19_010', 'DSO_T19_012', 'PRSD_S16_2', 'PINV_0028', 30),
-- DSO_T19_013 (PROCESSING) - RX_SEED_0017 migraine
('DSD_T19_011', 'DSO_T19_013', 'PRSD_S17_1', 'PINV_0029', 6),
('DSD_T19_012', 'DSO_T19_013', 'PRSD_S17_2', 'PINV_0001', 10),
('DSD_T19_013', 'DSO_T19_013', 'PRSD_S17_3', 'PINV_0015', 10),
-- DSO_T19_014 (COMPLETED) - RX_SEED_0018 nhiễm trùng tiết niệu
('DSD_T19_014', 'DSO_T19_014', 'PRSD_S18_1', 'PINV_0031', 14),
('DSD_T19_015', 'DSO_T19_014', 'PRSD_S18_2', 'PINV_0032', 14),
-- DSO_T19_015 (COMPLETED) - RX_SEED_0019 viêm xoang
('DSD_T19_016', 'DSO_T19_015', 'PRSD_S19_1', 'PINV_0011', 14),
('DSD_T19_017', 'DSO_T19_015', 'PRSD_S19_2', 'PINV_0033', 10),
('DSD_T19_018', 'DSO_T19_015', 'PRSD_S19_3', 'PINV_0035', 1),
-- DSO_T19_016 (COMPLETED) - RX_SEED_0020 suy giáp
('DSD_T19_019', 'DSO_T19_016', 'PRSD_S20_1', 'PINV_0036', 30),
-- DSO_T19_017 (COMPLETED) - RX_SEED_0021 GERD
('DSD_T19_020', 'DSO_T19_017', 'PRSD_S21_1', 'PINV_0003', 30),
('DSD_T19_021', 'DSO_T19_017', 'PRSD_S21_2', 'PINV_0037', 30),
-- DSO_T19_018 (COMPLETED) - RX_SEED_0022 viêm da dị ứng
('DSD_T19_022', 'DSO_T19_018', 'PRSD_S22_1', 'PINV_0008', 14),
('DSD_T19_023', 'DSO_T19_018', 'PRSD_S22_2', 'PINV_0039', 1),
('DSD_T19_024', 'DSO_T19_018', 'PRSD_S22_3', 'PINV_0040', 1),
-- DSO_T19_019 (COMPLETED) - RX_SEED_0023 COPD
('DSD_T19_025', 'DSO_T19_019', 'PRSD_S23_1', 'PINV_0019', 1),
('DSD_T19_026', 'DSO_T19_019', 'PRSD_S23_2', 'PINV_0041', 30),
-- DSO_T19_020 (COMPLETED) - RX_SEED_0024 đau khớp gối
('DSD_T19_027', 'DSO_T19_020', 'PRSD_S24_1', 'PINV_0013', 20),
('DSD_T19_028', 'DSO_T19_020', 'PRSD_S24_2', 'PINV_0043', 30),
-- DSO_T19_021 (COMPLETED) - PRS_TELE_001 đau đầu
('DSD_T19_029', 'DSO_T19_021', 'PD_TELE_001_1', 'PINV_0001', 9),
-- DSO_T19_022 (COMPLETED) - PRS_TELE_002 viêm họng bé
('DSD_T19_030', 'DSO_T19_022', 'PD_TELE_002_1', 'PINV_0002', 6),
('DSD_T19_031', 'DSO_T19_022', 'PD_TELE_002_2', 'PINV_0007', 6),
-- DSO_T19_023 (COMPLETED) - PRS_TELE_003 tăng huyết áp
('DSD_T19_032', 'DSO_T19_023', 'PD_TELE_003_1', 'PINV_0003', 30),
('DSD_T19_033', 'DSO_T19_023', 'PD_TELE_003_2', 'PINV_0004', 30)
ON CONFLICT (drug_dispense_details_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 5. TELE_PRESCRIPTIONS — 5 đơn thuốc tele bổ sung cho hôm nay
--    Linked tới các RX_SEED_0009/0011/0014/0017/0022 + tele consultations
--    NOTE: tele_consultation_id phải tồn tại trong tele_consultations.
--    Để an toàn, dùng lại TC_DEMO_001..003 đã có ở 11_tele_demo_seed.
--    (1 tele_consultation có thể link nhiều tele_prescriptions không?)
--    → prescription_id là UNIQUE, tele_consultation_id KHÔNG unique → OK
-- ---------------------------------------------------------------------
INSERT INTO tele_prescriptions
    (tele_prescription_id, prescription_id, tele_consultation_id, encounter_id,
     is_remote_prescription, remote_restrictions_checked,
     delivery_method, delivery_address, delivery_phone,
     sent_to_patient, sent_at, doctor_confirmed_identity,
     has_lab_orders, has_referral, pharmacy_notes, stock_checked)
VALUES
('TP_T19_001', 'RX_SEED_0009', 'TC_DEMO_001', 'ENC_DEMO_015', TRUE, TRUE,
 'PICKUP',   '12 Trần Hưng Đạo, Q.5, TP.HCM', '0920500030',
 TRUE, '2026-05-19 08:35:00+07', TRUE, FALSE, FALSE,
 'Đã chuẩn bị sẵn tại quầy 2', TRUE),
('TP_T19_002', 'RX_SEED_0011', 'TC_DEMO_002', 'ENC_DEMO_017', TRUE, TRUE,
 'DELIVERY', '45 Nguyễn Văn Linh, Q.7, TP.HCM', '0920500032',
 TRUE, '2026-05-19 09:10:00+07', TRUE, FALSE, FALSE,
 'Cần đóng gói riêng thuốc hướng thần', TRUE),
('TP_T19_003', 'RX_SEED_0014', 'TC_DEMO_003', 'ENC_DEMO_020', TRUE, TRUE,
 'PICKUP',   '78 Lê Văn Sỹ, Q.Tân Bình, TP.HCM', '0920500035',
 FALSE, NULL, TRUE, FALSE, FALSE,
 'Đang chuẩn bị thuốc - chờ thông báo BN', TRUE),
('TP_T19_004', 'RX_SEED_0017', 'TC_DEMO_001', 'ENC_DEMO_023', TRUE, TRUE,
 'DIGITAL',  NULL, '0920500038',
 TRUE, '2026-05-19 10:35:00+07', TRUE, FALSE, FALSE,
 'Đơn migraine - đã gửi đơn điện tử cho BN', TRUE),
('TP_T19_005', 'RX_SEED_0022', 'TC_DEMO_002', 'ENC_DEMO_028', TRUE, TRUE,
 'DELIVERY', '23 Cách Mạng Tháng 8, Q.10, TP.HCM', '0920500043',
 TRUE, '2026-05-19 09:30:00+07', TRUE, FALSE, TRUE,
 'Kèm chỉ định tái khám da liễu sau 2 tuần', TRUE)
ON CONFLICT (tele_prescription_id) DO NOTHING;

COMMIT;

-- =====================================================================
-- KẾT THÚC seed 20_pharmacist_dispense_today.sql
-- Tổng số dòng được thêm (tối đa, nếu chưa tồn tại):
--   prescriptions             : 25  (RX_SEED_0005..0029)
--   prescription_details      : 57  (PRSD_S05_1..PRSD_S29_1)
--   drug_dispense_orders      : 25  (DSO_T19_001..025)
--     - PENDING    : 8
--     - PROCESSING : 5
--     - COMPLETED  : 10
--     - CANCELLED  : 2
--   drug_dispense_details     : 33  (DSD_T19_001..033)
--   tele_prescriptions        : 5   (TP_T19_001..005)
-- =====================================================================
