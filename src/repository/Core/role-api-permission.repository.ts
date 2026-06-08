import { pool } from '../../config/postgresdb';
import { RoleApiPermissionDetail } from '../../models/Core/role-api-permission.model';
import { randomUUID } from 'crypto';

export class RoleApiPermissionRepository {
    /**
     * Lấy danh sách toàn bộ API Permissions được phép truy cập bởi một Vai trò
     */
    static async getApiPermissionsByRoleId(roleId: string): Promise<RoleApiPermissionDetail[]> {
        const query = `
            SELECT 
                r.roles_id AS role_id, r.name AS role_name, r.code AS role_code,
                a.api_id, a.method, a.endpoint, a.description, a.module, a.status
            FROM role_api_permissions rap
            JOIN roles r ON rap.role_id = r.roles_id
            JOIN api_permissions a ON rap.api_id = a.api_id
            WHERE rap.role_id = $1 AND r.deleted_at IS NULL AND a.deleted_at IS NULL AND a.status = 'ACTIVE'
            ORDER BY a.module ASC, a.endpoint ASC, a.method ASC
        `;
        const result = await pool.query(query, [roleId]);
        return result.rows;
    }

    /**
     * Gán 1 API permission cho một Role
     */
    static async assignApiPermission(
        roleId: string,
        apiId: string,
        adminId: string,
        ipAddress: string | null = null,
        userAgent: string | null = null
    ): Promise<void> {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            await client.query(`
                INSERT INTO role_api_permissions (role_id, api_id)
                VALUES ($1, $2)
                ON CONFLICT DO NOTHING
            `, [roleId, apiId]);




            await client.query('COMMIT');
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Xóa gán API permission khỏi Role
     */
    static async removeApiPermission(
        roleId: string,
        apiId: string,
        adminId: string,
        ipAddress: string | null = null,
        userAgent: string | null = null
    ): Promise<void> {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            const checkExists = await client.query(`SELECT 1 FROM role_api_permissions WHERE role_id = $1 AND api_id = $2`, [roleId, apiId]);
            if (checkExists.rowCount === 0) {
                return; // Nothing to delete
            }

            await client.query(`
                DELETE FROM role_api_permissions
                WHERE role_id = $1 AND api_id = $2
            `, [roleId, apiId]);

            await client.query('COMMIT');
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Thay thế toàn bộ danh sách API Permissions của một Vai trò
     */
    static async replaceApiPermissions(
        roleId: string,
        apiIds: string[],
        adminId: string,
        ipAddress: string | null = null,
        userAgent: string | null = null
    ): Promise<void> {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // 1. Delete all existing api permissions
            await client.query(`
                DELETE FROM role_api_permissions WHERE role_id = $1
            `, [roleId]);

            // 2. Insert new ones
            if (apiIds && apiIds.length > 0) {
                const values = apiIds.map((apiId, idx) => `($1, $${idx + 2})`).join(', ');
                const params = [roleId, ...apiIds];
                await client.query(`
                    INSERT INTO role_api_permissions (role_id, api_id)
                    VALUES ${values}
                    ON CONFLICT DO NOTHING
                `, params);
            }

            await client.query('COMMIT');
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }
}
