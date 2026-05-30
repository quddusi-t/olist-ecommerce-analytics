view: fct_delivery_performance {
  sql_table_name: OLIST_ANALYTICS.OLIST_MARTS.FCT_DELIVERY_PERFORMANCE ;;
  label: "Delivery Performance"

  # -------------------------------------------------------
  # Note: This view is pre-aggregated at seller × customer_state × month grain.
  # Joining to fct_orders produces a many_to_many join on (customer_state, month).
  # Use measures in this view for delivery-lane analytics; avoid mixing raw order
  # counts from fct_orders with counts from this view in the same query.
  # -------------------------------------------------------

  # -------------------------------------------------------
  # Dimensions
  # -------------------------------------------------------

  dimension: seller_id {
    type: string
    sql: ${TABLE}.SELLER_ID ;;
    label: "Seller ID"
    description: "Olist seller identifier."
  }

  dimension: seller_state {
    type: string
    sql: ${TABLE}.SELLER_STATE ;;
    label: "Seller State"
    group_label: "Geography"
    description: "Brazilian state where the seller is based."
  }

  dimension: customer_state {
    type: string
    sql: ${TABLE}.CUSTOMER_STATE ;;
    label: "Customer State"
    group_label: "Geography"
    description: "Brazilian state where the customer is located."
  }

  dimension: delivery_lane {
    type: string
    sql: ${TABLE}.SELLER_STATE || ' → ' || ${TABLE}.CUSTOMER_STATE ;;
    label: "Delivery Lane"
    group_label: "Geography"
    description: "Seller state to customer state route (e.g. SP → RJ)."
  }

  dimension_group: year_month {
    type: time
    timeframes: [raw, date, month, quarter, year]
    datatype: date
    sql: ${TABLE}.YEAR_MONTH ;;
    label: "Month"
    description: "Month of delivery activity (first day of the month)."
  }

  dimension: orders_delivered {
    type: number
    sql: ${TABLE}.ORDERS_DELIVERED ;;
    label: "Orders Delivered (Row)"
    description: "Pre-aggregated delivered order count for this seller × state × month combination."
    hidden: yes
  }

  dimension: avg_delivery_days_raw {
    type: number
    sql: ${TABLE}.AVG_DELIVERY_DAYS ;;
    label: "Avg Delivery Days (Row)"
    description: "Pre-aggregated average delivery days for this row. Use the measure for cross-row analysis."
    hidden: yes
  }

  dimension: late_rate_pct_raw {
    type: number
    sql: ${TABLE}.LATE_RATE_PCT ;;
    label: "Late Rate % (Row)"
    description: "Pre-aggregated late rate % for this row."
    hidden: yes
  }

  dimension: avg_review_score_raw {
    type: number
    sql: ${TABLE}.AVG_REVIEW_SCORE ;;
    label: "Avg Review Score (Row)"
    hidden: yes
  }

  # -------------------------------------------------------
  # Measures
  # -------------------------------------------------------

  measure: total_orders_delivered {
    type: sum
    sql: ${TABLE}.ORDERS_DELIVERED ;;
    label: "Orders Delivered"
    description: "Total delivered orders across selected seller-state-month combinations."
  }

  measure: avg_delivery_days {
    type: average
    sql: ${TABLE}.AVG_DELIVERY_DAYS ;;
    label: "Avg Delivery Days"
    description: "Average delivery days across lanes and months in the selection."
    value_format_name: decimal_1
  }

  measure: avg_delay_days {
    type: average
    sql: ${TABLE}.AVG_DELAY_DAYS ;;
    label: "Avg Delay Days"
    description: "Average delay beyond estimated delivery date. Negative = early arrival."
    value_format_name: decimal_1
  }

  measure: total_late_orders {
    type: sum
    sql: ${TABLE}.LATE_ORDERS ;;
    label: "Late Orders"
    description: "Total orders delivered after the estimated delivery date."
  }

  measure: avg_late_rate {
    type: average
    sql: ${TABLE}.LATE_RATE_PCT ;;
    label: "Avg Late Rate %"
    description: "Average late delivery rate across selected seller-state-month combinations."
    value_format_name: decimal_1
  }

  measure: avg_review_score {
    type: average
    sql: ${TABLE}.AVG_REVIEW_SCORE ;;
    label: "Avg Review Score"
    description: "Average customer review score across selected delivery lanes and months."
    value_format_name: decimal_2
  }

  measure: count_lanes {
    type: count
    label: "Lane-Month Count"
    description: "Number of distinct seller × customer_state × month combinations."
    drill_fields: [seller_id, seller_state, customer_state, year_month_month, orders_delivered, avg_delivery_days_raw, late_rate_pct_raw]
  }
}
