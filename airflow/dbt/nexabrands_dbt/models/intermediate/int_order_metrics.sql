WITH order_lines AS (
    SELECT * FROM {{ ref('stg_order_lines') }}
),
orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),
date_dim AS (
    SELECT * FROM {{ ref('dim_date') }}
),
order_metrics AS (
    SELECT
        ol.order_id,
        -- Keep existing metrics
        COUNT(DISTINCT ol.product_id) as total_lines,
        SUM(ol.order_qty) as total_ordered_qty,
        SUM(ol.delivery_qty) as total_delivered_qty,
        SUM(CASE WHEN ol.delivery_qty >= ol.order_qty THEN 1 ELSE 0 END) as fulfilled_lines,
        
        -- Line and volume fill rates
        SUM(CASE WHEN ol.delivery_qty >= ol.order_qty THEN 1 ELSE 0 END) * 100.0 / 
            NULLIF(COUNT(DISTINCT ol.product_id), 0) as line_fill_rate,
        SUM(ol.delivery_qty) * 100.0 / NULLIF(SUM(ol.order_qty), 0) as volume_fill_rate,
        
        -- Time-based calculations
        MAX(ol.agreed_delivery_date) as promised_delivery_date,
        MAX(ol.actual_delivery_date) as actual_delivery_date,
        
        -- Calculate delivery delay in days using PostgreSQL date subtraction
        (MAX(ol.actual_delivery_date) - MAX(ol.agreed_delivery_date)) as delivery_delay_days,
        
        -- On-time calculation with more detail
        CASE 
            WHEN MAX(ol.actual_delivery_date) <= MAX(ol.agreed_delivery_date) THEN 1 
            ELSE 0 
        END as on_time,
        
        -- In-full calculation
        CASE 
            WHEN SUM(CASE WHEN ol.delivery_qty >= ol.order_qty THEN 1 ELSE 0 END) = COUNT(*) 
            THEN 1 
            ELSE 0 
        END as in_full,
        
        -- OTIF calculation
        CASE 
            WHEN MAX(ol.actual_delivery_date) <= MAX(ol.agreed_delivery_date) 
             AND SUM(CASE WHEN ol.delivery_qty >= ol.order_qty THEN 1 ELSE 0 END) = COUNT(*) 
            THEN 1 
            ELSE 0 
        END as ontime_in_full,
        
        -- Add time period references
        o.order_placement_date,
        d.year as order_year,
        d.quarter as order_quarter,
        d.month_number as order_month,
        d.week_number as order_week,
        
        -- Add lead time calculation using PostgreSQL date subtraction
        (MAX(ol.agreed_delivery_date) - o.order_placement_date) as promised_lead_time_days,
        (MAX(ol.actual_delivery_date) - o.order_placement_date) as actual_lead_time_days
        
    FROM order_lines ol
    JOIN orders o ON ol.order_id = o.order_id
    LEFT JOIN date_dim d ON o.order_placement_date = d.date
    GROUP BY 
        ol.order_id,
        o.order_placement_date,
        d.year,
        d.quarter,
        d.month_number,
        d.week_number
)
SELECT * FROM order_metrics