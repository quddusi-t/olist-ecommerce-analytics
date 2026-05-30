# Olist Analytics — LookML Semantic Layer

LookML project defining the semantic layer on top of the Olist dbt mart tables in Snowflake. Translates warehouse columns into business-facing dimensions and measures, and defines how the three core mart tables join together.

## Project Structure

```
lookml/
├── manifest.lkml               # Project name declaration
├── olist.model.lkml            # Connection, explore, join definitions
├── views/
│   ├── fct_orders.view.lkml            # Order-level fact (primary grain)
│   ├── fct_rfm_segments.view.lkml      # Customer RFM scores and segments
│   └── fct_delivery_performance.view.lkml  # Monthly delivery lane metrics
└── README.md
```

## Data Source

**Warehouse**: Snowflake — `OLIST_ANALYTICS`
**Schema**: `OLIST_MARTS` (dbt output: target schema `olist` + custom schema `marts`)
**Dialect**: Snowflake SQL
**Tables**: materialized by dbt as `TABLE` type

The three views map directly to dbt mart models in `src/etl/dbt_project/models/marts/`.

## Views

### `fct_orders` — Order Grain
One row per order. Joins items, payments, reviews, and customer location at build time in dbt.

**Key dimensions**: `order_id`, `customer_unique_id`, `customer_state`, `order_status`, `primary_payment_type`, `order_date` (date group), `is_delivered`, `is_late`, `review_score`

**Key measures**:
| Measure | Description |
|---|---|
| `count_orders` | Total orders |
| `total_gross_revenue` | Sum of item prices (BRL) |
| `avg_order_value` | Average gross revenue per order |
| `avg_review_score` | Average review score (1–5) |
| `avg_delivery_days` | Average days to delivery |
| `late_rate` | % of orders delivered after estimated date |

---

### `fct_rfm_segments` — Customer Grain
One row per customer. RFM scores calculated against reference date 2018-10-17 (last order date in dataset).

**Key dimensions**: `customer_unique_id`, `segment`, `r_score`, `f_score`, `m_score`, `rfm_score`, `segment_health` (derived rollup), `recency_days`, `frequency`, `monetary`

**Segments**: Champions · Loyal Customers · Recent Customers · Potential Loyalists · At Risk · Cant Lose Them · Lost

**Key measures**:
| Measure | Description |
|---|---|
| `count_customers` | Distinct customer count |
| `avg_rfm_score` | Average composite score |
| `total_lifetime_revenue` | Sum of lifetime spend (BRL) |
| `avg_monetary` | Average customer lifetime spend |
| `avg_recency_days` | Average days since last purchase |

---

### `fct_delivery_performance` — Seller × State × Month Grain
Pre-aggregated delivery metrics. One row per (seller_id, seller_state, customer_state, year_month).

**Key dimensions**: `seller_id`, `seller_state`, `customer_state`, `delivery_lane` (derived: seller → customer), `year_month` (date group)

**Key measures**:
| Measure | Description |
|---|---|
| `total_orders_delivered` | Sum of delivered orders across rows |
| `avg_delivery_days` | Average delivery time |
| `avg_delay_days` | Average delay vs estimated date |
| `total_late_orders` | Total late deliveries |
| `avg_late_rate` | Average late rate % |
| `avg_review_score` | Average review score by lane |

## Explore: `fct_orders`

The single explore joins all three views. Entry point for most analyses.

```
fct_orders (one row per order)
  └── fct_rfm_segments       [many_to_one]  on customer_unique_id
  └── fct_delivery_performance [many_to_many] on (customer_state, month)
```

### Join Notes

**`fct_rfm_segments` (many_to_one)**
Clean join. Many orders belong to one customer; each customer has exactly one RFM row. Adding RFM dimensions to an order-level query is safe — no fan-out.

**`fct_delivery_performance` (many_to_many)**
This view is pre-aggregated. The join brings in the delivery lane metrics for the matching customer state and calendar month. Because the view already aggregates multiple orders into one row, **do not combine `fct_orders` order-count measures with `fct_delivery_performance` order-count measures in the same query** — the counts come from different grains and will not match.

Use `fct_delivery_performance` measures when you want to analyze delivery performance characteristics by state and time period alongside order attributes. Use `fct_orders` measures when you need accurate order counts and revenue figures.

## Example Queries

**Revenue by customer segment:**
Dimensions: `fct_rfm_segments.segment` · Measures: `fct_orders.total_gross_revenue`, `fct_orders.count_orders`, `fct_rfm_segments.count_customers`

**Late rate trend by month:**
Dimensions: `fct_orders.order_date_month` · Measures: `fct_orders.count_orders`, `fct_orders.count_late_orders`, `fct_orders.late_rate`

**Delivery performance by seller state:**
Dimensions: `fct_delivery_performance.seller_state` · Measures: `fct_delivery_performance.avg_delivery_days`, `fct_delivery_performance.avg_late_rate`, `fct_delivery_performance.avg_review_score`

**At-risk customers:**
Filter: `fct_rfm_segments.segment` = "At Risk" OR "Cant Lose Them" · Dimensions: `fct_rfm_segments.customer_unique_id`, `fct_rfm_segments.rfm_score` · Measures: `fct_rfm_segments.total_lifetime_revenue`, `fct_rfm_segments.avg_recency_days`

## Deployment Notes

- **Connection name** in `olist.model.lkml` is `snowflake_olist` — update to match your Looker instance's Snowflake connection name.
- This project is designed for Looker (LookML IDE). It cannot run standalone; it requires a Looker instance connected to the `OLIST_ANALYTICS` Snowflake database.
- As a portfolio piece, the LookML demonstrates semantic layer design: column→dimension mapping, measure definitions, grain-aware join documentation, and derived dimensions — the same patterns used in production Looker projects.
