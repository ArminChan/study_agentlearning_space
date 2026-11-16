-- G4：核对运行、不可变草稿、确认待办和脱敏事件。前置：G0 案件表已建立。
BEGIN;

CREATE TABLE public.agent_run (
    run_id uuid PRIMARY KEY,
    case_id varchar(32) NOT NULL REFERENCES public.claim_case(case_id),
    owner_id varchar(32) NOT NULL,
    case_revision integer NOT NULL CHECK (case_revision > 0),
    question text NOT NULL,
    run_status varchar(24) NOT NULL CHECK (run_status IN (
        'RECEIVED', 'COLLECTING', 'WAIT_CONFIRM', 'COMMITTED', 'NEED_INFO', 'NO_EVIDENCE', 'FAILED'
    )),
    result_status varchar(24) CHECK (result_status IN ('READY_FOR_REVIEW', 'NEED_INFO', 'NO_EVIDENCE')),
    -- 供 GET /api/reviews/{runId} 恢复核对结果，包括没有草稿的分支。
    result_json jsonb CHECK (jsonb_typeof(result_json) = 'object'),
    tool_count integer NOT NULL DEFAULT 0 CHECK (tool_count >= 0),
    deadline_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_agent_run_owner ON public.agent_run (owner_id, run_id);

CREATE TABLE public.review_draft (
    draft_id uuid PRIMARY KEY,
    run_id uuid NOT NULL UNIQUE REFERENCES public.agent_run(run_id),
    draft_version integer NOT NULL DEFAULT 1 CHECK (draft_version > 0),
    case_revision integer NOT NULL CHECK (case_revision > 0),
    result_json jsonb NOT NULL CHECK (jsonb_typeof(result_json) = 'object'),
    expires_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.review_task (
    task_id uuid PRIMARY KEY,
    draft_id uuid NOT NULL UNIQUE REFERENCES public.review_draft(draft_id),
    owner_id varchar(32) NOT NULL,
    idempotency_key varchar(64) NOT NULL CHECK (length(btrim(idempotency_key)) > 0),
    status varchar(16) NOT NULL DEFAULT 'OPEN' CHECK (status = 'OPEN'),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (owner_id, idempotency_key)
);

CREATE TABLE public.run_event (
    event_id uuid PRIMARY KEY,
    run_id uuid NOT NULL REFERENCES public.agent_run(run_id),
    event_type varchar(32) NOT NULL,
    payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_run_event_timeline ON public.run_event (run_id, created_at, event_id);

COMMIT;
