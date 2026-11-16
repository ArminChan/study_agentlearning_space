-- G3：Spring AI 2.0.2 PgVectorStore 的 public.vector_store。
-- 在查询窗口整份执行。若模型输出的维度不是 1024，先修改下方的 dimensions。
BEGIN;

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

DO $create_vector_store$
DECLARE
    dimensions constant integer := 1024;
BEGIN
    IF dimensions <= 0 THEN
        RAISE EXCEPTION 'dimensions 应为实际 Embedding 模型输出的正整数维度';
    END IF;

    EXECUTE format('
        CREATE TABLE public.vector_store (
            id uuid DEFAULT public.uuid_generate_v4() PRIMARY KEY,
            content text,
            metadata json,
            embedding public.vector(%s)
        )', dimensions);

    -- vector 类型的 HNSW 索引上限为 2000 维。维度更高时使用精确检索。
    IF dimensions <= 2000 THEN
        CREATE INDEX spring_ai_vector_index
            ON public.vector_store USING hnsw (embedding public.vector_cosine_ops);
    ELSE
        RAISE NOTICE '已建表，使用精确检索。Spring AI 的 index-type 请设为 NONE。';
    END IF;
END
$create_vector_store$;

COMMIT;
