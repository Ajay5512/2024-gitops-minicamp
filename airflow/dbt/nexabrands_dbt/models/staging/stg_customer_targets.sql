WITH source AS (
    SELECT * 
    FROM {{ source('raw', 'customer_targets') }}
),
staged AS (
    SELECT
        customer_id,
        "ontime_target%" as ontime_target,
        "infull_target%" as infull_target,
        "otif_target%" as otif_target,
        1 as dummy_variable -- Add the constant dummy variable
    FROM source
)
SELECT * 
FROM staged
