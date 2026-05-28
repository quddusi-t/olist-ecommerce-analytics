{{
    config(materialized='table')
}}

-- SCD Type 2: one row per seller per version of their location.
-- Rows with valid_to IS NULL are the current version.
--
-- Source: seller_location_history seed (synthetic change log).
-- In production: replace the seed with a CDC stream or audit table
-- that captures every city/state update with a timestamp.
WITH history AS (
    SELECT
        seller_id,
        INITCAP(seller_city)   AS seller_city,
        UPPER(seller_state)    AS seller_state,
        effective_date::DATE   AS valid_from
    FROM {{ ref('seller_location_history') }}
),

versioned AS (
    SELECT
        seller_id,
        seller_city,
        seller_state,
        valid_from,

        -- valid_to = day before the next version starts (NULL for current)
        DATEADD(
            DAY,
            -1,
            LEAD(valid_from) OVER (PARTITION BY seller_id ORDER BY valid_from)
        ) AS valid_to,

        ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY valid_from)       AS version_number,
        ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY valid_from DESC)  AS _recency_rank
    FROM history
)

SELECT
    -- Surrogate key: seller_id + version ensures uniqueness across history
    seller_id || '_v' || version_number         AS seller_version_key,
    seller_id,
    seller_city,
    seller_state,
    valid_from,
    valid_to,
    _recency_rank = 1                           AS is_current,
    version_number,
    CURRENT_TIMESTAMP()                         AS _loaded_at
FROM versioned
