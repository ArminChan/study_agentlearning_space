-- G0 学习参考：PostgreSQL 17。仅在独立学习数据库执行。
-- 不删除已有表或数据；重复运行前自行检查现状。
BEGIN;
CREATE TABLE product (
    product_code varchar(32) PRIMARY KEY,
    product_name varchar(100) NOT NULL,
    synthetic boolean NOT NULL DEFAULT true CHECK (synthetic = true)
);
CREATE TABLE claim_case (
    case_id varchar(32) PRIMARY KEY CHECK (case_id ~ '^CASE-[0-9]{3}$'),
    owner_id varchar(32) NOT NULL,
    product_code varchar(32) NOT NULL REFERENCES product(product_code),
    rule_version varchar(16),
    scene varchar(32) NOT NULL DEFAULT 'OUTPATIENT' CHECK (scene = 'OUTPATIENT'),
    revision integer NOT NULL DEFAULT 1 CHECK (revision > 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_claim_case_owner ON claim_case(owner_id, case_id);
CREATE TABLE case_material (
    case_id varchar(32) NOT NULL REFERENCES claim_case(case_id),
    material_type varchar(16) NOT NULL CHECK (material_type IN ('MAT_A','MAT_B','MAT_C')),
    material_name varchar(100) NOT NULL,
    registered_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (case_id, material_type)
);
COMMIT;
