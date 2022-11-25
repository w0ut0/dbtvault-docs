WITH source_data AS (
    SELECT
    "O_ORDERKEY",
    "O_CUSTKEY",
    "O_ORDERSTATUS",
    "O_TOTALPRICE",
    "O_ORDERDATE",
    "O_ORDERPRIORITY",
    "O_CLERK",
    "O_SHIPPRIORITY",
    "O_COMMENT"
    FROM "DBTVAULT_DEV"."TEST"."ORDERS"
),
derived_columns AS (
    SELECT
    "O_ORDERKEY",
    "O_CUSTKEY",
    "O_ORDERSTATUS",
    "O_TOTALPRICE",
    "O_ORDERDATE",
    "O_ORDERPRIORITY",
    "O_CLERK",
    "O_SHIPPRIORITY",
    "O_COMMENT",
    O_CUSTKEY AS "CUSTOMER_ID",
    '1998-01-01' AS "LOAD_DATETIME",
    'TPCH_ORDERS' AS "RECORD_SOURCE"
    FROM source_data
),
hashed_columns AS (
    SELECT
    "O_ORDERKEY",
    "O_CUSTKEY",
    "O_ORDERSTATUS",
    "O_TOTALPRICE",
    "O_ORDERDATE",
    "O_ORDERPRIORITY",
    "O_CLERK",
    "O_SHIPPRIORITY",
    "O_COMMENT",
    "CUSTOMER_ID",
    "LOAD_DATETIME",
    "RECORD_SOURCE",
    CAST(HASHBYTES('MD5', NULLIF(UPPER(TRIM(CAST("O_CUSTKEY" AS VARCHAR(max)))), '')) AS BINARY(16)) AS "CUSTOMER_HK"
    FROM derived_columns
),
columns_to_select AS (
    SELECT
    "O_ORDERKEY",
    "O_CUSTKEY",
    "O_ORDERSTATUS",
    "O_TOTALPRICE",
    "O_ORDERDATE",
    "O_ORDERPRIORITY",
    "O_CLERK",
    "O_SHIPPRIORITY",
    "O_COMMENT",
    "CUSTOMER_ID",
    "LOAD_DATETIME",
    "RECORD_SOURCE",
    "CUSTOMER_HK"
    FROM hashed_columns
)
SELECT * FROM columns_to_select