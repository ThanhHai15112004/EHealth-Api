-- ========================================================================
-- seed-reset.sql — Truncate DEMO tables (KEEP master data)
-- ========================================================================
-- Run BEFORE seed:dev to reset state cleanly.
-- DO NOT truncate: roles, users, user_profiles, master_data_*,
-- notification_templates, drugs, drug_categories, patients, doctors,
-- facilities, departments, services, appointment_slots, insurance_providers.
-- ========================================================================

BEGIN;

TRUNCATE TABLE
    -- Doctor demo data
    appointments,
    encounters,
    encounter_diagnoses,
    clinical_examinations,
    medical_orders,
    medical_order_results,
    emr_record_snapshots,
    patient_health_metrics,
    -- Pharmacy demo data
    suppliers,
    warehouses,
    stock_in_orders,
    stock_in_details,
    stock_out_orders,
    stock_out_details,
    medication_instruction_templates,
    drug_default_instructions,
    drug_dispense_orders,
    drug_dispense_details,
    -- Billing demo data
    invoices,
    invoice_details,
    payment_orders,
    payment_transactions,
    refund_requests,
    -- Notification/AI demo data
    user_notifications,
    ai_chat_sessions,
    ai_chat_messages,
    -- not in schema: ai_health_alerts
    -- not in schema: ai_token_analytics
    -- Admin ops demo data
    room_maintenance_schedules,
    equipment_maintenance_logs,
    cashier_shifts,
    cashier_activity_logs,
    pos_terminals,
    -- Audit/timeline demo data
    appointment_audit_logs,
    appointment_change_logs, -- renamed from appointment_change_log (schema uses plural)
    health_timeline_events,
    ehr_health_alerts,
    ehr_medication_adherence,
    ehr_device_sync_log,
    -- Existing seed mỏng (4-10 rows)
    treatment_plans,
    leave_requests,
    e_invoices
RESTART IDENTITY CASCADE;

COMMIT;
