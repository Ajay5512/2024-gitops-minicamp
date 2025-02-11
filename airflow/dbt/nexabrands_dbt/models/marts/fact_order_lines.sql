
-- models/marts/fact_order_lines.sql
SELECT * FROM {{ ref('stg_order_lines') }}
