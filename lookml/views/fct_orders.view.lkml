view: fct_orders {
  sql_table_name: OLIST_ANALYTICS.OLIST_MARTS.FCT_ORDERS ;;
  label: "Orders"

  # -------------------------------------------------------
  # Primary Key
  # -------------------------------------------------------

  dimension: order_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.ORDER_ID ;;
    label: "Order ID"
    description: "Unique order identifier (Olist order_id)."
    hidden: yes
  }

  # -------------------------------------------------------
  # Customer Dimensions
  # -------------------------------------------------------

  dimension: customer_unique_id {
    type: string
    sql: ${TABLE}.CUSTOMER_UNIQUE_ID ;;
    label: "Customer ID"
    description: "De-duplicated customer identifier (one customer across multiple orders)."
  }

  dimension: customer_city {
    type: string
    sql: ${TABLE}.CUSTOMER_CITY ;;
    label: "Customer City"
    group_label: "Customer Location"
  }

  dimension: customer_state {
    type: string
    sql: ${TABLE}.CUSTOMER_STATE ;;
    label: "Customer State"
    group_label: "Customer Location"
    description: "Brazilian state abbreviation (e.g. SP, RJ, MG)."
  }

  # -------------------------------------------------------
  # Order Status & Flags
  # -------------------------------------------------------

  dimension: order_status {
    type: string
    sql: ${TABLE}.ORDER_STATUS ;;
    label: "Order Status"
    description: "Current order status: delivered, shipped, canceled, etc."
  }

  dimension: primary_payment_type {
    type: string
    sql: ${TABLE}.PRIMARY_PAYMENT_TYPE ;;
    label: "Payment Type"
    description: "Dominant payment method on the order (credit_card, boleto, voucher, debit_card)."
  }

  dimension: max_installments {
    type: number
    sql: ${TABLE}.MAX_INSTALLMENTS ;;
    label: "Installments"
    description: "Maximum number of installments used for payment on this order."
  }

  dimension: is_delivered {
    type: yesno
    sql: ${TABLE}.IS_DELIVERED ;;
    label: "Is Delivered"
  }

  dimension: is_canceled {
    type: yesno
    sql: ${TABLE}.IS_CANCELED ;;
    label: "Is Canceled"
  }

  dimension: is_late {
    type: yesno
    sql: ${TABLE}.IS_LATE ;;
    label: "Is Late"
    description: "True when actual delivery exceeded the estimated delivery date."
  }

  # -------------------------------------------------------
  # Date Dimensions
  # -------------------------------------------------------

  dimension_group: order_date {
    type: time
    timeframes: [raw, date, month, quarter, year]
    datatype: date
    sql: ${TABLE}.ORDER_DATE ;;
    label: "Order"
    description: "Date the order was placed (purchase date)."
  }

  dimension_group: delivered_at {
    type: time
    timeframes: [raw, date, month, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.DELIVERED_AT ;;
    label: "Delivered"
    description: "Timestamp when the order was delivered to the customer."
  }

  dimension_group: estimated_delivery_at {
    type: time
    timeframes: [raw, date, month]
    datatype: timestamp
    sql: ${TABLE}.ESTIMATED_DELIVERY_AT ;;
    label: "Estimated Delivery"
    description: "Seller-estimated delivery date at time of purchase."
  }

  # -------------------------------------------------------
  # Delivery Dimensions
  # -------------------------------------------------------

  dimension: delivery_days {
    type: number
    sql: ${TABLE}.DELIVERY_DAYS ;;
    label: "Delivery Days"
    description: "Actual number of days from order purchase to delivery."
  }

  dimension: delay_days {
    type: number
    sql: ${TABLE}.DELAY_DAYS ;;
    label: "Delay Days"
    description: "Days beyond the estimated delivery date. Negative means early delivery."
  }

  # -------------------------------------------------------
  # Review Dimensions
  # -------------------------------------------------------

  dimension: review_score {
    type: number
    sql: ${TABLE}.REVIEW_SCORE ;;
    label: "Review Score"
    description: "Customer review score 1–5. NULL when no review was submitted."
  }

  dimension: review_is_positive {
    type: yesno
    sql: ${TABLE}.REVIEW_IS_POSITIVE ;;
    label: "Positive Review"
    description: "True when review score is 4 or 5."
  }

  dimension: review_is_negative {
    type: yesno
    sql: ${TABLE}.REVIEW_IS_NEGATIVE ;;
    label: "Negative Review"
    description: "True when review score is 1 or 2."
  }

  # -------------------------------------------------------
  # Measures
  # -------------------------------------------------------

  measure: count_orders {
    type: count
    label: "Order Count"
    description: "Total number of orders."
    drill_fields: [order_id, customer_unique_id, order_date_date, order_status, gross_revenue]
  }

  measure: total_gross_revenue {
    type: sum
    sql: ${TABLE}.GROSS_REVENUE ;;
    label: "Total Revenue (BRL)"
    description: "Sum of item prices (items_revenue). Excludes freight."
    value_format_name: decimal_2
  }

  measure: avg_order_value {
    type: average
    sql: ${TABLE}.GROSS_REVENUE ;;
    label: "Avg Order Value (BRL)"
    description: "Average gross revenue per order."
    value_format_name: decimal_2
  }

  measure: total_payment_value {
    type: sum
    sql: ${TABLE}.TOTAL_PAYMENT_VALUE ;;
    label: "Total Payment Value (BRL)"
    description: "Sum of all payments including freight and installment charges."
    value_format_name: decimal_2
  }

  measure: total_freight {
    type: sum
    sql: ${TABLE}.TOTAL_FREIGHT ;;
    label: "Total Freight (BRL)"
    description: "Sum of freight charges across all orders."
    value_format_name: decimal_2
  }

  measure: avg_review_score {
    type: average
    sql: ${TABLE}.REVIEW_SCORE ;;
    label: "Avg Review Score"
    description: "Average customer review score (1–5) across orders with a review."
    value_format_name: decimal_2
    filters: [review_score: "NOT NULL"]
  }

  measure: avg_delivery_days {
    type: average
    sql: ${TABLE}.DELIVERY_DAYS ;;
    label: "Avg Delivery Days"
    description: "Average days from order placement to delivery (delivered orders only)."
    value_format_name: decimal_1
    filters: [is_delivered: "Yes"]
  }

  measure: count_late_orders {
    type: count
    label: "Late Orders"
    description: "Number of orders delivered after the estimated delivery date."
    filters: [is_late: "Yes"]
  }

  measure: late_rate {
    type: number
    sql: ${count_late_orders} / NULLIF(${count_orders}, 0) ;;
    label: "Late Rate"
    description: "Proportion of orders that were delivered late."
    value_format_name: percent_1
  }

  measure: count_reviewed_orders {
    type: count
    label: "Reviewed Orders"
    description: "Number of orders that received a customer review."
    filters: [review_score: "NOT NULL"]
  }
}
