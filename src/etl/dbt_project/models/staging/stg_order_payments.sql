WITH source AS (
    SELECT * FROM {{ var('raw_dataset') }}.ORDER_PAYMENTS
),

cleaned AS (
    SELECT
        ORDER_ID,
        PAYMENT_SEQUENTIAL,
        -- Treat 'not_defined' as NULL
        NULLIF(PAYMENT_TYPE, 'not_defined')  AS payment_type,
        PAYMENT_INSTALLMENTS::INT            AS payment_installments,
        PAYMENT_VALUE::FLOAT                 AS payment_value
    FROM source
    WHERE ORDER_ID IS NOT NULL
),

-- Aggregate to order level: total value, dominant payment type, max installments
order_level AS (
    SELECT
        ORDER_ID,
        SUM(payment_value)                           AS total_payment_value,
        MAX(payment_installments)                    AS max_installments,
        -- Most-used payment type for the order (by value)
        MAX_BY(payment_type, payment_value)          AS primary_payment_type,
        COUNT(*)                                     AS payment_row_count
    FROM cleaned
    GROUP BY ORDER_ID
)

SELECT * FROM order_level
