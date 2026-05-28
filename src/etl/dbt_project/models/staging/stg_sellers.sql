WITH source AS (
    SELECT * FROM {{ var('raw_dataset') }}.SELLERS
),

cleaned AS (
    SELECT
        SELLER_ID,
        SELLER_ZIP_CODE_PREFIX::VARCHAR(5) AS zip_code,
        INITCAP(SELLER_CITY)               AS seller_city,
        UPPER(SELLER_STATE)                AS seller_state
    FROM source
    WHERE SELLER_ID IS NOT NULL
)

SELECT * FROM cleaned
