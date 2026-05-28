WITH source AS (
    SELECT * FROM {{ var('raw_dataset') }}.PRODUCTS
),

xlat AS (
    SELECT * FROM {{ var('raw_dataset') }}.PRODUCT_CATEGORY_NAME_TRANSLATION
),

cleaned AS (
    SELECT
        p.PRODUCT_ID,
        -- 2 categories missing from translation; 610 products have no category in source
        COALESCE(x.PRODUCT_CATEGORY_NAME_ENGLISH, p.PRODUCT_CATEGORY_NAME, 'uncategorized') AS category,
        p.PRODUCT_CATEGORY_NAME                                              AS category_pt,
        p.PRODUCT_NAME_LENGHT::INT                                           AS product_name_length,
        p.PRODUCT_DESCRIPTION_LENGHT::INT                                    AS product_description_length,
        p.PRODUCT_PHOTOS_QTY::INT                                            AS photos_qty,
        p.PRODUCT_WEIGHT_G::FLOAT                                            AS weight_g,
        p.PRODUCT_LENGTH_CM::FLOAT                                           AS length_cm,
        p.PRODUCT_HEIGHT_CM::FLOAT                                           AS height_cm,
        p.PRODUCT_WIDTH_CM::FLOAT                                            AS width_cm
    FROM source p
    LEFT JOIN xlat x ON p.PRODUCT_CATEGORY_NAME = x.PRODUCT_CATEGORY_NAME
    WHERE p.PRODUCT_ID IS NOT NULL
)

SELECT * FROM cleaned
