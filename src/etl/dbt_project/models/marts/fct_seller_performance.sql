{{
    config(materialized='table')
}}

WITH order_items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),

orders AS (
    SELECT
        order_id,
        is_delivered,
        is_canceled,
        is_late,
        review_score,
        review_is_positive,
        review_is_negative,
        delivery_days
    FROM {{ ref('fct_orders') }}
),

sellers AS (
    SELECT * FROM {{ ref('stg_sellers') }}
),

joined AS (
    SELECT
        i.seller_id,
        s.seller_city,
        s.seller_state,
        i.order_id,
        i.product_id,
        i.price,
        i.freight_value,
        o.is_delivered,
        o.is_canceled,
        o.is_late,
        o.review_score,
        o.review_is_positive,
        o.review_is_negative,
        o.delivery_days
    FROM order_items i
    LEFT JOIN orders  o ON i.order_id  = o.order_id
    LEFT JOIN sellers s ON i.seller_id = s.seller_id
)

SELECT
    seller_id,
    seller_city,
    seller_state,

    COUNT(DISTINCT order_id)                                        AS total_orders,
    COUNT(DISTINCT product_id)                                      AS distinct_products,
    ROUND(SUM(price), 2)                                           AS total_revenue,
    ROUND(SUM(freight_value), 2)                                   AS total_freight_charged,
    ROUND(AVG(price), 2)                                           AS avg_item_price,

    COUNT_IF(is_delivered)                                         AS delivered_orders,
    COUNT_IF(is_canceled)                                          AS canceled_orders,
    COUNT_IF(is_late)                                              AS late_orders,
    ROUND(COUNT_IF(is_late) / NULLIF(COUNT_IF(is_delivered), 0) * 100, 1) AS late_rate_pct,
    ROUND(AVG(CASE WHEN is_delivered THEN delivery_days END), 1)  AS avg_delivery_days,

    COUNT_IF(review_score IS NOT NULL)                             AS reviewed_orders,
    ROUND(AVG(review_score), 2)                                    AS avg_review_score,
    COUNT_IF(review_is_positive)                                   AS positive_reviews,
    COUNT_IF(review_is_negative)                                   AS negative_reviews,

    CURRENT_TIMESTAMP()                                            AS _loaded_at

FROM joined
GROUP BY seller_id, seller_city, seller_state
