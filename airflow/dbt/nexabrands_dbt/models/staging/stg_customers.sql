
-- models/staging/stg_customers.sql
WITH source AS (
    SELECT * FROM {{ source('raw', 'customers') }}
),
staged AS (
    SELECT
        customer_id,
        customer_name,
        city
    FROM source
)
SELECT * FROM staged
