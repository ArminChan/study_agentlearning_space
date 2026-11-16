-- G3 只读核对查询。
SELECT doc_type, count(*) FROM public.knowledge_document GROUP BY doc_type ORDER BY doc_type;

SELECT format_type(atttypid, atttypmod) AS embedding_type
FROM pg_attribute
WHERE attrelid = 'public.vector_store'::regclass AND attname = 'embedding';
