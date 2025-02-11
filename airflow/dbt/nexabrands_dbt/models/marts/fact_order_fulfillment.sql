-- models/marts/fact_order_fulfillment.sql
WITH order_metrics AS (
    SELECT * FROM {{ ref('int_order_metrics') }}
),
orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),
order_lines AS (
    SELECT * FROM {{ ref('stg_order_lines') }}
),
final AS (
    SELECT
        -- Keys for joining to other dimensions
        f.order_id,
        o.customer_id,
        ol.product_id,
        
        -- Join to date dimension for each relevant date
        placement_date.date_key as order_placement_date_key,
        placement_date.year as order_year,
        placement_date.month_name as order_month,
        placement_date.quarter_year as order_quarter,
        
        agreed_date.date_key as agreed_delivery_date_key,
        agreed_date.year as agreed_delivery_year,
        agreed_date.month_name as agreed_delivery_month,
        
        actual_date.date_key as actual_delivery_date_key,
        actual_date.year as actual_delivery_year,
        actual_date.month_name as actual_delivery_month,
        
        -- Metrics
        f.total_lines,
        f.total_ordered_qty,
        f.total_delivered_qty,
        f.fulfilled_lines,
        f.line_fill_rate,
        f.volume_fill_rate,
        f.on_time,
        f.in_full,
        f.ontime_in_full
        
    FROM order_metrics f
    JOIN orders o 
        ON f.order_id = o.order_id
    JOIN order_lines ol 
        ON f.order_id = ol.order_id
    -- Join to date dimension for each type of date
    LEFT JOIN {{ ref('dim_date') }} placement_date 
        ON o.order_placement_date = placement_date.date
    LEFT JOIN {{ ref('dim_date') }} agreed_date 
        ON ol.agreed_delivery_date = agreed_date.date
    LEFT JOIN {{ ref('dim_date') }} actual_date 
        ON ol.actual_delivery_date = actual_date.date
)
SELECT * FROM final