-- =====================================================================
-- TELE DEMO SEED — Sinh dữ liệu mẫu để demo các page admin/teleconsultation
-- Idempotent: ON CONFLICT DO NOTHING / WHERE NOT EXISTS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. tele_consultation_types — Đảm bảo có 4 hình thức (đã có sẵn)
-- ---------------------------------------------------------------------
INSERT INTO tele_consultation_types
    (type_id, code, name, description, default_platform, requires_video, requires_audio, allows_file_sharing, allows_screen_sharing, default_duration_minutes, min_duration_minutes, max_duration_minutes, sort_order, is_active)
VALUES
    ('TCT_VIDEO',  'VIDEO',  'Khám qua Video',         'Khám bệnh trực tuyến qua cuộc gọi video 2 chiều. Bác sĩ có thể quan sát bệnh nhân, đánh giá triệu chứng trực quan.', 'AGORA', TRUE,  TRUE,  TRUE,  TRUE,  30, 15, 60, 1, TRUE),
    ('TCT_AUDIO',  'AUDIO',  'Tư vấn qua Audio',       'Tư vấn y tế qua cuộc gọi thoại. Phù hợp ca không cần quan sát hình ảnh.',                                          'AGORA', FALSE, TRUE,  TRUE,  FALSE, 20, 10, 45, 2, TRUE),
    ('TCT_CHAT',   'CHAT',   'Tư vấn Chat y tế',       'Trao đổi văn bản với bác sĩ, kèm chia sẻ file hình ảnh / kết quả XN.',                                              'INTERNAL', FALSE, FALSE, TRUE, FALSE, 60, 30, 1440, 3, TRUE),
    ('TCT_HYBRID', 'HYBRID', 'Khám kết hợp (Hybrid)',  'Kết hợp video + chat hỗ trợ, phù hợp cho ca phức tạp.',                                                              'AGORA', TRUE,  TRUE,  TRUE,  TRUE,  45, 30, 90, 4, TRUE)
ON CONFLICT (type_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 2. tele_type_specialty_config — 6 chuyên khoa enable tele
-- ---------------------------------------------------------------------
INSERT INTO tele_type_specialty_config
    (config_id, type_id, specialty_id, facility_id, is_enabled, allowed_platforms, min_duration_minutes, max_duration_minutes, default_duration_minutes, base_price, insurance_price, vip_price, advance_booking_days, cancellation_hours, priority, is_active)
VALUES
    ('TSC_VIDEO_TONG_QUAT','TCT_VIDEO','SPC_TONG_QUAT','FAC_EHEALTH', TRUE, '["AGORA"]'::jsonb, 15, 45, 30, 300000, 250000, 500000, 30, 2, 1, TRUE),
    ('TSC_VIDEO_NHI',      'TCT_VIDEO','SPC_NHI',      'FAC_EHEALTH', TRUE, '["AGORA"]'::jsonb, 15, 45, 30, 350000, 300000, 600000, 30, 2, 1, TRUE),
    ('TSC_VIDEO_NOI',      'TCT_VIDEO','SPC_NOI',      'FAC_EHEALTH', TRUE, '["AGORA"]'::jsonb, 15, 45, 30, 350000, 300000, 600000, 30, 2, 1, TRUE),
    ('TSC_AUDIO_TONG_QUAT','TCT_AUDIO','SPC_TONG_QUAT','FAC_EHEALTH', TRUE, '["AGORA"]'::jsonb, 10, 30, 20, 200000, 150000, 350000, 30, 2, 2, TRUE),
    ('TSC_AUDIO_SAN',      'TCT_AUDIO','SPC_SAN',      'FAC_EHEALTH', TRUE, '["AGORA"]'::jsonb, 10, 30, 20, 250000, 200000, 400000, 30, 2, 2, TRUE),
    ('TSC_CHAT_TONG_QUAT', 'TCT_CHAT', 'SPC_TONG_QUAT','FAC_EHEALTH', TRUE, '["INTERNAL"]'::jsonb, 30, 1440, 60, 100000, 80000, 200000, 14, 1, 3, TRUE)
ON CONFLICT (type_id, specialty_id, facility_id) DO NOTHING;

-- Helper: tìm config_id thực tế cho (type, specialty, facility) — viewable bằng CTE bên dưới khi cần

-- ---------------------------------------------------------------------
-- 3. tele_service_pricing — bảng giá 6 dòng
-- ---------------------------------------------------------------------
INSERT INTO tele_service_pricing
    (pricing_id, type_id, specialty_id, facility_id, base_price, currency, discount_percent, effective_from, is_active)
VALUES
    ('TSP_VIDEO_TONG_QUAT', 'TCT_VIDEO', 'SPC_TONG_QUAT', 'FAC_EHEALTH', 300000, 'VND', 0,  '2026-01-01', TRUE),
    ('TSP_VIDEO_NHI',       'TCT_VIDEO', 'SPC_NHI',       'FAC_EHEALTH', 350000, 'VND', 5,  '2026-01-01', TRUE),
    ('TSP_VIDEO_NOI',       'TCT_VIDEO', 'SPC_NOI',       'FAC_EHEALTH', 350000, 'VND', 0,  '2026-01-01', TRUE),
    ('TSP_AUDIO_TONG_QUAT', 'TCT_AUDIO', 'SPC_TONG_QUAT', 'FAC_EHEALTH', 200000, 'VND', 0,  '2026-01-01', TRUE),
    ('TSP_AUDIO_SAN',       'TCT_AUDIO', 'SPC_SAN',       'FAC_EHEALTH', 250000, 'VND', 10, '2026-01-01', TRUE),
    ('TSP_CHAT_TONG_QUAT',  'TCT_CHAT',  'SPC_TONG_QUAT', 'FAC_EHEALTH', 100000, 'VND', 0,  '2026-01-01', TRUE)
ON CONFLICT (type_id, specialty_id, facility_id, effective_from) DO NOTHING;

-- ---------------------------------------------------------------------
-- 4. tele_booking_sessions — 8 booking với mix status (đã có 1 sẵn)
-- ---------------------------------------------------------------------
-- Dùng subquery để lookup config_id thực — tránh hardcode mismatch
INSERT INTO tele_booking_sessions
    (session_id, session_code, patient_id, specialty_id, facility_id, type_id, config_id, doctor_id,
     booking_date, booking_start_time, booking_end_time, duration_minutes, platform,
     price_amount, price_type, status, payment_required, payment_status, reason_for_visit, symptoms_notes,
     confirmed_at, confirmed_by, created_at)
SELECT v.session_id, v.session_code, v.patient_id, v.specialty_id, v.facility_id, v.type_id,
       (SELECT config_id FROM tele_type_specialty_config WHERE type_id = v.type_id AND specialty_id = v.specialty_id AND facility_id = v.facility_id LIMIT 1),
       v.doctor_id, v.booking_date::date, v.booking_start_time::time, v.booking_end_time::time, v.duration_minutes, v.platform,
       v.price_amount, v.price_type, v.status, v.payment_required, v.payment_status, v.reason_for_visit, v.symptoms_notes,
       v.confirmed_at::timestamptz, v.confirmed_by, v.created_at::timestamptz
FROM (VALUES
    ('TBS_DEMO_001', 'TBS-DEMO-001', 'PAT_SEED_1001', 'SPC_TONG_QUAT', 'FAC_EHEALTH', 'TCT_VIDEO', 'DOC_01',
     '2026-05-15', '09:00:00', '09:30:00', 30, 'AGORA',
     300000::numeric, 'BASE', 'COMPLETED', TRUE, 'PAID', 'Đau đầu kéo dài 3 ngày', 'Đau vùng trán, kèm chóng mặt nhẹ',
     '2026-05-15 08:30:00+07', 'USR_ADMIN_01', '2026-05-15 08:00:00+07'),
    ('TBS_DEMO_002', 'TBS-DEMO-002', 'PAT_SEED_1003', 'SPC_NHI', 'FAC_EHEALTH', 'TCT_VIDEO', 'DOC_05',
     '2026-05-16', '10:30:00', '11:00:00', 30, 'AGORA',
     350000::numeric, 'BASE', 'COMPLETED', TRUE, 'PAID', 'Bé sốt 38.5 độ', 'Bé ho khan, biếng ăn 2 ngày nay',
     '2026-05-16 10:00:00+07', 'USR_ADMIN_01', '2026-05-16 09:30:00+07'),
    ('TBS_DEMO_003', 'TBS-DEMO-003', 'PAT_SEED_1004', 'SPC_NOI', 'FAC_EHEALTH', 'TCT_VIDEO', 'DOC_02',
     '2026-05-17', '14:00:00', '14:30:00', 30, 'AGORA',
     350000::numeric, 'BASE', 'COMPLETED', TRUE, 'PAID', 'Tái khám tăng huyết áp', 'Tăng huyết áp đang điều trị',
     '2026-05-17 13:30:00+07', 'USR_ADMIN_01', '2026-05-17 13:00:00+07'),
    ('TBS_DEMO_004', 'TBS-DEMO-004', 'PAT_SEED_1005', 'SPC_NHI', 'FAC_EHEALTH', 'TCT_VIDEO', 'DOC_05',
     '2026-05-20', '15:00:00', '15:30:00', 30, 'AGORA',
     350000::numeric, 'BASE', 'CONFIRMED', TRUE, 'PAID', 'Bé bị tiêu chảy', 'Tiêu chảy 3 lần/ngày',
     '2026-05-19 09:00:00+07', 'USR_ADMIN_01', '2026-05-19 08:00:00+07'),
    ('TBS_DEMO_005', 'TBS-DEMO-005', 'PAT_SEED_1007', 'SPC_TONG_QUAT', 'FAC_EHEALTH', 'TCT_VIDEO', 'DOC_01',
     '2026-05-20', '16:00:00', '16:30:00', 30, 'AGORA',
     300000::numeric, 'BASE', 'CONFIRMED', TRUE, 'PAID', 'Đau dạ dày', 'Đau bụng vùng thượng vị sau ăn',
     '2026-05-19 10:00:00+07', 'USR_ADMIN_01', '2026-05-19 09:00:00+07'),
    ('TBS_DEMO_006', 'TBS-DEMO-006', 'PAT_SEED_1010', 'SPC_SAN', 'FAC_EHEALTH', 'TCT_AUDIO', NULL,
     '2026-05-21', '09:00:00', '09:20:00', 20, 'AGORA',
     250000::numeric, 'BASE', 'PENDING', TRUE, 'PAID', 'Tư vấn sức khỏe phụ nữ', NULL,
     NULL, NULL, '2026-05-19 06:00:00+07'),
    ('TBS_DEMO_007', 'TBS-DEMO-007', 'PAT_SEED_1011', 'SPC_TONG_QUAT', 'FAC_EHEALTH', 'TCT_CHAT', NULL,
     '2026-05-19', '20:00:00', '21:00:00', 60, 'INTERNAL',
     100000::numeric, 'BASE', 'PENDING', TRUE, 'PAID', 'Hỏi về kết quả xét nghiệm', NULL,
     NULL, NULL, '2026-05-19 07:00:00+07'),
    ('TBS_DEMO_008', 'TBS-DEMO-008', 'PAT_SEED_1013', 'SPC_TONG_QUAT', 'FAC_EHEALTH', 'TCT_VIDEO', 'DOC_01',
     '2026-05-18', '11:00:00', '11:30:00', 30, 'AGORA',
     300000::numeric, 'BASE', 'CANCELLED', TRUE, 'REFUNDED', 'Khám tổng quát', NULL,
     NULL, NULL, '2026-05-18 08:00:00+07')
) AS v(session_id, session_code, patient_id, specialty_id, facility_id, type_id, doctor_id,
       booking_date, booking_start_time, booking_end_time, duration_minutes, platform,
       price_amount, price_type, status, payment_required, payment_status, reason_for_visit, symptoms_notes,
       confirmed_at, confirmed_by, created_at)
ON CONFLICT (session_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 5. encounters — Tạo encounter cho mỗi consultation (cần cho FK của tele_consultations)
--    Phòng tele dùng room_id sẵn có (ROOM_KB_05 - Phòng tư vấn)
-- ---------------------------------------------------------------------
INSERT INTO encounters
    (encounters_id, patient_id, doctor_id, room_id, encounter_type, status, start_time, end_time, conclusion, is_finalized, finalized_at, notes)
VALUES
    ('ENC_TELE_001', 'PAT_SEED_1001', 'DOC_01', 'ROOM_KB_05', 'TELE', 'COMPLETED',
     '2026-05-15 09:00:00+07', '2026-05-15 09:28:00+07', 'Đau đầu căng thẳng do stress, kê thuốc giảm đau và tư vấn nghỉ ngơi', TRUE, '2026-05-15 09:30:00+07', 'Phiên khám online ổn'),

    ('ENC_TELE_002', 'PAT_SEED_1003', 'DOC_05', 'ROOM_KB_05', 'TELE', 'COMPLETED',
     '2026-05-16 10:30:00+07', '2026-05-16 11:00:00+07', 'Viêm họng cấp do virus, điều trị triệu chứng', TRUE, '2026-05-16 11:05:00+07', 'Bé hợp tác tốt'),

    ('ENC_TELE_003', 'PAT_SEED_1004', 'DOC_02', 'ROOM_KB_05', 'TELE', 'COMPLETED',
     '2026-05-17 14:00:00+07', '2026-05-17 14:30:00+07', 'Tăng huyết áp ổn định, tiếp tục phác đồ hiện tại', TRUE, '2026-05-17 14:32:00+07', 'BN tuân thủ thuốc tốt'),

    -- Active rooms (room_status WAITING/ONGOING) — encounter chưa finalize
    ('ENC_TELE_004', 'PAT_SEED_1005', 'DOC_05', 'ROOM_KB_05', 'TELE', 'IN_PROGRESS',
     CURRENT_TIMESTAMP - INTERVAL '12 minutes', NULL, NULL, FALSE, NULL, 'Đang khám'),

    ('ENC_TELE_005', 'PAT_SEED_1007', 'DOC_01', 'ROOM_KB_05', 'TELE', 'IN_PROGRESS',
     CURRENT_TIMESTAMP - INTERVAL '3 minutes', NULL, NULL, FALSE, NULL, 'Đang chờ BN'),

    ('ENC_TELE_006', 'PAT_SEED_1010', 'DOC_04', 'ROOM_KB_05', 'TELE', 'IN_PROGRESS',
     CURRENT_TIMESTAMP - INTERVAL '8 minutes', NULL, NULL, FALSE, NULL, 'Đang tư vấn audio')
ON CONFLICT (encounters_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 6. tele_consultations — Gắn encounter ↔ booking session
-- ---------------------------------------------------------------------
INSERT INTO tele_consultations
    (tele_consultations_id, encounter_id, platform, meeting_id, join_url, recording_url, recording_duration,
     call_status, actual_start_time, actual_end_time, consultation_type_id, booking_session_id,
     room_status, room_opened_at, room_opened_by, room_closed_at, total_duration_seconds,
     participant_count, has_video, has_audio, has_chat, has_file_sharing, has_result, result_status)
VALUES
    ('TC_DEMO_001', 'ENC_TELE_001', 'AGORA', 'meet-001', 'https://meet.ehealth.vn/c/TC_DEMO_001', 'https://cdn.ehealth.vn/rec/tc001.mp4', 1680,
     'COMPLETED', '2026-05-15 09:02:00', '2026-05-15 09:28:00', 'TCT_VIDEO', 'TBS_DEMO_001',
     'COMPLETED', '2026-05-15 09:00:00+07', 'USR_DOC_01', '2026-05-15 09:30:00+07', 1680,
     2, TRUE, TRUE, TRUE, TRUE, TRUE, 'SIGNED'),

    ('TC_DEMO_002', 'ENC_TELE_002', 'AGORA', 'meet-002', 'https://meet.ehealth.vn/c/TC_DEMO_002', 'https://cdn.ehealth.vn/rec/tc002.mp4', 1800,
     'COMPLETED', '2026-05-16 10:30:00', '2026-05-16 11:00:00', 'TCT_VIDEO', 'TBS_DEMO_002',
     'COMPLETED', '2026-05-16 10:30:00+07', 'USR_DOC_05', '2026-05-16 11:02:00+07', 1800,
     3, TRUE, TRUE, TRUE, TRUE, TRUE, 'SIGNED'),

    ('TC_DEMO_003', 'ENC_TELE_003', 'AGORA', 'meet-003', 'https://meet.ehealth.vn/c/TC_DEMO_003', NULL, NULL,
     'COMPLETED', '2026-05-17 14:00:00', '2026-05-17 14:30:00', 'TCT_VIDEO', 'TBS_DEMO_003',
     'COMPLETED', '2026-05-17 14:00:00+07', 'USR_DOC_02', '2026-05-17 14:31:00+07', 1800,
     2, TRUE, TRUE, TRUE, TRUE, TRUE, 'COMPLETED'),

    -- Active rooms — đang hoạt động
    ('TC_DEMO_004', 'ENC_TELE_004', 'AGORA', 'meet-004', 'https://meet.ehealth.vn/c/TC_DEMO_004', NULL, NULL,
     'IN_PROGRESS', CURRENT_TIMESTAMP - INTERVAL '12 minutes', NULL, 'TCT_VIDEO', 'TBS_DEMO_004',
     'ONGOING', CURRENT_TIMESTAMP - INTERVAL '12 minutes', 'USR_DOC_05', NULL, 720,
     2, TRUE, TRUE, TRUE, TRUE, FALSE, NULL),

    ('TC_DEMO_005', 'ENC_TELE_005', 'AGORA', 'meet-005', 'https://meet.ehealth.vn/c/TC_DEMO_005', NULL, NULL,
     'WAITING', CURRENT_TIMESTAMP - INTERVAL '3 minutes', NULL, 'TCT_VIDEO', 'TBS_DEMO_005',
     'WAITING', CURRENT_TIMESTAMP - INTERVAL '3 minutes', 'USR_DOC_01', NULL, 180,
     1, FALSE, FALSE, TRUE, FALSE, FALSE, NULL),

    ('TC_DEMO_006', 'ENC_TELE_006', 'AGORA', 'meet-006', 'https://meet.ehealth.vn/c/TC_DEMO_006', NULL, NULL,
     'IN_PROGRESS', CURRENT_TIMESTAMP - INTERVAL '8 minutes', NULL, 'TCT_AUDIO', NULL,
     'ONGOING', CURRENT_TIMESTAMP - INTERVAL '8 minutes', 'USR_DOC_04', NULL, 480,
     2, FALSE, TRUE, TRUE, FALSE, FALSE, NULL)
ON CONFLICT (tele_consultations_id) DO NOTHING;

-- Liên kết ngược booking_session.tele_consultation_id
UPDATE tele_booking_sessions SET tele_consultation_id = 'TC_DEMO_001' WHERE session_id = 'TBS_DEMO_001' AND tele_consultation_id IS NULL;
UPDATE tele_booking_sessions SET tele_consultation_id = 'TC_DEMO_002' WHERE session_id = 'TBS_DEMO_002' AND tele_consultation_id IS NULL;
UPDATE tele_booking_sessions SET tele_consultation_id = 'TC_DEMO_003' WHERE session_id = 'TBS_DEMO_003' AND tele_consultation_id IS NULL;
UPDATE tele_booking_sessions SET tele_consultation_id = 'TC_DEMO_004' WHERE session_id = 'TBS_DEMO_004' AND tele_consultation_id IS NULL;
UPDATE tele_booking_sessions SET tele_consultation_id = 'TC_DEMO_005' WHERE session_id = 'TBS_DEMO_005' AND tele_consultation_id IS NULL;

-- ---------------------------------------------------------------------
-- 7. tele_consultation_results — 3 result cho 3 consultation đã COMPLETED
-- ---------------------------------------------------------------------
INSERT INTO tele_consultation_results
    (result_id, tele_consultation_id, encounter_id, chief_complaint, symptom_description, symptom_duration, symptom_severity,
     self_reported_vitals, remote_examination_notes, clinical_impression, medical_conclusion, conclusion_type,
     treatment_plan, treatment_advice, lifestyle_recommendations, medication_notes,
     referral_needed, follow_up_needed, follow_up_date, follow_up_type,
     is_signed, signed_at, signed_by, status, created_by, created_at)
VALUES
    ('TCR_DEMO_001', 'TC_DEMO_001', 'ENC_TELE_001',
     'Đau đầu kéo dài 3 ngày',
     'Đau căng vùng trán, lan ra sau gáy, không có aura, không buồn nôn',
     '3 ngày', 'MODERATE',
     '{"systolic":120,"diastolic":80,"pulse":78,"temperature":36.7}'::jsonb,
     'BN tỉnh táo, không có dấu thần kinh khu trú qua video',
     'Đau đầu type tension do stress công việc',
     'Đau đầu căng thẳng (Tension Headache)', 'DEFINITIVE',
     'Nghỉ ngơi, giảm stress, paracetamol khi đau',
     'Tập thở sâu, massage thái dương 5 phút/lần',
     'Ngủ đủ 7-8 tiếng, hạn chế cà phê, tập yoga 3 lần/tuần',
     'Paracetamol 500mg khi đau, tối đa 3 viên/ngày',
     FALSE, TRUE, '2026-05-29', 'TELE',
     TRUE, '2026-05-15 09:35:00+07', 'USR_DOC_01', 'SIGNED', 'USR_DOC_01', '2026-05-15 09:30:00+07'),

    ('TCR_DEMO_002', 'TC_DEMO_002', 'ENC_TELE_002',
     'Bé sốt 38.5 độ',
     'Sốt 2 ngày, ho khan, biếng ăn, không tiêu chảy',
     '2 ngày', 'MILD',
     '{"temperature":38.5,"pulse":110,"respiratory_rate":22}'::jsonb,
     'Bé tỉnh, không lờ đờ, mắt sáng, niêm hồng',
     'Viêm họng cấp do virus',
     'Viêm họng cấp - virus', 'PRELIMINARY',
     'Hạ sốt, bù nước, theo dõi tại nhà',
     'Lau mát khi sốt cao, uống nhiều nước',
     'Cho bé nghỉ ngơi, ăn cháo loãng, tránh đồ lạnh',
     'Paracetamol 80mg/5ml: 10ml mỗi 6h khi sốt >38.5°C',
     FALSE, TRUE, '2026-05-23', 'TELE',
     TRUE, '2026-05-16 11:10:00+07', 'USR_DOC_05', 'SIGNED', 'USR_DOC_05', '2026-05-16 11:05:00+07'),

    ('TCR_DEMO_003', 'TC_DEMO_003', 'ENC_TELE_003',
     'Tái khám tăng huyết áp',
     'Huyết áp ổn định 130/85 trong 2 tuần qua, không đau đầu chóng mặt',
     '6 tháng', 'MILD',
     '{"systolic":130,"diastolic":85,"pulse":72,"weight":68}'::jsonb,
     'BN tỉnh táo, không phù chi dưới qua quan sát',
     'Tăng huyết áp giai đoạn 1 - kiểm soát tốt',
     'Tăng huyết áp ổn định', 'DEFINITIVE',
     'Tiếp tục Amlodipine 5mg/ngày, ăn nhạt, tập thể dục đều',
     'Theo dõi HA tại nhà 2 lần/ngày, ghi nhật ký',
     'Hạn chế muối <5g/ngày, giảm cân nếu BMI >25',
     'Amlodipine 5mg uống sáng, không đổi liều',
     FALSE, TRUE, '2026-06-17', 'IN_PERSON',
     FALSE, NULL, NULL, 'COMPLETED', 'USR_DOC_02', '2026-05-17 14:35:00+07')
ON CONFLICT (result_id) DO NOTHING;

-- Cập nhật flags has_result trên tele_consultations
UPDATE tele_consultations SET has_result = TRUE, result_status = 'SIGNED'    WHERE tele_consultations_id = 'TC_DEMO_001';
UPDATE tele_consultations SET has_result = TRUE, result_status = 'SIGNED'    WHERE tele_consultations_id = 'TC_DEMO_002';
UPDATE tele_consultations SET has_result = TRUE, result_status = 'COMPLETED' WHERE tele_consultations_id = 'TC_DEMO_003';

-- ---------------------------------------------------------------------
-- 8. prescriptions + tele_prescriptions + prescription_details
-- ---------------------------------------------------------------------
INSERT INTO prescriptions
    (prescriptions_id, prescription_code, encounter_id, doctor_id, patient_id, status, clinical_diagnosis, doctor_notes, prescribed_at)
VALUES
    ('PRS_TELE_001', 'PRS-TELE-001', 'ENC_TELE_001', 'USR_DOC_01', 'PAT_SEED_1001', 'PRESCRIBED', 'Đau đầu căng thẳng do stress',           'Theo dõi tại nhà 1 tuần', '2026-05-15 09:30:00'),
    ('PRS_TELE_002', 'PRS-TELE-002', 'ENC_TELE_002', 'USR_DOC_05', 'PAT_SEED_1003', 'SENT',       'Viêm họng cấp do virus',                 'Bé uống đúng liều', '2026-05-16 11:05:00'),
    ('PRS_TELE_003', 'PRS-TELE-003', 'ENC_TELE_003', 'USR_DOC_02', 'PAT_SEED_1004', 'PRESCRIBED', 'Tăng huyết áp giai đoạn 1 - ổn định',    'Tiếp tục phác đồ', '2026-05-17 14:30:00')
ON CONFLICT (prescriptions_id) DO NOTHING;

INSERT INTO tele_prescriptions
    (tele_prescription_id, prescription_id, tele_consultation_id, encounter_id,
     is_remote_prescription, remote_restrictions_checked,
     delivery_method, delivery_address, delivery_phone,
     sent_to_patient, sent_at, doctor_confirmed_identity, has_lab_orders, has_referral)
VALUES
    ('TP_DEMO_001', 'PRS_TELE_001', 'TC_DEMO_001', 'ENC_TELE_001', TRUE, TRUE,
     'PICKUP', '123 Nguyễn Trãi, Q1, TP.HCM', '0901234567',
     FALSE, NULL, TRUE, FALSE, FALSE),

    ('TP_DEMO_002', 'PRS_TELE_002', 'TC_DEMO_002', 'ENC_TELE_002', TRUE, TRUE,
     'DELIVERY', '456 Lê Lợi, Q3, TP.HCM', '0907654321',
     TRUE,  '2026-05-16 11:15:00+07', TRUE, FALSE, FALSE),

    ('TP_DEMO_003', 'PRS_TELE_003', 'TC_DEMO_003', 'ENC_TELE_003', TRUE, TRUE,
     'DIGITAL', NULL, '0912345678',
     FALSE, NULL, TRUE, FALSE, FALSE)
ON CONFLICT (tele_prescription_id) DO NOTHING;

INSERT INTO prescription_details
    (prescription_details_id, prescription_id, drug_id, quantity, dosage, frequency, duration_days, usage_instruction, route_of_administration)
VALUES
    -- Đơn 001 - đau đầu
    ('PD_TELE_001_1', 'PRS_TELE_001', 'DRG_001', 9,  '500mg', '3 lần/ngày', 3, 'Uống sau ăn, không vượt quá 3g/ngày', 'ORAL'),

    -- Đơn 002 - viêm họng bé
    ('PD_TELE_002_1', 'PRS_TELE_002', 'DRG_001', 6, '80mg/5ml', '4 lần/ngày khi sốt >38.5', 3, 'Uống khi sốt, cách nhau ít nhất 4 tiếng', 'ORAL'),
    ('PD_TELE_002_2', 'PRS_TELE_002', 'DRG_005', 6, '200mg', '1 lần/ngày', 3, 'Uống vào buổi sáng sau ăn', 'ORAL'),

    -- Đơn 003 - tăng huyết áp
    ('PD_TELE_003_1', 'PRS_TELE_003', 'DRG_002', 30, '5mg',  '1 lần/ngày',  30, 'Uống sáng, cùng giờ mỗi ngày', 'ORAL'),
    ('PD_TELE_003_2', 'PRS_TELE_003', 'DRG_003', 30, '500mg','2 lần/ngày', 30, 'Uống sau ăn sáng và tối',      'ORAL')
ON CONFLICT (prescription_details_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 9. tele_follow_up_plans — 5 kế hoạch tái khám
-- ---------------------------------------------------------------------
INSERT INTO tele_follow_up_plans
    (plan_id, tele_consultation_id, patient_id, doctor_id, encounter_id,
     plan_type, description, instructions, monitoring_items, frequency,
     start_date, end_date, next_follow_up_date, follow_up_type, status, created_at)
VALUES
    ('TFP_DEMO_001', 'TC_DEMO_001', 'PAT_SEED_1001', 'DOC_01', 'ENC_TELE_001',
     'SYMPTOM_TRACKING', 'Theo dõi triệu chứng đau đầu sau khi giảm stress',
     'BN báo cáo mức độ đau hàng ngày qua app, ghi nhật ký giấc ngủ',
     '["pain_level","sleep_hours","stress_level"]'::jsonb, 'DAILY',
     '2026-05-16', '2026-05-30', '2026-05-29', 'TELE', 'ACTIVE', '2026-05-15 09:35:00+07'),

    ('TFP_DEMO_002', 'TC_DEMO_002', 'PAT_SEED_1003', 'DOC_05', 'ENC_TELE_002',
     'POST_ILLNESS', 'Theo dõi bé sau viêm họng cấp',
     'Theo dõi nhiệt độ, ho, ăn uống của bé trong 5 ngày',
     '["temperature","cough_frequency","appetite"]'::jsonb, 'DAILY',
     '2026-05-17', '2026-05-22', '2026-05-23', 'TELE', 'ACTIVE', '2026-05-16 11:10:00+07'),

    ('TFP_DEMO_003', 'TC_DEMO_003', 'PAT_SEED_1004', 'DOC_02', 'ENC_TELE_003',
     'CHRONIC_DISEASE', 'Quản lý tăng huyết áp dài hạn',
     'Đo HA 2 lần/ngày (sáng/tối), ghi nhật ký vào app',
     '["systolic","diastolic","pulse","weight"]'::jsonb, 'DAILY',
     '2026-05-18', '2026-06-17', '2026-06-17', 'IN_PERSON', 'ACTIVE', '2026-05-17 14:35:00+07'),

    ('TFP_DEMO_004', 'TC_DEMO_001', 'PAT_SEED_1001', 'DOC_01', 'ENC_TELE_001',
     'MEDICATION_REVIEW', 'Đánh giá hiệu quả thuốc giảm đau',
     'BN báo cáo mức cải thiện sau 1 tuần dùng thuốc',
     '["pain_level","medication_taken"]'::jsonb, 'WEEKLY',
     '2026-04-20', '2026-05-04', '2026-05-04', 'TELE', 'COMPLETED', '2026-04-19 14:00:00+07'),

    ('TFP_DEMO_005', 'TC_DEMO_002', 'PAT_SEED_1003', 'DOC_05', 'ENC_TELE_002',
     'POST_ILLNESS', 'Theo dõi sau viêm phế quản',
     'Theo dõi ho, khó thở của bé',
     '["cough","wheeze","activity_level"]'::jsonb, 'DAILY',
     '2026-04-25', '2026-05-02', '2026-05-02', 'TELE', 'COMPLETED', '2026-04-24 10:00:00+07')
ON CONFLICT (plan_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 10. tele_health_updates — Update giúp 1 plan có needs_attention
-- ---------------------------------------------------------------------
INSERT INTO tele_health_updates
    (update_id, plan_id, reported_by, reporter_type, update_type, content, vital_data, severity_level, requires_attention, created_at)
VALUES
    ('THU_DEMO_001', 'TFP_DEMO_001', 'USR_SEED_001', 'PATIENT', 'SYMPTOM',
     'Đau đầu giảm rõ sau 3 ngày dùng thuốc', '{"pain_level":3,"sleep_hours":7.5}'::jsonb,
     'LOW', FALSE, '2026-05-17 20:00:00+07'),

    ('THU_DEMO_002', 'TFP_DEMO_001', 'USR_SEED_001', 'PATIENT', 'SYMPTOM',
     'Đau đầu tái phát nặng, kèm buồn nôn', '{"pain_level":8,"nausea":true}'::jsonb,
     'HIGH', TRUE, '2026-05-19 09:00:00+07'),

    ('THU_DEMO_003', 'TFP_DEMO_002', 'USR_SEED_002', 'PATIENT', 'VITAL',
     'Bé hạ sốt, ăn tốt hơn', '{"temperature":37.0,"appetite":"NORMAL"}'::jsonb,
     'LOW', FALSE, '2026-05-18 18:00:00+07'),

    ('THU_DEMO_004', 'TFP_DEMO_003', 'USR_SEED_003', 'PATIENT', 'VITAL',
     'HA hơi tăng buổi sáng', '{"systolic":145,"diastolic":92}'::jsonb,
     'MEDIUM', TRUE, '2026-05-19 07:30:00+07')
ON CONFLICT (update_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 11. tele_quality_reviews — 5 review từ BN sau khám
-- ---------------------------------------------------------------------
INSERT INTO tele_quality_reviews
    (review_id, tele_consultation_id, patient_id, doctor_id,
     doctor_professionalism, doctor_communication, doctor_knowledge, doctor_empathy, doctor_overall, doctor_comment,
     ease_of_use, waiting_time_rating, overall_satisfaction, would_recommend, patient_comment,
     video_quality, audio_quality, connection_stability, is_anonymous, created_at)
VALUES
    ('TQR_DEMO_001', 'TC_DEMO_001', 'USR_SEED_001', 'USR_DOC_01',
     5, 5, 5, 5, 5, 'Bác sĩ tận tâm, giải thích rõ ràng, tư vấn cụ thể',
     5, 5, 5, TRUE, 'Rất hài lòng, sẽ giới thiệu cho người thân',
     5, 5, 5, FALSE, '2026-05-15 10:00:00+07'),

    ('TQR_DEMO_002', 'TC_DEMO_002', 'USR_SEED_002', 'USR_DOC_05',
     5, 5, 5, 5, 5, 'Bác sĩ nhi rất kiên nhẫn với bé, hướng dẫn mẹ chu đáo',
     4, 5, 5, TRUE, 'Tiện lợi, không phải đưa bé đi xa',
     4, 5, 4, FALSE, '2026-05-16 11:30:00+07'),

    ('TQR_DEMO_003', 'TC_DEMO_003', 'USR_SEED_003', 'USR_DOC_02',
     4, 4, 5, 4, 4, 'Bác sĩ chuyên môn tốt, hơi nhanh',
     4, 3, 4, TRUE, 'Hài lòng, mong thời gian khám lâu hơn',
     5, 5, 5, FALSE, '2026-05-17 14:45:00+07')
ON CONFLICT (tele_consultation_id) DO NOTHING;

-- Một số review từ "consultation" cũ hơn (giả lập history)
INSERT INTO tele_consultations
    (tele_consultations_id, encounter_id, platform, join_url, call_status, consultation_type_id,
     room_status, room_opened_at, room_closed_at, total_duration_seconds, participant_count,
     has_video, has_audio, has_chat, has_result, result_status)
SELECT
    'TC_HIST_'||lpad(s::text,3,'0'),
    'ENC_HIST_'||lpad(s::text,3,'0'),
    'AGORA',
    'https://meet.ehealth.vn/c/hist'||s,
    'COMPLETED',
    CASE WHEN s % 2 = 0 THEN 'TCT_VIDEO' ELSE 'TCT_AUDIO' END,
    'COMPLETED',
    (CURRENT_TIMESTAMP - INTERVAL '1 day' * (s+10))::timestamptz,
    (CURRENT_TIMESTAMP - INTERVAL '1 day' * (s+10) + INTERVAL '30 minutes')::timestamptz,
    1800,
    2, TRUE, TRUE, TRUE, FALSE, NULL
FROM generate_series(1,5) AS s
WHERE NOT EXISTS (SELECT 1 FROM tele_consultations WHERE tele_consultations_id = 'TC_HIST_'||lpad(s::text,3,'0'));

-- Phải tạo encounters trước (nếu chưa có)
INSERT INTO encounters (encounters_id, patient_id, doctor_id, room_id, encounter_type, status, start_time, end_time, is_finalized)
SELECT
    'ENC_HIST_'||lpad(s::text,3,'0'),
    'PAT_SEED_'||lpad((1000+s)::text,4,'0'),
    CASE WHEN s % 3 = 0 THEN 'DOC_03' WHEN s % 3 = 1 THEN 'DOC_04' ELSE 'DOC_06' END,
    'ROOM_KB_05',
    'TELE',
    'COMPLETED',
    (CURRENT_TIMESTAMP - INTERVAL '1 day' * (s+10))::timestamptz,
    (CURRENT_TIMESTAMP - INTERVAL '1 day' * (s+10) + INTERVAL '30 minutes')::timestamptz,
    TRUE
FROM generate_series(1,5) AS s
WHERE NOT EXISTS (SELECT 1 FROM encounters WHERE encounters_id = 'ENC_HIST_'||lpad(s::text,3,'0'));

-- 5 review history
INSERT INTO tele_quality_reviews
    (review_id, tele_consultation_id, patient_id, doctor_id,
     doctor_professionalism, doctor_communication, doctor_knowledge, doctor_empathy, doctor_overall,
     ease_of_use, waiting_time_rating, overall_satisfaction, would_recommend,
     video_quality, audio_quality, connection_stability,
     doctor_comment, patient_comment, is_anonymous, created_at)
VALUES
    ('TQR_HIST_001', 'TC_HIST_001', 'USR_SEED_005', 'USR_DOC_04', 5, 5, 4, 5, 5, 5, 5, 5, TRUE, 4, 5, 4, 'Bác sĩ nhiệt tình', 'Tốt', FALSE, '2026-05-08 10:00+07'),
    ('TQR_HIST_002', 'TC_HIST_002', 'USR_SEED_006', 'USR_DOC_06', 4, 5, 5, 4, 4, 5, 4, 4, TRUE, 5, 5, 5, 'Tư vấn hữu ích', 'Ổn', FALSE, '2026-05-07 14:00+07'),
    ('TQR_HIST_003', 'TC_HIST_003', 'USR_SEED_007', 'USR_DOC_03', 5, 4, 5, 4, 5, 4, 5, 5, TRUE, 5, 5, 4, 'Chuyên nghiệp', 'Hài lòng', FALSE, '2026-05-06 09:00+07'),
    ('TQR_HIST_004', 'TC_HIST_004', 'USR_SEED_008', 'USR_DOC_04', 5, 5, 5, 5, 5, 5, 5, 5, TRUE, 5, 5, 5, 'Tuyệt vời', 'Rất hài lòng', FALSE, '2026-05-05 15:30+07'),
    ('TQR_HIST_005', 'TC_HIST_005', 'USR_SEED_009', 'USR_DOC_06', 3, 3, 4, 3, 3, 4, 2, 3, FALSE, 3, 3, 2, 'Có thể tốt hơn', 'Tạm ổn, chờ lâu', FALSE, '2026-05-04 16:00+07')
ON CONFLICT (tele_consultation_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 12. tele_quality_alerts — 4 alert mix mức độ và status
-- ---------------------------------------------------------------------
INSERT INTO tele_quality_alerts
    (alert_id, alert_type, severity, target_type, target_id, title, description, metrics_snapshot, status, created_at)
VALUES
    ('TQA_DEMO_001', 'LOW_RATING', 'CRITICAL', 'DOCTOR', 'USR_DOC_06',
     'Bác sĩ nhận đánh giá thấp 2 lần liên tiếp',
     'BS. Vũ Thị Phương có 2 review dưới 4 sao trong tuần qua, cần kiểm tra chất lượng dịch vụ',
     '{"avg_rating":3.5,"reviews_count":3,"recent_low":2}'::jsonb, 'OPEN', '2026-05-19 06:00:00+07'),

    ('TQA_DEMO_002', 'CONNECTION_ISSUE', 'WARNING', 'CONSULTATION', 'TC_DEMO_002',
     'Phiên khám có vấn đề kết nối',
     'Phiên khám của BS.Hoàng Văn Em với bé có 2 lần mất kết nối',
     '{"disconnect_count":2,"avg_latency":280}'::jsonb, 'OPEN', '2026-05-16 11:00:00+07'),

    ('TQA_DEMO_003', 'LONG_WAIT', 'WARNING', 'CONSULTATION', 'TC_DEMO_005',
     'Bệnh nhân chờ quá lâu',
     'BN đã chờ vào phòng tele >5 phút mà bác sĩ chưa join',
     '{"wait_minutes":6}'::jsonb, 'OPEN', CURRENT_TIMESTAMP - INTERVAL '4 minutes'),

    ('TQA_DEMO_004', 'CANCELLED_HIGH', 'INFO', 'DOCTOR', 'USR_DOC_03',
     'Số booking bị huỷ cao',
     'BS. Lê Văn Cường có tỉ lệ huỷ booking 15% trong tuần',
     '{"cancel_rate":0.15,"total":20}'::jsonb, 'RESOLVED', '2026-05-15 10:00:00+07')
ON CONFLICT (alert_id) DO NOTHING;

-- Update resolved alert
UPDATE tele_quality_alerts
SET resolved_at = '2026-05-16 14:00:00+07',
    resolved_by = 'USR_ADMIN_01',
    resolution_notes = 'Đã liên hệ BS xác nhận lịch & nhắc BN xác nhận trước 24h'
WHERE alert_id = 'TQA_DEMO_004' AND resolved_at IS NULL;

-- ---------------------------------------------------------------------
-- 13. tele_room_participants — Cho 3 phòng đang hoạt động
-- ---------------------------------------------------------------------
INSERT INTO tele_room_participants
    (participant_id, tele_consultation_id, user_id, participant_role, status, join_time, room_token, token_expires_at, is_video_on, is_audio_on, connection_quality)
VALUES
    ('TRP_DEMO_004_DOC', 'TC_DEMO_004', 'USR_DOC_05',   'DOCTOR',  'IN_ROOM', CURRENT_TIMESTAMP - INTERVAL '12 minutes', 'tok_004_doc', CURRENT_TIMESTAMP + INTERVAL '1 hour', TRUE, TRUE,  'GOOD'),
    ('TRP_DEMO_004_PAT', 'TC_DEMO_004', 'USR_SEED_004', 'PATIENT', 'IN_ROOM', CURRENT_TIMESTAMP - INTERVAL '11 minutes', 'tok_004_pat', CURRENT_TIMESTAMP + INTERVAL '1 hour', TRUE, TRUE,  'GOOD'),
    ('TRP_DEMO_005_DOC', 'TC_DEMO_005', 'USR_DOC_01',   'DOCTOR',  'WAITING', CURRENT_TIMESTAMP - INTERVAL '3 minutes',  'tok_005_doc', CURRENT_TIMESTAMP + INTERVAL '1 hour', FALSE, FALSE, NULL),
    ('TRP_DEMO_006_DOC', 'TC_DEMO_006', 'USR_DOC_04',   'DOCTOR',  'IN_ROOM', CURRENT_TIMESTAMP - INTERVAL '8 minutes',  'tok_006_doc', CURRENT_TIMESTAMP + INTERVAL '1 hour', FALSE, TRUE,  'EXCELLENT'),
    ('TRP_DEMO_006_PAT', 'TC_DEMO_006', 'USR_SEED_006', 'PATIENT', 'IN_ROOM', CURRENT_TIMESTAMP - INTERVAL '7 minutes',  'tok_006_pat', CURRENT_TIMESTAMP + INTERVAL '1 hour', FALSE, TRUE,  'GOOD')
ON CONFLICT (participant_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- Done. Verify counts
-- ---------------------------------------------------------------------
SELECT 'tele_consultation_types'   AS t, COUNT(*) FROM tele_consultation_types
UNION ALL SELECT 'tele_type_specialty_config', COUNT(*) FROM tele_type_specialty_config
UNION ALL SELECT 'tele_service_pricing',       COUNT(*) FROM tele_service_pricing
UNION ALL SELECT 'tele_booking_sessions',      COUNT(*) FROM tele_booking_sessions
UNION ALL SELECT 'encounters (TELE)',          COUNT(*) FROM encounters WHERE encounter_type = 'TELE'
UNION ALL SELECT 'tele_consultations',         COUNT(*) FROM tele_consultations
UNION ALL SELECT 'tele_consultation_results',  COUNT(*) FROM tele_consultation_results
UNION ALL SELECT 'tele_prescriptions',         COUNT(*) FROM tele_prescriptions
UNION ALL SELECT 'tele_follow_up_plans',       COUNT(*) FROM tele_follow_up_plans
UNION ALL SELECT 'tele_health_updates',        COUNT(*) FROM tele_health_updates
UNION ALL SELECT 'tele_quality_reviews',       COUNT(*) FROM tele_quality_reviews
UNION ALL SELECT 'tele_quality_alerts',        COUNT(*) FROM tele_quality_alerts
UNION ALL SELECT 'tele_room_participants',     COUNT(*) FROM tele_room_participants
ORDER BY t;
