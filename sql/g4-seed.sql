-- G4 可选：为确认接口准备待确认、已过期、已确认、缺版本四种初始状态。
-- 一次性执行，重复 UUID 会使本次事务回滚。依赖 G0 合成案件和 G3 规则原文。
BEGIN;

DO $seed_reviews$
DECLARE
    base_time timestamptz := CURRENT_TIMESTAMP;
    rule_text text;
    pending_run constant uuid := 'a4000000-0000-4000-8000-000000000001';
    expired_run constant uuid := 'a4000000-0000-4000-8000-000000000002';
    committed_run constant uuid := 'a4000000-0000-4000-8000-000000000003';
    need_info_run constant uuid := 'a4000000-0000-4000-8000-000000000004';
    committed_draft constant uuid := 'd4000000-0000-4000-8000-000000000003';
    ready_result jsonb := '{
        "caseId": "CASE-001",
        "resultStatus": "READY_FOR_REVIEW",
        "requiredMaterials": ["MAT_A", "MAT_B"],
        "providedMaterials": ["MAT_A"],
        "missingMaterials": ["MAT_B"],
        "questions": [],
        "citations": [{"docId":"RULE-A-v1","version":"v1","chunkId":"A-V1-01"}],
        "explanation": "按虚构产品 A 的 v1 规则，目前缺材料乙。"
    }';
    draft_result jsonb;
    need_info_result jsonb := '{
        "caseId": "CASE-008",
        "resultStatus": "NEED_INFO",
        "requiredMaterials": [],
        "providedMaterials": ["MAT_A"],
        "missingMaterials": [],
        "questions": [{"field":"ruleVersion","message":"请确认适用规则版本"}],
        "citations": [],
        "explanation": "确认适用规则版本后才能核对材料。"
    }';
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.claim_case
        WHERE case_id = 'CASE-001' AND owner_id = 'demo-a' AND product_code = 'DEMO-A'
          AND rule_version = 'v1' AND revision = 1
    ) OR NOT EXISTS (
        SELECT 1 FROM public.claim_case
        WHERE case_id = 'CASE-008' AND owner_id = 'demo-a' AND product_code = 'DEMO-A'
          AND rule_version IS NULL AND revision = 1
    ) OR EXISTS (
        SELECT 1
        FROM (VALUES ('CASE-001'), ('CASE-008')) AS fixture(case_id)
        WHERE (
            SELECT array_agg(m.material_type::text ORDER BY m.material_type)
            FROM public.case_material m
            WHERE m.case_id = fixture.case_id
        ) IS DISTINCT FROM ARRAY['MAT_A']
    ) THEN
        RAISE EXCEPTION 'G4 样例依赖 G0 原始的 CASE-001 和 CASE-008，请在保留种子数据的学习库执行';
    END IF;

    SELECT content INTO STRICT rule_text
    FROM public.knowledge_document
    WHERE doc_id = 'RULE-A-v1' AND doc_type = 'RULE'
      AND product_code = 'DEMO-A' AND rule_version = 'v1' AND active;

    draft_result := ready_result || jsonb_build_object('evidenceSnapshot', jsonb_build_array(
        jsonb_build_object('docId', 'RULE-A-v1', 'version', 'v1', 'chunkId', 'A-V1-01', 'content', rule_text)
    ));

    INSERT INTO public.agent_run (
        run_id, case_id, owner_id, case_revision, question, run_status, result_status,
        result_json, deadline_at, created_at, updated_at
    ) VALUES
        (pending_run, 'CASE-001', 'demo-a', 1, '核对缺失材料', 'WAIT_CONFIRM', 'READY_FOR_REVIEW',
         ready_result, base_time + interval '30 seconds', base_time, base_time),
        (expired_run, 'CASE-001', 'demo-a', 1, '核对缺失材料', 'WAIT_CONFIRM', 'READY_FOR_REVIEW',
         ready_result, base_time - interval '25 hours' + interval '30 seconds',
         base_time - interval '25 hours', base_time - interval '25 hours'),
        (committed_run, 'CASE-001', 'demo-a', 1, '核对缺失材料', 'COMMITTED', 'READY_FOR_REVIEW',
         ready_result, base_time - interval '1 hour' + interval '30 seconds',
         base_time - interval '1 hour', base_time),
        (need_info_run, 'CASE-008', 'demo-a', 1, '核对缺失材料', 'NEED_INFO', 'NEED_INFO',
         need_info_result, base_time + interval '30 seconds', base_time, base_time);

    INSERT INTO public.review_draft (draft_id, run_id, case_revision, result_json, expires_at, created_at)
    VALUES
        ('d4000000-0000-4000-8000-000000000001', pending_run, 1, draft_result,
         base_time + interval '24 hours', base_time),
        ('d4000000-0000-4000-8000-000000000002', expired_run, 1, draft_result,
         base_time - interval '1 hour', base_time - interval '25 hours'),
        (committed_draft, committed_run, 1, draft_result,
         base_time + interval '23 hours', base_time - interval '1 hour');

    INSERT INTO public.review_task (task_id, draft_id, owner_id, idempotency_key)
    VALUES ('b4000000-0000-4000-8000-000000000003', committed_draft, 'demo-a', 'fixture-confirm-003');

    INSERT INTO public.run_event (event_id, run_id, event_type, payload)
    VALUES
        ('e4000000-0000-4000-8000-000000000001', pending_run, 'FIXTURE_LOADED', '{"runStatus":"WAIT_CONFIRM"}'),
        ('e4000000-0000-4000-8000-000000000002', expired_run, 'FIXTURE_LOADED', '{"runStatus":"WAIT_CONFIRM"}'),
        ('e4000000-0000-4000-8000-000000000003', committed_run, 'FIXTURE_LOADED', '{"runStatus":"COMMITTED"}'),
        ('e4000000-0000-4000-8000-000000000004', need_info_run, 'FIXTURE_LOADED', '{"runStatus":"NEED_INFO"}');
END
$seed_reviews$;

COMMIT;
