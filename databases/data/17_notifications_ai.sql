-- =====================================================================
-- SEED DATA: 17_notifications_ai.sql
-- =====================================================================
-- Demo dữ liệu cho 3 bảng còn trống:
--   1. user_notifications  (30 rows) — 10 admin/staff + 10 doctor + 10 patient
--   2. ai_chat_sessions    (10 rows) — 5 phiên bệnh nhân + 5 phiên bác sĩ
--   3. ai_chat_messages    (50 rows) — ~5 messages/phiên, alternating USER/ASSISTANT
--
-- Idempotent: ON CONFLICT DO NOTHING — có thể chạy lại nhiều lần.
-- Span: tất cả timestamp nằm trong 7 ngày gần nhất (NOW() - INTERVAL).
--
-- Dependencies (thứ tự chạy):
--   - 01_core_roles_users.sql      (USR_ADMIN_*, USR_DOC_*, USR_NUR_*, USR_STF_*)
--   - 01b_patient_users.sql        (USR_PAT_*)
--   - 03_facilities.sql            (specialties — SPC_*)
--   - 07_patients.sql              (PAT_*)
--   - 10_notification_templates.sql (NTPL_APT_*)
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 1. USER_NOTIFICATIONS (30 rows: 10 admin/staff + 10 doctor + 10 patient)
-- Mix is_read TRUE/FALSE, mix template_id (NULL cho ad-hoc system notif)
-- ---------------------------------------------------------------------
INSERT INTO user_notifications (
    user_notifications_id, user_id, template_id, title, content,
    data_payload, is_read, read_at, created_at
) VALUES
-- ===== ADMIN / STAFF NOTIFICATIONS (10 rows) — cảnh báo vận hành =====
('NOTIF_DEMO_001', 'USR_ADMIN_01', NULL,
 'Cảnh báo tồn kho thấp',
 'Paracetamol 500mg còn dưới 100 viên tại kho trung tâm. Vui lòng nhập thêm hàng.',
 '{"module":"pharmacy","alert_type":"LOW_STOCK","drug_code":"PARA500"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '2 hours'),

('NOTIF_DEMO_002', 'USR_ADMIN_01', NULL,
 'Báo cáo doanh thu tuần',
 'Doanh thu tuần qua đạt 1.245.000.000 VND, tăng 12% so với tuần trước.',
 '{"module":"finance","revenue":1245000000,"growth":0.12}'::jsonb,
 TRUE, NOW() - INTERVAL '1 day', NOW() - INTERVAL '2 days'),

('NOTIF_DEMO_003', 'USR_ADMIN_01', NULL,
 'Cảnh báo bảo trì hệ thống',
 'Hệ thống sẽ bảo trì từ 23:00 ngày 19/05 đến 02:00 ngày 20/05. Vui lòng thông báo nhân viên.',
 '{"module":"system","maintenance_start":"2026-05-19T23:00:00Z"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '6 hours'),

('NOTIF_DEMO_004', 'USR_STF_01', NULL,
 'Yêu cầu xác nhận lịch hẹn',
 'Có 8 lịch hẹn mới chờ xác nhận tại quầy lễ tân. Vui lòng xử lý trong ca trực.',
 '{"module":"reception","pending_count":8}'::jsonb,
 TRUE, NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '3 hours'),

('NOTIF_DEMO_005', 'USR_STF_02', NULL,
 'Cập nhật quy trình check-in',
 'Quy trình check-in mới áp dụng từ 20/05. Vui lòng đọc tài liệu hướng dẫn đính kèm.',
 '{"module":"hr","doc_url":"/docs/checkin_v2.pdf"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '1 day'),

('NOTIF_DEMO_006', 'USR_PHA_01', NULL,
 'Đơn thuốc chờ phát',
 'Có 5 đơn thuốc chờ phát tại nhà thuốc. Vui lòng kiểm tra hàng đợi.',
 '{"module":"pharmacy","pending_prescriptions":5}'::jsonb,
 TRUE, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '4 hours'),

('NOTIF_DEMO_007', 'USR_PHA_02', NULL,
 'Cảnh báo thuốc hết hạn',
 'Lô Amlor 5mg (LOT-2024-A12) sẽ hết hạn trong 30 ngày. Vui lòng xử lý kho.',
 '{"module":"pharmacy","alert_type":"EXPIRY_WARN","lot_code":"LOT-2024-A12"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '12 hours'),

('NOTIF_DEMO_008', 'USR_NUR_01', NULL,
 'Phân công ca trực mới',
 'Bạn được phân công ca đêm 20/05 tại khoa Cấp cứu. Vui lòng xác nhận lịch.',
 '{"module":"hr","shift_date":"2026-05-20","department":"DEPT_CC"}'::jsonb,
 TRUE, NOW() - INTERVAL '5 hours', NOW() - INTERVAL '1 day'),

('NOTIF_DEMO_009', 'USR_NUR_02', NULL,
 'Yêu cầu duyệt vật tư y tế',
 'Có 3 yêu cầu nhập vật tư y tế đang chờ duyệt từ khoa Nội.',
 '{"module":"inventory","pending_requests":3}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '8 hours'),

('NOTIF_DEMO_010', 'USR_ADMIN_01', NULL,
 'Báo cáo audit log',
 '127 hành động truy cập quan trọng được ghi nhận hôm nay. Click để xem chi tiết.',
 '{"module":"security","audit_count":127}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '4 hours'),

-- ===== DOCTOR NOTIFICATIONS (10 rows) — lịch hẹn, BN mới =====
('NOTIF_DEMO_011', 'USR_DOC_01', 'NTPL_APT_CREATED',
 'Lịch hẹn mới được đặt',
 'Bệnh nhân Trần Đức Bảo đã đặt lịch khám lúc 10:00 ngày 20/05/2026. Mã lịch: APT-2026-1001.',
 '{"appointment_id":"APT_DEMO_001","patient_id":"PAT_001","slot_time":"10:00"}'::jsonb,
 TRUE, NOW() - INTERVAL '1 hour', NOW() - INTERVAL '5 hours'),

('NOTIF_DEMO_012', 'USR_DOC_01', 'NTPL_APT_REMINDER',
 'Nhắc lịch khám sắp tới',
 'Bạn có 3 lịch khám trong ngày mai (20/05). Lịch đầu tiên lúc 08:30.',
 '{"appointment_count":3,"first_slot":"08:30"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '6 hours'),

('NOTIF_DEMO_013', 'USR_DOC_02', 'NTPL_APT_CHECKEDIN',
 'Bệnh nhân đã check-in',
 'BN Lê Thanh Diệu đã check-in lúc 08:45. STT: 12. Vui lòng chuẩn bị khám.',
 '{"patient_id":"PAT_002","queue_number":12}'::jsonb,
 TRUE, NOW() - INTERVAL '15 minutes', NOW() - INTERVAL '20 minutes'),

('NOTIF_DEMO_014', 'USR_DOC_02', NULL,
 'Yêu cầu hội chẩn',
 'BS Trần Thị Lan yêu cầu hội chẩn ca BN Phạm Quang Dũng (CT scan bất thường).',
 '{"consult_type":"INTERNAL","patient_id":"PAT_003","from_doctor":"USR_DOC_05"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '3 hours'),

('NOTIF_DEMO_015', 'USR_DOC_03', 'NTPL_APT_RESCHEDULED',
 'Lịch hẹn đã đổi giờ',
 'BN Hoàng Kim Hạnh đã đổi lịch khám sang 14:00 ngày 21/05/2026.',
 '{"patient_id":"PAT_004","new_slot":"2026-05-21 14:00"}'::jsonb,
 TRUE, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '8 hours'),

('NOTIF_DEMO_016', 'USR_DOC_03', NULL,
 'Kết quả xét nghiệm có sẵn',
 'Kết quả CBC + sinh hóa của BN Huỳnh Tấn Hải đã có. Vui lòng kiểm tra trước khi khám.',
 '{"patient_id":"PAT_005","lab_order_id":"LAB_001"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '1 day'),

('NOTIF_DEMO_017', 'USR_DOC_04', 'NTPL_APT_CANCELLED',
 'Lịch hẹn bị hủy',
 'BN Vũ Ánh Lan đã hủy lịch khám 11:00 ngày 19/05. Lý do: bận việc đột xuất.',
 '{"patient_id":"PAT_006","cancel_reason":"BUSY"}'::jsonb,
 TRUE, NOW() - INTERVAL '4 hours', NOW() - INTERVAL '10 hours'),

('NOTIF_DEMO_018', 'USR_DOC_05', NULL,
 'Cảnh báo dị ứng thuốc',
 'BN Võ Xuân Khang có tiền sử dị ứng Penicillin. Lưu ý khi kê đơn.',
 '{"patient_id":"PAT_007","allergy":"PENICILLIN"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '2 days'),

('NOTIF_DEMO_019', 'USR_DOC_06', 'NTPL_APT_COMPLETED',
 'Hoàn tất khám bệnh',
 'Phiên khám BN Đặng Diệu Mai đã hoàn tất. Vui lòng xác nhận hồ sơ điện tử.',
 '{"patient_id":"PAT_008","encounter_id":"ENC_DEMO_008"}'::jsonb,
 TRUE, NOW() - INTERVAL '1 day', NOW() - INTERVAL '2 days'),

('NOTIF_DEMO_020', 'USR_DOC_07', NULL,
 'Đơn xin nghỉ phép đã duyệt',
 'Đơn xin nghỉ phép 22-24/05 của bạn đã được Trưởng khoa duyệt.',
 '{"leave_id":"LV_DEMO_001","status":"APPROVED"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '18 hours'),

-- ===== PATIENT NOTIFICATIONS (10 rows) — lịch hẹn, đơn thuốc =====
('NOTIF_DEMO_021', 'USR_PAT_001', 'NTPL_APT_REMINDER',
 'Nhắc lịch khám ngày mai',
 'Bạn có lịch khám với BS Nguyễn Văn Hùng lúc 09:00 ngày 20/05/2026 tại phòng 201.',
 '{"appointment_id":"APT_DEMO_001","doctor":"BS Nguyễn Văn Hùng","slot":"09:00"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '12 hours'),

('NOTIF_DEMO_022', 'USR_PAT_002', 'NTPL_APT_CONFIRMED',
 'Lịch khám đã được xác nhận',
 'Lịch khám APT-2026-1002 của bạn ngày 20/05/2026 lúc 09:30 đã được xác nhận.',
 '{"appointment_id":"APT_DEMO_002","slot":"09:30"}'::jsonb,
 TRUE, NOW() - INTERVAL '5 hours', NOW() - INTERVAL '1 day'),

('NOTIF_DEMO_023', 'USR_PAT_003', NULL,
 'Đơn thuốc đã sẵn sàng',
 'Đơn thuốc Rx-2026-0312 của bạn đã sẵn sàng tại nhà thuốc tầng trệt.',
 '{"prescription_id":"RX_DEMO_001","pickup_location":"PHARMACY_MAIN"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '3 hours'),

('NOTIF_DEMO_024', 'USR_PAT_004', NULL,
 'Kết quả xét nghiệm đã có',
 'Kết quả tổng phân tích máu của bạn đã có. Đăng nhập app để xem chi tiết.',
 '{"lab_order_id":"LAB_DEMO_004","patient_id":"PAT_004"}'::jsonb,
 TRUE, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '8 hours'),

('NOTIF_DEMO_025', 'USR_PAT_005', NULL,
 'Hóa đơn cần thanh toán',
 'Hóa đơn INV-2026-0521 trị giá 850.000 VND chờ thanh toán. Hạn: 22/05/2026.',
 '{"invoice_id":"INV_DEMO_005","amount":850000,"due_date":"2026-05-22"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '6 hours'),

('NOTIF_DEMO_026', 'USR_PAT_006', 'NTPL_APT_CREATED',
 'Đặt lịch khám thành công',
 'Bạn đã đặt lịch khám thành công ngày 22/05/2026 lúc 10:30 với BS Trần Văn Nam.',
 '{"appointment_id":"APT_DEMO_006","doctor":"BS Trần Văn Nam"}'::jsonb,
 TRUE, NOW() - INTERVAL '4 hours', NOW() - INTERVAL '1 day'),

('NOTIF_DEMO_027', 'USR_PAT_007', NULL,
 'Khuyến mãi gói khám tổng quát',
 'Giảm 20% gói khám tổng quát đến hết 31/05/2026. Dùng mã GENERAL20 khi đặt lịch.',
 '{"promo_code":"GENERAL20","discount":0.20,"valid_until":"2026-05-31"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '2 days'),

('NOTIF_DEMO_028', 'USR_PAT_008', NULL,
 'Nhắc tái khám',
 'Đã đến hạn tái khám sau điều trị tăng huyết áp. Vui lòng đặt lịch trong 7 ngày tới.',
 '{"reminder_type":"FOLLOWUP","last_visit":"2026-04-20"}'::jsonb,
 TRUE, NOW() - INTERVAL '1 day', NOW() - INTERVAL '2 days'),

('NOTIF_DEMO_029', 'USR_PAT_009', 'NTPL_APT_CANCELLED',
 'Lịch khám đã hủy',
 'Lịch khám APT-2026-1009 ngày 19/05 đã được hủy do bác sĩ bận đột xuất. Xin lỗi quý khách.',
 '{"appointment_id":"APT_DEMO_009","cancel_by":"DOCTOR"}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '10 hours'),

('NOTIF_DEMO_030', 'USR_PAT_010', NULL,
 'Chương trình tiêm chủng',
 'Phòng khám tổ chức tiêm vắc-xin cúm mùa từ 25-30/05. Đăng ký tại quầy lễ tân.',
 '{"event_type":"VACCINATION","event_dates":["2026-05-25","2026-05-30"]}'::jsonb,
 FALSE, NULL, NOW() - INTERVAL '3 days')
ON CONFLICT (user_notifications_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 2. AI_CHAT_SESSIONS (10 phiên — 5 BN consult + 5 doctor lookup)
-- Mix status ACTIVE/COMPLETED. patient_id NULL cho doctor sessions.
-- ---------------------------------------------------------------------
INSERT INTO ai_chat_sessions (
    session_id, session_code, patient_id, user_id,
    suggested_specialty_id, suggested_specialty_name, suggested_priority,
    symptoms_summary, ai_conclusion,
    status, message_count, appointment_id,
    created_at, updated_at, completed_at
) VALUES
-- ===== PATIENT CONSULT SESSIONS (5 rows) =====
('AICS_DEMO_001', 'AIC-20260516-0001', 'PAT_001', 'USR_PAT_001',
 'SPC_NOI', 'Nội khoa', 'SOON',
 'Đau đầu kéo dài 3 ngày, không hết khi uống Paracetamol, kèm chóng mặt nhẹ.',
 'Gợi ý khám chuyên khoa Nội để loại trừ tăng huyết áp, đau đầu căng cơ hoặc nguyên nhân thần kinh.',
 'COMPLETED', 6, NULL,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '15 minutes',
 NOW() - INTERVAL '3 days' + INTERVAL '15 minutes'),

('AICS_DEMO_002', 'AIC-20260517-0002', 'PAT_005', 'USR_PAT_005',
 'SPC_TONG_QUAT', 'Đa khoa Tổng quát', 'NORMAL',
 'Hỏi về cách dùng thuốc Amlor 5mg điều trị tăng huyết áp.',
 'Tư vấn cách uống Amlor 5mg: 1 viên/ngày vào buổi sáng, không bỏ liều. Cần theo dõi huyết áp tại nhà.',
 'COMPLETED', 5, NULL,
 NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '10 minutes',
 NOW() - INTERVAL '2 days' + INTERVAL '10 minutes'),

('AICS_DEMO_003', 'AIC-20260519-0003', 'PAT_010', 'USR_PAT_010',
 'SPC_NOI', 'Nội khoa', 'NORMAL',
 'Tư vấn khẩu phần ăn cho người tiểu đường type 2.',
 NULL,
 'ACTIVE', 4, NULL,
 NOW() - INTERVAL '1 hour', NOW() - INTERVAL '5 minutes',
 NULL),

('AICS_DEMO_004', 'AIC-20260515-0004', 'PAT_015', 'USR_PAT_015',
 'SPC_NHI', 'Nhi khoa', 'URGENT',
 'Con 3 tuổi sốt cao 39.5°C, không hạ sốt sau khi uống Hapacol 250mg, lừ đừ.',
 'Cảnh báo dấu hiệu nguy hiểm. Yêu cầu đưa trẻ đến phòng khám Nhi hoặc cấp cứu ngay.',
 'COMPLETED', 5, NULL,
 NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days' + INTERVAL '8 minutes',
 NOW() - INTERVAL '4 days' + INTERVAL '8 minutes'),

('AICS_DEMO_005', 'AIC-20260518-0005', 'PAT_020', 'USR_PAT_020',
 'SPC_SAN', 'Sản - Phụ khoa', 'SOON',
 'Mang thai tuần 32, đau bụng âm ỉ, có ra chút máu.',
 'Khuyến nghị đến khám Sản khoa trong vòng 24h để loại trừ dấu hiệu chuyển dạ sớm hoặc nhau bong non.',
 'COMPLETED', 6, NULL,
 NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '12 minutes',
 NOW() - INTERVAL '1 day' + INTERVAL '12 minutes'),

-- ===== DOCTOR LOOKUP SESSIONS (5 rows) — patient_id NULL, user là BS =====
('AICS_DEMO_006', 'AIC-20260519-0006', NULL, 'USR_DOC_01',
 NULL, NULL, NULL,
 'BS tra cứu mã ICD-10 cho viêm phế quản cấp tính.',
 'ICD-10: J20 (Acute bronchitis), phân nhóm theo tác nhân J20.0-J20.9.',
 'COMPLETED', 4, NULL,
 NOW() - INTERVAL '5 hours', NOW() - INTERVAL '5 hours' + INTERVAL '3 minutes',
 NOW() - INTERVAL '5 hours' + INTERVAL '3 minutes'),

('AICS_DEMO_007', 'AIC-20260518-0007', NULL, 'USR_DOC_03',
 NULL, NULL, NULL,
 'BS tra cứu tương tác thuốc giữa Paracetamol và Warfarin.',
 'Cảnh báo: Paracetamol liều cao kéo dài (>2g/ngày, >7 ngày) làm tăng INR ở BN dùng Warfarin. Theo dõi INR sát.',
 'COMPLETED', 6, NULL,
 NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '5 minutes',
 NOW() - INTERVAL '1 day' + INTERVAL '5 minutes'),

('AICS_DEMO_008', 'AIC-20260516-0008', NULL, 'USR_DOC_05',
 NULL, NULL, NULL,
 'BS hỏi phác đồ điều trị viêm dạ dày HP dương tính.',
 'Phác đồ 3 thuốc 14 ngày: PPI + Amoxicillin 1g x2 + Clarithromycin 500mg x2. Test lại UBT sau 4 tuần.',
 'COMPLETED', 5, NULL,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '4 minutes',
 NOW() - INTERVAL '3 days' + INTERVAL '4 minutes'),

('AICS_DEMO_009', 'AIC-20260519-0009', NULL, 'USR_DOC_07',
 NULL, NULL, NULL,
 'BS Nhi tra cứu liều paracetamol theo cân nặng cho trẻ em.',
 'Liều khuyến cáo: 10-15 mg/kg/lần, mỗi 4-6h. Tối đa 60 mg/kg/ngày. Không dùng cho trẻ <3 tháng nếu chưa hỏi BS.',
 'ACTIVE', 4, NULL,
 NOW() - INTERVAL '2 hours', NOW() - INTERVAL '10 minutes',
 NULL),

('AICS_DEMO_010', 'AIC-20260514-0010', NULL, 'USR_DOC_09',
 NULL, NULL, NULL,
 'BS tra cứu chẩn đoán phân biệt khó thở cấp ở người trẻ.',
 'Chẩn đoán phân biệt: hen phế quản, viêm phổi, thuyên tắc phổi, tràn khí màng phổi, hoảng loạn. Cần X-quang ngực và D-dimer.',
 'COMPLETED', 5, NULL,
 NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '6 minutes',
 NOW() - INTERVAL '5 days' + INTERVAL '6 minutes')
ON CONFLICT (session_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 3. AI_CHAT_MESSAGES (50 rows, alternating USER/ASSISTANT roles)
-- 5 messages/session avg: 6+5+4+5+6+4+6+5+4+5 = 50
-- ---------------------------------------------------------------------
INSERT INTO ai_chat_messages (
    message_id, session_id, role, content,
    model_used, tokens_used, response_time_ms, analysis_data, created_at
) VALUES
-- ===== Session AICS_DEMO_001 — Đau đầu (6 messages) =====
('AICM_DEMO_001', 'AICS_DEMO_001', 'USER',
 'Tôi bị đau đầu liên tục 3 ngày, uống Panadol cũng không hết. Có sao không bác sĩ?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '3 days'),

('AICM_DEMO_002', 'AICS_DEMO_001', 'ASSISTANT',
 'Chào bạn. Để hỗ trợ tốt hơn, bạn cho mình hỏi: đau ở vị trí nào (trán, hai bên thái dương, sau gáy)? Có kèm buồn nôn, sốt, hay chóng mặt không?',
 'gemini-2.0-flash', 85, 1200,
 '{"phase":"DISCOVERY","is_complete":false,"follow_up_questions":["vị trí đau","triệu chứng kèm"]}'::jsonb,
 NOW() - INTERVAL '3 days' + INTERVAL '30 seconds'),

('AICM_DEMO_003', 'AICS_DEMO_001', 'USER',
 'Đau hai bên thái dương, kèm chóng mặt nhẹ. Không sốt, không buồn nôn.',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '3 days' + INTERVAL '1 minute'),

('AICM_DEMO_004', 'AICS_DEMO_001', 'ASSISTANT',
 'Cảm ơn bạn. Bạn có bị tăng huyết áp, làm việc với máy tính nhiều, hay đang stress không? Triệu chứng có nặng hơn vào buổi chiều/tối không?',
 'gemini-2.0-flash', 95, 1100,
 '{"phase":"DISCOVERY","is_complete":false,"symptoms_collected":["đau thái dương","chóng mặt"]}'::jsonb,
 NOW() - INTERVAL '3 days' + INTERVAL '2 minutes'),

('AICM_DEMO_005', 'AICS_DEMO_001', 'USER',
 'Tôi hay làm việc máy tính 10 tiếng/ngày, có thể bị tăng huyết áp nhẹ. Chiều tối thường nặng hơn.',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '3 days' + INTERVAL '8 minutes'),

('AICM_DEMO_006', 'AICS_DEMO_001', 'ASSISTANT',
 'Với triệu chứng này, mình gợi ý bạn khám chuyên khoa Nội để loại trừ tăng huyết áp và đau đầu căng cơ. Trong khi chờ khám, bạn nên: nghỉ ngơi mắt mỗi 30 phút, uống đủ nước, đo huyết áp tại nhà. Bạn có muốn đặt lịch khám Nội không?',
 'gemini-2.0-flash', 180, 1500,
 '{"phase":"CONCLUSION","is_complete":true,"suggested_specialty_code":"NOI-KHOA","priority":"SOON","should_suggest_booking":true}'::jsonb,
 NOW() - INTERVAL '3 days' + INTERVAL '14 minutes'),

-- ===== Session AICS_DEMO_002 — Amlor 5mg (5 messages) =====
('AICM_DEMO_007', 'AICS_DEMO_002', 'USER',
 'Bác sĩ kê cho tôi Amlor 5mg điều trị tăng huyết áp. Tôi nên uống lúc nào và có cần kiêng gì không?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '2 days'),

('AICM_DEMO_008', 'AICS_DEMO_002', 'ASSISTANT',
 'Amlor (Amlodipine) 5mg thường uống 1 viên/ngày vào buổi sáng, trước hoặc sau ăn đều được, uống vào giờ cố định. Bạn nên đo huyết áp tại nhà mỗi sáng để theo dõi. Có cần mình hướng dẫn cách đo không?',
 'gemini-2.0-flash', 130, 1300,
 '{"phase":"INFO","is_complete":false}'::jsonb,
 NOW() - INTERVAL '2 days' + INTERVAL '45 seconds'),

('AICM_DEMO_009', 'AICS_DEMO_002', 'USER',
 'Có. Và Amlor có tác dụng phụ gì không? Tôi có cần kiêng nước bưởi không?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '2 days' + INTERVAL '3 minutes'),

('AICM_DEMO_010', 'AICS_DEMO_002', 'ASSISTANT',
 'Tác dụng phụ thường gặp: phù mắt cá chân, đỏ bừng mặt, nhức đầu nhẹ trong tuần đầu. KHÔNG uống nước bưởi (grapefruit) vì làm tăng nồng độ thuốc gây tụt huyết áp. Hạn chế muối <5g/ngày, tập thể dục 30 phút/ngày.',
 'gemini-2.0-flash', 175, 1450,
 '{"phase":"INFO","is_complete":false,"safety_warning":"grapefruit_interaction"}'::jsonb,
 NOW() - INTERVAL '2 days' + INTERVAL '4 minutes'),

('AICM_DEMO_011', 'AICS_DEMO_002', 'ASSISTANT',
 'Nếu trong tuần đầu bạn có phù chân nặng, chóng mặt khi đứng dậy, hoặc tim đập nhanh bất thường, vui lòng quay lại tái khám sớm. Chúc bạn khỏe!',
 'gemini-2.0-flash', 95, 1000,
 '{"phase":"CONCLUSION","is_complete":true}'::jsonb,
 NOW() - INTERVAL '2 days' + INTERVAL '9 minutes'),

-- ===== Session AICS_DEMO_003 — Tiểu đường (4 messages, ACTIVE) =====
('AICM_DEMO_012', 'AICS_DEMO_003', 'USER',
 'Tôi mới phát hiện bị tiểu đường type 2, đường huyết 8.5 mmol/L. Tôi nên ăn uống như thế nào?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '1 hour'),

('AICM_DEMO_013', 'AICS_DEMO_003', 'ASSISTANT',
 'Chào bạn. Bạn nặng bao nhiêu kg, cao bao nhiêu cm, và đang dùng thuốc gì để mình tư vấn khẩu phần phù hợp?',
 'gemini-2.0-flash', 70, 950,
 '{"phase":"DISCOVERY","is_complete":false}'::jsonb,
 NOW() - INTERVAL '55 minutes'),

('AICM_DEMO_014', 'AICS_DEMO_003', 'USER',
 'Tôi 65 kg, cao 1m65, đang uống Metformin 500mg x 2 lần/ngày.',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '30 minutes'),

('AICM_DEMO_015', 'AICS_DEMO_003', 'ASSISTANT',
 'Với BMI 23.9 (gần thừa cân), bạn nên: chia 3 bữa chính + 2 bữa phụ. Hạn chế cơm trắng (1 chén/bữa), tăng rau xanh, đạm nạc (cá, thịt gà bỏ da). Tránh nước ngọt, bánh ngọt. Bạn có muốn mình gợi ý thực đơn 1 tuần mẫu không?',
 'gemini-2.0-flash', 180, 1400,
 '{"phase":"ADVICE","is_complete":false,"bmi":23.9}'::jsonb,
 NOW() - INTERVAL '10 minutes'),

-- ===== Session AICS_DEMO_004 — Trẻ sốt cao (5 messages) =====
('AICM_DEMO_016', 'AICS_DEMO_004', 'USER',
 'Con tôi 3 tuổi sốt 39.5 độ, đã uống Hapacol 250mg 2 lần nhưng không hạ, bé lừ đừ. Có sao không?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '4 days'),

('AICM_DEMO_017', 'AICS_DEMO_004', 'ASSISTANT',
 'CẢNH BÁO: Trẻ 3 tuổi sốt cao kéo dài >24h, không đáp ứng hạ sốt và LỪ ĐỪ là dấu hiệu nguy hiểm. Bạn cần đưa bé đến phòng khám Nhi hoặc cấp cứu NGAY trong 1-2 giờ tới. Trong khi di chuyển: lau mát bằng nước ấm 30-32°C, cho uống đủ nước.',
 'gemini-2.0-flash', 165, 1300,
 '{"phase":"URGENT_REFERRAL","is_complete":true,"priority":"URGENT","suggested_specialty_code":"NHI-KHOA"}'::jsonb,
 NOW() - INTERVAL '4 days' + INTERVAL '30 seconds'),

('AICM_DEMO_018', 'AICS_DEMO_004', 'USER',
 'Có thể cho bé uống thêm thuốc hạ sốt khác không? Khoảng cách bao lâu?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '4 days' + INTERVAL '2 minutes'),

('AICM_DEMO_019', 'AICS_DEMO_004', 'ASSISTANT',
 'KHÔNG tự ý thêm thuốc khác. Hapacol (Paracetamol) cách 4-6h mới được uống lần kế. Có thể xen kẽ Ibuprofen 100mg (cách Paracetamol 3h) NHƯNG chỉ khi BS đồng ý. ƯU TIÊN: đưa bé đi khám ngay, KHÔNG chờ thêm.',
 'gemini-2.0-flash', 140, 1200,
 '{"phase":"URGENT_REFERRAL","safety_warning":"no_self_medication"}'::jsonb,
 NOW() - INTERVAL '4 days' + INTERVAL '3 minutes'),

('AICM_DEMO_020', 'AICS_DEMO_004', 'ASSISTANT',
 'Dấu hiệu cần gọi cấp cứu ngay: co giật, tím tái, không tỉnh, không bú/uống, thở rút lõm ngực. Bạn ghi nhớ và liên hệ ngay nếu có bất kỳ dấu hiệu nào.',
 'gemini-2.0-flash', 100, 1100,
 '{"phase":"CONCLUSION","is_complete":true}'::jsonb,
 NOW() - INTERVAL '4 days' + INTERVAL '7 minutes'),

-- ===== Session AICS_DEMO_005 — Thai 32 tuần (6 messages) =====
('AICM_DEMO_021', 'AICS_DEMO_005', 'USER',
 'Tôi đang mang thai tuần 32, đau bụng âm ỉ từ tối qua, sáng nay có ra chút máu nâu nhẹ.',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '1 day'),

('AICM_DEMO_022', 'AICS_DEMO_005', 'ASSISTANT',
 'Đây là dấu hiệu cần được khám SẢN KHOA trong vòng 24h. Bạn cho mình hỏi: đau bụng có cơn không (giống cơn gò) hay đau liên tục? Lượng máu nhiều hay ít? Có ra dịch âm đạo bất thường không?',
 'gemini-2.0-flash', 130, 1300,
 '{"phase":"DISCOVERY","is_complete":false,"priority":"SOON"}'::jsonb,
 NOW() - INTERVAL '1 day' + INTERVAL '45 seconds'),

('AICM_DEMO_023', 'AICS_DEMO_005', 'USER',
 'Đau âm ỉ liên tục, không có cơn rõ. Máu rất ít, chỉ thấy khi đi vệ sinh. Không ra dịch.',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '1 day' + INTERVAL '3 minutes'),

('AICM_DEMO_024', 'AICS_DEMO_005', 'ASSISTANT',
 'Em bé có cử động bình thường không? (Tuần 32 nên đếm cử động: ít nhất 10 lần trong 2 giờ khi mẹ nằm nghỉ).',
 'gemini-2.0-flash', 75, 950,
 '{"phase":"DISCOVERY","is_complete":false,"symptoms_collected":["đau bụng âm ỉ","ra máu nâu nhẹ"]}'::jsonb,
 NOW() - INTERVAL '1 day' + INTERVAL '4 minutes'),

('AICM_DEMO_025', 'AICS_DEMO_005', 'USER',
 'Em bé đạp ít hơn hôm qua, mới có khoảng 5-6 lần từ sáng.',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '1 day' + INTERVAL '7 minutes'),

('AICM_DEMO_026', 'AICS_DEMO_005', 'ASSISTANT',
 'Giảm cử động thai + ra máu + đau bụng là nhóm 3 dấu hiệu cần khám SẢN KHOA NGAY trong vòng 6-12h để loại trừ: nhau bong non, chuyển dạ sớm, hoặc suy thai. Bạn nên đến BV có khoa Sản hoặc cấp cứu sản. Trong lúc di chuyển: nằm nghiêng trái, hạn chế vận động.',
 'gemini-2.0-flash', 195, 1500,
 '{"phase":"CONCLUSION","is_complete":true,"priority":"SOON","suggested_specialty_code":"SAN-KHOA","should_suggest_booking":true}'::jsonb,
 NOW() - INTERVAL '1 day' + INTERVAL '11 minutes'),

-- ===== Session AICS_DEMO_006 — BS tra ICD-10 viêm phế quản (4 messages) =====
('AICM_DEMO_027', 'AICS_DEMO_006', 'USER',
 'Cho tôi mã ICD-10 cho viêm phế quản cấp tính.',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '5 hours'),

('AICM_DEMO_028', 'AICS_DEMO_006', 'ASSISTANT',
 'ICD-10 cho viêm phế quản cấp tính: **J20** (Acute bronchitis). Phân nhóm theo tác nhân: J20.0 do Mycoplasma, J20.1 do H. influenzae, J20.2 do liên cầu, J20.3-J20.8 do virus, J20.9 không xác định.',
 'gemini-2.0-flash', 110, 900,
 '{"icd_code":"J20","category":"Respiratory"}'::jsonb,
 NOW() - INTERVAL '5 hours' + INTERVAL '20 seconds'),

('AICM_DEMO_029', 'AICS_DEMO_006', 'USER',
 'Nếu viêm phế quản mạn thì khác mã nào?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '5 hours' + INTERVAL '1 minute'),

('AICM_DEMO_030', 'AICS_DEMO_006', 'ASSISTANT',
 'Viêm phế quản MẠN: **J40** (không phân biệt cấp/mạn), **J41** (mạn đơn thuần), **J42** (không đặc hiệu). Lưu ý: nếu kèm COPD thì code J44.',
 'gemini-2.0-flash', 85, 850,
 '{"icd_code":"J40-J44","category":"Respiratory"}'::jsonb,
 NOW() - INTERVAL '5 hours' + INTERVAL '2 minutes'),

-- ===== Session AICS_DEMO_007 — BS tra tương tác thuốc (6 messages) =====
('AICM_DEMO_031', 'AICS_DEMO_007', 'USER',
 'Bệnh nhân đang dùng Warfarin 5mg/ngày. Nếu cho thêm Paracetamol 500mg x 3 lần/ngày trong 5 ngày có sao không?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '1 day'),

('AICM_DEMO_032', 'AICS_DEMO_007', 'ASSISTANT',
 'Tương tác Paracetamol-Warfarin: liều thấp ngắn ngày (1.5g/ngày x 5 ngày) THƯỜNG AN TOÀN. Cảnh báo: liều >2g/ngày trên 7-14 ngày làm tăng INR có ý nghĩa (cơ chế chưa rõ, có thể qua CYP). Khuyến cáo: theo dõi INR sau 5-7 ngày phối hợp.',
 'gemini-2.0-flash', 165, 1400,
 '{"interaction_severity":"MODERATE","monitoring":"INR_FOLLOWUP"}'::jsonb,
 NOW() - INTERVAL '1 day' + INTERVAL '30 seconds'),

('AICM_DEMO_033', 'AICS_DEMO_007', 'USER',
 'Vậy có thuốc giảm đau nào an toàn hơn cho BN dùng Warfarin?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '1 day' + INTERVAL '1 minute'),

('AICM_DEMO_034', 'AICS_DEMO_007', 'ASSISTANT',
 'Lựa chọn an toàn hơn: **Paracetamol liều thấp** (<2g/ngày, ngắn ngày) vẫn là ưu tiên. TRÁNH: NSAIDs (Ibuprofen, Diclofenac, Aspirin) vì tăng nguy cơ chảy máu tiêu hóa. Có thể dùng: Tramadol liều thấp khi đau vừa-nặng (lưu ý tăng INR nhẹ).',
 'gemini-2.0-flash', 145, 1300,
 '{"recommended":["Paracetamol low-dose","Tramadol"],"avoid":["NSAIDs"]}'::jsonb,
 NOW() - INTERVAL '1 day' + INTERVAL '2 minutes'),

('AICM_DEMO_035', 'AICS_DEMO_007', 'USER',
 'INR mục tiêu trong rung nhĩ là bao nhiêu?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '1 day' + INTERVAL '3 minutes'),

('AICM_DEMO_036', 'AICS_DEMO_007', 'ASSISTANT',
 'INR mục tiêu rung nhĩ không van: **2.0-3.0** (tối ưu 2.5). Rung nhĩ có van cơ học: **2.5-3.5**. Nếu BN >75 tuổi hoặc có nguy cơ chảy máu cao: mục tiêu thấp hơn (1.8-2.5). Tham khảo guideline ESC 2024.',
 'gemini-2.0-flash', 130, 1200,
 '{"reference":"ESC_2024","target_inr":"2.0-3.0"}'::jsonb,
 NOW() - INTERVAL '1 day' + INTERVAL '4 minutes'),

-- ===== Session AICS_DEMO_008 — BS phác đồ HP (5 messages) =====
('AICM_DEMO_037', 'AICS_DEMO_008', 'USER',
 'Phác đồ điều trị HP dương tính lần đầu hiện tại là gì? BN không dị ứng penicillin.',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '3 days'),

('AICM_DEMO_038', 'AICS_DEMO_008', 'ASSISTANT',
 'Phác đồ ưu tiên (Maastricht VI 2022, khu vực kháng Clarithromycin <15%): **3 thuốc 14 ngày** — PPI (Omeprazole 20mg / Esomeprazole 40mg) BID + Amoxicillin 1g BID + Clarithromycin 500mg BID.',
 'gemini-2.0-flash', 150, 1300,
 '{"protocol":"Maastricht_VI","regimen":"Triple_14d"}'::jsonb,
 NOW() - INTERVAL '3 days' + INTERVAL '30 seconds'),

('AICM_DEMO_039', 'AICS_DEMO_008', 'USER',
 'Nếu khu vực kháng Clarithromycin cao (>15%) thì sao?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '3 days' + INTERVAL '1 minute'),

('AICM_DEMO_040', 'AICS_DEMO_008', 'ASSISTANT',
 'Khuyến cáo phác đồ **4 thuốc Bismuth 14 ngày**: PPI BID + Bismuth subcitrate 120mg QID + Tetracycline 500mg QID + Metronidazole 500mg TID. Hoặc phác đồ tuần tự 10 ngày.',
 'gemini-2.0-flash', 130, 1250,
 '{"alternative":"Bismuth_Quadruple_14d"}'::jsonb,
 NOW() - INTERVAL '3 days' + INTERVAL '2 minutes'),

('AICM_DEMO_041', 'AICS_DEMO_008', 'ASSISTANT',
 'Sau điều trị: test xác nhận tiệt trừ bằng UBT (urea breath test) hoặc test kháng nguyên trong phân, ít nhất 4 tuần sau khi dừng kháng sinh và 2 tuần sau khi dừng PPI.',
 'gemini-2.0-flash', 105, 1100,
 '{"followup":"UBT_4weeks_post"}'::jsonb,
 NOW() - INTERVAL '3 days' + INTERVAL '3 minutes'),

-- ===== Session AICS_DEMO_009 — BS Nhi liều Paracetamol (4 messages, ACTIVE) =====
('AICM_DEMO_042', 'AICS_DEMO_009', 'USER',
 'Cho tôi liều paracetamol theo cân nặng cho trẻ em.',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '2 hours'),

('AICM_DEMO_043', 'AICS_DEMO_009', 'ASSISTANT',
 'Liều paracetamol cho trẻ em: **10-15 mg/kg/lần**, mỗi 4-6h. Tối đa **60 mg/kg/ngày** (không quá 4g/ngày). Không dùng cho trẻ <3 tháng tuổi nếu chưa hỏi ý kiến BS.',
 'gemini-2.0-flash', 110, 1100,
 '{"dose_per_kg":"10-15mg","max_daily":"60mg/kg"}'::jsonb,
 NOW() - INTERVAL '1 hour 50 minutes'),

('AICM_DEMO_044', 'AICS_DEMO_009', 'USER',
 'Trẻ 12 kg thì liều cụ thể bao nhiêu mL siro Hapacol 80mg/5mL?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '30 minutes'),

('AICM_DEMO_045', 'AICS_DEMO_009', 'ASSISTANT',
 'Trẻ 12kg: liều mỗi lần 120-180mg (10-15mg/kg). Với Hapacol siro 80mg/5mL: **7.5-10mL/lần** (tương đương 120-160mg). Khoảng cách 4-6h, tối đa 4 lần/ngày.',
 'gemini-2.0-flash', 115, 1200,
 '{"weight":12,"dose_ml":"7.5-10","product":"Hapacol_80mg/5mL"}'::jsonb,
 NOW() - INTERVAL '10 minutes'),

-- ===== Session AICS_DEMO_010 — BS Chẩn đoán phân biệt khó thở (5 messages) =====
('AICM_DEMO_046', 'AICS_DEMO_010', 'USER',
 'BN nam 28 tuổi đến khám vì khó thở cấp tính 2 giờ, không sốt, không ho. Cần chẩn đoán phân biệt gì?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '5 days'),

('AICM_DEMO_047', 'AICS_DEMO_010', 'ASSISTANT',
 'Chẩn đoán phân biệt khó thở cấp ở người trẻ KHÔNG sốt: **1) Hen phế quản** (tiền sử, khò khè), **2) Tràn khí màng phổi tự phát** (đau ngực kèm), **3) Thuyên tắc phổi** (yếu tố nguy cơ huyết khối), **4) Hoảng loạn / lo âu** (chẩn đoán loại trừ), **5) Dị vật đường thở**, **6) Viêm phổi không điển hình** (ít sốt).',
 'gemini-2.0-flash', 175, 1500,
 '{"differential_count":6,"category":"Acute_Dyspnea"}'::jsonb,
 NOW() - INTERVAL '5 days' + INTERVAL '45 seconds'),

('AICM_DEMO_048', 'AICS_DEMO_010', 'USER',
 'Cận lâm sàng ban đầu nên chỉ định gì?',
 NULL, 0, 0, NULL,
 NOW() - INTERVAL '5 days' + INTERVAL '1 minute'),

('AICM_DEMO_049', 'AICS_DEMO_010', 'ASSISTANT',
 'Ưu tiên: **X-quang ngực** (tràn khí, viêm phổi), **SpO2 + khí máu** (đánh giá suy hô hấp), **ECG** (loại trừ tim), **D-dimer** (nếu nghi thuyên tắc phổi — kết hợp Wells score), **CTM + CRP**. Nếu nghi PE và D-dimer (+), cân nhắc **CT angio phổi**.',
 'gemini-2.0-flash', 165, 1450,
 '{"tests":["CXR","SpO2","ECG","D-dimer","CTM","CRP"]}'::jsonb,
 NOW() - INTERVAL '5 days' + INTERVAL '2 minutes'),

('AICM_DEMO_050', 'AICS_DEMO_010', 'ASSISTANT',
 'Lưu ý: nếu SpO2 <92% hoặc khó thở tăng, ưu tiên xử trí cấp cứu trước khi hoàn tất chẩn đoán. Oxygen liệu pháp và đường truyền tĩnh mạch nên có ngay.',
 'gemini-2.0-flash', 95, 1050,
 '{"phase":"CONCLUSION","red_flag":"SpO2_lt_92"}'::jsonb,
 NOW() - INTERVAL '5 days' + INTERVAL '5 minutes')
ON CONFLICT (message_id) DO NOTHING;

COMMIT;

-- =====================================================================
-- VERIFY counts sau khi seed
-- =====================================================================
\echo '=== POST-SEED COUNTS (17_notifications_ai) ==='
SELECT 'user_notifications' AS table_name, COUNT(*) AS row_count
  FROM user_notifications WHERE user_notifications_id LIKE 'NOTIF_DEMO_%'
UNION ALL
SELECT 'ai_chat_sessions',  COUNT(*) FROM ai_chat_sessions WHERE session_id LIKE 'AICS_DEMO_%'
UNION ALL
SELECT 'ai_chat_messages',  COUNT(*) FROM ai_chat_messages WHERE message_id LIKE 'AICM_DEMO_%';
