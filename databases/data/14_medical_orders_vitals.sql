-- ========================================================================
-- 14_medical_orders_vitals.sql
-- ========================================================================
-- Demo data:
--   40 medical_orders          (chỉ định CLS: XN / CĐHA / Thủ thuật)
--   20 medical_order_results   (kết quả cho 20 order COMPLETED)
--   60 patient_health_metrics  (vital signs: BP / HR / Temp / SpO2 /
--                               Glucose / Weight / Height / Resp rate)
-- Idempotent: ON CONFLICT (PK) DO NOTHING.
-- Dependencies:
--   01_core_roles_users.sql            (USR_DOC_*, USR_NUR_*)
--   06_services.sql                    (SVC_XN_*, SVC_CDHA_*, SVC_TT_*)
--   07_patients.sql                    (PAT_001..PAT_045)
--   13_appointments_encounters.sql     (ENC_DEMO_001..ENC_DEMO_030)
-- Mapping encounter → patient (theo file 13):
--   ENC_001..010 ↔ PAT_016..025 (IN_PROGRESS hôm nay)
--   ENC_011..030 ↔ PAT_026..045 (COMPLETED day-1..day-20)
-- ordered_by FK → users(users_id): DOC_NN trong file 13 = USR_DOC_NN
-- ========================================================================

BEGIN;

-- ------------------------------------------------------------------------
-- 1. MEDICAL_ORDERS — 40 rows
-- ------------------------------------------------------------------------
-- Status mix: 20 COMPLETED (ENC_011..030) + 10 IN_PROGRESS (ENC_001..010)
--            + 5 PENDING + 5 CANCELLED.
-- Service mix: XN (CBC, sinh hoá, đường huyết, lipid, HbA1c, gan, thận...),
--              CĐHA (X-quang, siêu âm, CT, MRI), Thủ thuật (sinh thiết, nội soi).
-- ------------------------------------------------------------------------
INSERT INTO medical_orders (
    medical_orders_id, encounter_id, service_code, service_name,
    clinical_indicator, priority, status, ordered_by, ordered_at,
    order_type, service_id, notes
) VALUES
-- ===== 20 COMPLETED (ENC_DEMO_011..030) =====
('MO_DEMO_001','ENC_DEMO_011','XN-CTM','Xét nghiệm công thức máu (CBC)',
    'Bệnh nhân mệt mỏi, nghi thiếu máu','ROUTINE','COMPLETED','USR_DOC_06',NOW() - INTERVAL '1 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_01','Lấy máu lúc đói'),
('MO_DEMO_002','ENC_DEMO_011','XN-SINHH','Xét nghiệm sinh hoá máu 18 chỉ số',
    'Tầm soát chuyển hoá','ROUTINE','COMPLETED','USR_DOC_06',NOW() - INTERVAL '1 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_02','Nhịn đói 8 tiếng'),
('MO_DEMO_003','ENC_DEMO_012','XN-DUONG','Xét nghiệm đường huyết (Glucose)',
    'Nghi đái tháo đường type 2','ROUTINE','COMPLETED','USR_DOC_07',NOW() - INTERVAL '2 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_05','Glucose đói'),
('MO_DEMO_004','ENC_DEMO_012','XN-HBA1C','Xét nghiệm HbA1c',
    'Đánh giá kiểm soát ĐTĐ 3 tháng','ROUTINE','COMPLETED','USR_DOC_07',NOW() - INTERVAL '2 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_06','Theo dõi định kỳ'),
('MO_DEMO_005','ENC_DEMO_013','XN-LIPID','Xét nghiệm bộ mỡ máu (Lipid)',
    'Tăng huyết áp, tầm soát rối loạn lipid','ROUTINE','COMPLETED','USR_DOC_08',NOW() - INTERVAL '3 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_07','Nhịn đói 12 tiếng'),
('MO_DEMO_006','ENC_DEMO_013','CDHA-XQUANG-NGUC','X-quang ngực thẳng',
    'Ho kéo dài 2 tuần','ROUTINE','COMPLETED','USR_DOC_08',NOW() - INTERVAL '3 day' - INTERVAL '10 minute',
    'IMAGING','SVC_CDHA_01','Tư thế đứng PA'),
('MO_DEMO_007','ENC_DEMO_014','XN-CHUCN','Xét nghiệm chức năng gan',
    'Bệnh nhân uống rượu nhiều','URGENT','COMPLETED','USR_DOC_09',NOW() - INTERVAL '4 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_08','Theo dõi men gan'),
('MO_DEMO_008','ENC_DEMO_014','CDHA-SA-BUNG','Siêu âm bụng tổng quát',
    'Đau bụng vùng hạ sườn phải','URGENT','COMPLETED','USR_DOC_09',NOW() - INTERVAL '4 day' - INTERVAL '10 minute',
    'IMAGING','SVC_CDHA_03','Nhịn ăn trước 4h'),
('MO_DEMO_009','ENC_DEMO_015','XN-THAN','Xét nghiệm chức năng thận',
    'Tiền sử cao huyết áp 10 năm','ROUTINE','COMPLETED','USR_DOC_10',NOW() - INTERVAL '5 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_09','Tầm soát suy thận'),
('MO_DEMO_010','ENC_DEMO_015','XN-NUOC','Xét nghiệm tổng phân tích nước tiểu',
    'Theo dõi protein niệu','ROUTINE','COMPLETED','USR_DOC_10',NOW() - INTERVAL '5 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_03','Lấy giữa dòng'),
('MO_DEMO_011','ENC_DEMO_016','XN-TUYENG','Xét nghiệm chức năng tuyến giáp',
    'Bệnh nhân sụt cân, hồi hộp','ROUTINE','COMPLETED','USR_DOC_01',NOW() - INTERVAL '6 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_10','TSH, FT3, FT4'),
('MO_DEMO_012','ENC_DEMO_016','CDHA-SA-TUYEN','Siêu âm tuyến giáp',
    'Sờ thấy u tuyến giáp','ROUTINE','COMPLETED','USR_DOC_01',NOW() - INTERVAL '6 day' - INTERVAL '10 minute',
    'IMAGING','SVC_CDHA_07','Đánh giá nốt giáp'),
('MO_DEMO_013','ENC_DEMO_017','CDHA-SA-TIM','Siêu âm tim',
    'Khó thở khi gắng sức','URGENT','COMPLETED','USR_DOC_02',NOW() - INTERVAL '7 day' - INTERVAL '10 minute',
    'IMAGING','SVC_CDHA_06','Siêu âm Doppler tim'),
('MO_DEMO_014','ENC_DEMO_017','XN-CTM','Xét nghiệm công thức máu (CBC)',
    'Sốt 38.5°C 3 ngày','URGENT','COMPLETED','USR_DOC_02',NOW() - INTERVAL '7 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_01','Tìm nguyên nhân nhiễm trùng'),
('MO_DEMO_015','ENC_DEMO_018','XN-VGSB','Xét nghiệm viêm gan B (HBsAg)',
    'Khám sức khoẻ định kỳ','ROUTINE','COMPLETED','USR_DOC_03',NOW() - INTERVAL '8 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_11','Tầm soát'),
('MO_DEMO_016','ENC_DEMO_018','CDHA-CT-SO','CT Scanner sọ não',
    'Đau đầu kéo dài, chóng mặt','URGENT','COMPLETED','USR_DOC_03',NOW() - INTERVAL '8 day' - INTERVAL '10 minute',
    'IMAGING','SVC_CDHA_08','Không cản quang'),
('MO_DEMO_017','ENC_DEMO_019','CDHA-XQUANG-XUONG','X-quang xương khớp',
    'Đau khớp gối phải sau té ngã','URGENT','COMPLETED','USR_DOC_04',NOW() - INTERVAL '9 day' - INTERVAL '10 minute',
    'IMAGING','SVC_CDHA_02','Khớp gối P, 2 tư thế'),
('MO_DEMO_018','ENC_DEMO_019','XN-DONG','Xét nghiệm đông máu cơ bản',
    'Chuẩn bị tiền phẫu','URGENT','COMPLETED','USR_DOC_04',NOW() - INTERVAL '9 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_04','PT, APTT, INR'),
('MO_DEMO_019','ENC_DEMO_020','XN-PSA','Xét nghiệm PSA (tầm soát tiền liệt tuyến)',
    'Nam 55t, tiểu khó','ROUTINE','COMPLETED','USR_DOC_05',NOW() - INTERVAL '10 day' - INTERVAL '10 minute',
    'LAB_TEST','SVC_XN_13','Tầm soát U TLT'),
('MO_DEMO_020','ENC_DEMO_020','CDHA-SA-BUNG','Siêu âm bụng tổng quát',
    'Khám sức khoẻ định kỳ','ROUTINE','COMPLETED','USR_DOC_05',NOW() - INTERVAL '10 day' - INTERVAL '10 minute',
    'IMAGING','SVC_CDHA_03','Tổng quát ổ bụng'),
-- ===== 10 IN_PROGRESS (ENC_DEMO_001..010 — đang khám hôm nay) =====
('MO_DEMO_021','ENC_DEMO_001','XN-CTM','Xét nghiệm công thức máu (CBC)',
    'Mệt mỏi, da xanh xao','ROUTINE','IN_PROGRESS','USR_DOC_06',NOW() - INTERVAL '15 minute',
    'LAB_TEST','SVC_XN_01','Đang chờ kết quả'),
('MO_DEMO_022','ENC_DEMO_002','XN-DUONG','Xét nghiệm đường huyết (Glucose)',
    'Khát nhiều, tiểu nhiều','ROUTINE','IN_PROGRESS','USR_DOC_07',NOW() - INTERVAL '15 minute',
    'LAB_TEST','SVC_XN_05','Đang lấy mẫu'),
('MO_DEMO_023','ENC_DEMO_003','CDHA-XQUANG-NGUC','X-quang ngực thẳng',
    'Ho khan kéo dài 3 tuần','ROUTINE','IN_PROGRESS','USR_DOC_08',NOW() - INTERVAL '15 minute',
    'IMAGING','SVC_CDHA_01','Đã chuyển CĐHA'),
('MO_DEMO_024','ENC_DEMO_004','XN-LIPID','Xét nghiệm bộ mỡ máu (Lipid)',
    'BMI 28, gia đình có người tim mạch','ROUTINE','IN_PROGRESS','USR_DOC_09',NOW() - INTERVAL '15 minute',
    'LAB_TEST','SVC_XN_07','Chờ kết quả'),
('MO_DEMO_025','ENC_DEMO_005','CDHA-SA-BUNG','Siêu âm bụng tổng quát',
    'Đau bụng quanh rốn 2 ngày','URGENT','IN_PROGRESS','USR_DOC_10',NOW() - INTERVAL '15 minute',
    'IMAGING','SVC_CDHA_03','Ưu tiên'),
('MO_DEMO_026','ENC_DEMO_006','XN-CHUCN','Xét nghiệm chức năng gan',
    'Vàng da nhẹ','URGENT','IN_PROGRESS','USR_DOC_01',NOW() - INTERVAL '15 minute',
    'LAB_TEST','SVC_XN_08','Đang chạy mẫu'),
('MO_DEMO_027','ENC_DEMO_007','XN-NUOC','Xét nghiệm tổng phân tích nước tiểu',
    'Tiểu buốt 1 tuần','ROUTINE','IN_PROGRESS','USR_DOC_02',NOW() - INTERVAL '15 minute',
    'LAB_TEST','SVC_XN_03','Chờ nước tiểu giữa dòng'),
('MO_DEMO_028','ENC_DEMO_008','CDHA-SA-TIM','Siêu âm tim',
    'Hồi hộp, mệt khi gắng sức','URGENT','IN_PROGRESS','USR_DOC_03',NOW() - INTERVAL '15 minute',
    'IMAGING','SVC_CDHA_06','Đang siêu âm'),
('MO_DEMO_029','ENC_DEMO_009','XN-HBA1C','Xét nghiệm HbA1c',
    'Đường huyết đói 8.2 mmol/L','ROUTINE','IN_PROGRESS','USR_DOC_04',NOW() - INTERVAL '15 minute',
    'LAB_TEST','SVC_XN_06','Đánh giá ĐTĐ'),
('MO_DEMO_030','ENC_DEMO_010','CDHA-MRI-SO','MRI sọ não',
    'Đau đầu vùng chẩm, nghi u não','URGENT','IN_PROGRESS','USR_DOC_05',NOW() - INTERVAL '15 minute',
    'IMAGING','SVC_CDHA_10','Đang chụp'),
-- ===== 5 PENDING (mới chỉ định, chưa thực hiện) =====
('MO_DEMO_031','ENC_DEMO_021','XN-TUYENG','Xét nghiệm chức năng tuyến giáp',
    'Hẹn tái khám tuyến giáp','ROUTINE','PENDING','USR_DOC_06',NOW() - INTERVAL '11 day' - INTERVAL '5 minute',
    'LAB_TEST','SVC_XN_10','Bệnh nhân hẹn 7h sáng mai'),
('MO_DEMO_032','ENC_DEMO_022','CDHA-CT-BUNG','CT Scanner bụng',
    'Theo dõi u gan sau hoá trị','URGENT','PENDING','USR_DOC_07',NOW() - INTERVAL '12 day' - INTERVAL '5 minute',
    'IMAGING','SVC_CDHA_09','Đợi lịch CĐHA'),
('MO_DEMO_033','ENC_DEMO_023','XN-PAPSMEAR','Xét nghiệm Pap smear',
    'Tầm soát ung thư cổ tử cung định kỳ','ROUTINE','PENDING','USR_DOC_08',NOW() - INTERVAL '13 day' - INTERVAL '5 minute',
    'LAB_TEST','SVC_XN_14','Hẹn ngày sạch kinh'),
('MO_DEMO_034','ENC_DEMO_024','TT-NOISINH','Nội soi dạ dày',
    'Đau thượng vị, ợ chua kéo dài','ROUTINE','PENDING','USR_DOC_09',NOW() - INTERVAL '14 day' - INTERVAL '5 minute',
    'PROCEDURE','SVC_TT_07','Hẹn nội soi sáng thứ 3'),
('MO_DEMO_035','ENC_DEMO_025','TT-SINHTHIET','Sinh thiết',
    'U vú nghi ngờ ác tính','URGENT','PENDING','USR_DOC_10',NOW() - INTERVAL '15 day' - INTERVAL '5 minute',
    'PROCEDURE','SVC_TT_08','Sinh thiết dưới hướng dẫn siêu âm'),
-- ===== 5 CANCELLED =====
('MO_DEMO_036','ENC_DEMO_026','CDHA-SA-4D','Siêu âm thai 4D',
    'Thai 20 tuần đánh giá hình thái','ROUTINE','CANCELLED','USR_DOC_01',NOW() - INTERVAL '16 day' - INTERVAL '5 minute',
    'IMAGING','SVC_CDHA_05','Bệnh nhân huỷ lịch'),
('MO_DEMO_037','ENC_DEMO_027','XN-HIV','Xét nghiệm HIV (nhanh)',
    'Tự nguyện xét nghiệm','ROUTINE','CANCELLED','USR_DOC_02',NOW() - INTERVAL '17 day' - INTERVAL '5 minute',
    'LAB_TEST','SVC_XN_12','Bệnh nhân không đến'),
('MO_DEMO_038','ENC_DEMO_028','CDHA-XQUANG-NGUC','X-quang ngực thẳng',
    'Theo dõi viêm phổi đã điều trị','ROUTINE','CANCELLED','USR_DOC_03',NOW() - INTERVAL '18 day' - INTERVAL '5 minute',
    'IMAGING','SVC_CDHA_01','Triệu chứng đã hết, huỷ chỉ định'),
('MO_DEMO_039','ENC_DEMO_029','XN-COVID','Xét nghiệm RT-PCR SARS-CoV-2',
    'Tiền phẫu','ROUTINE','CANCELLED','USR_DOC_04',NOW() - INTERVAL '19 day' - INTERVAL '5 minute',
    'LAB_TEST','SVC_XN_15','Đã chuyển sang test nhanh'),
('MO_DEMO_040','ENC_DEMO_030','CDHA-MRI-SO','MRI sọ não',
    'Nghi tai biến thoáng qua','URGENT','CANCELLED','USR_DOC_05',NOW() - INTERVAL '20 day' - INTERVAL '5 minute',
    'IMAGING','SVC_CDHA_10','Máy MRI bảo trì, chuyển CT')
ON CONFLICT (medical_orders_id) DO NOTHING;


-- ------------------------------------------------------------------------
-- 2. MEDICAL_ORDER_RESULTS — 20 rows (cho 20 order COMPLETED MO_001..020)
-- ------------------------------------------------------------------------
-- performed_by FK → users(users_id): dùng USR_NUR_* (kỹ thuật viên / điều dưỡng)
-- result_details JSON: số liệu chi tiết theo từng loại CLS.
-- ------------------------------------------------------------------------
INSERT INTO medical_order_results (
    medical_order_results_id, order_id, result_summary, result_details,
    attachment_urls, performed_by, performed_at
) VALUES
('MOR_DEMO_001','MO_DEMO_001',
    'CBC: WBC 7.2 K/µL | RBC 4.8 M/µL | Hb 14.5 g/dL | PLT 250 K/µL — Bình thường',
    '{"WBC":7.2,"RBC":4.8,"Hb":14.5,"HCT":42.0,"PLT":250,"MCV":88,"interpretation":"NORMAL"}'::json,
    '["/files/cls/MOR_DEMO_001_CBC.pdf"]'::json,
    'USR_NUR_01', NOW() - INTERVAL '1 day' + INTERVAL '5 minute'),
('MOR_DEMO_002','MO_DEMO_002',
    'Sinh hoá 18 chỉ số: Glucose 5.2 | Cre 78 | GOT 28 | GPT 32 — Trong giới hạn bình thường',
    '{"Glucose":5.2,"Ure":4.5,"Creatinine":78,"GOT":28,"GPT":32,"Cholesterol":4.8,"Triglyceride":1.6,"interpretation":"NORMAL"}'::json,
    '["/files/cls/MOR_DEMO_002_SINHHOA.pdf"]'::json,
    'USR_NUR_02', NOW() - INTERVAL '1 day' + INTERVAL '10 minute'),
('MOR_DEMO_003','MO_DEMO_003',
    'Glucose máu đói: 8.7 mmol/L — Tăng (chẩn đoán ĐTĐ type 2)',
    '{"glucose_fasting":8.7,"unit":"mmol/L","ref_range":"3.9-5.6","interpretation":"HIGH","diagnosis_hint":"DM_T2"}'::json,
    '["/files/cls/MOR_DEMO_003_GLU.pdf"]'::json,
    'USR_NUR_03', NOW() - INTERVAL '2 day' + INTERVAL '5 minute'),
('MOR_DEMO_004','MO_DEMO_004',
    'HbA1c: 8.4% — Kiểm soát đường huyết KÉM',
    '{"HbA1c":8.4,"unit":"%","ref_range":"<6.5","interpretation":"POOR_CONTROL"}'::json,
    '["/files/cls/MOR_DEMO_004_HBA1C.pdf"]'::json,
    'USR_NUR_03', NOW() - INTERVAL '2 day' + INTERVAL '10 minute'),
('MOR_DEMO_005','MO_DEMO_005',
    'Lipid: Chol TP 6.2 | LDL 4.1 | HDL 1.0 | TG 2.4 — Rối loạn lipid máu',
    '{"Cholesterol_TP":6.2,"LDL_C":4.1,"HDL_C":1.0,"Triglyceride":2.4,"interpretation":"DYSLIPIDEMIA"}'::json,
    '["/files/cls/MOR_DEMO_005_LIPID.pdf"]'::json,
    'USR_NUR_04', NOW() - INTERVAL '3 day' + INTERVAL '5 minute'),
('MOR_DEMO_006','MO_DEMO_006',
    'X-quang ngực thẳng: Phổi 2 bên sáng, không tổn thương khu trú. Bóng tim không to. Bình thường.',
    '{"lung_field":"clear","cardiothoracic_ratio":0.48,"interpretation":"NORMAL"}'::json,
    '["/files/cls/MOR_DEMO_006_CXR.dcm","/files/cls/MOR_DEMO_006_CXR.jpg"]'::json,
    'USR_NUR_05', NOW() - INTERVAL '3 day' + INTERVAL '15 minute'),
('MOR_DEMO_007','MO_DEMO_007',
    'Chức năng gan: GOT 85 | GPT 102 | GGT 145 — Tăng men gan vừa',
    '{"GOT":85,"GPT":102,"GGT":145,"Bilirubin_TP":18,"Albumin":42,"interpretation":"ELEVATED_LIVER_ENZYMES"}'::json,
    '["/files/cls/MOR_DEMO_007_LFT.pdf"]'::json,
    'USR_NUR_06', NOW() - INTERVAL '4 day' + INTERVAL '5 minute'),
('MOR_DEMO_008','MO_DEMO_008',
    'Siêu âm bụng: Gan to nhẹ, nhu mô tăng âm — Nghi gan nhiễm mỡ độ 2. Túi mật, tụy, lách, thận bình thường.',
    '{"liver":"hepatomegaly_steatosis_grade_2","gallbladder":"normal","pancreas":"normal","spleen":"normal","kidneys":"normal"}'::json,
    '["/files/cls/MOR_DEMO_008_US.dcm"]'::json,
    'USR_NUR_06', NOW() - INTERVAL '4 day' + INTERVAL '20 minute'),
('MOR_DEMO_009','MO_DEMO_009',
    'Chức năng thận: Ure 6.8 | Cre 142 | eGFR 52 ml/ph — Suy thận mạn giai đoạn 3a',
    '{"Ure":6.8,"Creatinine":142,"eGFR":52,"Uric_acid":420,"interpretation":"CKD_STAGE_3A"}'::json,
    '["/files/cls/MOR_DEMO_009_RFT.pdf"]'::json,
    'USR_NUR_07', NOW() - INTERVAL '5 day' + INTERVAL '5 minute'),
('MOR_DEMO_010','MO_DEMO_010',
    'Tổng phân tích nước tiểu: Protein (++), Glucose (-), BC 5-10/HPF — Có đạm niệu',
    '{"protein":"++","glucose":"negative","leukocyte":"5-10/HPF","RBC":"negative","ketone":"negative","interpretation":"PROTEINURIA"}'::json,
    '["/files/cls/MOR_DEMO_010_UA.pdf"]'::json,
    'USR_NUR_07', NOW() - INTERVAL '5 day' + INTERVAL '10 minute'),
('MOR_DEMO_011','MO_DEMO_011',
    'Tuyến giáp: TSH 0.05 | FT3 8.2 | FT4 32 — Cường giáp',
    '{"TSH":0.05,"FT3":8.2,"FT4":32,"interpretation":"HYPERTHYROIDISM"}'::json,
    '["/files/cls/MOR_DEMO_011_THYROID.pdf"]'::json,
    'USR_NUR_08', NOW() - INTERVAL '6 day' + INTERVAL '5 minute'),
('MOR_DEMO_012','MO_DEMO_012',
    'Siêu âm tuyến giáp: Nốt giảm âm thuỳ phải 12x8mm, ranh giới rõ, TIRADS 3. Đề nghị FNA.',
    '{"right_lobe":{"nodule_size_mm":[12,8],"echogenicity":"hypoechoic","TIRADS":3},"left_lobe":"normal","recommendation":"FNA"}'::json,
    '["/files/cls/MOR_DEMO_012_THYROID_US.dcm"]'::json,
    'USR_NUR_08', NOW() - INTERVAL '6 day' + INTERVAL '20 minute'),
('MOR_DEMO_013','MO_DEMO_013',
    'Siêu âm tim: EF 55%, hở van 2 lá nhẹ (1/4), không huyết khối. Chức năng tim bảo tồn.',
    '{"EF":55,"mitral_regurgitation":"mild_1_of_4","aortic":"normal","LVID":48,"interpretation":"PRESERVED_FUNCTION"}'::json,
    '["/files/cls/MOR_DEMO_013_ECHO.dcm"]'::json,
    'USR_NUR_09', NOW() - INTERVAL '7 day' + INTERVAL '20 minute'),
('MOR_DEMO_014','MO_DEMO_014',
    'CBC: WBC 12.8 K/µL (Neutro 78%) — Tăng bạch cầu, nghi nhiễm khuẩn',
    '{"WBC":12.8,"Neutrophil_pct":78,"Lymphocyte_pct":18,"RBC":4.5,"Hb":13.8,"PLT":280,"interpretation":"NEUTROPHILIC_LEUKOCYTOSIS"}'::json,
    '["/files/cls/MOR_DEMO_014_CBC.pdf"]'::json,
    'USR_NUR_09', NOW() - INTERVAL '7 day' + INTERVAL '5 minute'),
('MOR_DEMO_015','MO_DEMO_015',
    'HBsAg: Âm tính. Không nhiễm viêm gan B.',
    '{"HBsAg":"negative","interpretation":"NOT_INFECTED"}'::json,
    '["/files/cls/MOR_DEMO_015_HBSAG.pdf"]'::json,
    'USR_NUR_10', NOW() - INTERVAL '8 day' + INTERVAL '5 minute'),
('MOR_DEMO_016','MO_DEMO_016',
    'CT sọ não: Không thấy tổn thương xuất huyết hay nhồi máu. Não thất, bể đáy bình thường.',
    '{"hemorrhage":"none","infarct":"none","ventricles":"normal","midline_shift":"none","interpretation":"NORMAL"}'::json,
    '["/files/cls/MOR_DEMO_016_CT.dcm"]'::json,
    'USR_NUR_10', NOW() - INTERVAL '8 day' + INTERVAL '25 minute'),
('MOR_DEMO_017','MO_DEMO_017',
    'X-quang khớp gối P 2 tư thế: Tràn dịch khớp gối, không gãy xương. Hẹp khe khớp nhẹ.',
    '{"fracture":"none","effusion":"present","joint_space":"mild_narrowing","interpretation":"KNEE_EFFUSION_OA_GRADE_1"}'::json,
    '["/files/cls/MOR_DEMO_017_XR.dcm"]'::json,
    'USR_NUR_01', NOW() - INTERVAL '9 day' + INTERVAL '15 minute'),
('MOR_DEMO_018','MO_DEMO_018',
    'Đông máu cơ bản: PT 12s | APTT 32s | INR 1.0 | Fib 3.2 g/L — Bình thường, sẵn sàng tiền phẫu',
    '{"PT":12,"APTT":32,"INR":1.0,"Fibrinogen":3.2,"interpretation":"NORMAL_PRE_OP"}'::json,
    '["/files/cls/MOR_DEMO_018_COAG.pdf"]'::json,
    'USR_NUR_02', NOW() - INTERVAL '9 day' + INTERVAL '5 minute'),
('MOR_DEMO_019','MO_DEMO_019',
    'PSA toàn phần: 4.8 ng/mL — Tăng nhẹ, đề nghị theo dõi 3 tháng',
    '{"PSA_total":4.8,"unit":"ng/mL","ref_range":"<4.0","interpretation":"SLIGHTLY_ELEVATED","recommendation":"FOLLOW_UP_3_MONTHS"}'::json,
    '["/files/cls/MOR_DEMO_019_PSA.pdf"]'::json,
    'USR_NUR_03', NOW() - INTERVAL '10 day' + INTERVAL '5 minute'),
('MOR_DEMO_020','MO_DEMO_020',
    'Siêu âm bụng: Gan, mật, tụy, lách, thận, tiền liệt tuyến bình thường. Không phát hiện bất thường.',
    '{"liver":"normal","gallbladder":"normal","pancreas":"normal","spleen":"normal","kidneys":"normal","prostate":"normal","interpretation":"NORMAL"}'::json,
    '["/files/cls/MOR_DEMO_020_US.dcm"]'::json,
    'USR_NUR_04', NOW() - INTERVAL '10 day' + INTERVAL '20 minute')
ON CONFLICT (medical_order_results_id) DO NOTHING;


-- ------------------------------------------------------------------------
-- 3. PATIENT_HEALTH_METRICS — 60 rows
-- ------------------------------------------------------------------------
-- 20 bệnh nhân (PAT_016..PAT_035) × 3 chỉ số trung bình mỗi người.
-- metric_code: BLOOD_PRESSURE, HEART_RATE, TEMPERATURE, SPO2, GLUCOSE,
--              WEIGHT, HEIGHT, RESP_RATE.
-- metric_value là JSON (cho phép cấu trúc phức tạp như BP systolic/diastolic).
-- source_type: CLINIC (đo tại CSYT), SELF_REPORTED (tự đo tại nhà), DEVICE (thiết bị IoT).
-- ------------------------------------------------------------------------
INSERT INTO patient_health_metrics (
    patient_health_metrics_id, patient_id, metric_code, metric_name,
    metric_value, unit, measured_at, source_type, device_info
) VALUES
-- ===== PAT_016 (ENC_001 IN_PROGRESS hôm nay) =====
('PHM_DEMO_001','PAT_016','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":120,"diastolic":80}'::json,'mmHg',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_002','PAT_016','HEART_RATE','Nhịp tim',
    '{"value":78}'::json,'bpm',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_003','PAT_016','TEMPERATURE','Nhiệt độ',
    '{"value":36.7}'::json,'°C',NOW() - INTERVAL '15 minute','CLINIC','Microlife MT-200'),
-- ===== PAT_017 =====
('PHM_DEMO_004','PAT_017','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":135,"diastolic":88}'::json,'mmHg',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_005','PAT_017','HEART_RATE','Nhịp tim',
    '{"value":82}'::json,'bpm',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_006','PAT_017','SPO2','Độ bão hoà oxy',
    '{"value":98}'::json,'%',NOW() - INTERVAL '15 minute','CLINIC','Beurer PO 30'),
-- ===== PAT_018 =====
('PHM_DEMO_007','PAT_018','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":118,"diastolic":76}'::json,'mmHg',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_008','PAT_018','TEMPERATURE','Nhiệt độ',
    '{"value":37.8}'::json,'°C',NOW() - INTERVAL '15 minute','CLINIC','Microlife MT-200'),
('PHM_DEMO_009','PAT_018','RESP_RATE','Nhịp thở',
    '{"value":20}'::json,'lần/phút',NOW() - INTERVAL '15 minute','CLINIC',NULL),
-- ===== PAT_019 =====
('PHM_DEMO_010','PAT_019','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":140,"diastolic":92}'::json,'mmHg',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_011','PAT_019','HEART_RATE','Nhịp tim',
    '{"value":95}'::json,'bpm',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_012','PAT_019','GLUCOSE','Đường huyết',
    '{"value":7.5}'::json,'mmol/L',NOW() - INTERVAL '15 minute','CLINIC','Accu-Chek Active'),
-- ===== PAT_020 =====
('PHM_DEMO_013','PAT_020','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":125,"diastolic":82}'::json,'mmHg',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_014','PAT_020','SPO2','Độ bão hoà oxy',
    '{"value":96}'::json,'%',NOW() - INTERVAL '15 minute','CLINIC','Beurer PO 30'),
('PHM_DEMO_015','PAT_020','WEIGHT','Cân nặng',
    '{"value":68.5}'::json,'kg',NOW() - INTERVAL '15 minute','CLINIC','Tanita HD-380'),
-- ===== PAT_021 =====
('PHM_DEMO_016','PAT_021','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":110,"diastolic":70}'::json,'mmHg',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_017','PAT_021','HEART_RATE','Nhịp tim',
    '{"value":65}'::json,'bpm',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_018','PAT_021','HEIGHT','Chiều cao',
    '{"value":165}'::json,'cm',NOW() - INTERVAL '15 minute','CLINIC',NULL),
-- ===== PAT_022 =====
('PHM_DEMO_019','PAT_022','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":132,"diastolic":85}'::json,'mmHg',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_020','PAT_022','TEMPERATURE','Nhiệt độ',
    '{"value":36.9}'::json,'°C',NOW() - INTERVAL '15 minute','CLINIC','Microlife MT-200'),
('PHM_DEMO_021','PAT_022','GLUCOSE','Đường huyết',
    '{"value":4.8}'::json,'mmol/L',NOW() - INTERVAL '15 minute','CLINIC','Accu-Chek Active'),
-- ===== PAT_023 =====
('PHM_DEMO_022','PAT_023','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":128,"diastolic":80}'::json,'mmHg',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_023','PAT_023','HEART_RATE','Nhịp tim',
    '{"value":72}'::json,'bpm',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_024','PAT_023','SPO2','Độ bão hoà oxy',
    '{"value":99}'::json,'%',NOW() - INTERVAL '15 minute','CLINIC','Beurer PO 30'),
-- ===== PAT_024 =====
('PHM_DEMO_025','PAT_024','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":115,"diastolic":75}'::json,'mmHg',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_026','PAT_024','WEIGHT','Cân nặng',
    '{"value":55.0}'::json,'kg',NOW() - INTERVAL '15 minute','CLINIC','Tanita HD-380'),
('PHM_DEMO_027','PAT_024','HEIGHT','Chiều cao',
    '{"value":158}'::json,'cm',NOW() - INTERVAL '15 minute','CLINIC',NULL),
-- ===== PAT_025 =====
('PHM_DEMO_028','PAT_025','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":138,"diastolic":90}'::json,'mmHg',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_029','PAT_025','HEART_RATE','Nhịp tim',
    '{"value":88}'::json,'bpm',NOW() - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_030','PAT_025','GLUCOSE','Đường huyết',
    '{"value":6.8}'::json,'mmol/L',NOW() - INTERVAL '15 minute','CLINIC','Accu-Chek Active'),

-- ===== Tự đo tại nhà (SELF_REPORTED) — bệnh nhân mạn tính theo dõi =====
('PHM_DEMO_031','PAT_026','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":142,"diastolic":94}'::json,'mmHg',NOW() - INTERVAL '1 day','SELF_REPORTED','Omron tại nhà'),
('PHM_DEMO_032','PAT_026','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":138,"diastolic":90}'::json,'mmHg',NOW() - INTERVAL '3 day','SELF_REPORTED','Omron tại nhà'),
('PHM_DEMO_033','PAT_026','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":135,"diastolic":88}'::json,'mmHg',NOW() - INTERVAL '7 day','SELF_REPORTED','Omron tại nhà'),
('PHM_DEMO_034','PAT_027','GLUCOSE','Đường huyết',
    '{"value":7.2,"time_of_day":"fasting"}'::json,'mmol/L',NOW() - INTERVAL '1 day','SELF_REPORTED','Accu-Chek Performa'),
('PHM_DEMO_035','PAT_027','GLUCOSE','Đường huyết',
    '{"value":9.5,"time_of_day":"post_meal"}'::json,'mmol/L',NOW() - INTERVAL '1 day' - INTERVAL '2 hour','SELF_REPORTED','Accu-Chek Performa'),
('PHM_DEMO_036','PAT_027','GLUCOSE','Đường huyết',
    '{"value":6.8,"time_of_day":"fasting"}'::json,'mmol/L',NOW() - INTERVAL '3 day','SELF_REPORTED','Accu-Chek Performa'),
('PHM_DEMO_037','PAT_028','WEIGHT','Cân nặng',
    '{"value":72.3}'::json,'kg',NOW() - INTERVAL '2 day','SELF_REPORTED','Cân điện tử Tanita'),
('PHM_DEMO_038','PAT_028','WEIGHT','Cân nặng',
    '{"value":71.8}'::json,'kg',NOW() - INTERVAL '9 day','SELF_REPORTED','Cân điện tử Tanita'),
('PHM_DEMO_039','PAT_029','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":125,"diastolic":82}'::json,'mmHg',NOW() - INTERVAL '4 day','SELF_REPORTED','Omron tại nhà'),
('PHM_DEMO_040','PAT_029','HEART_RATE','Nhịp tim',
    '{"value":74}'::json,'bpm',NOW() - INTERVAL '4 day','SELF_REPORTED','Omron tại nhà'),

-- ===== Thiết bị đeo (DEVICE / IoT) =====
('PHM_DEMO_041','PAT_030','HEART_RATE','Nhịp tim',
    '{"value":68,"context":"resting"}'::json,'bpm',NOW() - INTERVAL '5 day','DEVICE','Apple Watch Series 9'),
('PHM_DEMO_042','PAT_030','HEART_RATE','Nhịp tim',
    '{"value":125,"context":"exercise"}'::json,'bpm',NOW() - INTERVAL '5 day' - INTERVAL '4 hour','DEVICE','Apple Watch Series 9'),
('PHM_DEMO_043','PAT_030','SPO2','Độ bão hoà oxy',
    '{"value":97}'::json,'%',NOW() - INTERVAL '5 day','DEVICE','Apple Watch Series 9'),
('PHM_DEMO_044','PAT_031','HEART_RATE','Nhịp tim',
    '{"value":71,"context":"resting"}'::json,'bpm',NOW() - INTERVAL '6 day','DEVICE','Garmin Venu 3'),
('PHM_DEMO_045','PAT_031','SPO2','Độ bão hoà oxy',
    '{"value":96}'::json,'%',NOW() - INTERVAL '6 day','DEVICE','Garmin Venu 3'),
('PHM_DEMO_046','PAT_032','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":122,"diastolic":78}'::json,'mmHg',NOW() - INTERVAL '7 day','DEVICE','Omron HeartGuide'),
('PHM_DEMO_047','PAT_032','HEART_RATE','Nhịp tim',
    '{"value":76,"context":"resting"}'::json,'bpm',NOW() - INTERVAL '7 day','DEVICE','Omron HeartGuide'),

-- ===== Các đo CLINIC bổ sung cho ENC COMPLETED (PAT_033..PAT_045) =====
('PHM_DEMO_048','PAT_033','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":130,"diastolic":85}'::json,'mmHg',NOW() - INTERVAL '8 day' - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_049','PAT_033','TEMPERATURE','Nhiệt độ',
    '{"value":37.2}'::json,'°C',NOW() - INTERVAL '8 day' - INTERVAL '15 minute','CLINIC','Microlife MT-200'),
('PHM_DEMO_050','PAT_034','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":118,"diastolic":74}'::json,'mmHg',NOW() - INTERVAL '9 day' - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_051','PAT_034','HEART_RATE','Nhịp tim',
    '{"value":80}'::json,'bpm',NOW() - INTERVAL '9 day' - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_052','PAT_035','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":145,"diastolic":95}'::json,'mmHg',NOW() - INTERVAL '10 day' - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_053','PAT_035','GLUCOSE','Đường huyết',
    '{"value":5.5}'::json,'mmol/L',NOW() - INTERVAL '10 day' - INTERVAL '15 minute','CLINIC','Accu-Chek Active'),
('PHM_DEMO_054','PAT_036','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":112,"diastolic":72}'::json,'mmHg',NOW() - INTERVAL '11 day' - INTERVAL '15 minute','CLINIC','Omron HEM-7156'),
('PHM_DEMO_055','PAT_037','TEMPERATURE','Nhiệt độ',
    '{"value":36.5}'::json,'°C',NOW() - INTERVAL '12 day' - INTERVAL '15 minute','CLINIC','Microlife MT-200'),
('PHM_DEMO_056','PAT_038','WEIGHT','Cân nặng',
    '{"value":85.2}'::json,'kg',NOW() - INTERVAL '13 day' - INTERVAL '15 minute','CLINIC','Tanita HD-380'),
('PHM_DEMO_057','PAT_039','HEIGHT','Chiều cao',
    '{"value":172}'::json,'cm',NOW() - INTERVAL '14 day' - INTERVAL '15 minute','CLINIC',NULL),
('PHM_DEMO_058','PAT_040','SPO2','Độ bão hoà oxy',
    '{"value":94}'::json,'%',NOW() - INTERVAL '15 day' - INTERVAL '15 minute','CLINIC','Beurer PO 30'),
('PHM_DEMO_059','PAT_041','RESP_RATE','Nhịp thở',
    '{"value":18}'::json,'lần/phút',NOW() - INTERVAL '16 day' - INTERVAL '15 minute','CLINIC',NULL),
('PHM_DEMO_060','PAT_045','BLOOD_PRESSURE','Huyết áp',
    '{"systolic":128,"diastolic":82}'::json,'mmHg',NOW() - INTERVAL '20 day' - INTERVAL '15 minute','CLINIC','Omron HEM-7156')
ON CONFLICT (patient_health_metrics_id) DO NOTHING;

COMMIT;

-- ========================================================================
-- VERIFICATION (chạy thủ công sau khi seed):
--   SELECT COUNT(*) FROM medical_orders         WHERE medical_orders_id        LIKE 'MO_DEMO_%';   -- 40
--   SELECT COUNT(*) FROM medical_order_results  WHERE medical_order_results_id LIKE 'MOR_DEMO_%';  -- 20
--   SELECT COUNT(*) FROM patient_health_metrics WHERE patient_health_metrics_id LIKE 'PHM_DEMO_%'; -- 60
-- ========================================================================
