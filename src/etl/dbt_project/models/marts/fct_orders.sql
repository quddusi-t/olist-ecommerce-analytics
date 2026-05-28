{{
    config(materialized='table')
}}

WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

items AS (
    SELECT
        order_id,
        COUNT(*)            AS item_count,
        SUM(price)          AS items_revenue,
        SUM(freight_value)  AS total_freight,
        SUM(item_total)     AS gross_revenue
    FROM {{ ref('stg_order_items') }}
    GROUP BY order_id
),

payments AS (
    SELECT * FROM {{ ref('stg_order_payments') }}
),

reviews AS (
    SELECT
        order_id,
        review_score,
        is_positive,
        is_negative
    FROM {{ ref('stg_order_reviews') }}
),

customers AS (
    SELECT
        customer_id,
        customer_unique_id,
        customer_city,
        customer_state
    FROM {{ ref('stg_customers') }}
)

SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_date,
    o.purchased_at,
    o.delivered_at,
    o.estimated_delivery_at,

    -- Financials
    i.item_count,
    i.items_revenue,
    i.total_freight,
    i.gross_revenue,
    p.total_payment_value,
    p.primary_payment_type,
    p.max_installments,

    -- Delivery
    o.delivery_days,
    o.delay_days,
    o.is_delivered,
    o.is_canceled,
    o.delay_days > 0        AS is_late,

    -- Review (nullable — not every order has a review)
    r.review_score,
    r.is_positive           AS review_is_positive,
    r.is_negative           AS review_is_negative,

    CURRENT_TIMESTAMP()     AS _loaded_at

FROM orders o
LEFT JOIN customers  c ON o.customer_id    = c.customer_id
LEFT JOIN items      i ON o.order_id       = i.order_id
LEFT JOIN payments   p ON o.order_id       = p.order_id
LEFT JOIN reviews    r ON o.order_id       = r.order_id
