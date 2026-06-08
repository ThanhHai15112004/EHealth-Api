-- ========================================================================
-- 13_appointments_encounters.sql
-- ========================================================================
-- Demo data: 50 appointments + 30 encounters + 30 diagnoses + 20 clinical exams
-- Status mix realistic, span last 30 days + next 7 days future.
-- Idempotent: ON CONFLICT (PK) DO NOTHING.
-- Status mapping (task label → schema value):
--   BOOKED     → PENDING    (5 future days +1..+7)
--   CONFIRMED  → CONFIRMED  (10 today/tomorrow)
--   CHECKED_IN → CHECKED_IN (10 today)
--   DONE       → COMPLETED  (20 past days -30..-1)
--   CANCELLED  → CANCELLED  (5 past)
-- Dependencies: 01_core (users, doctors), 03_facilities (rooms, branches,
--   specialties), 05_scheduling (slots), 07_patients (patients)
-- ========================================================================

BEGIN;

-- ------------------------------------------------------------------------
-- 1. APPOINTMENTS — 50 rows (PENDING/CONFIRMED/CHECKED_IN/COMPLETED/CANCELLED)
-- ------------------------------------------------------------------------
INSERT INTO appointments (
    appointments_id, appointment_code, patient_id, doctor_id, slot_id,
    room_id, specialty_id, branch_id, appointment_date, booking_channel,
    reason_for_visit, status, priority, queue_number,
    confirmed_at, confirmed_by, checked_in_at, started_at, completed_at,
    cancelled_at, cancellation_reason, cancelled_by
) VALUES
('APT_DEMO_001','APP-PEND-001','PAT_001','DOC_01','SLOT_001','ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN',CURRENT_DATE + INTERVAL '1 day','WEB','Khám tổng quát định kỳ','PENDING','NORMAL',1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_002','APP-PEND-002','PAT_002','DOC_02','SLOT_002','ROOM_KB_02','SPC_NOI','BR_MAIN',CURRENT_DATE + INTERVAL '2 day','WEB','Khám tổng quát định kỳ','PENDING','NORMAL',2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_003','APP-PEND-003','PAT_003','DOC_03','SLOT_003','ROOM_KB_03','SPC_NGOAI','BR_MAIN',CURRENT_DATE + INTERVAL '3 day','WEB','Khám tổng quát định kỳ','PENDING','NORMAL',3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_004','APP-PEND-004','PAT_004','DOC_04','SLOT_004','ROOM_KB_04','SPC_NHI','BR_MAIN',CURRENT_DATE + INTERVAL '4 day','WEB','Khám tổng quát định kỳ','PENDING','NORMAL',4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_005','APP-PEND-005','PAT_005','DOC_05','SLOT_005','ROOM_KB_05','SPC_SAN','BR_MAIN',CURRENT_DATE + INTERVAL '5 day','WEB','Khám tổng quát định kỳ','PENDING','NORMAL',5,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_006','APP-CONF-001','PAT_006','DOC_06','SLOT_006','ROOM_KB_01','SPC_CC','BR_MAIN',CURRENT_DATE + INTERVAL '0 day','APP','Khám chuyên khoa','CONFIRMED','NORMAL',1,NOW() - INTERVAL '1 day','USR_DOC_06',NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_007','APP-CONF-002','PAT_007','DOC_07','SLOT_007','ROOM_KB_02','SPC_TONG_QUAT','BR_MAIN',CURRENT_DATE + INTERVAL '0 day','APP','Khám chuyên khoa','CONFIRMED','NORMAL',2,NOW() - INTERVAL '1 day','USR_DOC_07',NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_008','APP-CONF-003','PAT_008','DOC_08','SLOT_008','ROOM_KB_03','SPC_NOI','BR_MAIN',CURRENT_DATE + INTERVAL '0 day','APP','Khám chuyên khoa','CONFIRMED','NORMAL',3,NOW() - INTERVAL '1 day','USR_DOC_08',NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_009','APP-CONF-004','PAT_009','DOC_09','SLOT_009','ROOM_KB_04','SPC_NGOAI','BR_MAIN',CURRENT_DATE + INTERVAL '0 day','APP','Khám chuyên khoa','CONFIRMED','NORMAL',4,NOW() - INTERVAL '1 day','USR_DOC_09',NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_010','APP-CONF-005','PAT_010','DOC_10','SLOT_010','ROOM_KB_05','SPC_NHI','BR_MAIN',CURRENT_DATE + INTERVAL '0 day','APP','Khám chuyên khoa','CONFIRMED','NORMAL',5,NOW() - INTERVAL '1 day','USR_DOC_10',NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_011','APP-CONF-006','PAT_011','DOC_01','SLOT_011','ROOM_KB_01','SPC_SAN','BR_MAIN',CURRENT_DATE + INTERVAL '1 day','APP','Khám chuyên khoa','CONFIRMED','NORMAL',6,NOW() - INTERVAL '1 day','USR_DOC_01',NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_012','APP-CONF-007','PAT_012','DOC_02','SLOT_012','ROOM_KB_02','SPC_CC','BR_MAIN',CURRENT_DATE + INTERVAL '1 day','APP','Khám chuyên khoa','CONFIRMED','NORMAL',7,NOW() - INTERVAL '1 day','USR_DOC_02',NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_013','APP-CONF-008','PAT_013','DOC_03','SLOT_013','ROOM_KB_03','SPC_TONG_QUAT','BR_MAIN',CURRENT_DATE + INTERVAL '1 day','APP','Khám chuyên khoa','CONFIRMED','NORMAL',8,NOW() - INTERVAL '1 day','USR_DOC_03',NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_014','APP-CONF-009','PAT_014','DOC_04','SLOT_014','ROOM_KB_04','SPC_NOI','BR_MAIN',CURRENT_DATE + INTERVAL '1 day','APP','Khám chuyên khoa','CONFIRMED','NORMAL',9,NOW() - INTERVAL '1 day','USR_DOC_04',NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_015','APP-CONF-010','PAT_015','DOC_05','SLOT_015','ROOM_KB_05','SPC_NGOAI','BR_MAIN',CURRENT_DATE + INTERVAL '1 day','APP','Khám chuyên khoa','CONFIRMED','NORMAL',10,NOW() - INTERVAL '1 day','USR_DOC_05',NULL,NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_016','APP-CKIN-001','PAT_016','DOC_06','SLOT_016','ROOM_KB_01','SPC_NHI','BR_MAIN',CURRENT_DATE,'HOTLINE','Khám lâm sàng','CHECKED_IN','NORMAL',11,NOW() - INTERVAL '2 hour','USR_DOC_06',NOW() - INTERVAL '30 minute',NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_017','APP-CKIN-002','PAT_017','DOC_07','SLOT_017','ROOM_KB_02','SPC_SAN','BR_MAIN',CURRENT_DATE,'HOTLINE','Khám lâm sàng','CHECKED_IN','NORMAL',12,NOW() - INTERVAL '2 hour','USR_DOC_07',NOW() - INTERVAL '30 minute',NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_018','APP-CKIN-003','PAT_018','DOC_08','SLOT_018','ROOM_KB_03','SPC_CC','BR_MAIN',CURRENT_DATE,'HOTLINE','Khám lâm sàng','CHECKED_IN','NORMAL',13,NOW() - INTERVAL '2 hour','USR_DOC_08',NOW() - INTERVAL '30 minute',NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_019','APP-CKIN-004','PAT_019','DOC_09','SLOT_019','ROOM_KB_04','SPC_TONG_QUAT','BR_MAIN',CURRENT_DATE,'HOTLINE','Khám lâm sàng','CHECKED_IN','NORMAL',14,NOW() - INTERVAL '2 hour','USR_DOC_09',NOW() - INTERVAL '30 minute',NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_020','APP-CKIN-005','PAT_020','DOC_10','SLOT_020','ROOM_KB_05','SPC_NOI','BR_MAIN',CURRENT_DATE,'HOTLINE','Khám lâm sàng','CHECKED_IN','NORMAL',15,NOW() - INTERVAL '2 hour','USR_DOC_10',NOW() - INTERVAL '30 minute',NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_021','APP-CKIN-006','PAT_021','DOC_01','SLOT_021','ROOM_KB_01','SPC_NGOAI','BR_MAIN',CURRENT_DATE,'HOTLINE','Khám lâm sàng','CHECKED_IN','NORMAL',16,NOW() - INTERVAL '2 hour','USR_DOC_01',NOW() - INTERVAL '30 minute',NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_022','APP-CKIN-007','PAT_022','DOC_02','SLOT_022','ROOM_KB_02','SPC_NHI','BR_MAIN',CURRENT_DATE,'HOTLINE','Khám lâm sàng','CHECKED_IN','NORMAL',17,NOW() - INTERVAL '2 hour','USR_DOC_02',NOW() - INTERVAL '30 minute',NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_023','APP-CKIN-008','PAT_023','DOC_03','SLOT_023','ROOM_KB_03','SPC_SAN','BR_MAIN',CURRENT_DATE,'HOTLINE','Khám lâm sàng','CHECKED_IN','NORMAL',18,NOW() - INTERVAL '2 hour','USR_DOC_03',NOW() - INTERVAL '30 minute',NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_024','APP-CKIN-009','PAT_024','DOC_04','SLOT_024','ROOM_KB_04','SPC_CC','BR_MAIN',CURRENT_DATE,'HOTLINE','Khám lâm sàng','CHECKED_IN','NORMAL',19,NOW() - INTERVAL '2 hour','USR_DOC_04',NOW() - INTERVAL '30 minute',NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_025','APP-CKIN-010','PAT_025','DOC_05','SLOT_025','ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN',CURRENT_DATE,'HOTLINE','Khám lâm sàng','CHECKED_IN','NORMAL',20,NOW() - INTERVAL '2 hour','USR_DOC_05',NOW() - INTERVAL '30 minute',NULL,NULL,NULL,NULL,NULL),
('APT_DEMO_026','APP-DONE-001','PAT_026','DOC_06','SLOT_026','ROOM_KB_01','SPC_NOI','BR_MAIN',CURRENT_DATE - INTERVAL '1 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',21,NOW() - INTERVAL '2 day','USR_DOC_06',NOW() - INTERVAL '1 day' - INTERVAL '30 minute',NOW() - INTERVAL '1 day' - INTERVAL '15 minute',NOW() - INTERVAL '1 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_027','APP-DONE-002','PAT_027','DOC_07','SLOT_027','ROOM_KB_02','SPC_NGOAI','BR_MAIN',CURRENT_DATE - INTERVAL '2 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',22,NOW() - INTERVAL '3 day','USR_DOC_07',NOW() - INTERVAL '2 day' - INTERVAL '30 minute',NOW() - INTERVAL '2 day' - INTERVAL '15 minute',NOW() - INTERVAL '2 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_028','APP-DONE-003','PAT_028','DOC_08','SLOT_028','ROOM_KB_03','SPC_NHI','BR_MAIN',CURRENT_DATE - INTERVAL '3 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',23,NOW() - INTERVAL '4 day','USR_DOC_08',NOW() - INTERVAL '3 day' - INTERVAL '30 minute',NOW() - INTERVAL '3 day' - INTERVAL '15 minute',NOW() - INTERVAL '3 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_029','APP-DONE-004','PAT_029','DOC_09','SLOT_029','ROOM_KB_04','SPC_SAN','BR_MAIN',CURRENT_DATE - INTERVAL '4 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',24,NOW() - INTERVAL '5 day','USR_DOC_09',NOW() - INTERVAL '4 day' - INTERVAL '30 minute',NOW() - INTERVAL '4 day' - INTERVAL '15 minute',NOW() - INTERVAL '4 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_030','APP-DONE-005','PAT_030','DOC_10','SLOT_030','ROOM_KB_05','SPC_CC','BR_MAIN',CURRENT_DATE - INTERVAL '5 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',25,NOW() - INTERVAL '6 day','USR_DOC_10',NOW() - INTERVAL '5 day' - INTERVAL '30 minute',NOW() - INTERVAL '5 day' - INTERVAL '15 minute',NOW() - INTERVAL '5 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_031','APP-DONE-006','PAT_031','DOC_01','SLOT_031','ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN',CURRENT_DATE - INTERVAL '6 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',26,NOW() - INTERVAL '7 day','USR_DOC_01',NOW() - INTERVAL '6 day' - INTERVAL '30 minute',NOW() - INTERVAL '6 day' - INTERVAL '15 minute',NOW() - INTERVAL '6 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_032','APP-DONE-007','PAT_032','DOC_02','SLOT_032','ROOM_KB_02','SPC_NOI','BR_MAIN',CURRENT_DATE - INTERVAL '7 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',27,NOW() - INTERVAL '8 day','USR_DOC_02',NOW() - INTERVAL '7 day' - INTERVAL '30 minute',NOW() - INTERVAL '7 day' - INTERVAL '15 minute',NOW() - INTERVAL '7 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_033','APP-DONE-008','PAT_033','DOC_03','SLOT_033','ROOM_KB_03','SPC_NGOAI','BR_MAIN',CURRENT_DATE - INTERVAL '8 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',28,NOW() - INTERVAL '9 day','USR_DOC_03',NOW() - INTERVAL '8 day' - INTERVAL '30 minute',NOW() - INTERVAL '8 day' - INTERVAL '15 minute',NOW() - INTERVAL '8 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_034','APP-DONE-009','PAT_034','DOC_04','SLOT_034','ROOM_KB_04','SPC_NHI','BR_MAIN',CURRENT_DATE - INTERVAL '9 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',29,NOW() - INTERVAL '10 day','USR_DOC_04',NOW() - INTERVAL '9 day' - INTERVAL '30 minute',NOW() - INTERVAL '9 day' - INTERVAL '15 minute',NOW() - INTERVAL '9 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_035','APP-DONE-010','PAT_035','DOC_05','SLOT_001','ROOM_KB_05','SPC_SAN','BR_MAIN',CURRENT_DATE - INTERVAL '10 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',30,NOW() - INTERVAL '11 day','USR_DOC_05',NOW() - INTERVAL '10 day' - INTERVAL '30 minute',NOW() - INTERVAL '10 day' - INTERVAL '15 minute',NOW() - INTERVAL '10 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_036','APP-DONE-011','PAT_036','DOC_06','SLOT_002','ROOM_KB_01','SPC_CC','BR_MAIN',CURRENT_DATE - INTERVAL '11 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',31,NOW() - INTERVAL '12 day','USR_DOC_06',NOW() - INTERVAL '11 day' - INTERVAL '30 minute',NOW() - INTERVAL '11 day' - INTERVAL '15 minute',NOW() - INTERVAL '11 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_037','APP-DONE-012','PAT_037','DOC_07','SLOT_003','ROOM_KB_02','SPC_TONG_QUAT','BR_MAIN',CURRENT_DATE - INTERVAL '12 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',32,NOW() - INTERVAL '13 day','USR_DOC_07',NOW() - INTERVAL '12 day' - INTERVAL '30 minute',NOW() - INTERVAL '12 day' - INTERVAL '15 minute',NOW() - INTERVAL '12 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_038','APP-DONE-013','PAT_038','DOC_08','SLOT_004','ROOM_KB_03','SPC_NOI','BR_MAIN',CURRENT_DATE - INTERVAL '13 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',33,NOW() - INTERVAL '14 day','USR_DOC_08',NOW() - INTERVAL '13 day' - INTERVAL '30 minute',NOW() - INTERVAL '13 day' - INTERVAL '15 minute',NOW() - INTERVAL '13 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_039','APP-DONE-014','PAT_039','DOC_09','SLOT_005','ROOM_KB_04','SPC_NGOAI','BR_MAIN',CURRENT_DATE - INTERVAL '14 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',34,NOW() - INTERVAL '15 day','USR_DOC_09',NOW() - INTERVAL '14 day' - INTERVAL '30 minute',NOW() - INTERVAL '14 day' - INTERVAL '15 minute',NOW() - INTERVAL '14 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_040','APP-DONE-015','PAT_040','DOC_10','SLOT_006','ROOM_KB_05','SPC_NHI','BR_MAIN',CURRENT_DATE - INTERVAL '15 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',35,NOW() - INTERVAL '16 day','USR_DOC_10',NOW() - INTERVAL '15 day' - INTERVAL '30 minute',NOW() - INTERVAL '15 day' - INTERVAL '15 minute',NOW() - INTERVAL '15 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_041','APP-DONE-016','PAT_041','DOC_01','SLOT_007','ROOM_KB_01','SPC_SAN','BR_MAIN',CURRENT_DATE - INTERVAL '16 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',36,NOW() - INTERVAL '17 day','USR_DOC_01',NOW() - INTERVAL '16 day' - INTERVAL '30 minute',NOW() - INTERVAL '16 day' - INTERVAL '15 minute',NOW() - INTERVAL '16 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_042','APP-DONE-017','PAT_042','DOC_02','SLOT_008','ROOM_KB_02','SPC_CC','BR_MAIN',CURRENT_DATE - INTERVAL '17 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',37,NOW() - INTERVAL '18 day','USR_DOC_02',NOW() - INTERVAL '17 day' - INTERVAL '30 minute',NOW() - INTERVAL '17 day' - INTERVAL '15 minute',NOW() - INTERVAL '17 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_043','APP-DONE-018','PAT_043','DOC_03','SLOT_009','ROOM_KB_03','SPC_TONG_QUAT','BR_MAIN',CURRENT_DATE - INTERVAL '18 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',38,NOW() - INTERVAL '19 day','USR_DOC_03',NOW() - INTERVAL '18 day' - INTERVAL '30 minute',NOW() - INTERVAL '18 day' - INTERVAL '15 minute',NOW() - INTERVAL '18 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_044','APP-DONE-019','PAT_044','DOC_04','SLOT_010','ROOM_KB_04','SPC_NOI','BR_MAIN',CURRENT_DATE - INTERVAL '19 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',39,NOW() - INTERVAL '20 day','USR_DOC_04',NOW() - INTERVAL '19 day' - INTERVAL '30 minute',NOW() - INTERVAL '19 day' - INTERVAL '15 minute',NOW() - INTERVAL '19 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_045','APP-DONE-020','PAT_045','DOC_05','SLOT_011','ROOM_KB_05','SPC_NGOAI','BR_MAIN',CURRENT_DATE - INTERVAL '20 day','DIRECT_CLINIC','Tái khám','COMPLETED','NORMAL',40,NOW() - INTERVAL '21 day','USR_DOC_05',NOW() - INTERVAL '20 day' - INTERVAL '30 minute',NOW() - INTERVAL '20 day' - INTERVAL '15 minute',NOW() - INTERVAL '20 day' + INTERVAL '20 minute',NULL,NULL,NULL),
('APT_DEMO_046','APP-CNCL-001','PAT_046','DOC_06','SLOT_012','ROOM_KB_01','SPC_NHI','BR_MAIN',CURRENT_DATE - INTERVAL '2 day','ZALO','Khám bệnh','CANCELLED','NORMAL',1,NULL,NULL,NULL,NULL,NULL,NOW() - INTERVAL '3 day','Bệnh nhân bận đột xuất','USR_DOC_06'),
('APT_DEMO_047','APP-CNCL-002','PAT_047','DOC_07','SLOT_013','ROOM_KB_02','SPC_SAN','BR_MAIN',CURRENT_DATE - INTERVAL '4 day','ZALO','Khám bệnh','CANCELLED','NORMAL',2,NULL,NULL,NULL,NULL,NULL,NOW() - INTERVAL '5 day','Bệnh nhân bận đột xuất','USR_DOC_07'),
('APT_DEMO_048','APP-CNCL-003','PAT_048','DOC_08','SLOT_014','ROOM_KB_03','SPC_CC','BR_MAIN',CURRENT_DATE - INTERVAL '6 day','ZALO','Khám bệnh','CANCELLED','NORMAL',3,NULL,NULL,NULL,NULL,NULL,NOW() - INTERVAL '7 day','Bệnh nhân bận đột xuất','USR_DOC_08'),
('APT_DEMO_049','APP-CNCL-004','PAT_049','DOC_09','SLOT_015','ROOM_KB_04','SPC_TONG_QUAT','BR_MAIN',CURRENT_DATE - INTERVAL '8 day','ZALO','Khám bệnh','CANCELLED','NORMAL',4,NULL,NULL,NULL,NULL,NULL,NOW() - INTERVAL '9 day','Bệnh nhân bận đột xuất','USR_DOC_09'),
('APT_DEMO_050','APP-CNCL-005','PAT_050','DOC_10','SLOT_016','ROOM_KB_05','SPC_NOI','BR_MAIN',CURRENT_DATE - INTERVAL '10 day','ZALO','Khám bệnh','CANCELLED','NORMAL',5,NULL,NULL,NULL,NULL,NULL,NOW() - INTERVAL '11 day','Bệnh nhân bận đột xuất','USR_DOC_10')
ON CONFLICT (appointments_id) DO NOTHING;

-- ------------------------------------------------------------------------
-- 2. ENCOUNTERS — 30 rows (linked to CHECKED_IN + COMPLETED appointments)
-- ------------------------------------------------------------------------
INSERT INTO encounters (
    encounters_id, appointment_id, patient_id, doctor_id, room_id,
    encounter_type, visit_number, start_time, end_time, status, notes
) VALUES
('ENC_DEMO_001','APT_DEMO_016','PAT_016','DOC_06','ROOM_KB_01','OUTPATIENT',1,NOW() - INTERVAL '20 minute',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_DEMO_002','APT_DEMO_017','PAT_017','DOC_07','ROOM_KB_02','OUTPATIENT',1,NOW() - INTERVAL '20 minute',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_DEMO_003','APT_DEMO_018','PAT_018','DOC_08','ROOM_KB_03','OUTPATIENT',1,NOW() - INTERVAL '20 minute',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_DEMO_004','APT_DEMO_019','PAT_019','DOC_09','ROOM_KB_04','OUTPATIENT',1,NOW() - INTERVAL '20 minute',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_DEMO_005','APT_DEMO_020','PAT_020','DOC_10','ROOM_KB_05','OUTPATIENT',1,NOW() - INTERVAL '20 minute',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_DEMO_006','APT_DEMO_021','PAT_021','DOC_01','ROOM_KB_01','OUTPATIENT',1,NOW() - INTERVAL '20 minute',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_DEMO_007','APT_DEMO_022','PAT_022','DOC_02','ROOM_KB_02','OUTPATIENT',1,NOW() - INTERVAL '20 minute',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_DEMO_008','APT_DEMO_023','PAT_023','DOC_03','ROOM_KB_03','OUTPATIENT',1,NOW() - INTERVAL '20 minute',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_DEMO_009','APT_DEMO_024','PAT_024','DOC_04','ROOM_KB_04','OUTPATIENT',1,NOW() - INTERVAL '20 minute',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_DEMO_010','APT_DEMO_025','PAT_025','DOC_05','ROOM_KB_05','OUTPATIENT',1,NOW() - INTERVAL '20 minute',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_DEMO_011','APT_DEMO_026','PAT_026','DOC_06','ROOM_KB_01','OUTPATIENT',1,NOW() - INTERVAL '1 day' - INTERVAL '15 minute',NOW() - INTERVAL '1 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_012','APT_DEMO_027','PAT_027','DOC_07','ROOM_KB_02','OUTPATIENT',2,NOW() - INTERVAL '2 day' - INTERVAL '15 minute',NOW() - INTERVAL '2 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_013','APT_DEMO_028','PAT_028','DOC_08','ROOM_KB_03','OUTPATIENT',3,NOW() - INTERVAL '3 day' - INTERVAL '15 minute',NOW() - INTERVAL '3 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_014','APT_DEMO_029','PAT_029','DOC_09','ROOM_KB_04','OUTPATIENT',1,NOW() - INTERVAL '4 day' - INTERVAL '15 minute',NOW() - INTERVAL '4 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_015','APT_DEMO_030','PAT_030','DOC_10','ROOM_KB_05','OUTPATIENT',2,NOW() - INTERVAL '5 day' - INTERVAL '15 minute',NOW() - INTERVAL '5 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_016','APT_DEMO_031','PAT_031','DOC_01','ROOM_KB_01','OUTPATIENT',3,NOW() - INTERVAL '6 day' - INTERVAL '15 minute',NOW() - INTERVAL '6 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_017','APT_DEMO_032','PAT_032','DOC_02','ROOM_KB_02','OUTPATIENT',1,NOW() - INTERVAL '7 day' - INTERVAL '15 minute',NOW() - INTERVAL '7 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_018','APT_DEMO_033','PAT_033','DOC_03','ROOM_KB_03','OUTPATIENT',2,NOW() - INTERVAL '8 day' - INTERVAL '15 minute',NOW() - INTERVAL '8 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_019','APT_DEMO_034','PAT_034','DOC_04','ROOM_KB_04','OUTPATIENT',3,NOW() - INTERVAL '9 day' - INTERVAL '15 minute',NOW() - INTERVAL '9 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_020','APT_DEMO_035','PAT_035','DOC_05','ROOM_KB_05','OUTPATIENT',1,NOW() - INTERVAL '10 day' - INTERVAL '15 minute',NOW() - INTERVAL '10 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_021','APT_DEMO_036','PAT_036','DOC_06','ROOM_KB_01','OUTPATIENT',2,NOW() - INTERVAL '11 day' - INTERVAL '15 minute',NOW() - INTERVAL '11 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_022','APT_DEMO_037','PAT_037','DOC_07','ROOM_KB_02','OUTPATIENT',3,NOW() - INTERVAL '12 day' - INTERVAL '15 minute',NOW() - INTERVAL '12 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_023','APT_DEMO_038','PAT_038','DOC_08','ROOM_KB_03','OUTPATIENT',1,NOW() - INTERVAL '13 day' - INTERVAL '15 minute',NOW() - INTERVAL '13 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_024','APT_DEMO_039','PAT_039','DOC_09','ROOM_KB_04','OUTPATIENT',2,NOW() - INTERVAL '14 day' - INTERVAL '15 minute',NOW() - INTERVAL '14 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_025','APT_DEMO_040','PAT_040','DOC_10','ROOM_KB_05','OUTPATIENT',3,NOW() - INTERVAL '15 day' - INTERVAL '15 minute',NOW() - INTERVAL '15 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_026','APT_DEMO_041','PAT_041','DOC_01','ROOM_KB_01','OUTPATIENT',1,NOW() - INTERVAL '16 day' - INTERVAL '15 minute',NOW() - INTERVAL '16 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_027','APT_DEMO_042','PAT_042','DOC_02','ROOM_KB_02','OUTPATIENT',2,NOW() - INTERVAL '17 day' - INTERVAL '15 minute',NOW() - INTERVAL '17 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_028','APT_DEMO_043','PAT_043','DOC_03','ROOM_KB_03','OUTPATIENT',3,NOW() - INTERVAL '18 day' - INTERVAL '15 minute',NOW() - INTERVAL '18 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_029','APT_DEMO_044','PAT_044','DOC_04','ROOM_KB_04','OUTPATIENT',1,NOW() - INTERVAL '19 day' - INTERVAL '15 minute',NOW() - INTERVAL '19 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_DEMO_030','APT_DEMO_045','PAT_045','DOC_05','ROOM_KB_05','OUTPATIENT',2,NOW() - INTERVAL '20 day' - INTERVAL '15 minute',NOW() - INTERVAL '20 day' + INTERVAL '20 minute','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám')
ON CONFLICT (encounters_id) DO NOTHING;

-- ------------------------------------------------------------------------
-- 3. ENCOUNTER_DIAGNOSES — 30 rows (1 per encounter, mix ICD-10 codes)
-- ------------------------------------------------------------------------
INSERT INTO encounter_diagnoses (
    encounter_diagnoses_id, encounter_id, icd10_code, diagnosis_name,
    diagnosis_type, notes, diagnosed_by
) VALUES
('DX_DEMO_001','ENC_DEMO_001','J00','Cảm thông thường','PRELIMINARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_06'),
('DX_DEMO_002','ENC_DEMO_002','K29','Viêm dạ dày và tá tràng','PRELIMINARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_07'),
('DX_DEMO_003','ENC_DEMO_003','I10','Tăng huyết áp vô căn','PRELIMINARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_08'),
('DX_DEMO_004','ENC_DEMO_004','E11','Đái tháo đường type 2','PRELIMINARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_09'),
('DX_DEMO_005','ENC_DEMO_005','M25.5','Đau khớp','PRELIMINARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_10'),
('DX_DEMO_006','ENC_DEMO_006','R51','Đau đầu','PRELIMINARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_01'),
('DX_DEMO_007','ENC_DEMO_007','F41.1','Rối loạn lo âu lan toả','PRELIMINARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_02'),
('DX_DEMO_008','ENC_DEMO_008','J45','Hen suyễn','PRELIMINARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_03'),
('DX_DEMO_009','ENC_DEMO_009','N39.0','Nhiễm khuẩn đường tiết niệu','PRELIMINARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_04'),
('DX_DEMO_010','ENC_DEMO_010','K59.0','Táo bón / rối loạn tiêu hoá','PRELIMINARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_05'),
('DX_DEMO_011','ENC_DEMO_011','J20','Viêm phế quản cấp','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_06'),
('DX_DEMO_012','ENC_DEMO_012','L20','Viêm da cơ địa','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_07'),
('DX_DEMO_013','ENC_DEMO_013','J00','Cảm thông thường','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_08'),
('DX_DEMO_014','ENC_DEMO_014','K29','Viêm dạ dày và tá tràng','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_09'),
('DX_DEMO_015','ENC_DEMO_015','I10','Tăng huyết áp vô căn','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_10'),
('DX_DEMO_016','ENC_DEMO_016','E11','Đái tháo đường type 2','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_01'),
('DX_DEMO_017','ENC_DEMO_017','M25.5','Đau khớp','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_02'),
('DX_DEMO_018','ENC_DEMO_018','R51','Đau đầu','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_03'),
('DX_DEMO_019','ENC_DEMO_019','F41.1','Rối loạn lo âu lan toả','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_04'),
('DX_DEMO_020','ENC_DEMO_020','J45','Hen suyễn','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_05'),
('DX_DEMO_021','ENC_DEMO_021','N39.0','Nhiễm khuẩn đường tiết niệu','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_06'),
('DX_DEMO_022','ENC_DEMO_022','K59.0','Táo bón / rối loạn tiêu hoá','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_07'),
('DX_DEMO_023','ENC_DEMO_023','J20','Viêm phế quản cấp','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_08'),
('DX_DEMO_024','ENC_DEMO_024','L20','Viêm da cơ địa','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_09'),
('DX_DEMO_025','ENC_DEMO_025','J00','Cảm thông thường','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_10'),
('DX_DEMO_026','ENC_DEMO_026','K29','Viêm dạ dày và tá tràng','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_01'),
('DX_DEMO_027','ENC_DEMO_027','I10','Tăng huyết áp vô căn','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_02'),
('DX_DEMO_028','ENC_DEMO_028','E11','Đái tháo đường type 2','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_03'),
('DX_DEMO_029','ENC_DEMO_029','M25.5','Đau khớp','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_04'),
('DX_DEMO_030','ENC_DEMO_030','R51','Đau đầu','PRIMARY','Chẩn đoán dựa trên triệu chứng và thăm khám lâm sàng','USR_DOC_05')
ON CONFLICT (encounter_diagnoses_id) DO NOTHING;

-- ------------------------------------------------------------------------
-- 4. CLINICAL_EXAMINATIONS — 20 rows (vital signs, encounter_id UNIQUE)
-- ------------------------------------------------------------------------
INSERT INTO clinical_examinations (
    clinical_examinations_id, encounter_id, pulse,
    blood_pressure_systolic, blood_pressure_diastolic, temperature,
    respiratory_rate, spo2, weight, height, bmi,
    chief_complaint, medical_history_notes, physical_examination,
    status, recorded_by
) VALUES
('CE_DEMO_001','ENC_DEMO_001',72,118,78,36.6,16,98,62.5,168,22.14,'Sốt nhẹ, ho khan, mệt mỏi','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','DRAFT','USR_DOC_06'),
('CE_DEMO_002','ENC_DEMO_002',88,132,86,37.1,18,97,70.0,172,23.66,'Đau thượng vị sau ăn, ợ nóng','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','DRAFT','USR_DOC_07'),
('CE_DEMO_003','ENC_DEMO_003',65,110,70,36.4,14,99,55.0,160,21.48,'Đau đầu kéo dài, chóng mặt','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','DRAFT','USR_DOC_08'),
('CE_DEMO_004','ENC_DEMO_004',95,138,90,37.8,22,95,78.5,175,25.63,'Khó thở khi gắng sức','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','DRAFT','USR_DOC_09'),
('CE_DEMO_005','ENC_DEMO_005',78,122,80,36.8,17,98,65.0,165,23.88,'Đau khớp gối phải, tê chân','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','DRAFT','USR_DOC_10'),
('CE_DEMO_006','ENC_DEMO_006',82,128,84,36.9,18,97,68.0,170,23.53,'Tiểu nhiều, khát nước','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','DRAFT','USR_DOC_01'),
('CE_DEMO_007','ENC_DEMO_007',70,115,75,36.5,16,99,58.0,162,22.1,'Đau bụng quanh rốn, buồn nôn','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','DRAFT','USR_DOC_02'),
('CE_DEMO_008','ENC_DEMO_008',90,140,88,37.4,20,96,75.0,174,24.77,'Ho có đờm, đau ngực','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','DRAFT','USR_DOC_03'),
('CE_DEMO_009','ENC_DEMO_009',76,120,78,36.7,16,98,63.0,167,22.59,'Mất ngủ, lo lắng','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','DRAFT','USR_DOC_04'),
('CE_DEMO_010','ENC_DEMO_010',85,134,88,37.2,19,97,72.0,173,24.06,'Nổi mẩn ngứa toàn thân','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','DRAFT','USR_DOC_05'),
('CE_DEMO_011','ENC_DEMO_011',72,118,78,36.6,16,98,62.5,168,22.14,'Sốt nhẹ, ho khan, mệt mỏi','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','FINAL','USR_DOC_06'),
('CE_DEMO_012','ENC_DEMO_012',88,132,86,37.1,18,97,70.0,172,23.66,'Đau thượng vị sau ăn, ợ nóng','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','FINAL','USR_DOC_07'),
('CE_DEMO_013','ENC_DEMO_013',65,110,70,36.4,14,99,55.0,160,21.48,'Đau đầu kéo dài, chóng mặt','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','FINAL','USR_DOC_08'),
('CE_DEMO_014','ENC_DEMO_014',95,138,90,37.8,22,95,78.5,175,25.63,'Khó thở khi gắng sức','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','FINAL','USR_DOC_09'),
('CE_DEMO_015','ENC_DEMO_015',78,122,80,36.8,17,98,65.0,165,23.88,'Đau khớp gối phải, tê chân','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','FINAL','USR_DOC_10'),
('CE_DEMO_016','ENC_DEMO_016',82,128,84,36.9,18,97,68.0,170,23.53,'Tiểu nhiều, khát nước','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','FINAL','USR_DOC_01'),
('CE_DEMO_017','ENC_DEMO_017',70,115,75,36.5,16,99,58.0,162,22.1,'Đau bụng quanh rốn, buồn nôn','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','FINAL','USR_DOC_02'),
('CE_DEMO_018','ENC_DEMO_018',90,140,88,37.4,20,96,75.0,174,24.77,'Ho có đờm, đau ngực','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','FINAL','USR_DOC_03'),
('CE_DEMO_019','ENC_DEMO_019',76,120,78,36.7,16,98,63.0,167,22.59,'Mất ngủ, lo lắng','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','FINAL','USR_DOC_04'),
('CE_DEMO_020','ENC_DEMO_020',85,134,88,37.2,19,97,72.0,173,24.06,'Nổi mẩn ngứa toàn thân','Tiền sử không có gì đặc biệt','Toàn thân tỉnh táo, tiếp xúc tốt, không phát hiện bất thường khác','FINAL','USR_DOC_05')
ON CONFLICT (clinical_examinations_id) DO NOTHING;

COMMIT;
