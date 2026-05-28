{{
    config(materialized='table')
}}

WITH delivered AS (
    SELECT *
    FROM {{ ref('fct_orders') }}
    WHERE is_delivered = TRUE
),

seller_items AS (
    SELECT
        i.order_id,
        i.seller_id
    FROM {{ ref('stg_order_items') }} i
),

joined AS (
    SELECT
        d.order_id,
        d.order_date,
        DATE_TRUNC('MONTH', d.order_date)   AS year_month,
        d.customer_state,
        s.seller_id,
        sel.seller_state,
        d.delivery_days,
        d.delay_days,
        d.is_late,
        d.review_score
    FROM delivered d
    LEFT JOIN seller_items s  ON d.order_id    = s.order_id
    LEFT JOIN {{ ref('stg_sellers') }} sel ON s.seller_id = sel.seller_id
),

aggregated AS (
    SELECT
        seller_id,
        seller_state,
        customer_state,
        year_month,

        COUNT(*)                                                    AS orders_delivered,
        ROUND(AVG(delivery_days), 1)                               AS avg_delivery_days,
        ROUND(AVG(delay_days), 1)                                  AS avg_delay_days,
        COUNT_IF(is_late)                                          AS late_orders,
        ROUND(COUNT_IF(is_late) / COUNT(*) * 100, 1)              AS late_rate_pct,
        ROUND(AVG(review_score), 2)                                AS avg_review_score,
        COUNT_IF(review_score IS NOT NULL)                         AS reviewed_orders
    FROM joined
    GROUP BY
        seller_id,
        seller_state,
        customer_state,
        year_month
)

SELECT
    *,
    CURRENT_TIMESTAMP() AS _loaded_at
FROM aggregated
