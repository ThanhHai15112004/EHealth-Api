// src/repository/Appointment Management/appointment-status.repository.ts
import { pool } from '../../config/postgresdb';
import { Appointment } from '../../models/Appointment Management/appointment.model';
import { AppointmentAuditLogRepository } from './appointment-audit-log.repository';
import { NO_SHOW_LIMITS } from '../../constants/appointment-status.constant';
import { APPOINTMENT_STATUS } from '../../constants/appointment.constant';


export class AppointmentStatusRepository {

    /**
     * Lấy số thứ tự tiếp theo trong hàng đợi hôm nay
     */
    static async getNextQueueNumber(): Promise<number> {
        const query = `
            SELECT COALESCE(MAX(queue_number), 0) + 1 AS next_queue
            FROM appointments
            WHERE appointment_date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
              AND queue_number IS NOT NULL;
        `;
        const result = await pool.query(query);
        return result.rows[0].next_queue;
    }

    /**
     * Check-in với cấp queue_number + ghi nhận late (transaction)
     */
    static async checkInWithQueue(
        id: string,
        queueNumber: number,
        checkInMethod: string,
        isLate: boolean,
        lateMinutes: number,
        auditLog: { appointment_audit_logs_id: string; appointment_id: string; changed_by: string; old_status: string; new_status: string; action_note: string }
    ): Promise<Appointment | null> {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            const query = `
                UPDATE appointments
                SET status = '${APPOINTMENT_STATUS.CHECKED_IN}',
                    checked_in_at = CURRENT_TIMESTAMP,
                    queue_number = $2,
                    check_in_method = $3,
                    is_late = $4,
                    late_minutes = $5,
                    qr_token = NULL,
                    qr_token_expires_at = NULL,
                    updated_at = CURRENT_TIMESTAMP
                WHERE appointments_id = $1 AND status = '${APPOINTMENT_STATUS.CONFIRMED}'
                RETURNING *, TO_CHAR(appointment_date, 'YYYY-MM-DD') AS appointment_date;
            `;
            const result = await client.query(query, [id, queueNumber, checkInMethod, isLate, lateMinutes]);
            const checkedIn = result.rows[0] || null;

            if (checkedIn) {
                await AppointmentAuditLogRepository.create(auditLog, client);
            }

            await client.query('COMMIT');
            return checkedIn;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Lưu QR token vào appointment
     */
    static async saveQrToken(id: string, qrToken: string, expiresAt: string): Promise<boolean> {
        const query = `
            UPDATE appointments
            SET qr_token = $2,
                qr_token_expires_at = $3,
                updated_at = CURRENT_TIMESTAMP
            WHERE appointments_id = $1 AND status = '${APPOINTMENT_STATUS.CONFIRMED}'
              AND qr_token IS NULL
        `;
        const result = await pool.query(query, [id, qrToken, expiresAt]);
        return (result.rowCount ?? 0) > 0;
    }

    /**
     * Tìm appointment theo QR token (chưa hết hạn)
     */
    static async findByQrToken(qrToken: string): Promise<(Appointment & { slot_start_time: string; account_id: string | null; patient_name: string }) | null> {
        const query = `
            SELECT a.*,
                   TO_CHAR(a.appointment_date, 'YYYY-MM-DD') AS appointment_date,
                   p.full_name AS patient_name,
                   p.account_id,
                   sl.start_time AS slot_start_time,
                   sl.end_time AS slot_end_time,
                   CONCAT(sl.start_time, ' - ', sl.end_time) AS slot_time,
                   up.full_name AS doctor_name
            FROM appointments a
            LEFT JOIN patients p ON a.patient_id = p.id::varchar
            LEFT JOIN appointment_slots sl ON a.slot_id = sl.slot_id
            LEFT JOIN doctors d ON a.doctor_id = d.doctors_id
            LEFT JOIN user_profiles up ON d.user_id = up.user_id
            WHERE a.qr_token = $1
              AND a.qr_token_expires_at >= CURRENT_TIMESTAMP
              AND a.status = '${APPOINTMENT_STATUS.CONFIRMED}';
        `;
        const result = await pool.query(query, [qrToken]);
        return result.rows[0] || null;
    }

    /**
     * Bắt đầu khám: CHECKED_IN → IN_PROGRESS + cập nhật phòng (transaction)
     */
    static async startExam(
        id: string,
        roomId: string,
        patientId: string,
        auditLog: { appointment_audit_logs_id: string; appointment_id: string; changed_by: string; old_status: string; new_status: string; action_note: string }
    ): Promise<Appointment | null> {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Cập nhật appointment
            const aptQuery = `
                UPDATE appointments
                SET status = '${APPOINTMENT_STATUS.IN_PROGRESS}',
                    started_at = CURRENT_TIMESTAMP,
                    updated_at = CURRENT_TIMESTAMP
                WHERE appointments_id = $1 AND status = '${APPOINTMENT_STATUS.CHECKED_IN}'
                RETURNING *, TO_CHAR(appointment_date, 'YYYY-MM-DD') AS appointment_date;
            `;
            const aptResult = await client.query(aptQuery, [id]);
            const updated = aptResult.rows[0] || null;

            if (updated) {
                // Cập nhật phòng: OCCUPIED
                await client.query(`
                    UPDATE medical_rooms
                    SET room_status = 'OCCUPIED',
                        current_appointment_id = $1,
                        current_patient_id = $2
                    WHERE medical_rooms_id = $3;
                `, [id, patientId, roomId]);

                await AppointmentAuditLogRepository.create(auditLog, client);
            }

            await client.query('COMMIT');
            return updated;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Hoàn tất khám: IN_PROGRESS → COMPLETED + giải phóng phòng (transaction)
     */
    static async completeExam(
        id: string,
        roomId: string | null,
        auditLog: { appointment_audit_logs_id: string; appointment_id: string; changed_by: string; old_status: string; new_status: string; action_note: string }
    ): Promise<Appointment | null> {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            const aptQuery = `
                UPDATE appointments
                SET status = '${APPOINTMENT_STATUS.COMPLETED}',
                    completed_at = CURRENT_TIMESTAMP,
                    updated_at = CURRENT_TIMESTAMP
                WHERE appointments_id = $1 AND status = '${APPOINTMENT_STATUS.IN_PROGRESS}'
                RETURNING *, TO_CHAR(appointment_date, 'YYYY-MM-DD') AS appointment_date;
            `;
            const aptResult = await client.query(aptQuery, [id]);
            const completed = aptResult.rows[0] || null;

            if (completed && roomId) {
                // Giải phóng phòng
                await client.query(`
                    UPDATE medical_rooms
                    SET room_status = 'AVAILABLE',
                        current_appointment_id = NULL,
                        current_patient_id = NULL
                    WHERE medical_rooms_id = $1
                      AND current_appointment_id = $2;
                `, [roomId, id]);

                await AppointmentAuditLogRepository.create(auditLog, client);
            } else if (completed) {
                await AppointmentAuditLogRepository.create(auditLog, client);
            }

            await client.query('COMMIT');
            return completed;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Đánh dấu No-Show (transaction)
     */
    static async markNoShow(
        id: string,
        auditLog: { appointment_audit_logs_id: string; appointment_id: string; changed_by?: string; old_status: string; new_status: string; action_note: string }
    ): Promise<Appointment | null> {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            const query = `
                UPDATE appointments
                SET status = '${APPOINTMENT_STATUS.NO_SHOW}',
                    updated_at = CURRENT_TIMESTAMP
                WHERE appointments_id = $1 AND status IN ('${APPOINTMENT_STATUS.PENDING}', '${APPOINTMENT_STATUS.CONFIRMED}')
                RETURNING *, TO_CHAR(appointment_date, 'YYYY-MM-DD') AS appointment_date;
            `;
            const result = await client.query(query, [id]);
            const noShow = result.rows[0] || null;

            if (noShow) {
                await AppointmentAuditLogRepository.create(auditLog, client);

                // Task 11: Auto-flag no-show blacklist
                const patientUpdateQuery = `
                    UPDATE patients
                    SET no_show_count = COALESCE(no_show_count, 0) + 1,
                        is_blacklisted = CASE WHEN COALESCE(no_show_count, 0) + 1 >= $2 THEN TRUE ELSE is_blacklisted END,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = $1
                    RETURNING no_show_count, is_blacklisted;
                `;
                await client.query(patientUpdateQuery, [noShow.patient_id, NO_SHOW_LIMITS.BLACKLIST_THRESHOLD]);
            }

            await client.query('COMMIT');
            return noShow;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Tìm appointments quá hạn cần đánh No-Show tự động
     */
    static async findExpiredForNoShow(bufferMinutes: number): Promise<Array<{
        appointments_id: string;
        appointment_code: string;
        patient_id: string;
        patient_name: string;
        account_id: string | null;
        status: string;
        appointment_date: string;
        slot_time: string;
    }>> {
        const query = `
            SELECT
                a.appointments_id,
                a.appointment_code,
                a.patient_id,
                a.status,
                p.full_name AS patient_name,
                p.account_id,
                TO_CHAR(a.appointment_date, 'YYYY-MM-DD') AS appointment_date,
                CONCAT(sl.start_time, ' - ', sl.end_time) AS slot_time
            FROM appointments a
            JOIN patients p ON a.patient_id = p.id::varchar
            JOIN appointment_slots sl ON a.slot_id = sl.slot_id
            WHERE a.status IN ('${APPOINTMENT_STATUS.PENDING}', '${APPOINTMENT_STATUS.CONFIRMED}')
              AND a.appointment_date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
              AND sl.end_time IS NOT NULL
              AND (a.appointment_date + sl.end_time::time + INTERVAL '1 minute' * $1) < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')
            ORDER BY sl.start_time ASC;
        `;
        const result = await pool.query(query, [bufferMinutes]);
        return result.rows;
    }

    /**
     * Dashboard: thống kê trạng thái lịch khám theo ngày
     */
    static async getDashboardByDate(branchId?: string, date?: string): Promise<{
        total: number;
        pending: number;
        confirmed: number;
        checked_in: number;
        in_progress: number;
        completed: number;
        cancelled: number;
        no_show: number;
        current_serving: number | null;
        next_in_line: number | null;
        total_waiting: number;
    }> {
        const conditions: string[] = [];
        const params: any[] = [];
        let paramIdx = 1;

        if (date) {
            conditions.push(`a.appointment_date = $${paramIdx++}::date`);
            params.push(date);
        } else {
            conditions.push(`a.appointment_date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::date`);
        }

        if (branchId) {
            conditions.push(`mr.branch_id = $${paramIdx++}`);
            params.push(branchId);
        }

        const query = `
            SELECT
                COUNT(*) AS total,
                COUNT(*) FILTER (WHERE a.status = '${APPOINTMENT_STATUS.PENDING}') AS pending,
                COUNT(*) FILTER (WHERE a.status = '${APPOINTMENT_STATUS.CONFIRMED}') AS confirmed,
                COUNT(*) FILTER (WHERE a.status = '${APPOINTMENT_STATUS.CHECKED_IN}') AS checked_in,
                COUNT(*) FILTER (WHERE a.status = '${APPOINTMENT_STATUS.IN_PROGRESS}') AS in_progress,
                COUNT(*) FILTER (WHERE a.status = '${APPOINTMENT_STATUS.COMPLETED}') AS completed,
                COUNT(*) FILTER (WHERE a.status = '${APPOINTMENT_STATUS.CANCELLED}') AS cancelled,
                COUNT(*) FILTER (WHERE a.status = '${APPOINTMENT_STATUS.NO_SHOW}') AS no_show,
                MIN(a.queue_number) FILTER (WHERE a.status = '${APPOINTMENT_STATUS.IN_PROGRESS}') AS current_serving,
                (
                    SELECT queue_number FROM appointments sub
                    LEFT JOIN medical_rooms smr ON sub.room_id = smr.medical_rooms_id
                    WHERE sub.appointment_date = COALESCE(${date ? `$1::date` : `(CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::date`}, (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)
                      AND sub.status = '${APPOINTMENT_STATUS.CHECKED_IN}'
                      ${branchId ? `AND smr.branch_id = '${branchId}'` : ''}
                    ORDER BY CASE sub.priority WHEN 'EMERGENCY' THEN 0 WHEN 'URGENT' THEN 1 ELSE 2 END, sub.queue_number ASC
                    LIMIT 1
                ) AS next_in_line,
                COUNT(*) FILTER (WHERE a.status = '${APPOINTMENT_STATUS.CHECKED_IN}') AS total_waiting
            FROM appointments a
            LEFT JOIN medical_rooms mr ON a.room_id = mr.medical_rooms_id
            WHERE ${conditions.join(' AND ')};
        `;
        const result = await pool.query(query, params);
        const row = result.rows[0];

        return {
            total: parseInt(row.total),
            pending: parseInt(row.pending),
            confirmed: parseInt(row.confirmed),
            checked_in: parseInt(row.checked_in),
            in_progress: parseInt(row.in_progress),
            completed: parseInt(row.completed),
            cancelled: parseInt(row.cancelled),
            no_show: parseInt(row.no_show),
            current_serving: row.current_serving ? parseInt(row.current_serving) : null,
            next_in_line: row.next_in_line ? parseInt(row.next_in_line) : null,
            total_waiting: parseInt(row.total_waiting),
        };
    }

    /**
     * Hàng đợi hôm nay (CHECKED_IN + IN_PROGRESS)
     * Sắp xếp: EMERGENCY → URGENT → NORMAL, rồi theo queue_number.
     * Lọc thêm theo chuyên khoa để xem hàng đợi từng khoa.
     */
    static async getQueueToday(filters: {
        branch_id?: string;
        room_id?: string;
        status?: string;
        specialty_id?: string;
        include_all?: boolean;
    }): Promise<any[]> {
        const conditions: string[] = [`a.appointment_date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::date`];
        const params: any[] = [];
        let paramIdx = 1;

        if (!filters.status && !filters.include_all) {
            conditions.push(`a.status IN ('${APPOINTMENT_STATUS.CHECKED_IN}', '${APPOINTMENT_STATUS.IN_PROGRESS}')`);
        }

        if (filters.branch_id) {
            conditions.push(`mr.branch_id = $${paramIdx++}`);
            params.push(filters.branch_id);
        }
        if (filters.room_id) {
            conditions.push(`a.room_id = $${paramIdx++}`);
            params.push(filters.room_id);
        }
        if (filters.status) {
            conditions.push(`a.status = $${paramIdx++}`);
            params.push(filters.status);
        }
        if (filters.specialty_id) {
            conditions.push(`d.specialty_id = $${paramIdx++}`);
            params.push(filters.specialty_id);
        }

        const query = `
            SELECT
                a.appointments_id,
                a.appointment_code,
                a.patient_id,
                a.status,
                a.priority,
                a.queue_number,
                a.is_late,
                a.late_minutes,
                a.checked_in_at,
                a.started_at,
                a.check_in_method,
                TO_CHAR(a.appointment_date, 'YYYY-MM-DD') AS appointment_date,
                p.full_name AS patient_name,
                up.full_name AS doctor_name,
                sp.name AS specialty_name,
                mr.name AS room_name,
                CONCAT(sl.start_time, ' - ', sl.end_time) AS slot_time
            FROM appointments a
            LEFT JOIN patients p ON a.patient_id = p.id::varchar
            LEFT JOIN doctors d ON a.doctor_id = d.doctors_id
            LEFT JOIN user_profiles up ON d.user_id = up.user_id
            LEFT JOIN specialties sp ON d.specialty_id = sp.specialties_id
            LEFT JOIN medical_rooms mr ON a.room_id = mr.medical_rooms_id
            LEFT JOIN appointment_slots sl ON a.slot_id = sl.slot_id
            WHERE ${conditions.join(' AND ')}
            ORDER BY
                CASE a.priority WHEN 'EMERGENCY' THEN 0 WHEN 'URGENT' THEN 1 ELSE 2 END,
                a.queue_number ASC NULLS LAST;
        `;
        const result = await pool.query(query, params);
        return result.rows;
    }

    /**
     * Bỏ qua 1 BN trong hàng đợi (status CHECKED_IN → SKIPPED tạm)
     * Staff dùng khi gọi BN không thấy → bỏ qua, gọi số tiếp theo.
     */
    static async skipQueueItem(
        id: string,
        auditLog: { appointment_audit_logs_id: string; appointment_id: string; changed_by: string; old_status: string; new_status: string; action_note: string }
    ): Promise<Appointment | null> {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const query = `
                UPDATE appointments
                SET status = '${APPOINTMENT_STATUS.SKIPPED}',
                    updated_at = CURRENT_TIMESTAMP
                WHERE appointments_id = $1 AND status = '${APPOINTMENT_STATUS.CHECKED_IN}'
                RETURNING *, TO_CHAR(appointment_date, 'YYYY-MM-DD') AS appointment_date;
            `;
            const result = await client.query(query, [id]);
            const skipped = result.rows[0] || null;
            if (skipped) {
                await AppointmentAuditLogRepository.create(auditLog, client);
            }
            await client.query('COMMIT');
            return skipped;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Gọi lại BN đã bị skip (SKIPPED → CHECKED_IN, gán queue_number mới ở cuối hàng)
     */
    static async recallQueueItem(
        id: string,
        newQueueNumber: number,
        auditLog: { appointment_audit_logs_id: string; appointment_id: string; changed_by: string; old_status: string; new_status: string; action_note: string }
    ): Promise<Appointment | null> {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const query = `
                UPDATE appointments
                SET status = '${APPOINTMENT_STATUS.CHECKED_IN}',
                    queue_number = $2,
                    updated_at = CURRENT_TIMESTAMP
                WHERE appointments_id = $1 AND status = '${APPOINTMENT_STATUS.SKIPPED}'
                RETURNING *, TO_CHAR(appointment_date, 'YYYY-MM-DD') AS appointment_date;
            `;
            const result = await client.query(query, [id, newQueueNumber]);
            const recalled = result.rows[0] || null;
            if (recalled) {
                await AppointmentAuditLogRepository.create(auditLog, client);
            }
            await client.query('COMMIT');
            return recalled;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Trạng thái phòng khám (room occupancy)
     */
    static async getRoomStatusList(branchId?: string): Promise<any[]> {
        const conditions: string[] = [`mr.deleted_at IS NULL`, `mr.status = 'ACTIVE'`];
        const params: any[] = [];

        if (branchId) {
            conditions.push(`mr.branch_id = $1`);
            params.push(branchId);
        }

        const query = `
            SELECT
                mr.medical_rooms_id,
                mr.code AS room_code,
                mr.name AS room_name,
                mr.room_type,
                mr.room_status AS status,
                mr.current_appointment_id,
                mr.current_patient_id,
                dep.name AS department_name,
                br.name AS branch_name,
                a.appointment_code AS current_appointment_code,
                p.full_name AS current_patient_name,
                up.full_name AS doctor_name,
                (
                    SELECT COUNT(*)
                    FROM appointments sub_a
                    WHERE sub_a.room_id = mr.medical_rooms_id
                      AND sub_a.appointment_date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
                      AND sub_a.status = 'CHECKED_IN'
                )::int AS waiting_count,
                (
                    SELECT COUNT(*)
                    FROM appointments sub_a
                    WHERE sub_a.room_id = mr.medical_rooms_id
                      AND sub_a.appointment_date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
                      AND sub_a.status = 'COMPLETED'
                )::int AS completed_count
            FROM medical_rooms mr
            LEFT JOIN departments dep ON mr.department_id = dep.departments_id
            LEFT JOIN branches br ON mr.branch_id = br.branches_id
            LEFT JOIN appointments a ON mr.current_appointment_id = a.appointments_id
            LEFT JOIN patients p ON mr.current_patient_id = p.id::varchar
            LEFT JOIN doctors d ON a.doctor_id = d.doctors_id
            LEFT JOIN user_profiles up ON d.user_id = up.user_id
            WHERE ${conditions.join(' AND ')}
            ORDER BY mr.room_status DESC, mr.code ASC;
        `;
        const result = await pool.query(query, params);
        return result.rows;
    }

    /**
     * Force release a medical room, setting its status to AVAILABLE and clearing current appointment/patient.
     */
    static async forceReleaseRoom(roomId: string, auditLog?: any): Promise<boolean> {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            const query = `
                UPDATE medical_rooms
                SET room_status = 'AVAILABLE',
                    current_appointment_id = NULL,
                    current_patient_id = NULL,
                    updated_at = CURRENT_TIMESTAMP
                WHERE medical_rooms_id = $1
                RETURNING *;
            `;
            const result = await client.query(query, [roomId]);

            if (result.rowCount === 0) {
                throw new Error('Không tìm thấy phòng khám để giải phóng.');
            }

            if (auditLog) {
                const logQuery = `
                    INSERT INTO appointment_audit_logs 
                        (appointment_audit_logs_id, appointment_id, changed_by, old_status, new_status, action_note, created_at)
                    VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
                `;
                await client.query(logQuery, [
                    auditLog.appointment_audit_logs_id,
                    auditLog.appointment_id,
                    auditLog.changed_by,
                    auditLog.old_status,
                    auditLog.new_status,
                    auditLog.action_note
                ]);
            }

            await client.query('COMMIT');
            return true;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Lấy trạng thái phòng khám theo ID (dùng cho kiểm tra trước khi bắt đầu khám)
     */
    static async getRoomStatusById(roomId: string): Promise<string | null> {
        const query = `SELECT room_status FROM medical_rooms WHERE medical_rooms_id = $1`;
        const result = await pool.query(query, [roomId]);
        return result.rows[0]?.room_status || null;
    }

    /**
     * Đọc cấu hình check-in & no-show từ system_settings
     */
    static async getSettingsByKeys(keys: string[]): Promise<Record<string, any>> {
        const result = await pool.query(
            `SELECT setting_key, setting_value FROM system_settings WHERE setting_key = ANY($1)`,
            [keys]
        );
        const settings: Record<string, any> = {};
        for (const row of result.rows) {
            settings[row.setting_key] = row.setting_value?.value;
        }
        return settings;
    }

    /**
     * Cập nhật 1 setting trong system_settings
     */
    static async updateSetting(key: string, value: any): Promise<void> {
        await pool.query(
            `UPDATE system_settings SET setting_value = $1, updated_at = CURRENT_TIMESTAMP WHERE setting_key = $2`,
            [JSON.stringify(value), key]
        );
    }
}
