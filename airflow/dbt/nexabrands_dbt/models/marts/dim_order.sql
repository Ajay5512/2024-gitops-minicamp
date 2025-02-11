
-- models/marts/dim_order.sql
SELECT * FROM {{ ref('stg_orders') }}
