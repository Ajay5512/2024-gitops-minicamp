
-- models/staging/stg_dates.sql
WITH source AS (
    SELECT * FROM {{ source('raw', 'date') }}
),
staged AS (
    SELECT date FROM source
)
SELECT * FROM staged
