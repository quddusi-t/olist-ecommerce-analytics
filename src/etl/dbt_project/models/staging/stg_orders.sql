WITH source AS (
    SELECT * FROM {{ var('raw_dataset') }}.ORDERS
),

cleaned AS (
    SELECT
        ORDER_ID,
        CUSTOMER_ID,
        ORDER_STATUS,
        ORDER_PURCHASE_TIMESTAMP::TIMESTAMP_NTZ   AS purchased_at,
        ORDER_APPROVED_AT::TIMESTAMP_NTZ          AS approved_at,
        ORDER_DELIVERED_CARRIER_DATE::TIMESTAMP_NTZ AS shipped_at,
        ORDER_DELIVERED_CUSTOMER_DATE::TIMESTAMP_NTZ AS delivered_at,
        ORDER_ESTIMATED_DELIVERY_DATE::TIMESTAMP_NTZ AS estimated_delivery_at,

        -- Derived flags
        ORDER_STATUS = 'delivered'                         AS is_delivered,
        ORDER_STATUS = 'canceled'                          AS is_canceled,
        ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL          AS has_delivery_date,

        -- Delivery metrics (null when not delivered)
        CASE
            WHEN ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
            THEN DATEDIFF(
                DAY,
                ORDER_PURCHASE_TIMESTAMP::DATE,
                ORDER_DELIVERED_CUSTOMER_DATE::DATE
            )
        END AS delivery_days,

        CASE
            WHEN ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
            THEN DATEDIFF(
                DAY,
                ORDER_ESTIMATED_DELIVERY_DATE::DATE,
                ORDER_DELIVERED_CUSTOMER_DATE::DATE
            )
        END AS delay_days, -- positive = late, negative = early

        ORDER_PURCHASE_TIMESTAMP::DATE AS order_date
    FROM source
    WHERE ORDER_ID IS NOT NULL
)

SELECT * FROM cleaned
