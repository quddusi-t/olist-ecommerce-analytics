WITH source AS (
    SELECT * FROM {{ var('raw_dataset') }}.ORDER_REVIEWS
),

cleaned AS (
    SELECT
        REVIEW_ID,
        ORDER_ID,
        REVIEW_SCORE::INT                          AS review_score,
        -- Comment fields are sparse (88% / 59% null) — keep as-is, no coercion needed
        NULLIF(TRIM(REVIEW_COMMENT_TITLE), '')     AS review_comment_title,
        NULLIF(TRIM(REVIEW_COMMENT_MESSAGE), '')   AS review_comment_message,
        REVIEW_CREATION_DATE::TIMESTAMP_NTZ        AS review_created_at,
        REVIEW_ANSWER_TIMESTAMP::TIMESTAMP_NTZ     AS review_answered_at,

        review_score >= 4                          AS is_positive,
        review_score <= 2                          AS is_negative
    FROM source
    WHERE ORDER_ID IS NOT NULL
      AND REVIEW_SCORE IS NOT NULL
),

-- Source has duplicate review_ids AND multiple reviews per order_id.
-- Keep one row per order: latest by review_answered_at, then review_created_at.
deduped AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ORDER_ID
        ORDER BY review_answered_at DESC NULLS LAST, review_created_at DESC NULLS LAST
    ) = 1
)

SELECT * FROM deduped
