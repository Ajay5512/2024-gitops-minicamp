
-- models/marts/dim_product.sql
SELECT * FROM {{ ref('stg_products') }}


