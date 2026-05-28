{% macro date_trunc_month(date_expr) %}
    {%- if target.type == 'bigquery' -%} DATE_TRUNC({{ date_expr }}, MONTH)
    {%- elif target.type == 'snowflake' -%} DATE_TRUNC('MONTH', {{ date_expr }})
    {%- else -%} DATE_TRUNC('month', {{ date_expr }}) {%- endif %}
{% endmacro %}

{% macro datediff_days(start_date, end_date) %}
    {%- if target.type == 'bigquery' -%} DATE_DIFF({{ end_date }}, {{ start_date }}, DAY)
    {%- elif target.type == 'snowflake' -%} DATEDIFF(DAY, {{ start_date }}, {{ end_date }})
    {%- else -%} DATEDIFF({{ start_date }}, {{ end_date }}) {%- endif %}
{% endmacro %}

{% macro dateadd_days(date_expr, n_days) %}
    {%- if target.type == 'bigquery' -%} DATE_ADD({{ date_expr }}, INTERVAL {{ n_days }} DAY)
    {%- elif target.type == 'snowflake' -%} DATEADD(DAY, {{ n_days }}, {{ date_expr }})
    {%- else -%} {{ date_expr }} + INTERVAL '{{ n_days }}' DAY {%- endif %}
{% endmacro %}

{% macro date_literal(date_str) %}
    {%- if target.type == 'bigquery' -%} DATE '{{ date_str }}'
    {%- elif target.type == 'snowflake' -%} '{{ date_str }}'::DATE
    {%- else -%} DATE '{{ date_str }}' {%- endif %}
{% endmacro %}

{% macro countif(condition) %}
    {%- if target.type == 'bigquery' -%} COUNTIF({{ condition }})
    {%- elif target.type == 'snowflake' -%} COUNT_IF({{ condition }})
    {%- else -%} SUM(CASE WHEN {{ condition }} THEN 1 ELSE 0 END) {%- endif %}
{% endmacro %}

{% macro safe_divide(numerator, denominator) %}
    {%- if target.type == 'bigquery' -%} SAFE_DIVIDE({{ numerator }}, {{ denominator }})
    {%- elif target.type == 'snowflake' -%} IFF({{ denominator }} = 0, NULL, {{ numerator }} / {{ denominator }})
    {%- else -%} CASE WHEN {{ denominator }} = 0 THEN NULL ELSE {{ numerator }} / {{ denominator }} END {%- endif %}
{% endmacro %}

{% macro cast_to_string(expr) %}
    {%- if target.type == 'bigquery' -%} CAST({{ expr }} AS STRING)
    {%- elif target.type == 'snowflake' -%} CAST({{ expr }} AS VARCHAR)
    {%- else -%} CAST({{ expr }} AS TEXT) {%- endif %}
{% endmacro %}
