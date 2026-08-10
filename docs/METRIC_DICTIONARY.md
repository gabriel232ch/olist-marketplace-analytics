# Analytics metric and population dictionary

## Status and interpretation rules

This dictionary defines the implemented measurement architecture. “Finalized” means the business rule has passed the applicable analytics validation gate.

- Delivered item GMV is a marketplace sales-value proxy, not Olist revenue or profit.
- Every rate must publish its numerator and denominator.
- Commercial trend uses purchase timing unless a specific operational workload question requires delivery timing.
- Item, payment and review children must be aggregated to the target grain before they are joined.
- A metric is not headline-ready until an independent reconciliation query passes.

## Analytical populations

| ID | Population | Inclusion | Exclusion/anomaly treatment | Date basis | Primary uses | Status |
|---|---|---|---|---|---|---|
| P0 | All-order audit | Every row in `staging.orders` | None; retain status and anomaly flags | Purchase timestamp | Population reconciliation, status coverage and exclusions | Finalized |
| P1 | Placed-demand orders | All order statuses, one row per order | Do not call item value from canceled/unavailable orders realized GMV | Purchase timestamp | Placed-order trend, status outcomes, cancellation/unavailability denominator | Finalized |
| P2 | Delivered commercial | `order_status = 'delivered'` and at least one item row | The 8 delivered orders missing customer-delivery time may remain for delivered GMV/orders, but not time-based KPIs | Purchase timestamp | Delivered orders, delivered item GMV, AOV, commercial contribution | Finalized |
| P3 | On-time eligible | P2 plus non-null customer-delivery and estimated-delivery timestamps; customer delivery not before purchase | Exclude missing/invalid required timestamps and report exclusions | Purchase cohort; delivery-date cut only for an explicit workload view | On-time/late rate and delay severity | Finalized |
| P4a | Approval-valid | Delivered order with approval and purchase timestamps where approval ≥ purchase | Exclude invalid/missing interval only from approval metrics | Purchase cohort | Purchase-to-approval time | Finalized |
| P4b | Handling-valid | Delivered order with approval and carrier timestamps where carrier ≥ approval and carrier ≥ purchase | Exclude and count chronology anomalies; primary seller analysis uses single-seller orders | Purchase cohort | Seller/handling time | Finalized |
| P4c | Carrier-valid | Delivered order with carrier and customer-delivery timestamps where delivery ≥ carrier | Exclude and count the 23 known reverse intervals | Purchase cohort | Carrier/logistics time | Finalized |
| P4d | Lead-time valid | Delivered order with purchase and customer-delivery timestamps where delivery ≥ purchase | Exclude missing/invalid required timestamps | Purchase cohort | Total order lead time | Finalized |
| P5 | Review eligible | Latest answered review per order using answer timestamp, creation timestamp and review ID as descending deterministic order | Always report review coverage and retain multiple/conflicting-review flags | Purchase cohort | Average review and low-review rate | Finalized |
| P6 | Customer longitudinal | `customer_unique_id` attached to delivered commercial orders | Equal 365-day follow-up required for repeat comparison; classic RFM remains secondary because equal-window repeat rate is 4.53% | First-purchase cohort | Observed repeat behavior and suitability test | Finalized for secondary use |
| P7 | Delivered item segment | Item rows belonging to P2 orders | Item GMV is attributed to that item’s seller/category; distinct orders are not additive across seller/category segments | Order purchase timestamp | Category × state × seller analysis | Finalized |
| P8 | Curated location | No object in the core foundation | State-level routes are sufficient; never join raw geolocation observations directly. Reconsider only if distance adds material diagnostic value. | Not a reporting period | Optional future distance sensitivity | Deferred by design |

### Status treatment

- `delivered` defines realized delivered-order and delivered-GMV populations.
- `canceled` and `unavailable` remain visible outcomes in P1 and form separate numerators; they are not delivered GMV.
- `shipped`, `invoiced`, `processing`, `created` and `approved` remain in placed-demand/status reporting but are excluded from realized delivery KPIs.
- The dataset has no complete returns/refunds outcome; do not imply that delivered GMV is net of returns.

## Reporting-period rules

| Question | Primary date | Rule |
|---|---|---|
| Marketplace demand and commercial contribution | `order_purchase_timestamp` | Group orders/items by purchase cohort so demand and its later outcome remain attached to when the order was placed. |
| Fulfillment performance | Purchase cohort | Primary view supports commercial decisions and controls right-censoring. A delivery-month view may be added only as an operational workload view and must be labeled separately. |
| Cancellation/unavailability | `order_purchase_timestamp` | Numerator and denominator come from the same purchase cohort. |
| Reviews | Order purchase cohort | Review is an outcome attached back to the purchased order; review creation month is not the commercial trend date. |
| Customer repeat | First-purchase cohort | Compare only cohorts with equal observable follow-up windows. |
| Growth | Complete comparable periods only | Stable monthly window is January 2017–August 2018. Matched growth uses January–August 2017 versus January–August 2018. Sparse/partial 2016 and September–October 2018 are excluded. |
| Year over year | Same complete calendar months | Use only where both periods are complete and sufficiently populated; otherwise use sequential complete periods with explicit labels. |

The baseline/current comparison window is finalized from the Stage 5B profile. Primary commercial and fulfillment analysis uses purchase cohorts; a delivery-month view must be separately labeled as operational workload.

## Commercial and growth metrics

| ID | Metric and business meaning | Formula; numerator / denominator | Population and grain | Exclusions / limitations | Validation | Status |
|---|---|---|---|---|---|---|
| M01 | Placed orders — observed demand attempts | `COUNT(DISTINCT order_id)` | P1; period/segment | Includes all statuses; not realized sales | Reconcile to status counts and P0 | Finalized |
| M02 | Delivered orders — realized order count proxy | `COUNT(DISTINCT order_id)` | P2; period/segment | Requires an item for commercial use; distinct orders across item segments are not additive | Reconcile P2 orders to item-bearing delivered orders | Finalized |
| M03 | Delivered item GMV proxy — observable marketplace item value | `SUM(order_items.price)` for P7 | Item, then period/segment | Excludes freight; not Olist revenue/profit or net of returns | Reconcile segment sum to P2 item-price total | Finalized |
| M04 | Delivered AOV proxy — item value per delivered order | M03 / M02 | Period/segment | For category/seller cuts, denominator is distinct orders containing that segment and results are non-additive across segments | Recompute from independent order-level item summaries | Finalized |
| M05 | Delivered customers — observed buying identities | `COUNT(DISTINCT customer_unique_id)` | P2; period/segment | Identity quality and limited history constrain lifetime interpretation | Reconcile customer/order bridge and null coverage | Finalized |
| M06 | Observed purchase frequency | Delivered orders / delivered customers | P6 cohort/period | Not lifetime frequency; classic RFM remains Tier 3 because repeats are sparse | Reconcile numerator/denominator to M02/M05 | Finalized for secondary use |
| M07 | Absolute GMV change | Current complete-period M03 − prior comparable-period M03 | Marketplace/segment × period | Sensitive to window choice and absent inflation/promotion controls | Reconcile segment changes to marketplace change | Finalized after period gate |
| M08 | GMV growth rate | M07 / prior-period M03 | Segment × period | Do not rank zero/tiny bases; show absolute change beside rate | Recompute from period totals; flag denominator floor | Finalized after volume rule |
| M09 | Contribution to GMV change | Segment M07 / marketplace M07 | Segment × period | Unstable if marketplace change is near zero; positive and negative contributions should remain visible | Sum mutually exclusive segment contributions to marketplace change | Finalized after period gate |
| M10 | Items per delivered order | Count of item rows / M02 | P7 aggregated to order/segment | Item line is treated as an item proxy; source has no separate quantity field | Reconcile item rows and distinct orders | Finalized |
| M11 | Average item value | M03 / count of delivered item rows | P7; period/segment | Product/mix proxy, not unit price where lines could differ conceptually | Reconcile to M03 and item count | Finalized |

## Supply, concentration and geography metrics

| ID | Metric and business meaning | Formula; numerator / denominator | Population and grain | Exclusions / limitations | Validation | Status |
|---|---|---|---|---|---|---|
| M12 | Active sellers | Distinct `seller_id` with ≥1 P7 item in period/segment | Category/state/period | One seller can be active in multiple segments; counts are non-additive | Reconcile seller-item bridge | Finalized |
| M13 | Seller top-1/top-3 share | Largest seller(s) M03 / segment M03 | Category or category × state × period | Item GMV proxy only; does not prove replaceability | Sum seller shares and inspect ties | Finalized |
| M14 | Seller HHI | Sum of squared seller M03 shares within segment | Category or category × state × period | Describes concentration, not competition law or causal risk | Seller shares must sum to 1 within rounding | Finalized |
| M15 | Interstate fulfillment share | Delivered item/order exposure where seller state ≠ customer state / eligible delivered exposure | P7 item or order, explicitly labeled | Item and order versions answer different questions; no distance inference | Reconcile same-state + interstate to eligible total | Finalized |
| M16 | Local active seller availability | Distinct active sellers in the customer state for category/period | Category × customer state | Presence is not capacity, inventory or assortment depth | Reconcile seller/category/state bridge | Finalized as an availability signal |
| M17 | Seller geographic reach | Distinct customer states or customers served by seller | Seller × period | Reach does not indicate profitable or intentional coverage | Reconcile distinct destinations to seller items | Finalized |

## Fulfillment and customer-experience metrics

| ID | Metric and business meaning | Formula; numerator / denominator | Population and grain | Exclusions / limitations | Validation | Status |
|---|---|---|---|---|---|---|
| M18 | On-time delivery rate | Orders with `delivered_customer_date::date <= estimated_delivery_date::date` / P3 orders | Order, then segment | Estimated dates are midnight timestamps, so calendar-date comparison is used; promise quality is unknown | On-time + late = P3 denominator | Finalized |
| M19 | Late rate | Orders with actual delivery date after estimated date / P3 orders | Order, then segment | Same denominator caveats as M18 | Must equal 1 − M18 within rounding | Finalized |
| M20 | Delay severity | `GREATEST(actual_delivery_date - estimated_delivery_date, 0)` in days; median/P75/P90 and total days | P3 late orders, then segment | Use calendar-day definition consistently; zeros belong in all-delivered distribution only when labeled | Reconcile late-order count to M19 numerator | Finalized |
| M21 | Approval time | Approval timestamp − purchase timestamp; median/P75/P90 | P4a order | Excludes missing/invalid intervals; not necessarily payment-processing time only | Publish included/excluded counts and nonnegative range | Finalized |
| M22 | Seller-handling proxy | Carrier handoff − approval; median/P75/P90 | P4b order; single-seller primary seller view | Handoff is order-level; multi-seller attribution is unsafe without sensitivity analysis | Publish seller-count mix and interval exclusions | Finalized with attribution rule |
| M23 | Carrier-time proxy | Customer delivery − carrier handoff; median/P75/P90 | P4c order/route | No carrier identity; excludes 23 known reverse intervals | Publish included/excluded counts and nonnegative range | Finalized |
| M24 | Total lead time | Customer delivery − purchase; median/P75/P90 | P4d order | Does not identify ownership by itself | Reconcile to purchase/delivery timestamps and exclusions | Finalized |
| M25 | Cancellation rate | `status='canceled'` orders / P1 orders | Purchase period/segment | Cancellation reason and refund outcome absent | Status numerators sum to P1 | Finalized |
| M26 | Unavailability rate | `status='unavailable'` orders / P1 orders | Purchase period/segment | Reason/stock status absent | Status numerators sum to P1 | Finalized |
| M27 | Average selected review score | Sum latest-selected review score / P5 reviewed orders | Reviewed order/segment | Review nonresponse and product/service factors may bias results | Score range, selected-review uniqueness and coverage | Finalized |
| M28 | Low-review rate | Latest-selected reviewed orders with score 1–2 / P5 reviewed orders | Reviewed order/segment | Must never use all delivered orders as denominator; headline segments require ≥95% coverage | Low + neutral/high bands reconcile to reviewed denominator | Finalized |
| M29 | Review coverage | P5 reviewed orders / eligible order population | Order/segment | Coverage differences can bias comparisons | Reviewed + unreviewed = eligible population | Finalized |
| M30 | Freight burden | Sum freight / (sum item price + sum freight) | P7 item, then segment | Observable charge burden, not logistics cost or margin | Reconcile price/freight totals to staging | Finalized |
| M31 | Multi-seller order share | Orders with >1 distinct seller / item-bearing eligible orders | Order/period | Does not identify which seller controls order-level delivery | Reconcile single + multi-seller orders | Finalized |
| M32 | Current GMV exposure | Current-period M03 inside an action posture or risk segment | Segment portfolio | Describes observable value associated with the segment; it is not uplift, preventable loss or profit | Reconcile mutually exclusive portfolio allocations to current GMV | Finalized |
| M33 | Peer-median late-order gap scenario | `eligible orders × MAX(peer median on-time − segment on-time, 0)` | Qualified segment | Arithmetic benchmark only; assumes peer comparability and is not a forecast or causal effect | Must be nonnegative, no larger than the eligible denominator, and recomputable from visible fields | Finalized |
| M34 | Rule-based action posture | Ordered qualification and peer-threshold rules producing Grow, Defend, Fix, Investigate, Deprioritize, Monitor or Not ranked | Category-state, seller or route | Not a KPI or score; rule order and input evidence must remain visible | Zero ineligible ranked rows; posture rows preserve source grain | Finalized |

## Volume, confidence and coverage policy

- **High confidence:** 400+ eligible orders (worst-case approximate 95% proportion margin of error ≤5 percentage points).
- **Medium confidence:** 100–399 eligible orders (approximately ≤10 points at the floor).
- **Exploratory:** 30–99 eligible orders; investigate but do not assign a final action posture.
- **Insufficient:** fewer than 30 eligible orders; appendix or pooled analysis only.
- Headline review comparisons additionally require at least 95% review coverage.

These are evidence labels, not claims of causal or statistical significance. Exact estimates still show their numerator, denominator and peer benchmark.

## Resolved downstream methods

1. **Growth decomposition:** use the symmetric/Shapley allocation of the order-volume/AOV interaction; the components must reconstruct observed GMV change exactly.
2. **Operational guardrails:** use eligible-peer P25/median/P75 distributions after the 100-order and 95%-review-coverage screens; these are dataset-relative benchmarks, not universal service standards.
3. **Prioritization:** use ordered rules with separate impact, operating-health and confidence fields; no weighted composite score.
4. **Geolocation:** deferred because state-route diagnostics are decision-useful and a ZIP centroid would add approximation and coverage risk.

## Global reconciliation rules

- Every analytics base must preserve its declared primary key and report row count before and after joins.
- M03 plus freight must independently reconcile to staging item totals for the same population.
- Status-level order counts must reconcile to P0/P1 totals.
- P3 on-time and late numerators must partition the eligible denominator.
- Every duration metric must report missing/invalid exclusions and never convert missing timestamps to zero.
- Seller/category/state contributions must reconcile to the parent total only when the segmentation is mutually exclusive; distinct-order metrics across item segments are explicitly non-additive.
- Review outputs must reconcile selected reviewed orders, unreviewed orders and duplicate-review exclusions.
- Headline numbers require a second query using a different aggregation path.
