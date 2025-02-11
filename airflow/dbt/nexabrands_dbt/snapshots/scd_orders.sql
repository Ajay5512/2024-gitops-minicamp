{% snapshot scd_orders %}
{{
    config(
        target_schema='raw',
        unique_key='order_id',  
        strategy='timestamp',
        updated_at='order_placement_date', 
        invalidate_hard_deletes=True
    )
}}

select *
FROM  {{ source('raw', 'orders') }}

{% endsnapshot %}