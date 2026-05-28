-- Geolocation has avg 52.6 rows per zip code (max 1,146).
-- Aggregate to one representative point per zip to make it joinable.
WITH source AS (
    SELECT * FROM {{ var('raw_dataset') }}.GEOLOCATION
),

one_point_per_zip AS (
    SELECT
        GEOLOCATION_ZIP_CODE_PREFIX::VARCHAR(5) AS zip_code,
        UPPER(GEOLOCATION_STATE)                AS state,
        INITCAP(MIN(GEOLOCATION_CITY))          AS city,
        AVG(GEOLOCATION_LAT)                    AS lat,
        AVG(GEOLOCATION_LNG)                    AS lng
    FROM source
    GROUP BY
        GEOLOCATION_ZIP_CODE_PREFIX,
        GEOLOCATION_STATE
)

SELECT * FROM one_point_per_zip
