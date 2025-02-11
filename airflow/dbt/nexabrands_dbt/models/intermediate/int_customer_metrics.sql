-- models/intermediate/int_customer_metrics.sql
WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),
order_metrics AS (
    SELECT * FROM {{ ref('int_order_metrics') }}
),
customer_metrics AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id) as total_orders,
        -- Changed to use direct column values in AVG since they're already 0/1
        AVG(CASE WHEN om.on_time = 1 THEN 1 ELSE 0 END) * 100 as ontime_delivery_rate,
        AVG(CASE WHEN om.in_full = 1 THEN 1 ELSE 0 END) * 100 as infull_delivery_rate,
        AVG(CASE WHEN om.ontime_in_full = 1 THEN 1 ELSE 0 END) * 100 as otif_rate,
        SUM(om.fulfilled_lines) * 100.0 / NULLIF(SUM(om.total_lines), 0) as line_fill_rate,
        SUM(om.total_delivered_qty) * 100.0 / NULLIF(SUM(om.total_ordered_qty), 0) as volume_fill_rate
    FROM orders o
    JOIN order_metrics om ON o.order_id = om.order_id
    GROUP BY o.customer_id
)
SELECT * FROM customer_metrics