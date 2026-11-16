-- G3：知识库文档清单。前置：G0 的 public.product 已建表。
BEGIN;

CREATE TABLE public.knowledge_document (
    doc_id varchar(64) PRIMARY KEY,
    product_code varchar(32) REFERENCES public.product(product_code),
    rule_version varchar(16),
    doc_type varchar(16) NOT NULL CHECK (doc_type IN ('RULE', 'FAQ', 'OTHER')),
    title varchar(150) NOT NULL,
    content text NOT NULL,
    content_hash char(64) NOT NULL CHECK (content_hash ~ '^[0-9a-f]{64}$'),
    synthetic boolean NOT NULL DEFAULT true CHECK (synthetic),
    active boolean NOT NULL DEFAULT true,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (doc_type <> 'RULE' OR (product_code IS NOT NULL AND rule_version IS NOT NULL))
);

COMMIT;
