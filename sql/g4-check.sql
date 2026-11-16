-- G4 只读核对查询。
SELECT r.case_id, r.run_status, r.result_status, d.draft_id, d.expires_at, t.task_id
FROM public.agent_run r
LEFT JOIN public.review_draft d ON d.run_id = r.run_id
LEFT JOIN public.review_task t ON t.draft_id = d.draft_id
ORDER BY r.run_id;
