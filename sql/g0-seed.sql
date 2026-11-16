-- 纯合成数据，仅供技术学习；不代表真实保险业务规则。
-- 只在完成g0-schema.sql的新学习库执行一次。重复执行会因主键冲突而回滚。
BEGIN;
INSERT INTO product(product_code, product_name) VALUES
('DEMO-A','虚构产品 A'),('DEMO-B','虚构产品 B');
INSERT INTO claim_case(case_id,owner_id,product_code,rule_version) VALUES
('CASE-001','demo-a','DEMO-A','v1'),
('CASE-002','demo-a','DEMO-A','v1'),
('CASE-003','demo-a','DEMO-A','v2'),
('CASE-004','demo-a','DEMO-B','v1'),
('CASE-005','demo-a','DEMO-B','v1'),
('CASE-006','demo-a','DEMO-A','v1'),
('CASE-007','demo-b','DEMO-A','v1'),
('CASE-008','demo-a','DEMO-A',NULL);
INSERT INTO case_material(case_id,material_type,material_name) VALUES
('CASE-001','MAT_A','材料甲'),
('CASE-002','MAT_A','材料甲'),('CASE-002','MAT_B','材料乙'),
('CASE-003','MAT_A','材料甲'),('CASE-003','MAT_B','材料乙'),
('CASE-004','MAT_A','材料甲'),
('CASE-005','MAT_A','材料甲'),('CASE-005','MAT_C','材料丙'),
('CASE-007','MAT_A','材料甲'),
('CASE-008','MAT_A','材料甲');
COMMIT;
