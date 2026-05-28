{{
    config(materialized='table')
}}

{%- set ref_date = date_literal('2018-10-17') -%}

-- Reference date: last order date in the dataset (2018-10-17).
-- Swap to CURRENT_DATE when running against live data.
WITH orders AS (
    SELECT
        customer_unique_id,
        order_date,
        gross_revenue
    FROM {{ ref('fct_orders') }}
    WHERE is_delivered = TRUE
      AND gross_revenue IS NOT NULL
),

rfm_raw AS (
    SELECT
        customer_unique_id,

        -- Recency: days since last purchase
        {{ datediff_days('MAX(order_date)', ref_date) }}    AS recency_days,

        -- Frequency: number of delivered orders
        COUNT(*)                                            AS frequency,

        -- Monetary: total spend
        ROUND(SUM(gross_revenue), 2)                        AS monetary

    FROM orders
    GROUP BY customer_unique_id
),

rfm_scored AS (
    SELECT
        *,
        -- Score 1 (worst) to 5 (best) using NTILE
        6 - NTILE(5) OVER (ORDER BY recency_days)   AS r_score,  -- lower days = better
        NTILE(5)     OVER (ORDER BY frequency)       AS f_score,
        NTILE(5)     OVER (ORDER BY monetary)        AS m_score
    FROM rfm_raw
),

rfm_segmented AS (
    SELECT
        *,
        ROUND((r_score + f_score + m_score) / 3.0, 2) AS rfm_score,
        CASE
            WHEN r_score >= 4 AND f_score >= 4             THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3             THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2             THEN 'Recent Customers'
            WHEN r_score <= 2 AND f_score >= 3             THEN 'At Risk'
            WHEN r_score = 1  AND f_score >= 4             THEN 'Cant Lose Them'
            WHEN r_score <= 2 AND f_score <= 2             THEN 'Lost'
            ELSE                                                'Potential Loyalists'
        END AS segment
    FROM rfm_scored
)

SELECT
    *,
    {{ ref_date }}      AS as_of_date,
    CURRENT_TIMESTAMP() AS _loaded_at
FROM rfm_segmented
