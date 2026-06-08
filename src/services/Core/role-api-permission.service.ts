import { RoleApiPermissionDetail } from '../../models/Core/role-api-permission.model';
import { RoleApiPermissionRepository } from '../../repository/Core/role-api-permission.repository';
import { RoleRepository } from '../../repository/Core/role.repository';
import { ApiPermissionRepository } from '../../repository/Core/api-permission.repository';
import { AppError } from '../../utils/app-error.util';
import { ApiPermissionCacheService } from './api-permission-cache.service';

export class RoleApiPermissionService {
    /**
     * Lấy các API mà Role này được uỷ quyền
     */
    static async getApiPermissionsByRoleId(roleId: string): Promise<RoleApiPermissionDetail[]> {
        const role = await RoleRepository.getRoleById(roleId);
        if (!role) {
            throw new AppError(404, 'ROLE_NOT_FOUND', 'Vai trò không tồn tại');
        }
        return await RoleApiPermissionRepository.getApiPermissionsByRoleId(roleId);
    }

    /**
     * Gán 1 API endpoint vào cho Role
     */
    static async assignApiPermission(
        roleId: string,
        apiId: string,
        adminId: string,
        ipAddress: string | null = null,
        userAgent: string | null = null
    ): Promise<void> {
        const role = await RoleRepository.getRoleById(roleId);
        if (!role) {
            throw new AppError(404, 'ROLE_NOT_FOUND', 'Vai trò không tồn tại');
        }

        const apiParam = await ApiPermissionRepository.getApiPermissionById(apiId);
        if (!apiParam) {
            throw new AppError(404, 'API_PERMISSION_NOT_FOUND', 'Dữ liệu API Endpoint không tồn tại');
        }

        await RoleApiPermissionRepository.assignApiPermission(roleId, apiId, adminId, ipAddress, userAgent);
        await ApiPermissionCacheService.refreshCache();
    }

    /**
     * Gỡ bỏ 1 API endpoint khỏi Role
     */
    static async removeApiPermission(
        roleId: string,
        apiId: string,
        adminId: string,
        ipAddress: string | null = null,
        userAgent: string | null = null
    ): Promise<void> {
        const role = await RoleRepository.getRoleById(roleId);
        if (!role) {
            throw new AppError(404, 'ROLE_NOT_FOUND', 'Vai trò không tồn tại');
        }

        await RoleApiPermissionRepository.removeApiPermission(roleId, apiId, adminId, ipAddress, userAgent);
        await ApiPermissionCacheService.refreshCache();
    }

    /**
     * Thay thế toàn bộ API endpoints cho Role
     */
    static async replaceApiPermissions(
        roleId: string,
        apiIds: string[],
        adminId: string,
        ipAddress: string | null = null,
        userAgent: string | null = null
    ): Promise<void> {
        const role = await RoleRepository.getRoleById(roleId);
        if (!role) {
            throw new AppError(404, 'ROLE_NOT_FOUND', 'Vai trò không tồn tại');
        }

        await RoleApiPermissionRepository.replaceApiPermissions(roleId, apiIds, adminId, ipAddress, userAgent);
        await ApiPermissionCacheService.refreshCache();
    }
}
