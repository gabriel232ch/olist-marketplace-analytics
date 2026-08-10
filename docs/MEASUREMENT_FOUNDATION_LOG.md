# Stage 5B measurement-foundation log

## Scope and validation environment

Stage 5B resolves measurement rules and builds reusable foundations only. It does not perform marketplace baseline, growth, opportunity, root-cause, ranking or recommendation analysis.

The SQL was first tested in a clean PostgreSQL 18 validation environment rebuilt from the nine immutable CSVs and the repository scripts. The same measurement views and reconciliations were then deployed to the persistent `olist_portfolio` database. No credentials or machine-specific connection strings are stored in the project.

Validation sequence:

1. existing schemas/raw/staging scripts and nine CSV imports;
2. [`07_measurement_rule_profile.sql`](../sql/07_measurement_rule_profile.sql);
3. [`08_create_measurement_foundations.sql`](../sql/08_create_measurement_foundations.sql);
4. [`09_measurement_reconciliation.sql`](../sql/09_measurement_reconciliation.sql) plus individually repeated core reconciliations.

## Resolved measurement decisions

### Reporting periods

- Stable monthly window: **2017-01-01 through 2018-08-31**.
- Matched growth comparison: **January–August 2017 versus January–August 2018**.
- September 2016, October/December 2016, September 2018 and October 2018 are excluded from normal growth comparison because the source is sparse/partial.
- Commercial and primary fulfillment reporting use purchase cohorts. Delivery month may be used only for a separately labeled operational-workload view.

The source has 800–7,544 placed orders per month from January 2017 through August 2018. September 2018 has 16 placed orders and no delivered orders; October 2018 has 4 placed orders and no delivered orders.

### Review selection

Use the latest `review_answer_timestamp` per `order_id`, with `review_creation_date` and `review_id` as deterministic descending tie-breakers.

- Reviewed orders: 98,673.
- Orders with multiple review rows: 547.
- Orders with conflicting scores: 202.
- Latest-timestamp ties: 0.
- Latest-selected average score: 4.0864.
- Average of each order's review rows: 4.0868.

The near-identical averages and zero latest-timestamp ties support the latest-answer rule while multiplicity/conflict flags remain visible for sensitivity checks.

### Volume and confidence policy

For rate-based seller, category-state and route comparisons:

| Confidence label | Eligible denominator | Use |
|---|---:|---|
| High | 400+ orders | Headline-eligible; worst-case approximate 95% margin of error for a proportion is no more than 5 percentage points. |
| Medium | 100–399 orders | Ranked decision evidence with visible denominator; worst-case approximate margin of error is no more than 10 points at the floor. |
| Exploratory | 30–99 orders | Investigate only; do not assign Grow/Fix/Deprioritize as a final posture. |
| Insufficient | Fewer than 30 orders | Appendix or pooled analysis only. |

Observed delivered-order distributions support these bands:

| Segment grain | Segments | 30+ | 100+ | 400+ |
|---|---:|---:|---:|---:|
| Category × customer state | 1,388 | 375 | 173 | 50 |
| Seller | 2,970 | 627 | 210 | 30 |
| Seller state × customer state | 412 | 125 | 71 | 31 |

Review-based headline comparisons additionally require at least 95% review coverage. All 173 category-state segments with at least 100 delivered orders exceed 96.84% coverage; median coverage is 99.38%.

### Populations and anomaly rules

| Population | Eligible orders |
|---|---:|
| All-order audit | 99,441 |
| Delivered commercial | 96,478 |
| On-time eligible | 96,470 |
| Approval-valid | 96,464 |
| Handling-valid | 95,112 |
| Handling-valid, single-seller | 93,870 |
| Carrier-valid | 96,446 |
| Lead-time valid | 96,470 |
| Item-bearing multi-seller orders | 1,278 |

Missing or reversed timestamps are excluded only from the duration that requires them; they are not deleted or converted to zero. Seller-handling comparisons use single-seller orders as the primary attribution population because the carrier-handoff timestamp is order-level.

### Customer/RFM suitability

- Delivered customers: 93,358.
- Observed repeat customers: 2,801 (3.00%).
- Customers with an equal 365-day follow-up window: 21,665.
- Repeat customers within that window: 981 (4.53%).

Classic RFM remains a Tier-3 appendix/suitability analysis, not a headline decision stream. The finite observation window and sparse repeats do not support strong customer-lifetime claims.

### Geolocation decision

A ZIP-prefix centroid is deferred. State-level seller/customer routes are sufficient for the core framework, while raw geolocation has repeated observations and incomplete customer/seller ZIP coverage. Approximate distance should be added only if a later route diagnosis demonstrates material incremental value.

## Created measurement foundations

| View | Grain | Purpose |
|---|---|---|
| `analytics.measurement_parameters` | One rule row | Stable periods, matched windows, confidence bands and review-coverage rule |
| `analytics.order_review_selected` | One reviewed order | Deterministic review selection plus multiplicity/conflict flags |
| `analytics.order_measurement_base` | One order | Commercial populations, item/payment summaries, status, periods, fulfillment intervals and selected review |
| `analytics.item_measurement_base` | One item line | Category × customer-state × seller allocation without child-table fanout |
| `analytics.customer_measurement_base` | One `customer_unique_id` | Repeat/RFM suitability with equal-follow-up flags |

## Reconciliation evidence

All foundation keys are unique:

| Foundation | Rows | Distinct keys |
|---|---:|---:|
| Order review selected | 98,673 | 98,673 |
| Order measurement base | 99,441 | 99,441 |
| Item measurement base | 112,650 | 112,650 |
| Customer measurement base | 96,096 | 96,096 |

Raw, staging and analytics totals match exactly:

| Measure | Raw | Staging | Analytics |
|---|---:|---:|---:|
| Item rows | 112,650 | 112,650 | 112,650 |
| Item GMV proxy | 13,591,643.70 | 13,591,643.70 | 13,591,643.70 |
| Freight | 2,251,909.54 | 2,251,909.54 | 2,251,909.54 |
| Payment rows | 103,886 | 103,886 | 103,886 |
| Payment value | 16,008,872.12 | 16,008,872.12 | 16,008,872.12 |

Delivered commercial value also reconciles independently between order and item foundations:

- Delivered item GMV proxy: 13,221,498.11.
- Delivered freight: 2,198,275.64.
- Delivered review coverage: 95,832 / 96,478 = 99.3304%.
- On-time partition: 89,936 on-time + 6,534 late = 96,470 eligible orders.

## Stage 5B gate

**SQL design, clean-environment validation, and persistent-database deployment passed.** Population, period, review, confidence, and anomaly rules are resolved; all grains and totals reconcile. Downstream analysis uses these validated foundations without redefining their populations or join rules.
