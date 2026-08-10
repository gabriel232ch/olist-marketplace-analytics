# Stage 5D opportunity and root-cause diagnostics

## Method and decision eligibility

The primary opportunity grain is **category × customer state**. Seller and seller-state → customer-state route views are separate drill-downs, so their measures are never joined at child grain and multiplied.

For a rate-based segment to enter a ranked decision, it needs at least 100 current-period delivered orders and at least 95% review coverage. Among the 104 eligible category-state peers, the operating benchmarks were:

| Peer statistic | Value |
|---|---:|
| On-time P25 | 90.03% |
| On-time median | 93.32% |
| Low-review median | 13.24% |
| Low-review P75 | 16.89% |
| Current GMV P75 | R$56,422.62 |
| Interstate GMV-share P75 | 97.23% |
| Top-seller-share P75 | 23.24% |

These are observed peer thresholds, not universal service standards.

## Commercially attractive but constrained markets

Six top-quartile-value category-state segments fail either the bottom-quartile on-time guardrail or the top-quartile low-review guardrail:

| Category × customer state | Orders | Current GMV proxy | GMV change | On-time | Low-review | Observed late orders |
|---|---:|---:|---:|---:|---:|---:|
| watches_gifts × RJ | 488 | R$100,773.88 | +R$70,247.73 | 86.68% | 21.16% | 65 |
| bed_bath_table × RJ | 646 | R$66,362.41 | +R$33,191.18 | 83.59% | 23.58% | 106 |
| bed_bath_table × MG | 554 | R$64,342.58 | +R$30,067.76 | 90.43% | 19.23% | 53 |
| office_furniture × SP | 286 | R$60,553.92 | +R$33,051.35 | 93.01% | 21.13% | 20 |
| sports_leisure × RJ | 456 | R$58,815.48 | +R$29,012.01 | 81.36% | 23.73% | 85 |
| computers_accessories × RJ | 490 | R$58,321.85 | +R$26,951.75 | 84.49% | 24.22% | 76 |

Together they represent 2,920 orders, R$409,170.12 of current GMV exposure, R$222,521.78 of observed GMV growth and 405 late orders. If each segment merely matched the eligible peer median on-time rate, the arithmetic benchmark gap is 210 orders. That is a scenario, not a forecast of preventable failures.

Four of the six are Rio de Janeiro demand segments. Their high interstate shares—83.14% to 99.08%—are consistent with route/supply friction, but do not prove distance or carrier causality.

## Scalable and defendable markets

- `stationery × SP`: 622 orders, R$55,371.45 current GMV, +R$41,861.02 change, 95.34% on-time and 6.63% low-review.
- `housewares × MG`: 397 orders, R$47,202.62 current GMV, +R$34,085.90 change, 94.71% on-time and 11.42% low-review.

Both have medium growth confidence and exceed the positive-change median among adequately observed growing peers while passing the strong-execution rule. They are qualified Grow candidates rather than claims of untapped market size.

Thirteen high-scale, strong-execution segments form the Defend portfolio. They account for 12,561 orders and R$1,575,723.47 of current GMV exposure. The largest are `health_beauty × SP`, `sports_leisure × SP`, `housewares × SP`, and `furniture_decor × SP`.

## Seller portfolio

Among 93 sellers with at least 100 orders and at least 95% review coverage:

- on-time P25 is 89.83% and the median is 92.89%;
- low-review P75 is 16.67%;
- current GMV P75 is R$33,636.03.

Ten high-value sellers fail an execution guardrail. Together they represent 4,508 orders, R$789,760.59 current GMV exposure, 503 late orders and a 189-order gap to the eligible seller median on-time rate. The largest is seller `4869f7a5dfa277a7dca6462dcf3b52b2`: 716 orders, R$136,164.90 current GMV and 88.69% on-time.

Handling-time evidence distinguishes likely seller-process cases. Seller `7c67e1448b00f6e969d365cea6b010ab` has a 330.3-hour median handling proxy and a 27.70% low-review rate; seller `2eb70248d66e0e3ef83659f71b244378` has a 232.8-hour median handling proxy and a 47.28% low-review rate. Category and route mix remain alternative explanations.

## Route concentration and fulfillment ownership

Fifty current-period routes have at least 100 delivered orders. Their late-rate median is 7.72% and P75 is 11.92%. Thirteen routes exceed P75, covering 8,893 orders, R$1,189,322.92 current GMV and 1,439 late orders.

The largest risk route is **SP → RJ**:

- 4,155 delivered orders;
- R$514,114.29 GMV proxy;
- 653 late orders / 15.72% late rate;
- 10-day median lateness among late orders and 31.8-day P90;
- 41.3-hour median handling and 222.7-hour median carrier time.

SP → RJ contributes 45.38% of late orders and 43.23% of GMV across the 13 high-late routes. Its stage medians do not exceed the P75 stage-duration thresholds, so promise setting and category/seller mix must be tested alongside carrier performance. SP → BA, SP → CE and SP → PA show clearer above-P75 carrier-time signals.

## Delay severity and reviews

| Delivery timing band | Eligible orders | Reviewed orders | Low-review rate | Average review |
|---|---:|---:|---:|---:|
| At least 7 days early | 39,514 | 39,339 | 9.14% | 4.315 |
| On time, within 6 days | 9,185 | 9,129 | 9.90% | 4.224 |
| 1–2 days late | 842 | 834 | 24.10% | 3.554 |
| 3–7 days late | 1,470 | 1,437 | 64.79% | 2.184 |
| 8+ days late | 1,766 | 1,723 | 80.21% | 1.657 |

Low reviews are strongly associated with lateness severity, especially after three days. The comparison is observational: product quality, damage, seller communication and review response behavior may contribute.

## Multi-seller sensitivity

Multi-seller delivered orders have a 0.76% late rate but a 49.62% low-review rate, compared with 7.83% and 12.82% for single-seller orders. Their median lead time is lower, but their promises may be more conservative and order complexity may create non-delivery dissatisfaction. This mixed evidence rejects a simple “multi-seller causes lateness” story and supports a separate experience investigation.

## Hypothesis disposition

| Hypothesis | Result | Reason |
|---|---|---|
| H1 growth concentration | Supported | Top 10 categories, top 5 states and top 100 sellers explain 67.58%, 76.03% and 63.10% of GMV change. |
| H2 scalable category-state opportunities | Supported, narrow | Two medium-confidence Grow candidates pass commercial and operating rules. |
| H3 attractive but constrained segments | Supported | Six high-value segments fail peer execution guardrails. |
| H4 route concentration | Supported | Thirteen high-late routes contain 1,439 late orders; SP → RJ supplies 45.38%. |
| H5 fulfillment-stage ownership | Partially supported | Seller-handling and carrier-time signals differ, but no carrier ID or causal control exists. |
| H6 delay severity and reviews | Supported as association | Low-review rates rise from 9.90% near on-time to 64.79% at 3–7 days late and 80.21% at 8+ days late. |
| H7 high-value weak sellers | Supported | Ten top-quartile-value sellers fail a peer guardrail. |
| H8 strategic supply concentration | Partially supported | Concentration and local-seller scarcity are measurable; substitutability/capacity are not. |
| H9 demand-supply mismatch | Supported as a signal | Several material interstate-heavy markets have weak execution or sparse local supply. |
| H10 multi-seller complexity | Mixed | Low lateness but extremely high low-review incidence; simple lateness mechanism rejected. |
| H11 order-volume versus AOV growth | Supported | 99.40% of GMV change is allocated to delivered-order volume. |
| H12 RFM suitability | Rejected for headline use | Only 4.53% repeat within an equal 365-day follow-up cohort. |

## Stage 5D gate

**Passed in the isolated PostgreSQL 18 validation database.** All category-state, seller and route GMV allocations reconcile to R$7,218,125.12; output grains are unique; all 104 ranked category-state candidates pass volume and review-coverage rules; and alternative explanations are retained.
