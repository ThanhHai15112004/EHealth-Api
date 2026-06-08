-- =================================================================
-- 21_today_slots_rooms.sql
-- Slots 5 ngay (2026-05-19..23) + room status + maintenance
-- Phuc vu Portal Le tan + Bac si (tinh trang phong, khung gio hom nay)
--
-- LUU Y: appointment_slots la TEMPLATE (chi co start/end time, shift_id).
-- Khung gio cua bac si theo NGAY duoc bieu dien qua bang staff_schedules.
-- Trang thai slot (BLOCKED) bieu dien qua locked_slots + doctor_absences.
-- Trang thai phong (IN_USE/CLEANING/MAINTENANCE) o medical_rooms.room_status.
--
-- Idempotent: dung ON CONFLICT DO NOTHING.
-- =================================================================

BEGIN;

-- -----------------------------------------------------------------
-- 1. STAFF SCHEDULES: 10 bac si x 5 ngay x 2 ca = 100 ban ghi
--    Bieu dien khung gio kha dung cua bac si theo ngay.
-- -----------------------------------------------------------------
INSERT INTO staff_schedules (staff_schedules_id, user_id, medical_room_id, shift_id, working_date, start_time, end_time, is_leave, leave_reason, status) VALUES
('SCH_T19_0001', 'USR_DOC_01', 'ROOM_KB_01', 'SHIFT_MORNING', '2026-05-19', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0002', 'USR_DOC_01', 'ROOM_KB_01', 'SHIFT_AFTERNOON', '2026-05-19', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0003', 'USR_DOC_02', 'ROOM_NOI_01', 'SHIFT_MORNING', '2026-05-19', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0004', 'USR_DOC_02', 'ROOM_NOI_01', 'SHIFT_AFTERNOON', '2026-05-19', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0005', 'USR_DOC_03', 'ROOM_NGOAI_01', 'SHIFT_MORNING', '2026-05-19', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0006', 'USR_DOC_03', 'ROOM_NGOAI_01', 'SHIFT_AFTERNOON', '2026-05-19', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0007', 'USR_DOC_04', 'ROOM_SAN_01', 'SHIFT_MORNING', '2026-05-19', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0008', 'USR_DOC_04', 'ROOM_SAN_01', 'SHIFT_AFTERNOON', '2026-05-19', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0009', 'USR_DOC_05', 'ROOM_NHI_01', 'SHIFT_MORNING', '2026-05-19', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0010', 'USR_DOC_05', 'ROOM_NHI_01', 'SHIFT_AFTERNOON', '2026-05-19', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0011', 'USR_DOC_06', 'ROOM_CC_02', 'SHIFT_MORNING', '2026-05-19', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0012', 'USR_DOC_06', 'ROOM_CC_02', 'SHIFT_AFTERNOON', '2026-05-19', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0013', 'USR_DOC_07', 'ROOM_ICU_01', 'SHIFT_MORNING', '2026-05-19', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0014', 'USR_DOC_07', 'ROOM_ICU_01', 'SHIFT_AFTERNOON', '2026-05-19', '13:00', '17:00', TRUE, 'Nghi phep dot xuat', 'ACTIVE'),
('SCH_T19_0015', 'USR_DOC_08', 'ROOM_XN_01', 'SHIFT_MORNING', '2026-05-19', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0016', 'USR_DOC_08', 'ROOM_XN_01', 'SHIFT_AFTERNOON', '2026-05-19', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0017', 'USR_DOC_09', 'ROOM_CDHA_01', 'SHIFT_MORNING', '2026-05-19', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0018', 'USR_DOC_09', 'ROOM_CDHA_01', 'SHIFT_AFTERNOON', '2026-05-19', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0019', 'USR_DOC_10', 'ROOM_KB_02', 'SHIFT_MORNING', '2026-05-19', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0020', 'USR_DOC_10', 'ROOM_KB_02', 'SHIFT_AFTERNOON', '2026-05-19', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0021', 'USR_DOC_01', 'ROOM_KB_01', 'SHIFT_MORNING', '2026-05-20', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0022', 'USR_DOC_01', 'ROOM_KB_01', 'SHIFT_AFTERNOON', '2026-05-20', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0023', 'USR_DOC_02', 'ROOM_NOI_01', 'SHIFT_MORNING', '2026-05-20', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0024', 'USR_DOC_02', 'ROOM_NOI_01', 'SHIFT_AFTERNOON', '2026-05-20', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0025', 'USR_DOC_03', 'ROOM_NGOAI_01', 'SHIFT_MORNING', '2026-05-20', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0026', 'USR_DOC_03', 'ROOM_NGOAI_01', 'SHIFT_AFTERNOON', '2026-05-20', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0027', 'USR_DOC_04', 'ROOM_SAN_01', 'SHIFT_MORNING', '2026-05-20', '07:00', '11:30', TRUE, 'Hop khoa Phu san', 'ACTIVE'),
('SCH_T19_0028', 'USR_DOC_04', 'ROOM_SAN_01', 'SHIFT_AFTERNOON', '2026-05-20', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0029', 'USR_DOC_05', 'ROOM_NHI_01', 'SHIFT_MORNING', '2026-05-20', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0030', 'USR_DOC_05', 'ROOM_NHI_01', 'SHIFT_AFTERNOON', '2026-05-20', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0031', 'USR_DOC_06', 'ROOM_CC_02', 'SHIFT_MORNING', '2026-05-20', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0032', 'USR_DOC_06', 'ROOM_CC_02', 'SHIFT_AFTERNOON', '2026-05-20', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0033', 'USR_DOC_07', 'ROOM_ICU_01', 'SHIFT_MORNING', '2026-05-20', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0034', 'USR_DOC_07', 'ROOM_ICU_01', 'SHIFT_AFTERNOON', '2026-05-20', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0035', 'USR_DOC_08', 'ROOM_XN_01', 'SHIFT_MORNING', '2026-05-20', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0036', 'USR_DOC_08', 'ROOM_XN_01', 'SHIFT_AFTERNOON', '2026-05-20', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0037', 'USR_DOC_09', 'ROOM_CDHA_01', 'SHIFT_MORNING', '2026-05-20', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0038', 'USR_DOC_09', 'ROOM_CDHA_01', 'SHIFT_AFTERNOON', '2026-05-20', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0039', 'USR_DOC_10', 'ROOM_KB_02', 'SHIFT_MORNING', '2026-05-20', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0040', 'USR_DOC_10', 'ROOM_KB_02', 'SHIFT_AFTERNOON', '2026-05-20', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0041', 'USR_DOC_01', 'ROOM_KB_01', 'SHIFT_MORNING', '2026-05-21', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0042', 'USR_DOC_01', 'ROOM_KB_01', 'SHIFT_AFTERNOON', '2026-05-21', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0043', 'USR_DOC_02', 'ROOM_NOI_01', 'SHIFT_MORNING', '2026-05-21', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0044', 'USR_DOC_02', 'ROOM_NOI_01', 'SHIFT_AFTERNOON', '2026-05-21', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0045', 'USR_DOC_03', 'ROOM_NGOAI_01', 'SHIFT_MORNING', '2026-05-21', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0046', 'USR_DOC_03', 'ROOM_NGOAI_01', 'SHIFT_AFTERNOON', '2026-05-21', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0047', 'USR_DOC_04', 'ROOM_SAN_01', 'SHIFT_MORNING', '2026-05-21', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0048', 'USR_DOC_04', 'ROOM_SAN_01', 'SHIFT_AFTERNOON', '2026-05-21', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0049', 'USR_DOC_05', 'ROOM_NHI_01', 'SHIFT_MORNING', '2026-05-21', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0050', 'USR_DOC_05', 'ROOM_NHI_01', 'SHIFT_AFTERNOON', '2026-05-21', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0051', 'USR_DOC_06', 'ROOM_CC_02', 'SHIFT_MORNING', '2026-05-21', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0052', 'USR_DOC_06', 'ROOM_CC_02', 'SHIFT_AFTERNOON', '2026-05-21', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0053', 'USR_DOC_07', 'ROOM_ICU_01', 'SHIFT_MORNING', '2026-05-21', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0054', 'USR_DOC_07', 'ROOM_ICU_01', 'SHIFT_AFTERNOON', '2026-05-21', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0055', 'USR_DOC_08', 'ROOM_XN_01', 'SHIFT_MORNING', '2026-05-21', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0056', 'USR_DOC_08', 'ROOM_XN_01', 'SHIFT_AFTERNOON', '2026-05-21', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0057', 'USR_DOC_09', 'ROOM_CDHA_01', 'SHIFT_MORNING', '2026-05-21', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0058', 'USR_DOC_09', 'ROOM_CDHA_01', 'SHIFT_AFTERNOON', '2026-05-21', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0059', 'USR_DOC_10', 'ROOM_KB_02', 'SHIFT_MORNING', '2026-05-21', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0060', 'USR_DOC_10', 'ROOM_KB_02', 'SHIFT_AFTERNOON', '2026-05-21', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0061', 'USR_DOC_01', 'ROOM_KB_01', 'SHIFT_MORNING', '2026-05-22', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0062', 'USR_DOC_01', 'ROOM_KB_01', 'SHIFT_AFTERNOON', '2026-05-22', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0063', 'USR_DOC_02', 'ROOM_NOI_01', 'SHIFT_MORNING', '2026-05-22', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0064', 'USR_DOC_02', 'ROOM_NOI_01', 'SHIFT_AFTERNOON', '2026-05-22', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0065', 'USR_DOC_03', 'ROOM_NGOAI_01', 'SHIFT_MORNING', '2026-05-22', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0066', 'USR_DOC_03', 'ROOM_NGOAI_01', 'SHIFT_AFTERNOON', '2026-05-22', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0067', 'USR_DOC_04', 'ROOM_SAN_01', 'SHIFT_MORNING', '2026-05-22', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0068', 'USR_DOC_04', 'ROOM_SAN_01', 'SHIFT_AFTERNOON', '2026-05-22', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0069', 'USR_DOC_05', 'ROOM_NHI_01', 'SHIFT_MORNING', '2026-05-22', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0070', 'USR_DOC_05', 'ROOM_NHI_01', 'SHIFT_AFTERNOON', '2026-05-22', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0071', 'USR_DOC_06', 'ROOM_CC_02', 'SHIFT_MORNING', '2026-05-22', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0072', 'USR_DOC_06', 'ROOM_CC_02', 'SHIFT_AFTERNOON', '2026-05-22', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0073', 'USR_DOC_07', 'ROOM_ICU_01', 'SHIFT_MORNING', '2026-05-22', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0074', 'USR_DOC_07', 'ROOM_ICU_01', 'SHIFT_AFTERNOON', '2026-05-22', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0075', 'USR_DOC_08', 'ROOM_XN_01', 'SHIFT_MORNING', '2026-05-22', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0076', 'USR_DOC_08', 'ROOM_XN_01', 'SHIFT_AFTERNOON', '2026-05-22', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0077', 'USR_DOC_09', 'ROOM_CDHA_01', 'SHIFT_MORNING', '2026-05-22', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0078', 'USR_DOC_09', 'ROOM_CDHA_01', 'SHIFT_AFTERNOON', '2026-05-22', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0079', 'USR_DOC_10', 'ROOM_KB_02', 'SHIFT_MORNING', '2026-05-22', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0080', 'USR_DOC_10', 'ROOM_KB_02', 'SHIFT_AFTERNOON', '2026-05-22', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0081', 'USR_DOC_01', 'ROOM_KB_01', 'SHIFT_MORNING', '2026-05-23', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0082', 'USR_DOC_01', 'ROOM_KB_01', 'SHIFT_AFTERNOON', '2026-05-23', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0083', 'USR_DOC_02', 'ROOM_NOI_01', 'SHIFT_MORNING', '2026-05-23', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0084', 'USR_DOC_02', 'ROOM_NOI_01', 'SHIFT_AFTERNOON', '2026-05-23', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0085', 'USR_DOC_03', 'ROOM_NGOAI_01', 'SHIFT_MORNING', '2026-05-23', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0086', 'USR_DOC_03', 'ROOM_NGOAI_01', 'SHIFT_AFTERNOON', '2026-05-23', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0087', 'USR_DOC_04', 'ROOM_SAN_01', 'SHIFT_MORNING', '2026-05-23', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0088', 'USR_DOC_04', 'ROOM_SAN_01', 'SHIFT_AFTERNOON', '2026-05-23', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0089', 'USR_DOC_05', 'ROOM_NHI_01', 'SHIFT_MORNING', '2026-05-23', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0090', 'USR_DOC_05', 'ROOM_NHI_01', 'SHIFT_AFTERNOON', '2026-05-23', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0091', 'USR_DOC_06', 'ROOM_CC_02', 'SHIFT_MORNING', '2026-05-23', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0092', 'USR_DOC_06', 'ROOM_CC_02', 'SHIFT_AFTERNOON', '2026-05-23', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0093', 'USR_DOC_07', 'ROOM_ICU_01', 'SHIFT_MORNING', '2026-05-23', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0094', 'USR_DOC_07', 'ROOM_ICU_01', 'SHIFT_AFTERNOON', '2026-05-23', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0095', 'USR_DOC_08', 'ROOM_XN_01', 'SHIFT_MORNING', '2026-05-23', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0096', 'USR_DOC_08', 'ROOM_XN_01', 'SHIFT_AFTERNOON', '2026-05-23', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0097', 'USR_DOC_09', 'ROOM_CDHA_01', 'SHIFT_MORNING', '2026-05-23', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0098', 'USR_DOC_09', 'ROOM_CDHA_01', 'SHIFT_AFTERNOON', '2026-05-23', '13:00', '17:00', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0099', 'USR_DOC_10', 'ROOM_KB_02', 'SHIFT_MORNING', '2026-05-23', '07:00', '11:30', FALSE, NULL, 'ACTIVE'),
('SCH_T19_0100', 'USR_DOC_10', 'ROOM_KB_02', 'SHIFT_AFTERNOON', '2026-05-23', '13:00', '17:00', FALSE, NULL, 'ACTIVE')
ON CONFLICT (staff_schedules_id) DO NOTHING;

-- -----------------------------------------------------------------
-- 2. DOCTOR ABSENCES: 2 bac si vang (mo phong tinh trang BLOCKED)
-- -----------------------------------------------------------------
INSERT INTO doctor_absences (absence_id, doctor_id, absence_date, shift_id, absence_type, reason, created_by) VALUES
('ABS_T19_001', 'DOC_04', '2026-05-20', 'SHIFT_MORNING', 'MEETING', 'Hop khoa Phu san dot xuat', 'USR_ADMIN_01'),
('ABS_T19_002', 'DOC_07', '2026-05-19', 'SHIFT_AFTERNOON', 'SICK_LEAVE', 'Nghi om dot xuat', 'USR_ADMIN_01')
ON CONFLICT (absence_id) DO NOTHING;

-- -----------------------------------------------------------------
-- 3. LOCKED SLOTS: slot bi khoa theo ngay (BLOCKED status)
--    Khoa 2 slot dau gio sang (giao ban) cho moi ngay.
-- -----------------------------------------------------------------
INSERT INTO locked_slots (locked_slot_id, slot_id, locked_date, lock_reason, locked_by) VALUES
('LCK_T19_001', 'SLT_2604_032760b4', '2026-05-19', 'Giao ban dau ngay', 'USR_ADMIN_01'),
('LCK_T19_002', 'SLT_2604_08e61bdc', '2026-05-19', 'Giao ban dau ngay', 'USR_ADMIN_01'),
('LCK_T19_003', 'SLT_2604_23278da3', '2026-05-19', 'Chuan bi nghi trua', 'USR_ADMIN_01'),
('LCK_T19_004', 'SLT_2604_032760b4', '2026-05-20', 'Giao ban dau ngay', 'USR_ADMIN_01'),
('LCK_T19_005', 'SLT_2604_08e61bdc', '2026-05-20', 'Giao ban dau ngay', 'USR_ADMIN_01'),
('LCK_T19_006', 'SLT_2604_23278da3', '2026-05-20', 'Chuan bi nghi trua', 'USR_ADMIN_01'),
('LCK_T19_007', 'SLT_2604_032760b4', '2026-05-21', 'Giao ban dau ngay', 'USR_ADMIN_01'),
('LCK_T19_008', 'SLT_2604_08e61bdc', '2026-05-21', 'Giao ban dau ngay', 'USR_ADMIN_01'),
('LCK_T19_009', 'SLT_2604_23278da3', '2026-05-21', 'Chuan bi nghi trua', 'USR_ADMIN_01'),
('LCK_T19_010', 'SLT_2604_032760b4', '2026-05-22', 'Giao ban dau ngay', 'USR_ADMIN_01'),
('LCK_T19_011', 'SLT_2604_08e61bdc', '2026-05-22', 'Giao ban dau ngay', 'USR_ADMIN_01'),
('LCK_T19_012', 'SLT_2604_23278da3', '2026-05-22', 'Chuan bi nghi trua', 'USR_ADMIN_01'),
('LCK_T19_013', 'SLT_2604_032760b4', '2026-05-23', 'Giao ban dau ngay', 'USR_ADMIN_01'),
('LCK_T19_014', 'SLT_2604_08e61bdc', '2026-05-23', 'Giao ban dau ngay', 'USR_ADMIN_01'),
('LCK_T19_015', 'SLT_2604_23278da3', '2026-05-23', 'Chuan bi nghi trua', 'USR_ADMIN_01')
ON CONFLICT (slot_id, locked_date) DO NOTHING;

-- -----------------------------------------------------------------
-- 4. CAP NHAT TINH TRANG PHONG (room_status)
--    Schema chi co: AVAILABLE, IN_USE, MAINTENANCE
--    CLEANING khong co trong DEFAULT -> dung MAINTENANCE thay the
--    hoac giu nguyen AVAILABLE cho ROOM_KB_04 (mo phong dang don dep -> MAINTENANCE)
-- -----------------------------------------------------------------
UPDATE medical_rooms SET room_status = 'IN_USE'      WHERE medical_rooms_id = 'ROOM_KB_01';
UPDATE medical_rooms SET room_status = 'IN_USE'      WHERE medical_rooms_id = 'ROOM_KB_02';
UPDATE medical_rooms SET room_status = 'AVAILABLE'   WHERE medical_rooms_id = 'ROOM_KB_03';
UPDATE medical_rooms SET room_status = 'MAINTENANCE' WHERE medical_rooms_id = 'ROOM_KB_04'; -- dang don dep
UPDATE medical_rooms SET room_status = 'MAINTENANCE' WHERE medical_rooms_id = 'ROOM_KB_05';

-- -----------------------------------------------------------------
-- 5. ROOM MAINTENANCE SCHEDULES: 5 lich bao tri
--    3 cho 2026-05-19 (1 dang chay, 2 da xong)
--    2 cho 2026-05-20..21 (sap toi)
--    Schema chi co start_date/end_date (DATE), khong co status.
-- -----------------------------------------------------------------
INSERT INTO room_maintenance_schedules (maintenance_id, room_id, start_date, end_date, reason, created_by) VALUES
('MNT_T19_001', 'ROOM_KB_05', '2026-05-19', '2026-05-19', 'Bao tri may dieu hoa - dang chay', 'USR_ADMIN_01'),
('MNT_T19_002', 'ROOM_NOI_01', '2026-05-17', '2026-05-18', 'Ve sinh tong the - da hoan tat', 'USR_ADMIN_01'),
('MNT_T19_003', 'ROOM_XN_01', '2026-05-16', '2026-05-18', 'Hieu chuan thiet bi xet nghiem - da xong', 'USR_ADMIN_01'),
('MNT_T19_004', 'ROOM_CDHA_01', '2026-05-20', '2026-05-20', 'Bao tri may X-quang dinh ky', 'USR_ADMIN_01'),
('MNT_T19_005', 'ROOM_KB_04', '2026-05-21', '2026-05-22', 'Sua chua he thong dien', 'USR_ADMIN_01')
ON CONFLICT (maintenance_id) DO NOTHING;

COMMIT;

-- =================================================================
-- TOM TAT INSERT/UPDATE:
--   staff_schedules:              100 INSERTs (10 doctors x 5 days x 2 shifts)
--   doctor_absences:              2 INSERTs
--   locked_slots:                 15 INSERTs (3 slot/day x 5 days)
--   medical_rooms (UPDATE):       5 UPDATEs (ROOM_KB_01..05)
--   room_maintenance_schedules:   5 INSERTs
-- =================================================================
