{% snapshot scd_customers %}
{{
    config(
        target_schema='raw',
        unique_key='customer_id',
        strategy='check',
        check_cols='all',
        invalidate_hard_deletes=True
    )
}}

select *
FROM  {{ source('raw', 'customers') }}

{% endsnapshot %}