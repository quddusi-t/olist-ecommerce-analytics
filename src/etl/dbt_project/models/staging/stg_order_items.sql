WITH source AS (
    SELECT * FROM {{ var('raw_dataset') }}.ORDER_ITEMS
),

cleaned AS (
    SELECT
        ORDER_ID,
        ORDER_ITEM_ID,
        PRODUCT_ID,
        SELLER_ID,
        SHIPPING_LIMIT_DATE::TIMESTAMP_NTZ AS shipping_limit_at,
        PRICE::FLOAT                       AS price,
        FREIGHT_VALUE::FLOAT               AS freight_value,
        (PRICE + FREIGHT_VALUE)::FLOAT     AS item_total
    FROM source
    WHERE ORDER_ID IS NOT NULL
      AND PRODUCT_ID IS NOT NULL
      AND SELLER_ID IS NOT NULL
)

SELECT * FROM cleaned
