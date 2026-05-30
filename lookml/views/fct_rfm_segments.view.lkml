view: fct_rfm_segments {
  sql_table_name: OLIST_ANALYTICS.OLIST_MARTS.FCT_RFM_SEGMENTS ;;
  label: "RFM Segments"

  # -------------------------------------------------------
  # Primary Key
  # -------------------------------------------------------

  dimension: customer_unique_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.CUSTOMER_UNIQUE_ID ;;
    label: "Customer ID"
    description: "De-duplicated customer identifier. One row per customer."
  }

  # -------------------------------------------------------
  # Segment Dimensions
  # -------------------------------------------------------

  dimension: segment {
    type: string
    sql: ${TABLE}.SEGMENT ;;
    label: "RFM Segment"
    description: "Customer segment derived from RFM scoring: Champions, Loyal Customers, Recent Customers, Potential Loyalists, At Risk, Cant Lose Them, Lost."
    order_by_field: rfm_score
  }

  dimension: r_score {
    type: number
    sql: ${TABLE}.R_SCORE ;;
    label: "Recency Score"
    description: "Recency score 1–5 via NTILE. 5 = purchased most recently."
    group_label: "RFM Scores"
  }

  dimension: f_score {
    type: number
    sql: ${TABLE}.F_SCORE ;;
    label: "Frequency Score"
    description: "Frequency score 1–5 via NTILE. 5 = ordered most often."
    group_label: "RFM Scores"
  }

  dimension: m_score {
    type: number
    sql: ${TABLE}.M_SCORE ;;
    label: "Monetary Score"
    description: "Monetary score 1–5 via NTILE. 5 = highest total spend."
    group_label: "RFM Scores"
  }

  dimension: rfm_score {
    type: number
    sql: ${TABLE}.RFM_SCORE ;;
    label: "RFM Score"
    description: "Average of R, F, M scores (1.00–5.00). Higher = more valuable customer."
    value_format_name: decimal_2
  }

  dimension: recency_days {
    type: number
    sql: ${TABLE}.RECENCY_DAYS ;;
    label: "Recency (Days)"
    description: "Days since the customer's last delivered order, as of as_of_date."
  }

  dimension: frequency {
    type: number
    sql: ${TABLE}.FREQUENCY ;;
    label: "Order Count"
    description: "Total number of delivered orders placed by this customer."
  }

  dimension: monetary {
    type: number
    sql: ${TABLE}.MONETARY ;;
    label: "Total Spend (BRL)"
    description: "Total gross revenue across all delivered orders for this customer."
    value_format_name: decimal_2
  }

  dimension: as_of_date {
    type: date
    sql: ${TABLE}.AS_OF_DATE ;;
    label: "Scored As Of"
    description: "Reference date used for RFM calculation. Fixed at 2018-10-17 (last order date in dataset)."
  }

  # -------------------------------------------------------
  # Segment Health Tier (derived)
  # -------------------------------------------------------

  dimension: segment_health {
    type: string
    sql:
      CASE ${TABLE}.SEGMENT
        WHEN 'Champions'           THEN '1 - High Value'
        WHEN 'Loyal Customers'     THEN '1 - High Value'
        WHEN 'Cant Lose Them'      THEN '2 - At Risk'
        WHEN 'At Risk'             THEN '2 - At Risk'
        WHEN 'Potential Loyalists' THEN '3 - Growing'
        WHEN 'Recent Customers'    THEN '3 - Growing'
        WHEN 'Lost'                THEN '4 - Lost'
        ELSE                            '5 - Unknown'
      END ;;
    label: "Segment Health Tier"
    description: "Rolled-up health category: High Value / At Risk / Growing / Lost."
    group_label: "RFM Scores"
  }

  # -------------------------------------------------------
  # Measures
  # -------------------------------------------------------

  measure: count_customers {
    type: count_distinct
    sql: ${TABLE}.CUSTOMER_UNIQUE_ID ;;
    label: "Customer Count"
    description: "Number of distinct customers with RFM scores."
    drill_fields: [customer_unique_id, segment, rfm_score, recency_days, frequency, monetary]
  }

  measure: avg_rfm_score {
    type: average
    sql: ${TABLE}.RFM_SCORE ;;
    label: "Avg RFM Score"
    description: "Average composite RFM score across customers in the selection."
    value_format_name: decimal_2
  }

  measure: total_lifetime_revenue {
    type: sum
    sql: ${TABLE}.MONETARY ;;
    label: "Total Lifetime Revenue (BRL)"
    description: "Sum of lifetime spend across all customers in the selection."
    value_format_name: decimal_2
  }

  measure: avg_monetary {
    type: average
    sql: ${TABLE}.MONETARY ;;
    label: "Avg Customer Spend (BRL)"
    description: "Average lifetime spend per customer."
    value_format_name: decimal_2
  }

  measure: avg_recency_days {
    type: average
    sql: ${TABLE}.RECENCY_DAYS ;;
    label: "Avg Recency (Days)"
    description: "Average days since last order across customers in the selection."
    value_format_name: decimal_0
  }

  measure: avg_frequency {
    type: average
    sql: ${TABLE}.FREQUENCY ;;
    label: "Avg Order Frequency"
    description: "Average number of orders per customer in the selection."
    value_format_name: decimal_1
  }
}
