-- Migration: Cho phép device_id NULL trong user_sessions
-- Lý do: Code BE (auth.service + auth-session.util) đã thiết kế để khi client không gửi
-- device info thì lưu session với device_id = NULL. Schema NOT NULL gây lỗi
-- "null value in column device_id of relation user_sessions violates not-null constraint"
-- mỗi khi login từ client không có x-device-id header.
-- Ngày: 2026-05-19

ALTER TABLE user_sessions
    ALTER COLUMN device_id DROP NOT NULL;
