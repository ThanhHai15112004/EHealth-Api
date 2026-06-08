-- =================================================================
-- 19_today_appointments_queue.sql
-- Demo data cho ngày 2026-05-19 — Portal Bác sĩ + Lễ tân
-- ~85 appointments today + 50 tomorrow + 20 encounters today
-- Idempotent (ON CONFLICT DO NOTHING)
--
-- Today (2026-05-19) breakdown:
--   25 CONFIRMED   — chờ check-in (lễ tân thấy)
--   20 CHECKED_IN  — đã check-in, queue 1-20 — hàng đợi bác sĩ
--   10 IN_PROGRESS — đang khám (started_at + checked_in_at SET)
--   20 COMPLETED   — đã xong khám sớm hôm nay
--    5 CANCELLED
--    5 NO_SHOW
-- Tomorrow (2026-05-20): 50 (25 CONFIRMED + 25 PENDING)
-- Encounters: 10 IN_PROGRESS (link APT_T19_046..055) + 10 COMPLETED (link APT_T19_056..065)
--
-- Dependencies: 01_core (users, doctors), 03_facilities (rooms, branches,
--   specialties), 05_scheduling (slots), 07_patients (patients)
-- =================================================================

BEGIN;

-- ------------------------------------------------------------------------
-- 1. APPOINTMENTS TODAY (2026-05-19) — 85 rows
-- ------------------------------------------------------------------------

-- 1A. CONFIRMED (25 rows) — chờ check-in tại lễ tân (8h-11h sáng)
INSERT INTO appointments (
    appointments_id, appointment_code, patient_id, doctor_id, slot_id,
    room_id, specialty_id, branch_id, appointment_date, booking_channel,
    reason_for_visit, status, priority, queue_number,
    confirmed_at, confirmed_by, checked_in_at, started_at, completed_at,
    symptoms_notes
) VALUES
('APT_T19_001','APP-T19-CONF-001','PAT_001','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'WEB','Khám tổng quát định kỳ','CONFIRMED','NORMAL',1,'2026-05-18 10:00:00+07','USR_DOC_01',NULL,NULL,NULL,'Mệt mỏi nhẹ vài ngày qua'),
('APT_T19_002','APP-T19-CONF-002','PAT_002','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-19'::date,'WEB','Khám nội tổng quát','CONFIRMED','NORMAL',2,'2026-05-18 10:15:00+07','USR_DOC_02',NULL,NULL,NULL,'Đau thượng vị sau ăn'),
('APT_T19_003','APP-T19-CONF-003','PAT_003','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-19'::date,'APP','Khám ngoại','CONFIRMED','NORMAL',3,'2026-05-18 10:30:00+07','USR_DOC_03',NULL,NULL,NULL,'Đau khớp gối phải'),
('APT_T19_004','APP-T19-CONF-004','PAT_004','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-19'::date,'APP','Khám nhi định kỳ','CONFIRMED','NORMAL',4,'2026-05-18 10:45:00+07','USR_DOC_04',NULL,NULL,NULL,'Bé sốt nhẹ ho khan'),
('APT_T19_005','APP-T19-CONF-005','PAT_005','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-19'::date,'APP','Khám sản phụ khoa','CONFIRMED','NORMAL',5,'2026-05-18 11:00:00+07','USR_DOC_05',NULL,NULL,NULL,'Khám thai định kỳ'),
('APT_T19_006','APP-T19-CONF-006','PAT_006','DOC_06',NULL,'ROOM_KB_01','SPC_CC','BR_MAIN','2026-05-19'::date,'HOTLINE','Khám cấp cứu nhẹ','CONFIRMED','HIGH',6,'2026-05-18 11:15:00+07','USR_DOC_06',NULL,NULL,NULL,'Đau bụng dữ dội đêm qua'),
('APT_T19_007','APP-T19-CONF-007','PAT_007','DOC_07',NULL,'ROOM_KB_02','SPC_XN','BR_MAIN','2026-05-19'::date,'HOTLINE','Xét nghiệm máu định kỳ','CONFIRMED','NORMAL',7,'2026-05-18 11:30:00+07','USR_DOC_07',NULL,NULL,NULL,'Theo dõi đường huyết'),
('APT_T19_008','APP-T19-CONF-008','PAT_008','DOC_08',NULL,'ROOM_KB_03','SPC_CDHA','BR_MAIN','2026-05-19'::date,'HOTLINE','Chẩn đoán hình ảnh','CONFIRMED','NORMAL',8,'2026-05-18 11:45:00+07','USR_DOC_08',NULL,NULL,NULL,'Đau lưng kéo dài, cần X-quang'),
('APT_T19_009','APP-T19-CONF-009','PAT_009','DOC_09',NULL,'ROOM_KB_04','SPC_HSCC','BR_MAIN','2026-05-19'::date,'WEB','Khám hồi sức','CONFIRMED','HIGH',9,'2026-05-18 12:00:00+07','USR_DOC_09',NULL,NULL,NULL,'Khó thở khi gắng sức'),
('APT_T19_010','APP-T19-CONF-010','PAT_010','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'WEB','Khám tổng quát','CONFIRMED','NORMAL',10,'2026-05-18 12:15:00+07','USR_DOC_10',NULL,NULL,NULL,'Kiểm tra sức khoẻ định kỳ'),
('APT_T19_011','APP-T19-CONF-011','PAT_011','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'APP','Tái khám','CONFIRMED','NORMAL',11,'2026-05-18 12:30:00+07','USR_DOC_01',NULL,NULL,NULL,'Tái khám sau đợt điều trị'),
('APT_T19_012','APP-T19-CONF-012','PAT_012','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-19'::date,'APP','Khám tim mạch','CONFIRMED','NORMAL',12,'2026-05-18 12:45:00+07','USR_DOC_02',NULL,NULL,NULL,'Hồi hộp đánh trống ngực'),
('APT_T19_013','APP-T19-CONF-013','PAT_013','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-19'::date,'APP','Khám chấn thương','CONFIRMED','NORMAL',13,'2026-05-18 13:00:00+07','USR_DOC_03',NULL,NULL,NULL,'Bong gân cổ chân'),
('APT_T19_014','APP-T19-CONF-014','PAT_014','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-19'::date,'ZALO','Khám nhi','CONFIRMED','NORMAL',14,'2026-05-18 13:15:00+07','USR_DOC_04',NULL,NULL,NULL,'Bé biếng ăn'),
('APT_T19_015','APP-T19-CONF-015','PAT_015','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-19'::date,'ZALO','Tư vấn tiền sản','CONFIRMED','NORMAL',15,'2026-05-18 13:30:00+07','USR_DOC_05',NULL,NULL,NULL,'Mang thai 28 tuần'),
('APT_T19_016','APP-T19-CONF-016','PAT_016','DOC_06',NULL,'ROOM_KB_01','SPC_CC','BR_MAIN','2026-05-19'::date,'DIRECT_CLINIC','Khám cấp cứu','CONFIRMED','URGENT',16,'2026-05-18 14:00:00+07','USR_DOC_06',NULL,NULL,NULL,'Chấn thương đầu nhẹ'),
('APT_T19_017','APP-T19-CONF-017','PAT_017','DOC_07',NULL,'ROOM_KB_02','SPC_XN','BR_MAIN','2026-05-19'::date,'DIRECT_CLINIC','Xét nghiệm','CONFIRMED','NORMAL',17,'2026-05-18 14:15:00+07','USR_DOC_07',NULL,NULL,NULL,'Tổng phân tích máu'),
('APT_T19_018','APP-T19-CONF-018','PAT_018','DOC_08',NULL,'ROOM_KB_03','SPC_CDHA','BR_MAIN','2026-05-19'::date,'DIRECT_CLINIC','Siêu âm bụng','CONFIRMED','NORMAL',18,'2026-05-18 14:30:00+07','USR_DOC_08',NULL,NULL,NULL,'Đau bụng dưới hạ sườn'),
('APT_T19_019','APP-T19-CONF-019','PAT_019','DOC_09',NULL,'ROOM_KB_04','SPC_HSCC','BR_MAIN','2026-05-19'::date,'WEB','Khám hồi sức','CONFIRMED','HIGH',19,'2026-05-18 14:45:00+07','USR_DOC_09',NULL,NULL,NULL,'Hậu phẫu theo dõi'),
('APT_T19_020','APP-T19-CONF-020','PAT_020','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'WEB','Khám tổng quát','CONFIRMED','NORMAL',20,'2026-05-18 15:00:00+07','USR_DOC_10',NULL,NULL,NULL,'Kiểm tra định kỳ'),
('APT_T19_021','APP-T19-CONF-021','PAT_021','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'APP','Khám tổng quát','CONFIRMED','NORMAL',21,'2026-05-18 15:15:00+07','USR_DOC_01',NULL,NULL,NULL,'Mất ngủ mãn tính'),
('APT_T19_022','APP-T19-CONF-022','PAT_022','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-19'::date,'APP','Khám nội','CONFIRMED','NORMAL',22,'2026-05-18 15:30:00+07','USR_DOC_02',NULL,NULL,NULL,'Đau dạ dày sau ăn'),
('APT_T19_023','APP-T19-CONF-023','PAT_023','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-19'::date,'APP','Khám ngoại','CONFIRMED','NORMAL',23,'2026-05-18 15:45:00+07','USR_DOC_03',NULL,NULL,NULL,'Đau vai gáy'),
('APT_T19_024','APP-T19-CONF-024','PAT_024','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-19'::date,'ZALO','Khám nhi','CONFIRMED','NORMAL',24,'2026-05-18 16:00:00+07','USR_DOC_04',NULL,NULL,NULL,'Bé ho khan hai ngày'),
('APT_T19_025','APP-T19-CONF-025','PAT_025','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-19'::date,'ZALO','Tái khám sản','CONFIRMED','NORMAL',25,'2026-05-18 16:15:00+07','USR_DOC_05',NULL,NULL,NULL,'Khám thai 32 tuần')
ON CONFLICT (appointments_id) DO NOTHING;

-- 1B. CHECKED_IN (20 rows) — đã check-in, queue 1-20, đang chờ bác sĩ
INSERT INTO appointments (
    appointments_id, appointment_code, patient_id, doctor_id, slot_id,
    room_id, specialty_id, branch_id, appointment_date, booking_channel,
    reason_for_visit, status, priority, queue_number,
    confirmed_at, confirmed_by, checked_in_at, started_at, completed_at,
    check_in_method, symptoms_notes
) VALUES
('APT_T19_026','APP-T19-CKIN-001','PAT_026','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'WEB','Khám tổng quát','CHECKED_IN','NORMAL',1,'2026-05-18 09:00:00+07','USR_DOC_01','2026-05-19 06:55:00+07',NULL,NULL,'QR','Sốt nhẹ, ho khan'),
('APT_T19_027','APP-T19-CKIN-002','PAT_027','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-19'::date,'APP','Khám nội','CHECKED_IN','NORMAL',2,'2026-05-18 09:15:00+07','USR_DOC_02','2026-05-19 06:58:00+07',NULL,NULL,'QR','Đau bụng âm ỉ'),
('APT_T19_028','APP-T19-CKIN-003','PAT_028','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-19'::date,'APP','Khám ngoại','CHECKED_IN','NORMAL',3,'2026-05-18 09:30:00+07','USR_DOC_03','2026-05-19 07:02:00+07',NULL,NULL,'MANUAL','Đau lưng dưới'),
('APT_T19_029','APP-T19-CKIN-004','PAT_029','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-19'::date,'APP','Khám nhi','CHECKED_IN','NORMAL',4,'2026-05-18 09:45:00+07','USR_DOC_04','2026-05-19 07:05:00+07',NULL,NULL,'KIOSK','Bé sốt 38.5 độ'),
('APT_T19_030','APP-T19-CKIN-005','PAT_030','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-19'::date,'HOTLINE','Khám sản','CHECKED_IN','NORMAL',5,'2026-05-18 10:00:00+07','USR_DOC_05','2026-05-19 07:10:00+07',NULL,NULL,'QR','Khám thai 24 tuần'),
('APT_T19_031','APP-T19-CKIN-006','PAT_031','DOC_06',NULL,'ROOM_KB_01','SPC_CC','BR_MAIN','2026-05-19'::date,'HOTLINE','Cấp cứu nhẹ','CHECKED_IN','HIGH',6,'2026-05-18 10:15:00+07','USR_DOC_06','2026-05-19 07:15:00+07',NULL,NULL,'MANUAL','Té ngã chấn thương'),
('APT_T19_032','APP-T19-CKIN-007','PAT_032','DOC_07',NULL,'ROOM_KB_02','SPC_XN','BR_MAIN','2026-05-19'::date,'HOTLINE','Xét nghiệm','CHECKED_IN','NORMAL',7,'2026-05-18 10:30:00+07','USR_DOC_07','2026-05-19 07:18:00+07',NULL,NULL,'QR','Tổng phân tích nước tiểu'),
('APT_T19_033','APP-T19-CKIN-008','PAT_033','DOC_08',NULL,'ROOM_KB_03','SPC_CDHA','BR_MAIN','2026-05-19'::date,'DIRECT_CLINIC','Siêu âm','CHECKED_IN','NORMAL',8,'2026-05-18 10:45:00+07','USR_DOC_08','2026-05-19 07:22:00+07',NULL,NULL,'KIOSK','Siêu âm ổ bụng'),
('APT_T19_034','APP-T19-CKIN-009','PAT_034','DOC_09',NULL,'ROOM_KB_04','SPC_HSCC','BR_MAIN','2026-05-19'::date,'DIRECT_CLINIC','Khám hồi sức','CHECKED_IN','HIGH',9,'2026-05-18 11:00:00+07','USR_DOC_09','2026-05-19 07:25:00+07',NULL,NULL,'MANUAL','Khó thở từng cơn'),
('APT_T19_035','APP-T19-CKIN-010','PAT_035','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'WEB','Khám tổng quát','CHECKED_IN','NORMAL',10,'2026-05-18 11:15:00+07','USR_DOC_10','2026-05-19 07:30:00+07',NULL,NULL,'QR','Kiểm tra sức khoẻ'),
('APT_T19_036','APP-T19-CKIN-011','PAT_036','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'APP','Tái khám','CHECKED_IN','NORMAL',11,'2026-05-18 11:30:00+07','USR_DOC_01','2026-05-19 07:35:00+07',NULL,NULL,'QR','Tái khám sau cảm cúm'),
('APT_T19_037','APP-T19-CKIN-012','PAT_037','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-19'::date,'APP','Khám tim mạch','CHECKED_IN','NORMAL',12,'2026-05-18 11:45:00+07','USR_DOC_02','2026-05-19 07:40:00+07',NULL,NULL,'KIOSK','Hồi hộp đêm khuya'),
('APT_T19_038','APP-T19-CKIN-013','PAT_038','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-19'::date,'WEB','Khám ngoại','CHECKED_IN','NORMAL',13,'2026-05-18 12:00:00+07','USR_DOC_03','2026-05-19 07:45:00+07',NULL,NULL,'MANUAL','Vết thương cũ tái phát'),
('APT_T19_039','APP-T19-CKIN-014','PAT_039','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-19'::date,'ZALO','Khám nhi','CHECKED_IN','NORMAL',14,'2026-05-18 12:15:00+07','USR_DOC_04','2026-05-19 07:50:00+07',NULL,NULL,'QR','Bé tiêu chảy'),
('APT_T19_040','APP-T19-CKIN-015','PAT_040','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-19'::date,'ZALO','Khám sản','CHECKED_IN','NORMAL',15,'2026-05-18 12:30:00+07','USR_DOC_05','2026-05-19 07:55:00+07',NULL,NULL,'QR','Khám thai 36 tuần'),
('APT_T19_041','APP-T19-CKIN-016','PAT_041','DOC_06',NULL,'ROOM_KB_01','SPC_CC','BR_MAIN','2026-05-19'::date,'HOTLINE','Cấp cứu','CHECKED_IN','URGENT',16,'2026-05-18 12:45:00+07','USR_DOC_06','2026-05-19 08:00:00+07',NULL,NULL,'MANUAL','Đau ngực dữ dội'),
('APT_T19_042','APP-T19-CKIN-017','PAT_042','DOC_07',NULL,'ROOM_KB_02','SPC_XN','BR_MAIN','2026-05-19'::date,'HOTLINE','Xét nghiệm','CHECKED_IN','NORMAL',17,'2026-05-18 13:00:00+07','USR_DOC_07','2026-05-19 08:05:00+07',NULL,NULL,'KIOSK','Xét nghiệm sinh hoá'),
('APT_T19_043','APP-T19-CKIN-018','PAT_043','DOC_08',NULL,'ROOM_KB_03','SPC_CDHA','BR_MAIN','2026-05-19'::date,'DIRECT_CLINIC','Chụp X-quang','CHECKED_IN','NORMAL',18,'2026-05-18 13:15:00+07','USR_DOC_08','2026-05-19 08:10:00+07',NULL,NULL,'QR','Đau ngực, cần chụp phổi'),
('APT_T19_044','APP-T19-CKIN-019','PAT_044','DOC_09',NULL,'ROOM_KB_04','SPC_HSCC','BR_MAIN','2026-05-19'::date,'WEB','Khám hồi sức','CHECKED_IN','HIGH',19,'2026-05-18 13:30:00+07','USR_DOC_09','2026-05-19 08:15:00+07',NULL,NULL,'MANUAL','Hậu phẫu theo dõi sát'),
('APT_T19_045','APP-T19-CKIN-020','PAT_045','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'WEB','Khám tổng quát','CHECKED_IN','NORMAL',20,'2026-05-18 13:45:00+07','USR_DOC_10','2026-05-19 08:20:00+07',NULL,NULL,'QR','Khám sức khoẻ tổng quát')
ON CONFLICT (appointments_id) DO NOTHING;

-- 1C. IN_PROGRESS (10 rows) — đang khám, started_at + checked_in_at SET
INSERT INTO appointments (
    appointments_id, appointment_code, patient_id, doctor_id, slot_id,
    room_id, specialty_id, branch_id, appointment_date, booking_channel,
    reason_for_visit, status, priority, queue_number,
    confirmed_at, confirmed_by, checked_in_at, started_at, completed_at,
    check_in_method, symptoms_notes
) VALUES
('APT_T19_046','APP-T19-PROG-001','PAT_046','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'WEB','Khám tổng quát','IN_PROGRESS','NORMAL',21,'2026-05-18 09:00:00+07','USR_DOC_01','2026-05-19 08:00:00+07','2026-05-19 08:30:00+07',NULL,'QR','Đau đầu kéo dài'),
('APT_T19_047','APP-T19-PROG-002','PAT_047','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-19'::date,'APP','Khám nội','IN_PROGRESS','NORMAL',22,'2026-05-18 09:15:00+07','USR_DOC_02','2026-05-19 08:05:00+07','2026-05-19 08:35:00+07',NULL,'QR','Đau dạ dày mãn tính'),
('APT_T19_048','APP-T19-PROG-003','PAT_048','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-19'::date,'APP','Khám ngoại','IN_PROGRESS','NORMAL',23,'2026-05-18 09:30:00+07','USR_DOC_03','2026-05-19 08:10:00+07','2026-05-19 08:40:00+07',NULL,'MANUAL','Đau khớp gối lâu ngày'),
('APT_T19_049','APP-T19-PROG-004','PAT_049','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-19'::date,'APP','Khám nhi','IN_PROGRESS','NORMAL',24,'2026-05-18 09:45:00+07','USR_DOC_04','2026-05-19 08:15:00+07','2026-05-19 08:45:00+07',NULL,'KIOSK','Bé viêm họng'),
('APT_T19_050','APP-T19-PROG-005','PAT_050','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-19'::date,'HOTLINE','Khám sản','IN_PROGRESS','NORMAL',25,'2026-05-18 10:00:00+07','USR_DOC_05','2026-05-19 08:20:00+07','2026-05-19 08:50:00+07',NULL,'QR','Khám thai 30 tuần'),
('APT_T19_051','APP-T19-PROG-006','PAT_051','DOC_06',NULL,'ROOM_KB_01','SPC_CC','BR_MAIN','2026-05-19'::date,'HOTLINE','Cấp cứu','IN_PROGRESS','URGENT',26,'2026-05-18 10:15:00+07','USR_DOC_06','2026-05-19 08:25:00+07','2026-05-19 08:55:00+07',NULL,'MANUAL','Chấn thương lao động'),
('APT_T19_052','APP-T19-PROG-007','PAT_052','DOC_07',NULL,'ROOM_KB_02','SPC_XN','BR_MAIN','2026-05-19'::date,'HOTLINE','Lấy mẫu máu','IN_PROGRESS','NORMAL',27,'2026-05-18 10:30:00+07','USR_DOC_07','2026-05-19 08:30:00+07','2026-05-19 09:00:00+07',NULL,'QR','Xét nghiệm tiền phẫu'),
('APT_T19_053','APP-T19-PROG-008','PAT_053','DOC_08',NULL,'ROOM_KB_03','SPC_CDHA','BR_MAIN','2026-05-19'::date,'DIRECT_CLINIC','Siêu âm tim','IN_PROGRESS','HIGH',28,'2026-05-18 10:45:00+07','USR_DOC_08','2026-05-19 08:35:00+07','2026-05-19 09:05:00+07',NULL,'KIOSK','Hồi hộp khó thở'),
('APT_T19_054','APP-T19-PROG-009','PAT_054','DOC_09',NULL,'ROOM_KB_04','SPC_HSCC','BR_MAIN','2026-05-19'::date,'WEB','Khám hồi sức','IN_PROGRESS','HIGH',29,'2026-05-18 11:00:00+07','USR_DOC_09','2026-05-19 08:40:00+07','2026-05-19 09:10:00+07',NULL,'MANUAL','Theo dõi sau xuất viện'),
('APT_T19_055','APP-T19-PROG-010','PAT_055','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'WEB','Khám tổng quát','IN_PROGRESS','NORMAL',30,'2026-05-18 11:15:00+07','USR_DOC_10','2026-05-19 08:45:00+07','2026-05-19 09:15:00+07',NULL,'QR','Mệt mỏi mãn tính')
ON CONFLICT (appointments_id) DO NOTHING;

-- 1D. COMPLETED (20 rows) — đã khám xong sáng nay
INSERT INTO appointments (
    appointments_id, appointment_code, patient_id, doctor_id, slot_id,
    room_id, specialty_id, branch_id, appointment_date, booking_channel,
    reason_for_visit, status, priority, queue_number,
    confirmed_at, confirmed_by, checked_in_at, started_at, completed_at,
    check_in_method, symptoms_notes
) VALUES
('APT_T19_056','APP-T19-DONE-001','PAT_056','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'WEB','Khám tổng quát','COMPLETED','NORMAL',31,'2026-05-18 08:00:00+07','USR_DOC_01','2026-05-19 06:30:00+07','2026-05-19 06:50:00+07','2026-05-19 07:15:00+07','QR','Khám sức khoẻ định kỳ'),
('APT_T19_057','APP-T19-DONE-002','PAT_057','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-19'::date,'APP','Khám nội','COMPLETED','NORMAL',32,'2026-05-18 08:15:00+07','USR_DOC_02','2026-05-19 06:35:00+07','2026-05-19 06:55:00+07','2026-05-19 07:20:00+07','QR','Đau dạ dày'),
('APT_T19_058','APP-T19-DONE-003','PAT_058','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-19'::date,'APP','Khám ngoại','COMPLETED','NORMAL',33,'2026-05-18 08:30:00+07','USR_DOC_03','2026-05-19 06:40:00+07','2026-05-19 07:00:00+07','2026-05-19 07:25:00+07','MANUAL','Đau lưng'),
('APT_T19_059','APP-T19-DONE-004','PAT_059','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-19'::date,'APP','Khám nhi','COMPLETED','NORMAL',34,'2026-05-18 08:45:00+07','USR_DOC_04','2026-05-19 06:45:00+07','2026-05-19 07:05:00+07','2026-05-19 07:30:00+07','KIOSK','Bé sốt phát ban'),
('APT_T19_060','APP-T19-DONE-005','PAT_060','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-19'::date,'HOTLINE','Khám sản','COMPLETED','NORMAL',35,'2026-05-18 09:00:00+07','USR_DOC_05','2026-05-19 06:50:00+07','2026-05-19 07:10:00+07','2026-05-19 07:35:00+07','QR','Tư vấn tiền sản'),
('APT_T19_061','APP-T19-DONE-006','PAT_061','DOC_06',NULL,'ROOM_KB_01','SPC_CC','BR_MAIN','2026-05-19'::date,'HOTLINE','Cấp cứu nhẹ','COMPLETED','HIGH',36,'2026-05-18 09:15:00+07','USR_DOC_06','2026-05-19 06:55:00+07','2026-05-19 07:15:00+07','2026-05-19 07:40:00+07','MANUAL','Xây xát nhẹ'),
('APT_T19_062','APP-T19-DONE-007','PAT_062','DOC_07',NULL,'ROOM_KB_02','SPC_XN','BR_MAIN','2026-05-19'::date,'HOTLINE','Xét nghiệm','COMPLETED','NORMAL',37,'2026-05-18 09:30:00+07','USR_DOC_07','2026-05-19 07:00:00+07','2026-05-19 07:20:00+07','2026-05-19 07:40:00+07','QR','Xét nghiệm máu định kỳ'),
('APT_T19_063','APP-T19-DONE-008','PAT_063','DOC_08',NULL,'ROOM_KB_03','SPC_CDHA','BR_MAIN','2026-05-19'::date,'DIRECT_CLINIC','Siêu âm','COMPLETED','NORMAL',38,'2026-05-18 09:45:00+07','USR_DOC_08','2026-05-19 07:05:00+07','2026-05-19 07:25:00+07','2026-05-19 07:50:00+07','KIOSK','Siêu âm bụng'),
('APT_T19_064','APP-T19-DONE-009','PAT_064','DOC_09',NULL,'ROOM_KB_04','SPC_HSCC','BR_MAIN','2026-05-19'::date,'WEB','Khám hồi sức','COMPLETED','HIGH',39,'2026-05-18 10:00:00+07','USR_DOC_09','2026-05-19 07:10:00+07','2026-05-19 07:30:00+07','2026-05-19 07:55:00+07','MANUAL','Theo dõi sau mổ'),
('APT_T19_065','APP-T19-DONE-010','PAT_065','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'WEB','Khám tổng quát','COMPLETED','NORMAL',40,'2026-05-18 10:15:00+07','USR_DOC_10','2026-05-19 07:15:00+07','2026-05-19 07:35:00+07','2026-05-19 08:00:00+07','QR','Kiểm tra sức khoẻ'),
('APT_T19_066','APP-T19-DONE-011','PAT_066','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'APP','Tái khám','COMPLETED','NORMAL',41,'2026-05-18 10:30:00+07','USR_DOC_01','2026-05-19 07:20:00+07','2026-05-19 07:40:00+07','2026-05-19 08:05:00+07','QR','Tái khám sau điều trị'),
('APT_T19_067','APP-T19-DONE-012','PAT_067','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-19'::date,'APP','Khám nội','COMPLETED','NORMAL',42,'2026-05-18 10:45:00+07','USR_DOC_02','2026-05-19 07:25:00+07','2026-05-19 07:45:00+07','2026-05-19 08:10:00+07','KIOSK','Đau bụng âm ỉ'),
('APT_T19_068','APP-T19-DONE-013','PAT_068','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-19'::date,'WEB','Khám ngoại','COMPLETED','NORMAL',43,'2026-05-18 11:00:00+07','USR_DOC_03','2026-05-19 07:30:00+07','2026-05-19 07:50:00+07','2026-05-19 08:15:00+07','MANUAL','Chấn thương tay'),
('APT_T19_069','APP-T19-DONE-014','PAT_069','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-19'::date,'ZALO','Khám nhi','COMPLETED','NORMAL',44,'2026-05-18 11:15:00+07','USR_DOC_04','2026-05-19 07:35:00+07','2026-05-19 07:55:00+07','2026-05-19 08:20:00+07','QR','Bé viêm tai giữa'),
('APT_T19_070','APP-T19-DONE-015','PAT_070','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-19'::date,'ZALO','Khám sản','COMPLETED','NORMAL',45,'2026-05-18 11:30:00+07','USR_DOC_05','2026-05-19 07:40:00+07','2026-05-19 08:00:00+07','2026-05-19 08:25:00+07','QR','Khám thai định kỳ'),
('APT_T19_071','APP-T19-DONE-016','PAT_071','DOC_06',NULL,'ROOM_KB_01','SPC_CC','BR_MAIN','2026-05-19'::date,'HOTLINE','Cấp cứu','COMPLETED','URGENT',46,'2026-05-18 11:45:00+07','USR_DOC_06','2026-05-19 07:45:00+07','2026-05-19 08:05:00+07','2026-05-19 08:30:00+07','MANUAL','Phản vệ nhẹ'),
('APT_T19_072','APP-T19-DONE-017','PAT_072','DOC_07',NULL,'ROOM_KB_02','SPC_XN','BR_MAIN','2026-05-19'::date,'HOTLINE','Xét nghiệm','COMPLETED','NORMAL',47,'2026-05-18 12:00:00+07','USR_DOC_07','2026-05-19 07:50:00+07','2026-05-19 08:10:00+07','2026-05-19 08:35:00+07','KIOSK','Tổng phân tích máu'),
('APT_T19_073','APP-T19-DONE-018','PAT_073','DOC_08',NULL,'ROOM_KB_03','SPC_CDHA','BR_MAIN','2026-05-19'::date,'DIRECT_CLINIC','X-quang','COMPLETED','NORMAL',48,'2026-05-18 12:15:00+07','USR_DOC_08','2026-05-19 07:55:00+07','2026-05-19 08:15:00+07','2026-05-19 08:40:00+07','QR','Đau ngực, chụp phổi'),
('APT_T19_074','APP-T19-DONE-019','PAT_074','DOC_09',NULL,'ROOM_KB_04','SPC_HSCC','BR_MAIN','2026-05-19'::date,'WEB','Khám hồi sức','COMPLETED','HIGH',49,'2026-05-18 12:30:00+07','USR_DOC_09','2026-05-19 08:00:00+07','2026-05-19 08:20:00+07','2026-05-19 08:45:00+07','MANUAL','Theo dõi suy tim'),
('APT_T19_075','APP-T19-DONE-020','PAT_075','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'WEB','Khám tổng quát','COMPLETED','NORMAL',50,'2026-05-18 12:45:00+07','USR_DOC_10','2026-05-19 08:05:00+07','2026-05-19 08:25:00+07','2026-05-19 08:50:00+07','QR','Kiểm tra sức khoẻ')
ON CONFLICT (appointments_id) DO NOTHING;

-- 1E. CANCELLED (5 rows)
INSERT INTO appointments (
    appointments_id, appointment_code, patient_id, doctor_id, slot_id,
    room_id, specialty_id, branch_id, appointment_date, booking_channel,
    reason_for_visit, status, priority, queue_number,
    confirmed_at, confirmed_by, cancelled_at, cancellation_reason, cancelled_by,
    symptoms_notes
) VALUES
('APT_T19_076','APP-T19-CNCL-001','PAT_076','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'ZALO','Khám tổng quát','CANCELLED','NORMAL',NULL,'2026-05-18 09:00:00+07','USR_DOC_01','2026-05-18 18:00:00+07','Bệnh nhân bận đột xuất','USR_DOC_01','Đã huỷ qua zalo'),
('APT_T19_077','APP-T19-CNCL-002','PAT_077','DOC_03',NULL,'ROOM_KB_02','SPC_NGOAI','BR_MAIN','2026-05-19'::date,'ZALO','Khám ngoại','CANCELLED','NORMAL',NULL,'2026-05-18 09:15:00+07','USR_DOC_03','2026-05-18 19:00:00+07','Hết triệu chứng, không cần khám','USR_DOC_03','Đã hồi phục'),
('APT_T19_078','APP-T19-CNCL-003','PAT_078','DOC_05',NULL,'ROOM_KB_03','SPC_SAN','BR_MAIN','2026-05-19'::date,'APP','Khám sản','CANCELLED','NORMAL',NULL,'2026-05-18 09:30:00+07','USR_DOC_05','2026-05-19 05:00:00+07','Đổi lịch sang tuần sau','USR_DOC_05','Yêu cầu dời lịch'),
('APT_T19_079','APP-T19-CNCL-004','PAT_079','DOC_07',NULL,'ROOM_KB_04','SPC_XN','BR_MAIN','2026-05-19'::date,'WEB','Xét nghiệm','CANCELLED','NORMAL',NULL,'2026-05-18 09:45:00+07','USR_DOC_07','2026-05-19 06:00:00+07','Bệnh nhân ốm không đến được','USR_DOC_07','Báo huỷ sáng nay'),
('APT_T19_080','APP-T19-CNCL-005','PAT_080','DOC_09',NULL,'ROOM_KB_05','SPC_HSCC','BR_MAIN','2026-05-19'::date,'HOTLINE','Khám hồi sức','CANCELLED','HIGH',NULL,'2026-05-18 10:00:00+07','USR_DOC_09','2026-05-19 07:00:00+07','Chuyển viện khẩn cấp','USR_DOC_09','Đã chuyển lên tuyến trên')
ON CONFLICT (appointments_id) DO NOTHING;

-- 1F. NO_SHOW (5 rows) — đã đặt, không tới khám
INSERT INTO appointments (
    appointments_id, appointment_code, patient_id, doctor_id, slot_id,
    room_id, specialty_id, branch_id, appointment_date, booking_channel,
    reason_for_visit, status, priority, queue_number,
    confirmed_at, confirmed_by, symptoms_notes
) VALUES
('APT_T19_081','APP-T19-NOSH-001','PAT_081','DOC_02',NULL,'ROOM_KB_01','SPC_NOI','BR_MAIN','2026-05-19'::date,'WEB','Khám nội','NO_SHOW','NORMAL',NULL,'2026-05-18 08:00:00+07','USR_DOC_02','Không tới khám, không báo trước'),
('APT_T19_082','APP-T19-NOSH-002','PAT_082','DOC_04',NULL,'ROOM_KB_02','SPC_NHI','BR_MAIN','2026-05-19'::date,'APP','Khám nhi','NO_SHOW','NORMAL',NULL,'2026-05-18 08:15:00+07','USR_DOC_04','Bé không đến khám'),
('APT_T19_083','APP-T19-NOSH-003','PAT_083','DOC_06',NULL,'ROOM_KB_03','SPC_CC','BR_MAIN','2026-05-19'::date,'HOTLINE','Cấp cứu nhẹ','NO_SHOW','HIGH',NULL,'2026-05-18 08:30:00+07','USR_DOC_06','Không tới, không liên lạc được'),
('APT_T19_084','APP-T19-NOSH-004','PAT_084','DOC_08',NULL,'ROOM_KB_04','SPC_CDHA','BR_MAIN','2026-05-19'::date,'DIRECT_CLINIC','Siêu âm','NO_SHOW','NORMAL',NULL,'2026-05-18 08:45:00+07','USR_DOC_08','Vắng mặt không lý do'),
('APT_T19_085','APP-T19-NOSH-005','PAT_085','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-19'::date,'WEB','Khám tổng quát','NO_SHOW','NORMAL',NULL,'2026-05-18 09:00:00+07','USR_DOC_10','Không đến khám')
ON CONFLICT (appointments_id) DO NOTHING;

-- ------------------------------------------------------------------------
-- 2. APPOINTMENTS TOMORROW (2026-05-20) — 50 rows (25 CONFIRMED + 25 PENDING)
-- ------------------------------------------------------------------------

-- 2A. CONFIRMED tomorrow (25 rows)
INSERT INTO appointments (
    appointments_id, appointment_code, patient_id, doctor_id, slot_id,
    room_id, specialty_id, branch_id, appointment_date, booking_channel,
    reason_for_visit, status, priority, queue_number,
    confirmed_at, confirmed_by, symptoms_notes
) VALUES
('APT_T19_086','APP-T20-CONF-001','PAT_086','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-20'::date,'WEB','Khám tổng quát','CONFIRMED','NORMAL',1,'2026-05-18 09:00:00+07','USR_DOC_01','Khám sức khoẻ định kỳ'),
('APT_T19_087','APP-T20-CONF-002','PAT_087','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-20'::date,'APP','Khám nội','CONFIRMED','NORMAL',2,'2026-05-18 09:15:00+07','USR_DOC_02','Đau dạ dày mãn'),
('APT_T19_088','APP-T20-CONF-003','PAT_088','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-20'::date,'APP','Khám ngoại','CONFIRMED','NORMAL',3,'2026-05-18 09:30:00+07','USR_DOC_03','Đau khớp'),
('APT_T19_089','APP-T20-CONF-004','PAT_089','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-20'::date,'APP','Khám nhi','CONFIRMED','NORMAL',4,'2026-05-18 09:45:00+07','USR_DOC_04','Bé sốt'),
('APT_T19_090','APP-T20-CONF-005','PAT_090','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-20'::date,'HOTLINE','Khám sản','CONFIRMED','NORMAL',5,'2026-05-18 10:00:00+07','USR_DOC_05','Khám thai 26 tuần'),
('APT_T19_091','APP-T20-CONF-006','PAT_091','DOC_06',NULL,'ROOM_KB_01','SPC_CC','BR_MAIN','2026-05-20'::date,'HOTLINE','Cấp cứu nhẹ','CONFIRMED','HIGH',6,'2026-05-18 10:15:00+07','USR_DOC_06','Chấn thương nhẹ'),
('APT_T19_092','APP-T20-CONF-007','PAT_092','DOC_07',NULL,'ROOM_KB_02','SPC_XN','BR_MAIN','2026-05-20'::date,'HOTLINE','Xét nghiệm','CONFIRMED','NORMAL',7,'2026-05-18 10:30:00+07','USR_DOC_07','Kiểm tra mỡ máu'),
('APT_T19_093','APP-T20-CONF-008','PAT_093','DOC_08',NULL,'ROOM_KB_03','SPC_CDHA','BR_MAIN','2026-05-20'::date,'DIRECT_CLINIC','Siêu âm','CONFIRMED','NORMAL',8,'2026-05-18 10:45:00+07','USR_DOC_08','Siêu âm tuyến giáp'),
('APT_T19_094','APP-T20-CONF-009','PAT_094','DOC_09',NULL,'ROOM_KB_04','SPC_HSCC','BR_MAIN','2026-05-20'::date,'WEB','Khám hồi sức','CONFIRMED','HIGH',9,'2026-05-18 11:00:00+07','USR_DOC_09','Theo dõi tim mạch'),
('APT_T19_095','APP-T20-CONF-010','PAT_095','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-20'::date,'WEB','Khám tổng quát','CONFIRMED','NORMAL',10,'2026-05-18 11:15:00+07','USR_DOC_10','Khám định kỳ'),
('APT_T19_096','APP-T20-CONF-011','PAT_096','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-20'::date,'APP','Tái khám','CONFIRMED','NORMAL',11,'2026-05-18 11:30:00+07','USR_DOC_01','Tái khám sau điều trị'),
('APT_T19_097','APP-T20-CONF-012','PAT_097','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-20'::date,'APP','Khám tim mạch','CONFIRMED','NORMAL',12,'2026-05-18 11:45:00+07','USR_DOC_02','Cao huyết áp'),
('APT_T19_098','APP-T20-CONF-013','PAT_098','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-20'::date,'APP','Khám ngoại','CONFIRMED','NORMAL',13,'2026-05-18 12:00:00+07','USR_DOC_03','Sưng đau vai'),
('APT_T19_099','APP-T20-CONF-014','PAT_099','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-20'::date,'ZALO','Khám nhi','CONFIRMED','NORMAL',14,'2026-05-18 12:15:00+07','USR_DOC_04','Bé ho dai dẳng'),
('APT_T19_100','APP-T20-CONF-015','PAT_100','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-20'::date,'ZALO','Khám sản','CONFIRMED','NORMAL',15,'2026-05-18 12:30:00+07','USR_DOC_05','Khám thai 34 tuần'),
('APT_T19_101','APP-T20-CONF-016','PAT_SEED_1001','DOC_06',NULL,'ROOM_KB_01','SPC_CC','BR_MAIN','2026-05-20'::date,'HOTLINE','Cấp cứu','CONFIRMED','URGENT',16,'2026-05-18 12:45:00+07','USR_DOC_06','Chấn thương tay'),
('APT_T19_102','APP-T20-CONF-017','PAT_SEED_1002','DOC_07',NULL,'ROOM_KB_02','SPC_XN','BR_MAIN','2026-05-20'::date,'HOTLINE','Xét nghiệm','CONFIRMED','NORMAL',17,'2026-05-18 13:00:00+07','USR_DOC_07','Xét nghiệm gan'),
('APT_T19_103','APP-T20-CONF-018','PAT_SEED_1003','DOC_08',NULL,'ROOM_KB_03','SPC_CDHA','BR_MAIN','2026-05-20'::date,'DIRECT_CLINIC','X-quang','CONFIRMED','NORMAL',18,'2026-05-18 13:15:00+07','USR_DOC_08','Đau lưng cần chụp'),
('APT_T19_104','APP-T20-CONF-019','PAT_SEED_1004','DOC_09',NULL,'ROOM_KB_04','SPC_HSCC','BR_MAIN','2026-05-20'::date,'WEB','Khám hồi sức','CONFIRMED','HIGH',19,'2026-05-18 13:30:00+07','USR_DOC_09','Hậu phẫu theo dõi'),
('APT_T19_105','APP-T20-CONF-020','PAT_SEED_1005','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-20'::date,'WEB','Khám tổng quát','CONFIRMED','NORMAL',20,'2026-05-18 13:45:00+07','USR_DOC_10','Mệt mỏi kéo dài'),
('APT_T19_106','APP-T20-CONF-021','PAT_SEED_1006','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-20'::date,'APP','Khám tổng quát','CONFIRMED','NORMAL',21,'2026-05-18 14:00:00+07','USR_DOC_01','Mất ngủ lo âu'),
('APT_T19_107','APP-T20-CONF-022','PAT_SEED_1007','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-20'::date,'APP','Khám nội','CONFIRMED','NORMAL',22,'2026-05-18 14:15:00+07','USR_DOC_02','Tiểu đường theo dõi'),
('APT_T19_108','APP-T20-CONF-023','PAT_SEED_1008','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-20'::date,'APP','Khám ngoại','CONFIRMED','NORMAL',23,'2026-05-18 14:30:00+07','USR_DOC_03','Đau khớp háng'),
('APT_T19_109','APP-T20-CONF-024','PAT_SEED_1009','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-20'::date,'ZALO','Khám nhi','CONFIRMED','NORMAL',24,'2026-05-18 14:45:00+07','USR_DOC_04','Bé tiêu chảy nhẹ'),
('APT_T19_110','APP-T20-CONF-025','PAT_SEED_1010','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-20'::date,'ZALO','Khám sản','CONFIRMED','NORMAL',25,'2026-05-18 15:00:00+07','USR_DOC_05','Khám tiền sinh')
ON CONFLICT (appointments_id) DO NOTHING;

-- 2B. PENDING tomorrow (25 rows) — chưa xác nhận
INSERT INTO appointments (
    appointments_id, appointment_code, patient_id, doctor_id, slot_id,
    room_id, specialty_id, branch_id, appointment_date, booking_channel,
    reason_for_visit, status, priority, queue_number, symptoms_notes
) VALUES
('APT_T19_111','APP-T20-PEND-001','PAT_SEED_1011','DOC_06',NULL,'ROOM_KB_01','SPC_CC','BR_MAIN','2026-05-20'::date,'WEB','Khám cấp cứu nhẹ','PENDING','HIGH',26,'Đau bụng cấp'),
('APT_T19_112','APP-T20-PEND-002','PAT_SEED_1012','DOC_07',NULL,'ROOM_KB_02','SPC_XN','BR_MAIN','2026-05-20'::date,'WEB','Xét nghiệm','PENDING','NORMAL',27,'Tổng phân tích máu'),
('APT_T19_113','APP-T20-PEND-003','PAT_SEED_1013','DOC_08',NULL,'ROOM_KB_03','SPC_CDHA','BR_MAIN','2026-05-20'::date,'WEB','Siêu âm','PENDING','NORMAL',28,'Siêu âm bụng'),
('APT_T19_114','APP-T20-PEND-004','PAT_SEED_1014','DOC_09',NULL,'ROOM_KB_04','SPC_HSCC','BR_MAIN','2026-05-20'::date,'WEB','Khám hồi sức','PENDING','HIGH',29,'Theo dõi tim'),
('APT_T19_115','APP-T20-PEND-005','PAT_SEED_1015','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-20'::date,'APP','Khám tổng quát','PENDING','NORMAL',30,'Khám định kỳ'),
('APT_T19_116','APP-T20-PEND-006','PAT_SEED_1016','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-20'::date,'APP','Khám tổng quát','PENDING','NORMAL',31,'Mệt mỏi'),
('APT_T19_117','APP-T20-PEND-007','PAT_SEED_1017','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-20'::date,'APP','Khám nội','PENDING','NORMAL',32,'Đau dạ dày'),
('APT_T19_118','APP-T20-PEND-008','PAT_SEED_1018','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-20'::date,'APP','Khám ngoại','PENDING','NORMAL',33,'Đau khớp gối'),
('APT_T19_119','APP-T20-PEND-009','PAT_SEED_1019','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-20'::date,'ZALO','Khám nhi','PENDING','NORMAL',34,'Bé biếng ăn'),
('APT_T19_120','APP-T20-PEND-010','PAT_SEED_1020','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-20'::date,'ZALO','Khám sản','PENDING','NORMAL',35,'Khám thai'),
('APT_T19_121','APP-T20-PEND-011','PAT_SEED_1021','DOC_06',NULL,'ROOM_KB_01','SPC_CC','BR_MAIN','2026-05-20'::date,'HOTLINE','Cấp cứu nhẹ','PENDING','HIGH',36,'Chấn thương đầu'),
('APT_T19_122','APP-T20-PEND-012','PAT_SEED_1022','DOC_07',NULL,'ROOM_KB_02','SPC_XN','BR_MAIN','2026-05-20'::date,'HOTLINE','Xét nghiệm','PENDING','NORMAL',37,'Xét nghiệm nước tiểu'),
('APT_T19_123','APP-T20-PEND-013','PAT_SEED_1023','DOC_08',NULL,'ROOM_KB_03','SPC_CDHA','BR_MAIN','2026-05-20'::date,'DIRECT_CLINIC','Siêu âm','PENDING','NORMAL',38,'Siêu âm tim'),
('APT_T19_124','APP-T20-PEND-014','PAT_SEED_1024','DOC_09',NULL,'ROOM_KB_04','SPC_HSCC','BR_MAIN','2026-05-20'::date,'WEB','Khám hồi sức','PENDING','HIGH',39,'Khó thở'),
('APT_T19_125','APP-T20-PEND-015','PAT_SEED_1025','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-20'::date,'WEB','Khám tổng quát','PENDING','NORMAL',40,'Khám sức khoẻ'),
('APT_T19_126','APP-T20-PEND-016','PAT_SEED_1026','DOC_01',NULL,'ROOM_KB_01','SPC_TONG_QUAT','BR_MAIN','2026-05-20'::date,'APP','Tái khám','PENDING','NORMAL',41,'Tái khám'),
('APT_T19_127','APP-T20-PEND-017','PAT_SEED_1027','DOC_02',NULL,'ROOM_KB_02','SPC_NOI','BR_MAIN','2026-05-20'::date,'APP','Khám nội','PENDING','NORMAL',42,'Đau ngực âm ỉ'),
('APT_T19_128','APP-T20-PEND-018','PAT_SEED_1028','DOC_03',NULL,'ROOM_KB_03','SPC_NGOAI','BR_MAIN','2026-05-20'::date,'APP','Khám ngoại','PENDING','NORMAL',43,'Chấn thương cũ'),
('APT_T19_129','APP-T20-PEND-019','PAT_SEED_1029','DOC_04',NULL,'ROOM_KB_04','SPC_NHI','BR_MAIN','2026-05-20'::date,'ZALO','Khám nhi','PENDING','NORMAL',44,'Bé viêm họng'),
('APT_T19_130','APP-T20-PEND-020','PAT_SEED_1030','DOC_05',NULL,'ROOM_KB_05','SPC_SAN','BR_MAIN','2026-05-20'::date,'ZALO','Khám sản','PENDING','NORMAL',45,'Khám thai 28 tuần'),
('APT_T19_131','APP-T20-PEND-021','PAT_SEED_1031','DOC_06',NULL,'ROOM_KB_01','SPC_CC','BR_MAIN','2026-05-20'::date,'HOTLINE','Cấp cứu','PENDING','URGENT',46,'Đau ngực dữ dội'),
('APT_T19_132','APP-T20-PEND-022','PAT_SEED_1032','DOC_07',NULL,'ROOM_KB_02','SPC_XN','BR_MAIN','2026-05-20'::date,'HOTLINE','Xét nghiệm','PENDING','NORMAL',47,'Xét nghiệm tổng quát'),
('APT_T19_133','APP-T20-PEND-023','PAT_SEED_1033','DOC_08',NULL,'ROOM_KB_03','SPC_CDHA','BR_MAIN','2026-05-20'::date,'DIRECT_CLINIC','Chụp CT','PENDING','HIGH',48,'Đau đầu kéo dài'),
('APT_T19_134','APP-T20-PEND-024','PAT_SEED_1034','DOC_09',NULL,'ROOM_KB_04','SPC_HSCC','BR_MAIN','2026-05-20'::date,'WEB','Khám hồi sức','PENDING','HIGH',49,'Hậu phẫu theo dõi'),
('APT_T19_135','APP-T20-PEND-025','PAT_SEED_1035','DOC_10',NULL,'ROOM_KB_05','SPC_TONG_QUAT','BR_MAIN','2026-05-20'::date,'WEB','Khám tổng quát','PENDING','NORMAL',50,'Khám sức khoẻ tổng quát')
ON CONFLICT (appointments_id) DO NOTHING;

-- ------------------------------------------------------------------------
-- 3. ENCOUNTERS — 20 rows (10 IN_PROGRESS + 10 COMPLETED cho today)
--    Link: APT_T19_046..055 (IN_PROGRESS) + APT_T19_056..065 (COMPLETED)
-- ------------------------------------------------------------------------
INSERT INTO encounters (
    encounters_id, appointment_id, patient_id, doctor_id, room_id,
    encounter_type, visit_number, start_time, end_time, status, notes
) VALUES
-- IN_PROGRESS encounters (link tới appointments IN_PROGRESS)
('ENC_T19_001','APT_T19_046','PAT_046','DOC_01','ROOM_KB_01','OUTPATIENT',1,'2026-05-19 08:30:00+07',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_T19_002','APT_T19_047','PAT_047','DOC_02','ROOM_KB_02','OUTPATIENT',2,'2026-05-19 08:35:00+07',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_T19_003','APT_T19_048','PAT_048','DOC_03','ROOM_KB_03','OUTPATIENT',1,'2026-05-19 08:40:00+07',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_T19_004','APT_T19_049','PAT_049','DOC_04','ROOM_KB_04','OUTPATIENT',1,'2026-05-19 08:45:00+07',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_T19_005','APT_T19_050','PAT_050','DOC_05','ROOM_KB_05','OUTPATIENT',3,'2026-05-19 08:50:00+07',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_T19_006','APT_T19_051','PAT_051','DOC_06','ROOM_KB_01','OUTPATIENT',1,'2026-05-19 08:55:00+07',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_T19_007','APT_T19_052','PAT_052','DOC_07','ROOM_KB_02','OUTPATIENT',2,'2026-05-19 09:00:00+07',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_T19_008','APT_T19_053','PAT_053','DOC_08','ROOM_KB_03','OUTPATIENT',1,'2026-05-19 09:05:00+07',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_T19_009','APT_T19_054','PAT_054','DOC_09','ROOM_KB_04','OUTPATIENT',3,'2026-05-19 09:10:00+07',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
('ENC_T19_010','APT_T19_055','PAT_055','DOC_10','ROOM_KB_05','OUTPATIENT',1,'2026-05-19 09:15:00+07',NULL,'IN_PROGRESS','Đang khám lâm sàng — ghi nhận sinh hiệu'),
-- COMPLETED encounters (link tới appointments COMPLETED today)
('ENC_T19_011','APT_T19_056','PAT_056','DOC_01','ROOM_KB_01','OUTPATIENT',1,'2026-05-19 06:50:00+07','2026-05-19 07:15:00+07','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_T19_012','APT_T19_057','PAT_057','DOC_02','ROOM_KB_02','OUTPATIENT',2,'2026-05-19 06:55:00+07','2026-05-19 07:20:00+07','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_T19_013','APT_T19_058','PAT_058','DOC_03','ROOM_KB_03','OUTPATIENT',1,'2026-05-19 07:00:00+07','2026-05-19 07:25:00+07','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_T19_014','APT_T19_059','PAT_059','DOC_04','ROOM_KB_04','OUTPATIENT',1,'2026-05-19 07:05:00+07','2026-05-19 07:30:00+07','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_T19_015','APT_T19_060','PAT_060','DOC_05','ROOM_KB_05','OUTPATIENT',2,'2026-05-19 07:10:00+07','2026-05-19 07:35:00+07','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_T19_016','APT_T19_061','PAT_061','DOC_06','ROOM_KB_01','OUTPATIENT',1,'2026-05-19 07:15:00+07','2026-05-19 07:40:00+07','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_T19_017','APT_T19_062','PAT_062','DOC_07','ROOM_KB_02','OUTPATIENT',3,'2026-05-19 07:20:00+07','2026-05-19 07:40:00+07','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_T19_018','APT_T19_063','PAT_063','DOC_08','ROOM_KB_03','OUTPATIENT',1,'2026-05-19 07:25:00+07','2026-05-19 07:50:00+07','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_T19_019','APT_T19_064','PAT_064','DOC_09','ROOM_KB_04','OUTPATIENT',2,'2026-05-19 07:30:00+07','2026-05-19 07:55:00+07','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám'),
('ENC_T19_020','APT_T19_065','PAT_065','DOC_10','ROOM_KB_05','OUTPATIENT',1,'2026-05-19 07:35:00+07','2026-05-19 08:00:00+07','COMPLETED','Khám hoàn tất, đã kê đơn và hẹn tái khám')
ON CONFLICT (encounters_id) DO NOTHING;

COMMIT;
