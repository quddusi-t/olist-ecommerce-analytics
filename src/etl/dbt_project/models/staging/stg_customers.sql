WITH source AS (
    SELECT * FROM {{ var('raw_dataset') }}.CUSTOMERS
),

cleaned AS (
    SELECT
        -- customer_id is a per-order alias — customer_unique_id is the real person
        CUSTOMER_ID,
        CUSTOMER_UNIQUE_ID,
        CUSTOMER_ZIP_CODE_PREFIX::VARCHAR(5) AS zip_code,
        INITCAP(CUSTOMER_CITY)               AS customer_city,
        UPPER(CUSTOMER_STATE)                AS customer_state
    FROM source
    WHERE CUSTOMER_ID IS NOT NULL
      AND CUSTOMER_UNIQUE_ID IS NOT NULL
)

SELECT * FROM cleaned
