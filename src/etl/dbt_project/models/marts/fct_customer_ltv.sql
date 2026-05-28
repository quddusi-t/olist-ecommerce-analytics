{{
    config(materialized='table')
}}

{%- set ref_date = date_literal('2018-10-17') -%}

WITH orders AS (
    SELECT
        customer_unique_id,
        order_date,
        gross_revenue,
        total_payment_value,
        is_delivered,
        review_score
    FROM {{ ref('fct_orders') }}
    WHERE is_delivered = TRUE
),

customer_agg AS (
    SELECT
        customer_unique_id,

        COUNT(*)                                                        AS total_orders,
        ROUND(SUM(gross_revenue), 2)                                   AS total_revenue,
        ROUND(AVG(gross_revenue), 2)                                   AS avg_order_value,

        MIN(order_date)                                                 AS first_order_date,
        MAX(order_date)                                                 AS last_order_date,
        {{ datediff_days('MIN(order_date)', ref_date) }}               AS customer_age_days,
        {{ datediff_days('MAX(order_date)', ref_date) }}               AS recency_days,

        -- Avg days between orders (null for single-order customers)
        CASE
            WHEN COUNT(*) > 1 THEN
                ROUND(
                    {{ datediff_days('MIN(order_date)', 'MAX(order_date)') }}
                    / (COUNT(*) - 1.0),
                1)
        END AS avg_days_between_orders,

        ROUND(AVG(review_score), 2)                                    AS avg_review_score,
        COUNT_IF(review_score IS NOT NULL)                             AS reviewed_orders

    FROM orders
    GROUP BY customer_unique_id
),

ltv_enriched AS (
    SELECT
        *,
        -- Simple LTV: annualised revenue projection
        -- (total_revenue / customer_age_days) * 365, floored at 1 day
        CASE
            WHEN customer_age_days > 0
            THEN ROUND(total_revenue / customer_age_days * 365, 2)
        END AS projected_annual_ltv,

        CASE
            WHEN total_orders = 1  THEN 'One-Time'
            WHEN total_orders <= 3 THEN 'Occasional'
            WHEN total_orders <= 7 THEN 'Regular'
            ELSE                        'VIP'
        END AS customer_tier

    FROM customer_agg
)

SELECT
    *,
    {{ ref_date }}      AS as_of_date,
    CURRENT_TIMESTAMP() AS _loaded_at
FROM ltv_enriched
