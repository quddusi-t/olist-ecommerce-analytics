connection: "snowflake_olist"

# Include all view files in the views/ directory
include: "/views/*.view.lkml"

# -------------------------------------------------------
# Explore: Olist Orders
#
# Primary grain: fct_orders (one row per order)
#
# Joins:
#   fct_rfm_segments     → many_to_one on customer_unique_id
#                          Safe: many orders map to one customer segment row.
#
#   fct_delivery_performance → many_to_many on (customer_state, month)
#                          This view is pre-aggregated at seller×state×month grain.
#                          Joining on customer_state + order month brings in
#                          delivery lane metrics for that route and period.
#                          Do NOT mix order-level counts with this view's
#                          pre-aggregated counts in the same query.
# -------------------------------------------------------

explore: fct_orders {
  label: "Olist Orders"
  description: "Order-level analytics with customer RFM segments and delivery lane performance. Start here for revenue, review, and customer quality analysis."
  group_label: "Olist Analytics"

  join: fct_rfm_segments {
    label: "Customer RFM"
    type: left_outer
    sql_on: ${fct_orders.customer_unique_id} = ${fct_rfm_segments.customer_unique_id} ;;
    relationship: many_to_one
  }

  join: fct_delivery_performance {
    label: "Delivery Performance"
    type: left_outer
    sql_on: ${fct_orders.customer_state} = ${fct_delivery_performance.customer_state}
            AND ${fct_orders.order_date_month} = ${fct_delivery_performance.year_month_date} ;;
    relationship: many_to_many
  }
}
