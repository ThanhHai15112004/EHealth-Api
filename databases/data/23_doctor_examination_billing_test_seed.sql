-- 23_doctor_examination_billing_test_seed.sql
-- Seed 1 fresh appointment for doctor examination -> prescription -> billing test.
-- Test URL:
-- http://localhost:3001/portal/doctor/examination?appointment=APT_EXAM_BILL_TEST_01&patient=PAT_001
--
-- Notes:
-- - This appointment has facility_service_id = FS_KB_08, so invoice generation has a consultation fee.
-- - For medicine charge testing, select Paracetamol 500mg / DRG_011 because it has inventory price.

BEGIN;

CREATE TEMP TABLE tmp_exam_bill_encounters ON COMMIT DROP AS
SELECT encounters_id
FROM encounters
WHERE appointment_id = 'APT_EXAM_BILL_TEST_01';

CREATE TEMP TABLE tmp_exam_bill_invoices ON COMMIT DROP AS
SELECT invoices_id
FROM invoices
WHERE encounter_id IN (SELECT encounters_id FROM tmp_exam_bill_encounters);

CREATE TEMP TABLE tmp_exam_bill_payment_transactions ON COMMIT DROP AS
SELECT payment_transactions_id
FROM payment_transactions
WHERE invoice_id IN (SELECT invoices_id FROM tmp_exam_bill_invoices);

CREATE TEMP TABLE tmp_exam_bill_prescriptions ON COMMIT DROP AS
SELECT prescriptions_id
FROM prescriptions
WHERE encounter_id IN (SELECT encounters_id FROM tmp_exam_bill_encounters);

CREATE TEMP TABLE tmp_exam_bill_dispense_orders ON COMMIT DROP AS
SELECT drug_dispense_orders_id
FROM drug_dispense_orders
WHERE prescription_id IN (SELECT prescriptions_id FROM tmp_exam_bill_prescriptions);

-- Cleanup billing/payment records for repeatable test runs.
DELETE FROM transaction_adjustments
WHERE invoice_id IN (SELECT invoices_id FROM tmp_exam_bill_invoices)
   OR original_transaction_id IN (SELECT payment_transactions_id FROM tmp_exam_bill_payment_transactions)
   OR corrective_transaction_id IN (SELECT payment_transactions_id FROM tmp_exam_bill_payment_transactions);

DELETE FROM refund_requests
WHERE invoice_id IN (SELECT invoices_id FROM tmp_exam_bill_invoices)
   OR transaction_id IN (SELECT payment_transactions_id FROM tmp_exam_bill_payment_transactions)
   OR refund_transaction_id IN (SELECT payment_transactions_id FROM tmp_exam_bill_payment_transactions);

DELETE FROM payment_receipts
WHERE invoice_id IN (SELECT invoices_id FROM tmp_exam_bill_invoices)
   OR payment_transaction_id IN (SELECT payment_transactions_id FROM tmp_exam_bill_payment_transactions);

DELETE FROM voucher_usage
WHERE invoice_id IN (SELECT invoices_id FROM tmp_exam_bill_invoices);

DELETE FROM payment_orders
WHERE invoice_id IN (SELECT invoices_id FROM tmp_exam_bill_invoices);

DELETE FROM billing_documents
WHERE invoice_id IN (SELECT invoices_id FROM tmp_exam_bill_invoices)
   OR payment_transaction_id IN (SELECT payment_transactions_id FROM tmp_exam_bill_payment_transactions);

DELETE FROM e_invoices
WHERE invoice_id IN (SELECT invoices_id FROM tmp_exam_bill_invoices)
   OR payment_transaction_id IN (SELECT payment_transactions_id FROM tmp_exam_bill_payment_transactions);

DELETE FROM payment_transactions
WHERE invoice_id IN (SELECT invoices_id FROM tmp_exam_bill_invoices);

DELETE FROM invoices
WHERE invoices_id IN (SELECT invoices_id FROM tmp_exam_bill_invoices);

-- Cleanup prescription/dispensing records for repeatable test runs.
DELETE FROM drug_dispense_details
WHERE dispense_order_id IN (SELECT drug_dispense_orders_id FROM tmp_exam_bill_dispense_orders);

DELETE FROM drug_dispense_orders
WHERE drug_dispense_orders_id IN (SELECT drug_dispense_orders_id FROM tmp_exam_bill_dispense_orders);

DELETE FROM prescription_details
WHERE prescription_id IN (SELECT prescriptions_id FROM tmp_exam_bill_prescriptions);

DELETE FROM prescriptions
WHERE prescriptions_id IN (SELECT prescriptions_id FROM tmp_exam_bill_prescriptions);

-- Cleanup encounter-side records. Most have ON DELETE CASCADE, but explicit deletes make reruns clearer.
DELETE FROM emr_signatures
WHERE encounter_id IN (SELECT encounters_id FROM tmp_exam_bill_encounters);

DELETE FROM medical_order_results
WHERE order_id IN (
    SELECT medical_orders_id
    FROM medical_orders
    WHERE encounter_id IN (SELECT encounters_id FROM tmp_exam_bill_encounters)
);

DELETE FROM medical_orders
WHERE encounter_id IN (SELECT encounters_id FROM tmp_exam_bill_encounters);

DELETE FROM encounter_diagnoses
WHERE encounter_id IN (SELECT encounters_id FROM tmp_exam_bill_encounters);

DELETE FROM clinical_examinations
WHERE encounter_id IN (SELECT encounters_id FROM tmp_exam_bill_encounters);

DELETE FROM encounters
WHERE encounters_id IN (SELECT encounters_id FROM tmp_exam_bill_encounters);

DELETE FROM appointment_audit_logs
WHERE appointment_id = 'APT_EXAM_BILL_TEST_01';

DELETE FROM appointments
WHERE appointments_id = 'APT_EXAM_BILL_TEST_01';

INSERT INTO appointments (
    appointments_id,
    appointment_code,
    patient_id,
    doctor_id,
    room_id,
    facility_service_id,
    specialty_id,
    branch_id,
    appointment_date,
    booking_channel,
    reason_for_visit,
    symptoms_notes,
    status,
    priority,
    queue_number,
    confirmed_at,
    confirmed_by
) VALUES (
    'APT_EXAM_BILL_TEST_01',
    'APP-EXAM-BILL-01',
    'PAT_001',
    'DOC_01',
    'ROOM_KB_01',
    'FS_KB_08',
    'SPC_TONG_QUAT',
    'BR_MAIN',
    DATE '2026-06-08',
    'WEB',
    'Test luong kham tao don thuoc va hoa don co phi kham',
    'TEST_EXAM_BILLING_WITH_SERVICE',
    'PENDING',
    'NORMAL',
    10,
    CURRENT_TIMESTAMP,
    'USR_REC_01'
);

COMMIT;
