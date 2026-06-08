-- =====================================================================
-- 15_pharmacy_warehouse.sql
-- =====================================================================
-- Seed data demo cho phân hệ Quản lý kho thuốc / Nhập - Xuất kho / NCC
--
-- Bao phủ các bảng đang trống:
--   * suppliers                          (5 nhà cung cấp)
--   * warehouses                         (3 kho: trung tâm, vệ tinh, dự phòng)
--   * stock_in_orders                    (30 phiếu nhập, trải 6 tháng gần nhất)
--   * stock_in_details                   (~90 dòng — TB 3 mặt hàng/phiếu)
--   * stock_out_orders                   (10 phiếu xuất)
--   * stock_out_details                  (~30 dòng)
--   * medication_instruction_templates   (+10 mẫu hướng dẫn bổ sung)
--
-- Idempotent: mọi INSERT đều kèm ON CONFLICT DO NOTHING.
-- Dependencies:
--   * 01_core_roles_users.sql            → USR_PHA_01..03 (dược sĩ), USR_ADMIN_01
--   * 03_facilities.sql                  → BR_MAIN
--   * 08_pharmacy.sql                    → DRG_001..120, PINV_0001..0160
--   * structure/migrations/warehouse_management.sql       (bảng warehouses)
--   * structure/migrations/stock_in_management.sql        (suppliers + stock_in_*)
--   * structure/migrations/stock_out_management.sql       (stock_out_*)
--   * structure/migrations/medication_instructions.sql    (templates + seed gốc)
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 1. SUPPLIERS (5 nhà cung cấp dược phẩm thực tế tại Việt Nam)
-- ---------------------------------------------------------------------
INSERT INTO suppliers (
    supplier_id, code, name, contact_person, phone, email, address, tax_code, is_active
) VALUES
('SUP_001', 'CPC1',   'Công ty Cổ phần Dược phẩm Trung ương 1 (CPC1)',
 'Nguyễn Văn An',  '02438254234', 'sales@cpc1.vn',
 '87 Nguyễn Văn Trỗi, phường Phương Liệt, quận Thanh Xuân, Hà Nội',
 '0100107307', TRUE),
('SUP_002', 'DHG',    'Công ty Cổ phần Dược Hậu Giang',
 'Trần Thị Bích',  '02923820223', 'sales@dhgpharma.com.vn',
 '288 Bis Nguyễn Văn Cừ, phường An Hòa, quận Ninh Kiều, Cần Thơ',
 '1800156801', TRUE),
('SUP_003', 'SANOFI', 'Công ty TNHH Sanofi-Aventis Việt Nam',
 'Lê Văn Cường',   '02838295868', 'vn.contact@sanofi.com',
 '15-17 Tân Tạo, Khu công nghiệp Tân Tạo, quận Bình Tân, TP. Hồ Chí Minh',
 '0300441437', TRUE),
('SUP_004', 'PFIZER', 'Công ty TNHH Pfizer (Việt Nam)',
 'Phạm Thị Dung',  '02838235828', 'vn.contact@pfizer.com',
 'Tầng 14, Tòa nhà Mê Linh Point, 2 Ngô Đức Kế, quận 1, TP. Hồ Chí Minh',
 '0300554328', TRUE),
('SUP_005', 'GSK',    'Công ty TNHH GlaxoSmithKline (GSK) Việt Nam',
 'Hoàng Văn Em',   '02838231234', 'vn.contact@gsk.com',
 'Tầng 9, Tòa nhà Metropolitan, 235 Đồng Khởi, quận 1, TP. Hồ Chí Minh',
 '0300667890', TRUE)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- 2. WAREHOUSES (3 kho thuộc BR_MAIN)
-- ---------------------------------------------------------------------
-- NOTE: warehouse code 'WH-MAIN' đã được system tạo sẵn cho BR_MAIN với
-- một warehouse_id auto-generated. Để tránh conflict UNIQUE(branch_id, code)
-- ta dùng các code mới (DEMO-MAIN/DEMO-SAT/DEMO-RES).
INSERT INTO warehouses (
    warehouse_id, branch_id, code, name, warehouse_type, address, is_active
) VALUES
('WH_MAIN',      'BR_MAIN', 'DEMO-MAIN', 'Kho trung tâm',
 'MAIN',      'Tầng hầm B1, Tòa nhà chính - Khu A',                    TRUE),
('WH_SATELLITE', 'BR_MAIN', 'DEMO-SAT',  'Kho vệ tinh - tầng 1',
 'SECONDARY', 'Tầng 1, gần khu phát thuốc ngoại trú - Khu B',          TRUE),
('WH_RESERVE',   'BR_MAIN', 'DEMO-RES',  'Kho dự phòng',
 'SECONDARY', 'Tầng 2, sau khu xét nghiệm - Khu C',                    TRUE)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- 3. STOCK_IN_ORDERS (30 phiếu nhập, trải 6 tháng gần nhất)
--    Phân bố trạng thái: 20 RECEIVED + 5 CONFIRMED + 3 DRAFT + 2 CANCELLED
-- ---------------------------------------------------------------------
INSERT INTO stock_in_orders (
    stock_in_order_id, order_code, supplier_id, warehouse_id, created_by,
    status, notes, total_amount, received_at, received_by,
    cancelled_at, cancelled_reason, created_at, updated_at
) VALUES
-- ---------- RECEIVED (20 phiếu) ----------
('STIN_001', 'GRN-2025-001', 'SUP_001', 'WH_MAIN',      'USR_PHA_01',
 'RECEIVED', 'Nhập kho định kỳ tháng 11/2025',  15750000, NOW() - INTERVAL '178 days', 'USR_PHA_01',
 NULL, NULL, NOW() - INTERVAL '180 days', NOW() - INTERVAL '178 days'),
('STIN_002', 'GRN-2025-002', 'SUP_002', 'WH_MAIN',      'USR_PHA_02',
 'RECEIVED', 'Bổ sung nhóm kháng sinh',         12400000, NOW() - INTERVAL '171 days', 'USR_PHA_02',
 NULL, NULL, NOW() - INTERVAL '173 days', NOW() - INTERVAL '171 days'),
('STIN_003', 'GRN-2025-003', 'SUP_003', 'WH_SATELLITE', 'USR_PHA_01',
 'RECEIVED', 'Nhập đợt ưu đãi nhà cung cấp',    22150000, NOW() - INTERVAL '165 days', 'USR_PHA_01',
 NULL, NULL, NOW() - INTERVAL '167 days', NOW() - INTERVAL '165 days'),
('STIN_004', 'GRN-2025-004', 'SUP_004', 'WH_MAIN',      'USR_PHA_03',
 'RECEIVED', 'Nhập thuốc tiểu đường',           18900000, NOW() - INTERVAL '158 days', 'USR_PHA_03',
 NULL, NULL, NOW() - INTERVAL '160 days', NOW() - INTERVAL '158 days'),
('STIN_005', 'GRN-2025-005', 'SUP_005', 'WH_RESERVE',   'USR_PHA_02',
 'RECEIVED', 'Dự trữ vắc-xin và thuốc tim mạch', 27500000, NOW() - INTERVAL '151 days', 'USR_PHA_02',
 NULL, NULL, NOW() - INTERVAL '153 days', NOW() - INTERVAL '151 days'),
('STIN_006', 'GRN-2025-006', 'SUP_001', 'WH_MAIN',      'USR_PHA_01',
 'RECEIVED', 'Nhập kháng viêm NSAID',           11280000, NOW() - INTERVAL '144 days', 'USR_PHA_01',
 NULL, NULL, NOW() - INTERVAL '146 days', NOW() - INTERVAL '144 days'),
('STIN_007', 'GRN-2025-007', 'SUP_002', 'WH_SATELLITE', 'USR_PHA_02',
 'RECEIVED', 'Bổ sung thuốc giảm đau',          8600000, NOW() - INTERVAL '137 days', 'USR_PHA_02',
 NULL, NULL, NOW() - INTERVAL '139 days', NOW() - INTERVAL '137 days'),
('STIN_008', 'GRN-2025-008', 'SUP_003', 'WH_MAIN',      'USR_PHA_03',
 'RECEIVED', 'Nhập đợt cuối quý 3',             19450000, NOW() - INTERVAL '130 days', 'USR_PHA_03',
 NULL, NULL, NOW() - INTERVAL '132 days', NOW() - INTERVAL '130 days'),
('STIN_009', 'GRN-2025-009', 'SUP_004', 'WH_MAIN',      'USR_PHA_01',
 'RECEIVED', 'Nhập kháng sinh phổ rộng',        24700000, NOW() - INTERVAL '123 days', 'USR_PHA_01',
 NULL, NULL, NOW() - INTERVAL '125 days', NOW() - INTERVAL '123 days'),
('STIN_010', 'GRN-2025-010', 'SUP_005', 'WH_RESERVE',   'USR_PHA_02',
 'RECEIVED', 'Nhập corticosteroid + giãn phế quản', 16800000, NOW() - INTERVAL '116 days', 'USR_PHA_02',
 NULL, NULL, NOW() - INTERVAL '118 days', NOW() - INTERVAL '116 days'),
('STIN_011', 'GRN-2025-011', 'SUP_001', 'WH_MAIN',      'USR_PHA_03',
 'RECEIVED', 'Nhập kho định kỳ tháng 1',        13200000, NOW() - INTERVAL '109 days', 'USR_PHA_03',
 NULL, NULL, NOW() - INTERVAL '111 days', NOW() - INTERVAL '109 days'),
('STIN_012', 'GRN-2025-012', 'SUP_002', 'WH_SATELLITE', 'USR_PHA_01',
 'RECEIVED', 'Bổ sung vitamin và bổ máu',       9450000, NOW() - INTERVAL '102 days', 'USR_PHA_01',
 NULL, NULL, NOW() - INTERVAL '104 days', NOW() - INTERVAL '102 days'),
('STIN_013', 'GRN-2025-013', 'SUP_003', 'WH_MAIN',      'USR_PHA_02',
 'RECEIVED', 'Đợt ưu đãi đầu năm Sanofi',       21300000, NOW() - INTERVAL '95 days',  'USR_PHA_02',
 NULL, NULL, NOW() - INTERVAL '97 days',  NOW() - INTERVAL '95 days'),
('STIN_014', 'GRN-2025-014', 'SUP_004', 'WH_MAIN',      'USR_PHA_03',
 'RECEIVED', 'Nhập thuốc huyết áp Pfizer',      17850000, NOW() - INTERVAL '88 days',  'USR_PHA_03',
 NULL, NULL, NOW() - INTERVAL '90 days',  NOW() - INTERVAL '88 days'),
('STIN_015', 'GRN-2025-015', 'SUP_005', 'WH_RESERVE',   'USR_PHA_01',
 'RECEIVED', 'Dự trữ thuốc hen suyễn GSK',      14600000, NOW() - INTERVAL '81 days',  'USR_PHA_01',
 NULL, NULL, NOW() - INTERVAL '83 days',  NOW() - INTERVAL '81 days'),
('STIN_016', 'GRN-2025-016', 'SUP_001', 'WH_MAIN',      'USR_PHA_02',
 'RECEIVED', 'Nhập thuốc dạ dày tiêu hóa',      10900000, NOW() - INTERVAL '74 days',  'USR_PHA_02',
 NULL, NULL, NOW() - INTERVAL '76 days',  NOW() - INTERVAL '74 days'),
('STIN_017', 'GRN-2025-017', 'SUP_002', 'WH_SATELLITE', 'USR_PHA_03',
 'RECEIVED', 'Bổ sung kháng dị ứng + ho',       7850000,  NOW() - INTERVAL '67 days',  'USR_PHA_03',
 NULL, NULL, NOW() - INTERVAL '69 days',  NOW() - INTERVAL '67 days'),
('STIN_018', 'GRN-2025-018', 'SUP_003', 'WH_MAIN',      'USR_PHA_01',
 'RECEIVED', 'Nhập đợt mua chung quý 1',        25400000, NOW() - INTERVAL '60 days',  'USR_PHA_01',
 NULL, NULL, NOW() - INTERVAL '62 days',  NOW() - INTERVAL '60 days'),
('STIN_019', 'GRN-2025-019', 'SUP_004', 'WH_MAIN',      'USR_PHA_02',
 'RECEIVED', 'Nhập thuốc tim mạch chuyên khoa', 31200000, NOW() - INTERVAL '53 days',  'USR_PHA_02',
 NULL, NULL, NOW() - INTERVAL '55 days',  NOW() - INTERVAL '53 days'),
('STIN_020', 'GRN-2025-020', 'SUP_005', 'WH_RESERVE',   'USR_PHA_03',
 'RECEIVED', 'Bổ sung thuốc tiêm và đặt hậu môn',12750000, NOW() - INTERVAL '46 days',  'USR_PHA_03',
 NULL, NULL, NOW() - INTERVAL '48 days',  NOW() - INTERVAL '46 days'),
-- ---------- CONFIRMED (5 phiếu, đã duyệt - chờ giao) ----------
('STIN_021', 'GRN-2025-021', 'SUP_001', 'WH_MAIN',      'USR_PHA_01',
 'CONFIRMED', 'Đặt thêm kháng sinh - chờ giao',  11500000, NULL, NULL,
 NULL, NULL, NOW() - INTERVAL '40 days', NOW() - INTERVAL '38 days'),
('STIN_022', 'GRN-2025-022', 'SUP_002', 'WH_SATELLITE', 'USR_PHA_02',
 'CONFIRMED', 'Đơn bổ sung khẩn cấp giảm đau',   6900000,  NULL, NULL,
 NULL, NULL, NOW() - INTERVAL '32 days', NOW() - INTERVAL '30 days'),
('STIN_023', 'GRN-2025-023', 'SUP_003', 'WH_MAIN',      'USR_PHA_03',
 'CONFIRMED', 'Đặt thuốc đặc trị - dự kiến giao tuần sau', 28400000, NULL, NULL,
 NULL, NULL, NOW() - INTERVAL '25 days', NOW() - INTERVAL '23 days'),
('STIN_024', 'GRN-2025-024', 'SUP_004', 'WH_MAIN',      'USR_PHA_01',
 'CONFIRMED', 'Đơn thuốc huyết áp tháng tới',    19850000, NULL, NULL,
 NULL, NULL, NOW() - INTERVAL '18 days', NOW() - INTERVAL '16 days'),
('STIN_025', 'GRN-2025-025', 'SUP_005', 'WH_RESERVE',   'USR_PHA_02',
 'CONFIRMED', 'Đặt vắc-xin theo kế hoạch',       33600000, NULL, NULL,
 NULL, NULL, NOW() - INTERVAL '12 days', NOW() - INTERVAL '10 days'),
-- ---------- DRAFT (3 phiếu, đang soạn) ----------
('STIN_026', 'GRN-2025-026', 'SUP_001', 'WH_MAIN',      'USR_PHA_03',
 'DRAFT',     'Phiếu mới đang chờ duyệt',        8200000,  NULL, NULL,
 NULL, NULL, NOW() - INTERVAL '7 days',  NOW() - INTERVAL '7 days'),
('STIN_027', 'GRN-2025-027', 'SUP_002', 'WH_SATELLITE', 'USR_PHA_01',
 'DRAFT',     'Soạn đơn quý 2',                  10750000, NULL, NULL,
 NULL, NULL, NOW() - INTERVAL '4 days',  NOW() - INTERVAL '4 days'),
('STIN_028', 'GRN-2025-028', 'SUP_003', 'WH_MAIN',      'USR_PHA_02',
 'DRAFT',     'Bổ sung thuốc thiếu - chưa duyệt', 5400000, NULL, NULL,
 NULL, NULL, NOW() - INTERVAL '2 days',  NOW() - INTERVAL '2 days'),
-- ---------- CANCELLED (2 phiếu, đã hủy) ----------
('STIN_029', 'GRN-2025-029', 'SUP_004', 'WH_MAIN',      'USR_PHA_03',
 'CANCELLED', 'NCC báo hết hàng - hủy đơn',       0,
 NULL, NULL,
 NOW() - INTERVAL '36 days', 'Nhà cung cấp không còn hàng theo lô đã đặt',
 NOW() - INTERVAL '42 days', NOW() - INTERVAL '36 days'),
('STIN_030', 'GRN-2025-030', 'SUP_005', 'WH_RESERVE',   'USR_PHA_01',
 'CANCELLED', 'Sai mã thuốc - hủy lập lại phiếu', 0,
 NULL, NULL,
 NOW() - INTERVAL '20 days', 'Lập sai chi tiết SKU - sẽ tạo phiếu mới',
 NOW() - INTERVAL '22 days', NOW() - INTERVAL '20 days')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- 4. STOCK_IN_DETAILS (~90 dòng — 3 mặt hàng / phiếu)
--    Mỗi dòng: drug_id, batch_number, expiry_date, quantity, unit_cost, unit_price, amount
--    Giá: 500đ - 50000đ/đơn vị; expiry: 6 tháng → 3 năm
-- ---------------------------------------------------------------------
INSERT INTO stock_in_details (
    stock_in_detail_id, stock_in_order_id, drug_id, batch_number,
    expiry_date, quantity, unit_cost, unit_price, amount
) VALUES
-- STIN_001 (CPC1 → WH_MAIN)
('STIND_0001', 'STIN_001', 'DRG_001', 'LOT-CPC1-2501-A', CURRENT_DATE + INTERVAL '730 days', 2000, 2000.00, 2600.00, 4000000.00),
('STIND_0002', 'STIN_001', 'DRG_011', 'LOT-CPC1-2501-B', CURRENT_DATE + INTERVAL '545 days', 1500, 700.00,  900.00,  1050000.00),
('STIND_0003', 'STIN_001', 'DRG_021', 'LOT-CPC1-2501-C', CURRENT_DATE + INTERVAL '900 days', 1000, 3350.00, 4350.00, 3350000.00),
-- STIN_002 (DHG → WH_MAIN)
('STIND_0004', 'STIN_002', 'DRG_031', 'LOT-DHG-2501-A',  CURRENT_DATE + INTERVAL '610 days', 800,  5200.00, 6700.00, 4160000.00),
('STIND_0005', 'STIN_002', 'DRG_032', 'LOT-DHG-2501-B',  CURRENT_DATE + INTERVAL '700 days', 600,  4800.00, 6200.00, 2880000.00),
('STIND_0006', 'STIN_002', 'DRG_033', 'LOT-DHG-2501-C',  CURRENT_DATE + INTERVAL '820 days', 500,  5100.00, 6600.00, 2550000.00),
-- STIN_003 (SANOFI → WH_SAT)
('STIND_0007', 'STIN_003', 'DRG_041', 'LOT-SAN-2502-A',  CURRENT_DATE + INTERVAL '550 days', 400,  12500.00, 16200.00, 5000000.00),
('STIND_0008', 'STIN_003', 'DRG_042', 'LOT-SAN-2502-B',  CURRENT_DATE + INTERVAL '750 days', 300,  18000.00, 23400.00, 5400000.00),
('STIND_0009', 'STIN_003', 'DRG_043', 'LOT-SAN-2502-C',  CURRENT_DATE + INTERVAL '900 days', 350,  15000.00, 19500.00, 5250000.00),
-- STIN_004 (PFIZER → WH_MAIN)
('STIND_0010', 'STIN_004', 'DRG_051', 'LOT-PFZ-2502-A',  CURRENT_DATE + INTERVAL '545 days', 600,  9500.00,  12400.00, 5700000.00),
('STIND_0011', 'STIN_004', 'DRG_052', 'LOT-PFZ-2502-B',  CURRENT_DATE + INTERVAL '700 days', 500,  11200.00, 14600.00, 5600000.00),
('STIND_0012', 'STIN_004', 'DRG_053', 'LOT-PFZ-2502-C',  CURRENT_DATE + INTERVAL '850 days', 400,  10800.00, 14000.00, 4320000.00),
-- STIN_005 (GSK → WH_RESERVE)
('STIND_0013', 'STIN_005', 'DRG_061', 'LOT-GSK-2502-A',  CURRENT_DATE + INTERVAL '450 days', 300,  22000.00, 28600.00, 6600000.00),
('STIND_0014', 'STIN_005', 'DRG_062', 'LOT-GSK-2502-B',  CURRENT_DATE + INTERVAL '600 days', 250,  35000.00, 45500.00, 8750000.00),
('STIND_0015', 'STIN_005', 'DRG_063', 'LOT-GSK-2502-C',  CURRENT_DATE + INTERVAL '720 days', 200,  28000.00, 36400.00, 5600000.00),
-- STIN_006 (CPC1 → WH_MAIN)
('STIND_0016', 'STIN_006', 'DRG_002', 'LOT-CPC1-2503-A', CURRENT_DATE + INTERVAL '700 days', 1800, 2050.00, 2660.00, 3690000.00),
('STIND_0017', 'STIN_006', 'DRG_012', 'LOT-CPC1-2503-B', CURRENT_DATE + INTERVAL '550 days', 1200, 720.00,  930.00,  864000.00),
('STIND_0018', 'STIN_006', 'DRG_022', 'LOT-CPC1-2503-C', CURRENT_DATE + INTERVAL '900 days', 800,  3400.00, 4420.00, 2720000.00),
-- STIN_007 (DHG → WH_SAT)
('STIND_0019', 'STIN_007', 'DRG_034', 'LOT-DHG-2503-A',  CURRENT_DATE + INTERVAL '610 days', 500,  4900.00, 6370.00, 2450000.00),
('STIND_0020', 'STIN_007', 'DRG_035', 'LOT-DHG-2503-B',  CURRENT_DATE + INTERVAL '720 days', 400,  5300.00, 6890.00, 2120000.00),
('STIND_0021', 'STIN_007', 'DRG_036', 'LOT-DHG-2503-C',  CURRENT_DATE + INTERVAL '850 days', 600,  6700.00, 8710.00, 4020000.00),
-- STIN_008 (SANOFI → WH_MAIN)
('STIND_0022', 'STIN_008', 'DRG_044', 'LOT-SAN-2503-A',  CURRENT_DATE + INTERVAL '550 days', 350,  14000.00, 18200.00, 4900000.00),
('STIND_0023', 'STIN_008', 'DRG_045', 'LOT-SAN-2503-B',  CURRENT_DATE + INTERVAL '750 days', 300,  16500.00, 21450.00, 4950000.00),
('STIND_0024', 'STIN_008', 'DRG_046', 'LOT-SAN-2503-C',  CURRENT_DATE + INTERVAL '900 days', 400,  17500.00, 22750.00, 7000000.00),
-- STIN_009 (PFIZER → WH_MAIN)
('STIND_0025', 'STIN_009', 'DRG_054', 'LOT-PFZ-2503-A',  CURRENT_DATE + INTERVAL '545 days', 500,  13800.00, 17940.00, 6900000.00),
('STIND_0026', 'STIN_009', 'DRG_055', 'LOT-PFZ-2503-B',  CURRENT_DATE + INTERVAL '700 days', 600,  12300.00, 15990.00, 7380000.00),
('STIND_0027', 'STIN_009', 'DRG_056', 'LOT-PFZ-2503-C',  CURRENT_DATE + INTERVAL '820 days', 450,  23200.00, 30160.00, 10440000.00),
-- STIN_010 (GSK → WH_RESERVE)
('STIND_0028', 'STIN_010', 'DRG_064', 'LOT-GSK-2503-A',  CURRENT_DATE + INTERVAL '450 days', 250,  25000.00, 32500.00, 6250000.00),
('STIND_0029', 'STIN_010', 'DRG_065', 'LOT-GSK-2503-B',  CURRENT_DATE + INTERVAL '600 days', 200,  31000.00, 40300.00, 6200000.00),
('STIND_0030', 'STIN_010', 'DRG_066', 'LOT-GSK-2503-C',  CURRENT_DATE + INTERVAL '720 days', 150,  29000.00, 37700.00, 4350000.00),
-- STIN_011 (CPC1 → WH_MAIN)
('STIND_0031', 'STIN_011', 'DRG_003', 'LOT-CPC1-2504-A', CURRENT_DATE + INTERVAL '720 days', 1600, 2080.00, 2700.00, 3328000.00),
('STIND_0032', 'STIN_011', 'DRG_013', 'LOT-CPC1-2504-B', CURRENT_DATE + INTERVAL '550 days', 1100, 740.00,  960.00,  814000.00),
('STIND_0033', 'STIN_011', 'DRG_023', 'LOT-CPC1-2504-C', CURRENT_DATE + INTERVAL '900 days', 750,  3450.00, 4485.00, 2587500.00),
-- STIN_012 (DHG → WH_SAT)
('STIND_0034', 'STIN_012', 'DRG_037', 'LOT-DHG-2504-A',  CURRENT_DATE + INTERVAL '610 days', 400,  4500.00, 5850.00, 1800000.00),
('STIND_0035', 'STIN_012', 'DRG_038', 'LOT-DHG-2504-B',  CURRENT_DATE + INTERVAL '730 days', 350,  5100.00, 6630.00, 1785000.00),
('STIND_0036', 'STIN_012', 'DRG_039', 'LOT-DHG-2504-C',  CURRENT_DATE + INTERVAL '850 days', 500,  5800.00, 7540.00, 2900000.00),
-- STIN_013 (SANOFI → WH_MAIN)
('STIND_0037', 'STIN_013', 'DRG_047', 'LOT-SAN-2504-A',  CURRENT_DATE + INTERVAL '545 days', 400,  18000.00, 23400.00, 7200000.00),
('STIND_0038', 'STIN_013', 'DRG_048', 'LOT-SAN-2504-B',  CURRENT_DATE + INTERVAL '700 days', 300,  21500.00, 27950.00, 6450000.00),
('STIND_0039', 'STIN_013', 'DRG_049', 'LOT-SAN-2504-C',  CURRENT_DATE + INTERVAL '850 days', 350,  21000.00, 27300.00, 7350000.00),
-- STIN_014 (PFIZER → WH_MAIN)
('STIND_0040', 'STIN_014', 'DRG_057', 'LOT-PFZ-2504-A',  CURRENT_DATE + INTERVAL '540 days', 550,  10500.00, 13650.00, 5775000.00),
('STIND_0041', 'STIN_014', 'DRG_058', 'LOT-PFZ-2504-B',  CURRENT_DATE + INTERVAL '700 days', 400,  14200.00, 18460.00, 5680000.00),
('STIND_0042', 'STIN_014', 'DRG_059', 'LOT-PFZ-2504-C',  CURRENT_DATE + INTERVAL '850 days', 300,  21300.00, 27690.00, 6390000.00),
-- STIN_015 (GSK → WH_RESERVE)
('STIND_0043', 'STIN_015', 'DRG_067', 'LOT-GSK-2504-A',  CURRENT_DATE + INTERVAL '450 days', 220,  26500.00, 34450.00, 5830000.00),
('STIND_0044', 'STIN_015', 'DRG_068', 'LOT-GSK-2504-B',  CURRENT_DATE + INTERVAL '600 days', 180,  28000.00, 36400.00, 5040000.00),
('STIND_0045', 'STIN_015', 'DRG_069', 'LOT-GSK-2504-C',  CURRENT_DATE + INTERVAL '720 days', 150,  25000.00, 32500.00, 3750000.00),
-- STIN_016 (CPC1 → WH_MAIN)
('STIND_0046', 'STIN_016', 'DRG_004', 'LOT-CPC1-2505-A', CURRENT_DATE + INTERVAL '730 days', 1500, 2100.00, 2730.00, 3150000.00),
('STIND_0047', 'STIN_016', 'DRG_014', 'LOT-CPC1-2505-B', CURRENT_DATE + INTERVAL '545 days', 1000, 760.00,  988.00,  760000.00),
('STIND_0048', 'STIN_016', 'DRG_024', 'LOT-CPC1-2505-C', CURRENT_DATE + INTERVAL '900 days', 700,  3500.00, 4550.00, 2450000.00),
-- STIN_017 (DHG → WH_SAT)
('STIND_0049', 'STIN_017', 'DRG_040', 'LOT-DHG-2505-A',  CURRENT_DATE + INTERVAL '610 days', 350,  4600.00, 5980.00, 1610000.00),
('STIND_0050', 'STIN_017', 'DRG_071', 'LOT-DHG-2505-B',  CURRENT_DATE + INTERVAL '720 days', 300,  5800.00, 7540.00, 1740000.00),
('STIND_0051', 'STIN_017', 'DRG_072', 'LOT-DHG-2505-C',  CURRENT_DATE + INTERVAL '850 days', 400,  6250.00, 8125.00, 2500000.00),
-- STIN_018 (SANOFI → WH_MAIN)
('STIND_0052', 'STIN_018', 'DRG_073', 'LOT-SAN-2505-A',  CURRENT_DATE + INTERVAL '545 days', 400,  19500.00, 25350.00, 7800000.00),
('STIND_0053', 'STIN_018', 'DRG_074', 'LOT-SAN-2505-B',  CURRENT_DATE + INTERVAL '700 days', 350,  22000.00, 28600.00, 7700000.00),
('STIND_0054', 'STIN_018', 'DRG_075', 'LOT-SAN-2505-C',  CURRENT_DATE + INTERVAL '850 days', 450,  21800.00, 28340.00, 9810000.00),
-- STIN_019 (PFIZER → WH_MAIN)
('STIND_0055', 'STIN_019', 'DRG_076', 'LOT-PFZ-2505-A',  CURRENT_DATE + INTERVAL '540 days', 600,  16500.00, 21450.00, 9900000.00),
('STIND_0056', 'STIN_019', 'DRG_077', 'LOT-PFZ-2505-B',  CURRENT_DATE + INTERVAL '700 days', 500,  18200.00, 23660.00, 9100000.00),
('STIND_0057', 'STIN_019', 'DRG_078', 'LOT-PFZ-2505-C',  CURRENT_DATE + INTERVAL '850 days', 400,  30500.00, 39650.00, 12200000.00),
-- STIN_020 (GSK → WH_RESERVE)
('STIND_0058', 'STIN_020', 'DRG_079', 'LOT-GSK-2505-A',  CURRENT_DATE + INTERVAL '450 days', 200,  22000.00, 28600.00, 4400000.00),
('STIND_0059', 'STIN_020', 'DRG_080', 'LOT-GSK-2505-B',  CURRENT_DATE + INTERVAL '600 days', 150,  27500.00, 35750.00, 4125000.00),
('STIND_0060', 'STIN_020', 'DRG_081', 'LOT-GSK-2505-C',  CURRENT_DATE + INTERVAL '720 days', 130,  32500.00, 42250.00, 4225000.00),
-- STIN_021 (CPC1 → WH_MAIN, CONFIRMED)
('STIND_0061', 'STIN_021', 'DRG_005', 'LOT-CPC1-2506-A', CURRENT_DATE + INTERVAL '720 days', 1400, 2120.00, 2756.00, 2968000.00),
('STIND_0062', 'STIN_021', 'DRG_015', 'LOT-CPC1-2506-B', CURRENT_DATE + INTERVAL '550 days', 1000, 1260.00, 1638.00, 1260000.00),
('STIND_0063', 'STIN_021', 'DRG_025', 'LOT-CPC1-2506-C', CURRENT_DATE + INTERVAL '900 days', 650,  3500.00, 4550.00, 2275000.00),
-- STIN_022 (DHG → WH_SAT, CONFIRMED)
('STIND_0064', 'STIN_022', 'DRG_082', 'LOT-DHG-2506-A',  CURRENT_DATE + INTERVAL '610 days', 300,  5400.00, 7020.00, 1620000.00),
('STIND_0065', 'STIN_022', 'DRG_083', 'LOT-DHG-2506-B',  CURRENT_DATE + INTERVAL '720 days', 250,  6800.00, 8840.00, 1700000.00),
('STIND_0066', 'STIN_022', 'DRG_084', 'LOT-DHG-2506-C',  CURRENT_DATE + INTERVAL '850 days', 350,  10200.00, 13260.00, 3570000.00),
-- STIN_023 (SANOFI → WH_MAIN, CONFIRMED)
('STIND_0067', 'STIN_023', 'DRG_085', 'LOT-SAN-2506-A',  CURRENT_DATE + INTERVAL '545 days', 400,  23000.00, 29900.00, 9200000.00),
('STIND_0068', 'STIN_023', 'DRG_086', 'LOT-SAN-2506-B',  CURRENT_DATE + INTERVAL '700 days', 350,  25500.00, 33150.00, 8925000.00),
('STIND_0069', 'STIN_023', 'DRG_087', 'LOT-SAN-2506-C',  CURRENT_DATE + INTERVAL '900 days', 400,  26000.00, 33800.00, 10400000.00),
-- STIN_024 (PFIZER → WH_MAIN, CONFIRMED)
('STIND_0070', 'STIN_024', 'DRG_088', 'LOT-PFZ-2506-A',  CURRENT_DATE + INTERVAL '545 days', 500,  15000.00, 19500.00, 7500000.00),
('STIND_0071', 'STIN_024', 'DRG_089', 'LOT-PFZ-2506-B',  CURRENT_DATE + INTERVAL '700 days', 400,  17500.00, 22750.00, 7000000.00),
('STIND_0072', 'STIN_024', 'DRG_090', 'LOT-PFZ-2506-C',  CURRENT_DATE + INTERVAL '850 days', 350,  15300.00, 19890.00, 5355000.00),
-- STIN_025 (GSK → WH_RESERVE, CONFIRMED)
('STIND_0073', 'STIN_025', 'DRG_091', 'LOT-GSK-2506-A',  CURRENT_DATE + INTERVAL '450 days', 250,  40000.00, 52000.00, 10000000.00),
('STIND_0074', 'STIN_025', 'DRG_092', 'LOT-GSK-2506-B',  CURRENT_DATE + INTERVAL '600 days', 200,  48000.00, 62400.00, 9600000.00),
('STIND_0075', 'STIN_025', 'DRG_093', 'LOT-GSK-2506-C',  CURRENT_DATE + INTERVAL '720 days', 200,  35000.00, 45500.00, 7000000.00),
-- STIN_026 (CPC1 → WH_MAIN, DRAFT)
('STIND_0076', 'STIN_026', 'DRG_006', 'LOT-CPC1-2507-A', CURRENT_DATE + INTERVAL '730 days', 1200, 2150.00, 2795.00, 2580000.00),
('STIND_0077', 'STIN_026', 'DRG_016', 'LOT-CPC1-2507-B', CURRENT_DATE + INTERVAL '545 days', 800,  1280.00, 1664.00, 1024000.00),
('STIND_0078', 'STIN_026', 'DRG_026', 'LOT-CPC1-2507-C', CURRENT_DATE + INTERVAL '900 days', 600,  3550.00, 4615.00, 2130000.00),
-- STIN_027 (DHG → WH_SAT, DRAFT)
('STIND_0079', 'STIN_027', 'DRG_094', 'LOT-DHG-2507-A',  CURRENT_DATE + INTERVAL '610 days', 350,  6500.00, 8450.00, 2275000.00),
('STIND_0080', 'STIN_027', 'DRG_095', 'LOT-DHG-2507-B',  CURRENT_DATE + INTERVAL '720 days', 300,  7800.00, 10140.00, 2340000.00),
('STIND_0081', 'STIN_027', 'DRG_096', 'LOT-DHG-2507-C',  CURRENT_DATE + INTERVAL '850 days', 450,  13600.00, 17680.00, 6120000.00),
-- STIN_028 (SANOFI → WH_MAIN, DRAFT)
('STIND_0082', 'STIN_028', 'DRG_097', 'LOT-SAN-2507-A',  CURRENT_DATE + INTERVAL '545 days', 250,  9500.00, 12350.00, 2375000.00),
('STIND_0083', 'STIN_028', 'DRG_098', 'LOT-SAN-2507-B',  CURRENT_DATE + INTERVAL '700 days', 200,  8800.00, 11440.00, 1760000.00),
('STIND_0084', 'STIN_028', 'DRG_099', 'LOT-SAN-2507-C',  CURRENT_DATE + INTERVAL '850 days', 200,  6500.00, 8450.00,  1300000.00),
-- STIN_029 (PFIZER → WH_MAIN, CANCELLED — vẫn có line gốc, không update inventory)
('STIND_0085', 'STIN_029', 'DRG_100', 'LOT-PFZ-2507-X',  CURRENT_DATE + INTERVAL '545 days', 400,  19000.00, 24700.00, 7600000.00),
('STIND_0086', 'STIN_029', 'DRG_101', 'LOT-PFZ-2507-Y',  CURRENT_DATE + INTERVAL '700 days', 300,  21500.00, 27950.00, 6450000.00),
('STIND_0087', 'STIN_029', 'DRG_102', 'LOT-PFZ-2507-Z',  CURRENT_DATE + INTERVAL '850 days', 250,  16800.00, 21840.00, 4200000.00),
-- STIN_030 (GSK → WH_RESERVE, CANCELLED)
('STIND_0088', 'STIN_030', 'DRG_103', 'LOT-GSK-2507-X',  CURRENT_DATE + INTERVAL '450 days', 200,  29000.00, 37700.00, 5800000.00),
('STIND_0089', 'STIN_030', 'DRG_104', 'LOT-GSK-2507-Y',  CURRENT_DATE + INTERVAL '600 days', 180,  33500.00, 43550.00, 6030000.00),
('STIND_0090', 'STIN_030', 'DRG_105', 'LOT-GSK-2507-Z',  CURRENT_DATE + INTERVAL '720 days', 150,  41000.00, 53300.00, 6150000.00)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- 5. STOCK_OUT_ORDERS (10 phiếu xuất)
--    Trạng thái: 6 CONFIRMED + 2 DRAFT + 2 CANCELLED
--    reason_type: DISPOSAL / RETURN_SUPPLIER / TRANSFER / OTHER
-- ---------------------------------------------------------------------
INSERT INTO stock_out_orders (
    stock_out_order_id, order_code, warehouse_id, reason_type,
    supplier_id, dest_warehouse_id, created_by, status, notes,
    total_quantity, confirmed_at, confirmed_by,
    cancelled_at, cancelled_reason, created_at, updated_at
) VALUES
-- 1. DISPOSAL - hết hạn
('STOUT_001', 'SOUT-2025-001', 'WH_MAIN',      'DISPOSAL',
 NULL, NULL, 'USR_PHA_01', 'CONFIRMED', 'Hủy lô thuốc hết hạn quý 4/2025',
 350, NOW() - INTERVAL '88 days', 'USR_PHA_01',
 NULL, NULL, NOW() - INTERVAL '90 days', NOW() - INTERVAL '88 days'),
-- 2. RETURN_SUPPLIER - trả lại NCC
('STOUT_002', 'SOUT-2025-002', 'WH_MAIN',      'RETURN_SUPPLIER',
 'SUP_001', NULL, 'USR_PHA_02', 'CONFIRMED', 'Trả hàng lô lỗi nhãn về CPC1',
 100, NOW() - INTERVAL '75 days', 'USR_PHA_02',
 NULL, NULL, NOW() - INTERVAL '77 days', NOW() - INTERVAL '75 days'),
-- 3. TRANSFER - chuyển sang kho vệ tinh
('STOUT_003', 'SOUT-2025-003', 'WH_MAIN',      'TRANSFER',
 NULL, 'WH_SATELLITE', 'USR_PHA_03', 'CONFIRMED', 'Điều chuyển bổ sung cho kho vệ tinh',
 200, NOW() - INTERVAL '62 days', 'USR_PHA_03',
 NULL, NULL, NOW() - INTERVAL '64 days', NOW() - INTERVAL '62 days'),
-- 4. DISPOSAL - hư hỏng
('STOUT_004', 'SOUT-2025-004', 'WH_SATELLITE', 'DISPOSAL',
 NULL, NULL, 'USR_PHA_01', 'CONFIRMED', 'Hủy chai vỡ do vận chuyển',
 50, NOW() - INTERVAL '50 days', 'USR_PHA_01',
 NULL, NULL, NOW() - INTERVAL '52 days', NOW() - INTERVAL '50 days'),
-- 5. TRANSFER - chuyển sang kho dự phòng
('STOUT_005', 'SOUT-2025-005', 'WH_MAIN',      'TRANSFER',
 NULL, 'WH_RESERVE',  'USR_PHA_02', 'CONFIRMED', 'Chuyển dự trữ phục vụ Tết',
 300, NOW() - INTERVAL '40 days', 'USR_PHA_02',
 NULL, NULL, NOW() - INTERVAL '42 days', NOW() - INTERVAL '40 days'),
-- 6. RETURN_SUPPLIER - trả lại Sanofi
('STOUT_006', 'SOUT-2025-006', 'WH_MAIN',      'RETURN_SUPPLIER',
 'SUP_003', NULL, 'USR_PHA_03', 'CONFIRMED', 'Trả hàng lô bao bì hỏng về Sanofi',
 75, NOW() - INTERVAL '28 days', 'USR_PHA_03',
 NULL, NULL, NOW() - INTERVAL '30 days', NOW() - INTERVAL '28 days'),
-- 7. DRAFT - đang soạn
('STOUT_007', 'SOUT-2025-007', 'WH_RESERVE',   'DISPOSAL',
 NULL, NULL, 'USR_PHA_01', 'DRAFT', 'Đang kiểm kê hủy thuốc hết hạn',
 0, NULL, NULL,
 NULL, NULL, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
-- 8. DRAFT - đang soạn
('STOUT_008', 'SOUT-2025-008', 'WH_SATELLITE', 'TRANSFER',
 NULL, 'WH_RESERVE', 'USR_PHA_02', 'DRAFT', 'Đang soạn phiếu chuyển kho dự phòng',
 0, NULL, NULL,
 NULL, NULL, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
-- 9. CANCELLED - hủy do nhập sai
('STOUT_009', 'SOUT-2025-009', 'WH_MAIN',      'OTHER',
 NULL, NULL, 'USR_PHA_03', 'CANCELLED', 'Lập sai - hủy',
 0, NULL, NULL,
 NOW() - INTERVAL '15 days', 'Phiếu tạo nhầm - sẽ tạo lại',
 NOW() - INTERVAL '17 days', NOW() - INTERVAL '15 days'),
-- 10. CANCELLED - hủy do duyệt lại không xuất
('STOUT_010', 'SOUT-2025-010', 'WH_MAIN',      'RETURN_SUPPLIER',
 'SUP_004', NULL, 'USR_PHA_01', 'CANCELLED', 'NCC không nhận lại - hủy phiếu',
 0, NULL, NULL,
 NOW() - INTERVAL '9 days', 'Pfizer từ chối nhận trả lô này',
 NOW() - INTERVAL '11 days', NOW() - INTERVAL '9 days')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- 6. STOCK_OUT_DETAILS (~30 dòng — 3 mặt hàng / phiếu CONFIRMED + 1-2/phiếu khác)
--    inventory_id phải tham chiếu pharmacy_inventory hiện có (PINV_0001..0160)
-- ---------------------------------------------------------------------
INSERT INTO stock_out_details (
    stock_out_detail_id, stock_out_order_id, inventory_id, drug_id,
    batch_number, quantity, reason_note
) VALUES
-- STOUT_001 — DISPOSAL hết hạn (3 dòng)
('STOUTD_001', 'STOUT_001', 'PINV_0001', 'DRG_001', 'LOT-2501-0001', 150, 'Hết hạn 30/11/2025'),
('STOUTD_002', 'STOUT_001', 'PINV_0003', 'DRG_002', 'LOT-2501-0003', 100, 'Hết hạn 30/11/2025'),
('STOUTD_003', 'STOUT_001', 'PINV_0004', 'DRG_003', 'LOT-2501-0004', 100, 'Hết hạn 15/12/2025'),
-- STOUT_002 — RETURN_SUPPLIER lỗi nhãn (2 dòng)
('STOUTD_004', 'STOUT_002', 'PINV_0005', 'DRG_004', 'LOT-2501-0005', 60, 'Nhãn mờ - trả CPC1'),
('STOUTD_005', 'STOUT_002', 'PINV_0007', 'DRG_005', 'LOT-2501-0007', 40, 'Nhãn mờ - trả CPC1'),
-- STOUT_003 — TRANSFER sang WH_SATELLITE (3 dòng)
('STOUTD_006', 'STOUT_003', 'PINV_0008', 'DRG_006', 'LOT-2501-0008', 80, 'Điều chuyển cho phát thuốc OPD'),
('STOUTD_007', 'STOUT_003', 'PINV_0011', 'DRG_008', 'LOT-2501-0011', 70, 'Điều chuyển cho phát thuốc OPD'),
('STOUTD_008', 'STOUT_003', 'PINV_0013', 'DRG_010', 'LOT-2501-0013', 50, 'Điều chuyển cho phát thuốc OPD'),
-- STOUT_004 — DISPOSAL hư hỏng (1 dòng)
('STOUTD_009', 'STOUT_004', 'PINV_0015', 'DRG_011', 'LOT-2501-0015', 50, 'Vỡ chai do vận chuyển'),
-- STOUT_005 — TRANSFER sang WH_RESERVE (3 dòng)
('STOUTD_010', 'STOUT_005', 'PINV_0017', 'DRG_013', 'LOT-2501-0017', 100, 'Dự trữ Tết'),
('STOUTD_011', 'STOUT_005', 'PINV_0019', 'DRG_014', 'LOT-2501-0019', 100, 'Dự trữ Tết'),
('STOUTD_012', 'STOUT_005', 'PINV_0020', 'DRG_015', 'LOT-2501-0020', 100, 'Dự trữ Tết'),
-- STOUT_006 — RETURN_SUPPLIER trả Sanofi (2 dòng)
('STOUTD_013', 'STOUT_006', 'PINV_0021', 'DRG_016', 'LOT-2501-0021', 40, 'Bao bì hỏng - trả Sanofi'),
('STOUTD_014', 'STOUT_006', 'PINV_0023', 'DRG_017', 'LOT-2501-0023', 35, 'Bao bì hỏng - trả Sanofi'),
-- STOUT_007 — DRAFT đang soạn (2 dòng, chưa confirm nên quantity là dự kiến)
('STOUTD_015', 'STOUT_007', 'PINV_0025', 'DRG_019', 'LOT-2501-0025', 30, 'Dự kiến hủy - chưa duyệt'),
('STOUTD_016', 'STOUT_007', 'PINV_0027', 'DRG_020', 'LOT-2501-0027', 25, 'Dự kiến hủy - chưa duyệt'),
-- STOUT_008 — DRAFT chuyển kho (2 dòng)
('STOUTD_017', 'STOUT_008', 'PINV_0028', 'DRG_021', 'LOT-2501-0028', 60, 'Dự kiến chuyển - chưa duyệt'),
('STOUTD_018', 'STOUT_008', 'PINV_0029', 'DRG_022', 'LOT-2501-0029', 50, 'Dự kiến chuyển - chưa duyệt'),
-- STOUT_009 — CANCELLED (1 dòng giữ lại lịch sử)
('STOUTD_019', 'STOUT_009', 'PINV_0030', 'DRG_022', 'LOT-2506-0030', 20, 'Đã hủy - lập sai'),
-- STOUT_010 — CANCELLED (2 dòng)
('STOUTD_020', 'STOUT_010', 'PINV_0001', 'DRG_001', 'LOT-2501-0001', 30, 'Đã hủy - NCC từ chối'),
('STOUTD_021', 'STOUT_010', 'PINV_0003', 'DRG_002', 'LOT-2501-0003', 25, 'Đã hủy - NCC từ chối'),
-- Phụ thêm để đạt ~30 dòng tổng (CONFIRMED bổ sung)
('STOUTD_022', 'STOUT_001', 'PINV_0006', 'DRG_004', 'LOT-2506-0006', 100, 'Hết hạn 30/11/2025'),
('STOUTD_023', 'STOUT_003', 'PINV_0014', 'DRG_010', 'LOT-2506-0014', 60,  'Điều chuyển cho phát thuốc OPD'),
('STOUTD_024', 'STOUT_005', 'PINV_0022', 'DRG_016', 'LOT-2506-0022', 50,  'Dự trữ Tết'),
('STOUTD_025', 'STOUT_002', 'PINV_0009', 'DRG_007', 'LOT-2501-0009', 30,  'Nhãn mờ - trả CPC1'),
('STOUTD_026', 'STOUT_006', 'PINV_0024', 'DRG_018', 'LOT-2501-0024', 40,  'Bao bì hỏng - trả Sanofi'),
('STOUTD_027', 'STOUT_004', 'PINV_0010', 'DRG_007', 'LOT-2506-0010', 25,  'Vỏ ống tiêm gãy'),
('STOUTD_028', 'STOUT_001', 'PINV_0002', 'DRG_001', 'LOT-2506-0002', 50,  'Hết hạn 30/11/2025'),
('STOUTD_029', 'STOUT_007', 'PINV_0026', 'DRG_019', 'LOT-2506-0026', 20,  'Dự kiến hủy - chưa duyệt'),
('STOUTD_030', 'STOUT_008', 'PINV_0012', 'DRG_009', 'LOT-2501-0012', 40,  'Dự kiến chuyển - chưa duyệt')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- 7. MEDICATION_INSTRUCTION_TEMPLATES — 10 mẫu hướng dẫn bổ sung
--    (Khác với 41 mẫu đã có sẵn trong migration medication_instructions.sql)
--    Bao phủ thêm: dosage Pediatric, frequency theo bữa ăn, route mới,
--    instruction về tác dụng phụ
-- ---------------------------------------------------------------------
INSERT INTO medication_instruction_templates (
    template_id, type, label, value, sort_order, is_active
) VALUES
-- Dosage Pediatric / lượng đặc biệt
('MIT_DOS_101', 'DOSAGE',      '1/2 viên',            '1/2 viên',                                        13, TRUE),
('MIT_DOS_102', 'DOSAGE',      '1 muỗng cà phê (5ml)','1 muỗng cà phê (5ml)',                            14, TRUE),
-- Frequency bổ sung
('MIT_FRQ_101', 'FREQUENCY',   'Sáng - tối',          'Sáng và tối',                                     11, TRUE),
('MIT_FRQ_102', 'FREQUENCY',   '2 ngày 1 lần',        '2 ngày 1 lần',                                    12, TRUE),
-- Route bổ sung
('MIT_RTE_101', 'ROUTE',       'Hít qua máy khí dung','NEBULIZER',                                       11, TRUE),
('MIT_RTE_102', 'ROUTE',       'Bôi mắt',             'OPHTHALMIC_OINTMENT',                             12, TRUE),
-- Instruction tác dụng phụ / lưu ý
('MIT_INS_101', 'INSTRUCTION', 'Tránh lái xe',        'Tránh lái xe và vận hành máy móc trong 4-6 giờ',  11, TRUE),
('MIT_INS_102', 'INSTRUCTION', 'Không dùng cùng rượu','Không sử dụng đồ uống có cồn khi đang dùng thuốc',12, TRUE),
('MIT_INS_103', 'INSTRUCTION', 'Bảo quản tủ lạnh',    'Bảo quản 2-8°C, không đông đá',                   13, TRUE),
('MIT_INS_104', 'INSTRUCTION', 'Báo bác sĩ nếu phản ứng', 'Báo bác sĩ ngay nếu xuất hiện phát ban, khó thở, sưng phù', 14, TRUE)
ON CONFLICT DO NOTHING;

COMMIT;

-- =====================================================================
-- KẾT THÚC seed 15_pharmacy_warehouse.sql
-- Tổng số dòng được thêm (tối đa, nếu chưa tồn tại):
--   suppliers                          : 5
--   warehouses                         : 3
--   stock_in_orders                    : 30
--   stock_in_details                   : 90
--   stock_out_orders                   : 10
--   stock_out_details                  : 30
--   medication_instruction_templates   : 10
-- =====================================================================
