-- 22_doctor_queue_test_seed.sql
-- Seed dữ liệu test cho Queue bác sĩ DOC_01 ngày hiện tại (2026-06-08)

BEGIN;

-- 1. Xóa dữ liệu rác nếu có trong ngày này của DOC_01 để tránh trùng
DELETE FROM encounters WHERE doctor_id = 'DOC_01' AND appointment_id IN (
    SELECT appointments_id FROM appointments WHERE doctor_id = 'DOC_01' AND appointment_date = '2026-06-08'::date
);
DELETE FROM appointments WHERE doctor_id = 'DOC_01' AND appointment_date = '2026-06-08'::date;

-- 2. Thêm 4 bệnh nhân (tái sử dụng từ PAT_001 -> PAT_004 có sẵn)
INSERT INTO appointments (
    appointments_id, appointment_code, patient_id, doctor_id,
    room_id, specialty_id, branch_id, appointment_date, 
    booking_channel, reason_for_visit, status, priority, queue_number, symptoms_notes
) VALUES
-- Kịch bản 1: Đang chờ (WAITING/PENDING)
('APT_DOC_TEST_01', 'APP-DOC-TEST-01', 'PAT_001', 'DOC_01', 'ROOM_KB_01', 'SPC_TONG_QUAT', 'BR_MAIN', '2026-06-08'::date, 'WEB', 'Đau đầu, chóng mặt', 'PENDING', 'NORMAL', 1, 'TEST WAITING'),

-- Kịch bản 2: Bị nhỡ / Bỏ qua (SKIPPED)
('APT_DOC_TEST_02', 'APP-DOC-TEST-02', 'PAT_002', 'DOC_01', 'ROOM_KB_01', 'SPC_TONG_QUAT', 'BR_MAIN', '2026-06-08'::date, 'WEB', 'Khám sức khỏe tổng quát', 'SKIPPED', 'NORMAL', 2, 'TEST SKIPPED'),

-- Kịch bản 3: Đang khám dở (IN_PROGRESS)
('APT_DOC_TEST_03', 'APP-DOC-TEST-03', 'PAT_003', 'DOC_01', 'ROOM_KB_01', 'SPC_TONG_QUAT', 'BR_MAIN', '2026-06-08'::date, 'APP', 'Ho khan, sốt nhẹ', 'IN_PROGRESS', 'NORMAL', 3, 'TEST IN PROGRESS'),

-- Kịch bản 4: Đã khám xong (COMPLETED)
('APT_DOC_TEST_04', 'APP-DOC-TEST-04', 'PAT_004', 'DOC_01', 'ROOM_KB_01', 'SPC_TONG_QUAT', 'BR_MAIN', '2026-06-08'::date, 'DIRECT_CLINIC', 'Đau dạ dày', 'COMPLETED', 'NORMAL', 4, 'TEST COMPLETED');


-- 3. Tạo Encounters cho IN_PROGRESS và COMPLETED
INSERT INTO encounters (
    encounters_id, appointment_id, patient_id, doctor_id, room_id,
    encounter_type, visit_number, start_time, end_time, status, notes
) VALUES
-- Encounter cho ca IN_PROGRESS
('ENC_DOC_TEST_01', 'APT_DOC_TEST_03', 'PAT_003', 'DOC_01', 'ROOM_KB_01', 'OUTPATIENT', 1, '2026-06-08 08:30:00+07', NULL, 'IN_PROGRESS', 'Bệnh nhân đang khám, đã đo sinh hiệu'),

-- Encounter cho ca COMPLETED
('ENC_DOC_TEST_02', 'APT_DOC_TEST_04', 'PAT_004', 'DOC_01', 'ROOM_KB_01', 'OUTPATIENT', 1, '2026-06-08 09:00:00+07', '2026-06-08 09:20:00+07', 'COMPLETED', 'Khám xong, đã kê đơn');


COMMIT;
