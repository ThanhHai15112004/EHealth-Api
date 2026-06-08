import { Router } from 'express';
import { RoleController } from '../../controllers/Core/role.controller';
import { verifyAccessToken } from '../../middleware/verifyAccessToken.middleware';

const roleRoutes = Router();

roleRoutes.use(verifyAccessToken);

/**
 * @swagger
 * /api/roles:
 *   get:
 *     summary: Lấy danh sách Roles (Vai trò)
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *       API trả về danh sách vai trò có phân trang/lọc.
 *     tags: [1.3.1 Quản lý danh mục vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Tìm kiếm theo mã hoặc tên
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [ACTIVE, INACTIVE]
 *       - in: query
 *         name: is_system
 *         schema:
 *           type: boolean
 *     responses:
 *       200:
 *         description: Thành công
 */
roleRoutes.get('/', RoleController.getRoles);

/**
 * @swagger
 * /api/roles/{roleId}:
 *   get:
 *     summary: Lấy chi tiết Role theo ID
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.1 Quản lý danh mục vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Thành công
 *       404:
 *         description: Không tìm thấy vai trò
 */
roleRoutes.get('/:roleId', RoleController.getRoleById);

/**
 * @swagger
 * /api/roles:
 *   post:
 *     summary: Tạo vai trò mới
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.1 Quản lý danh mục vai trò]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [code, name]
 *             properties:
 *               code:
 *                 type: string
 *                 example: "CUSTOMER_CARE"
 *               name:
 *                 type: string
 *                 example: "Chăm sóc khách hàng"
 *               description:
 *                 type: string
 *                 example: "Nhân sự hỗ trợ bệnh nhân"
 *     responses:
 *       201:
 *         description: Thành công
 *       400:
 *         description: Dữ liệu không hợp lệ hoặc trùng lặp mã Code
 */
roleRoutes.post('/', RoleController.createRole);

/**
 * @swagger
 * /api/roles/{roleId}:
 *   patch:
 *     summary: Cập nhật vai trò (Tên, Mô tả)
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.1 Quản lý danh mục vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *     responses:
 *       200:
 *         description: Thành công
 */
roleRoutes.patch('/:roleId', RoleController.updateRole);

/**
 * @swagger
 * /api/roles/{roleId}/status:
 *   patch:
 *     summary: Bật/Tắt (Active/Inactive) vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.1 Quản lý danh mục vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [status]
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [ACTIVE, INACTIVE]
 *                 example: INACTIVE
 *     responses:
 *       200:
 *         description: Đổi trạng thái thành công
 *       400:
 *         description: Đang có người dùng đang giữ vai trò này
 */
roleRoutes.patch('/:roleId/status', RoleController.updateRoleStatus);

/**
 * @swagger
 * /api/roles/{roleId}:
 *   delete:
 *     summary: Xóa vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.1 Quản lý danh mục vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Xóa thành công
 *       403:
 *         description: Không cho phép xóa Role mặc định của hệ thống
 */
roleRoutes.delete('/:roleId', RoleController.deleteRole);

// =========================================================================
// PHÂN QUYỀN (ROLE-PERMISSIONS)
// =========================================================================

/**
 * @swagger
 * /api/roles/{roleId}/permissions:
 *   get:
 *     summary: Lấy danh sách quyền của Vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.3 Gán quyền cho vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Thành công
 */
roleRoutes.get('/:roleId/permissions', RoleController.getRolePermissions);

/**
 * @swagger
 * /api/roles/{roleId}/permissions:
 *   put:
 *     summary: Thay thế (Replace) danh sách quyền của Vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.3 Gán quyền cho vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [permissions]
 *             properties:
 *               permissions:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["PATIENT_VIEW", "PATIENT_UPDATE"]
 *     responses:
 *       200:
 *         description: Cập nhật quyền thành công
 */
roleRoutes.put('/:roleId/permissions', RoleController.replaceRolePermissions);

/**
 * @swagger
 * /api/roles/{roleId}/permissions:
 *   post:
 *     summary: Gán thêm một quyền lẻ cho Vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.3 Gán quyền cho vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [permission_id]
 *             properties:
 *               permission_id:
 *                 type: string
 *                 example: "PATIENT_VIEW"
 *     responses:
 *       201:
 *         description: Gán quyền thành công
 */
roleRoutes.post('/:roleId/permissions', RoleController.assignRolePermission);

/**
 * @swagger
 * /api/roles/{roleId}/permissions/{permissionId}:
 *   delete:
 *     summary: Xóa một quyền lẻ khỏi Vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.3 Gán quyền cho vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: permissionId
 *         required: true
 *         schema:
 *           type: string
 *           description: ID hoặc Code của quyền
 *     responses:
 *       200:
 *         description: Xóa quyền thành công
 */
roleRoutes.delete('/:roleId/permissions/:permissionId', RoleController.removeRolePermission);

// =========================================================================
// QUẢN LÝ MENU (ROLE-MENUS)
// =========================================================================

/**
 * @swagger
 * /api/roles/{roleId}/menus:
 *   get:
 *     summary: Lấy danh sách Menu của Vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.5 Kiểm soát hiển thị menu theo vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Thành công
 */
roleRoutes.get('/:roleId/menus', RoleController.getRoleMenus);

/**
 * @swagger
 * /api/roles/{roleId}/menus:
 *   post:
 *     summary: Gán thêm một Menu cho Vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.5 Kiểm soát hiển thị menu theo vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [menu_id]
 *             properties:
 *               menu_id:
 *                 type: string
 *                 example: "MENU_001"
 *     responses:
 *       201:
 *         description: Gán Menu thành công
 */
roleRoutes.post('/:roleId/menus', RoleController.assignRoleMenu);

/**
 * @swagger
 * /api/roles/{roleId}/menus/{menuId}:
 *   delete:
 *     summary: Xóa một Menu khỏi Vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.5 Kiểm soát hiển thị menu theo vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: menuId
 *         required: true
 *         schema:
 *           type: string
 *           description: ID hoặc Mã Code của Menu
 *     responses:
 *       200:
 *         description: Gỡ Menu thành công
 */
roleRoutes.delete('/:roleId/menus/:menuId', RoleController.removeRoleMenu);

// =========================================================================
// QUẢN LÝ API PERMISSIONS (ROLE-API)
// =========================================================================

/**
 * @swagger
 * /api/roles/{roleId}/api-permissions:
 *   get:
 *     summary: Lấy danh sách API được phép truy cập của Vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.6 Kiểm soát API theo vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Trả về danh sách API
 */
roleRoutes.get('/:roleId/api-permissions', RoleController.getRoleApiPermissions);

/**
 * @swagger
 * /api/roles/{roleId}/api-permissions:
 *   put:
 *     summary: Thay thế danh sách API được phép truy cập của Vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.6 Kiểm soát API theo vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [api_ids]
 *             properties:
 *               api_ids:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       200:
 *         description: Trả về thành công
 */
roleRoutes.put('/:roleId/api-permissions', RoleController.replaceRoleApiPermissions);

/**
 * @swagger
 * /api/roles/{roleId}/api-permissions:
 *   post:
 *     summary: Gán thêm một API cho Vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.6 Kiểm soát API theo vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [api_id]
 *             properties:
 *               api_id:
 *                 type: string
 *     responses:
 *       201:
 *         description: Gán API Role thành công
 */
roleRoutes.post('/:roleId/api-permissions', RoleController.assignRoleApiPermission);

/**
 * @swagger
 * /api/roles/{roleId}/api-permissions/{apiId}:
 *   delete:
 *     summary: Xóa một API khỏi ranh giới Vai trò
 *     description: |
 *       **Vai trò được phép:** ADMIN
 *
 *     tags: [1.3.6 Kiểm soát API theo vai trò]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roleId
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: apiId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Gỡ API Role thành công
 */
roleRoutes.delete('/:roleId/api-permissions/:apiId', RoleController.removeRoleApiPermission);

export default roleRoutes;
