-- G3：导入合成文档原文，可重复执行。同 ID 的已有文档由后续更新流程维护。
-- chunkId 作为入向量库时的元数据，见各行注释与《合成数据与验收样例》。
BEGIN;

WITH fixture(doc_id, product_code, rule_version, doc_type, title, content) AS (
    VALUES
        -- A-V1-01
        ('RULE-A-v1', 'DEMO-A', 'v1', 'RULE', '虚构产品 A v1 门诊材料',
         '仅供技术演示：虚构产品A的v1门诊材料核对需要材料甲（MAT_A）和材料乙（MAT_B）。'),
        -- A-V2-01
        ('RULE-A-v2', 'DEMO-A', 'v2', 'RULE', '虚构产品 A v2 门诊材料',
         '仅供技术演示：虚构产品A的v2门诊材料核对需要材料甲（MAT_A）、材料乙（MAT_B）和材料丙（MAT_C）。'),
        -- B-V1-01
        ('RULE-B-v1', 'DEMO-B', 'v1', 'RULE', '虚构产品 B v1 门诊材料',
         '仅供技术演示：虚构产品B的v1门诊材料核对需要材料甲（MAT_A）和材料丙（MAT_C）。'),
        -- FAQ-A-01
        ('FAQ-A-v1', 'DEMO-A', 'v1', 'FAQ', '材料登记说明',
         '仅供技术演示：材料登记不代表文件已被核验，也不代表可以赔付。'),
        -- FAQ-B-01
        ('FAQ-B-v1', 'DEMO-B', 'v1', 'FAQ', '赔付范围说明',
         '仅供技术演示：本助手只能整理材料清单，不能作出真实赔付结论。'),
        -- OTHER-01
        ('OTHER-001', NULL, NULL, 'OTHER', '演示系统维护说明',
         '仅供技术演示：系统维护时请联系演示管理员。本条没有产品材料要求。')
)
INSERT INTO public.knowledge_document (
    doc_id, product_code, rule_version, doc_type, title, content, content_hash
)
SELECT doc_id, product_code, rule_version, doc_type, title, content,
       encode(sha256(convert_to(content, 'UTF8')), 'hex')
FROM fixture
ON CONFLICT (doc_id) DO NOTHING;

COMMIT;
