# Stage 5A analytical workplan

## Sequencing principle

Work proceeds only when the prior gate passes:

1. Stage 5B measurement architecture and reconciled analytics bases.
2. Stage 5C marketplace baseline and growth decomposition.
3. Stage 5D prioritized opportunity/root-cause analyses.
4. Stage 5E opportunity sizing and prioritization.
5. Stage 5F recommendation development.
6. Stage 5G executive synthesis.

No analysis is promoted because it uses sophisticated SQL. It must plausibly change a management decision and satisfy population, grain, benchmark, volume and validation requirements.

## W00 — Measurement foundation

| Field | Plan |
|---|---|
| Analysis ID | W00 |
| Decision supported | Establish which later evidence is trustworthy |
| Business question | Can commercial, fulfillment, review and item-segment metrics be calculated at stable grains without fanout? |
| Hypothesis | Verified order-, fulfillment-, review- and item-level bases will reconcile to staging and expose exclusions explicitly. |
| Why it matters | Every Tier-1 decision depends on a safe denominator and join path. |
| Priority | Prerequisite / Stage 5B |
| Required tables | All relevant `staging.*` tables; geolocation only if separately approved |
| Input grains | Orders: order; items: item line; reviews: review-order association; customers/products/sellers: entity |
| Target grain | One row per order for commercial/fulfillment/review bases; one row per item for seller/category allocation |
| Metrics | Population flags, item GMV/freight, seller count, selected review, fulfillment-valid flags and durations |
| Dimensions | Purchase period, status, category, seller, seller/customer state |
| Benchmark | Staging row counts and independent totals |
| Minimum volume | Not applicable to base construction; coverage distributions are required |
| SQL techniques expected | CTEs, grouped child pre-aggregation, deterministic `ROW_NUMBER`, conditional aggregation and interval logic |
| Validation checks | Key uniqueness, row preservation, population partitions, raw/staging amount reconciliation, exclusion counts and fanout tests |
| Expected output | Documented analytics-base design and validation results before any headline analysis |
| Possible business implication | None directly; enables defensible business interpretation |
| Limitation | Review-selection, stable-period and volume rules require Stage 5B evidence before final approval |

### W00 join contract

- **Left input:** `staging.orders`; grain/key: one row per `order_id`.
- **Right inputs:** each child independently aggregated to one row per `order_id`; entity dimensions joined M:1 by their keys.
- **Expected relationship/output:** 1:1 joins preserving one row per order.
- **Fanout risk:** raw item, payment or review rows would multiply measures.
- **Validation:** output key uniqueness, order count, child coverage and independent item/payment totals.

## A01 — Marketplace growth decomposition

| Field | Plan |
|---|---|
| Analysis ID | A01 |
| Decision supported | Choose which growth engines to defend, investigate or expand |
| Business question | What drives or drags delivered marketplace value? |
| Hypothesis | H1 and H11: change is concentrated and its order-volume versus AOV/mix drivers differ by segment. |
| Why it matters | A rate-only leaderboard does not reveal material contribution or the correct commercial lever. |
| Priority | Tier 1 / Stage 5C |
| Required tables | Reconciled order commercial base and delivered item base from W00 |
| Input grains | One row/order and one row/item, aggregated separately by period/segment |
| Target grain | Complete period × marketplace/category/customer state/seller |
| Metrics | Delivered GMV, delivered orders, AOV, customers, item value, items/order, absolute change, growth and contribution |
| Dimensions | Complete purchase period, category, customer state and seller |
| Benchmark | Prior comparable period, marketplace change and cumulative Pareto share |
| Minimum volume | Period and segment rules set from Stage 5B distributions; show absolute contribution for all, suppress unstable rate rankings |
| SQL techniques expected | Date bucketing, conditional aggregation, lag/window functions, decomposition and Pareto cumulative sums |
| Validation checks | Segment GMV reconciles to marketplace totals; decomposition components reconcile to change; partial months excluded |
| Expected output | Baseline table, trend, contribution analysis and volume-versus-AOV decomposition |
| Possible business implication | Protect material growth engines or investigate meaningful detractors with the correct lever |
| Limitation | No inflation, promotion, assortment availability or external-market controls |

## A02 — Category × geography opportunity map

| Field | Plan |
|---|---|
| Analysis ID | A02 |
| Decision supported | Allocate marketplace resources across category × customer-state markets |
| Business question | Where does attractive demand coincide with scalable marketplace conditions? |
| Hypothesis | H2 and H3: qualified emerging opportunities and material fix-before-growth segments both exist. |
| Why it matters | The largest market is not necessarily the best growth opportunity. |
| Priority | Tier 1 / Stage 5D, then Stage 5E classification |
| Required tables | A01 period outputs, delivered item base, fulfillment base, seller supply summary and review base |
| Input grains | Period × category × state commercial; order-level operations; seller supply aggregated to the same segment |
| Target grain | Complete period × category × customer state |
| Metrics | GMV/orders/growth contribution, AOV, active sellers, concentration, on-time rate, delay severity, review quality and freight burden |
| Dimensions | Category and customer state; seller drill-down only after segment selection |
| Benchmark | Marketplace, category and state peers; prior period; percentiles after distribution inspection |
| Minimum volume | Stage 5B delivered-order/review/confidence tiers; low-confidence segments cannot receive Grow/Fix ranking |
| SQL techniques expected | Multi-stage aggregation, conditional measures, percentile/window comparisons and rule-based classification |
| Validation checks | Mutually exclusive item GMV sums reconcile; distinct orders labeled non-additive; rate numerators/denominators visible |
| Expected output | Evidence map with Grow, Defend, Fix-before-growth, Investigate or Deprioritize posture |
| Possible business implication | Focus resources where commercial upside and service readiness align |
| Limitation | No TAM, margins, inventory, marketing response or competitor data |

## A03 — Supply–demand mismatch

| Field | Plan |
|---|---|
| Analysis ID | A03 |
| Decision supported | Recruit/develop/diversify sellers or investigate logistics in demand-rich markets |
| Business question | Where is customer demand stronger than available or diversified seller supply? |
| Hypothesis | H9: strong category-state demand sometimes coexists with thin/concentrated or geographically distant supply. |
| Why it matters | Demand activation and supply development are different management actions. |
| Priority | Tier 1 / Stage 5D |
| Required tables | Delivered item base, customers, sellers, product/category; optional curated ZIP lookup only after separate gate |
| Input grains | Item-level demand and seller activity separately summarized to category × customer state × period |
| Target grain | Category × customer state × complete period |
| Metrics | Demand GMV/orders/growth, active/local sellers, concentration, interstate share, freight burden, on-time rate and delay severity |
| Dimensions | Category, customer state, seller state and seller |
| Benchmark | Category/state peers and seller-depth/concentration distribution |
| Minimum volume | Demand and active-seller floors set after distributions; sparse markets flagged as insufficient evidence |
| SQL techniques expected | Separate demand/supply aggregates, distinct counts, HHI, conditional aggregation and peer percentiles |
| Validation checks | Demand measures reconcile to A02; seller shares sum correctly; no geolocation fanout; ZIP coverage reported if used |
| Expected output | Recruit/diversify, logistics-investigate, fix-before-growth or insufficient-evidence market list |
| Possible business implication | Add/strengthen seller supply where demand is credible, or address route constraints first |
| Limitation | Seller presence is not capacity or inventory; distance remains approximate and optional |

### A03 join contract

- **Left input:** category × customer-state demand summary; one row per segment-period.
- **Right input:** seller-supply summary at the same key; never raw item or geolocation rows.
- **Expected relationship/output:** 1:1 segment join.
- **Fanout risk:** joining item demand directly to sellers/geolocation can multiply GMV.
- **Required pre-aggregation:** distinct active sellers and seller GMV shares by segment; optional ZIP lookup one row/prefix.
- **Validation:** segment GMV before/after join and unmatched location coverage.

## A04 — Fulfillment root-cause decomposition

| Field | Plan |
|---|---|
| Analysis ID | A04 |
| Decision supported | Assign high-impact delivery problems to the right operational owner |
| Business question | Where do delays originate and where are they concentrated? |
| Hypothesis | H4 and H5: high-impact route/seller problems have distinguishable handling versus carrier bottlenecks. |
| Why it matters | Total delay identifies a symptom; stage decomposition makes intervention ownership clearer. |
| Priority | Tier 1 / Stage 5D |
| Required tables | W00 fulfillment base, order seller-count summary, sellers, customers and product/category dimensions |
| Input grains | One fulfillment-valid order; single-seller order for primary seller attribution |
| Target grain | Seller/category/route × complete purchase cohort |
| Metrics | On-time rate, delay days, approval/handling/carrier/lead-time median/P75/P90, freight burden and exposure |
| Dimensions | Seller, category, seller state, customer state, route and single/multi-seller flag |
| Benchmark | Marketplace, category, same-origin/destination and volume-matched peers |
| Minimum volume | Valid-order floor and exclusion-rate guardrail set in Stage 5B |
| SQL techniques expected | Interval arithmetic, percentile functions, flags, peer partitions and Pareto contribution |
| Validation checks | Duration populations/exclusions, nonnegative intervals, percentile sanity, late partition and single-seller coverage |
| Expected output | High-volume bottleneck map with likely owner and alternative explanations |
| Possible business implication | Seller SLA action, carrier/route review, approval investigation or promise calibration |
| Limitation | No carrier identity, capacity, SLA or exact route; order-level handoff limits multi-seller attribution |

## A05 — Seller portfolio

| Field | Plan |
|---|---|
| Analysis ID | A05 |
| Decision supported | Grow, protect, fix, investigate or reassess sellers |
| Business question | Which sellers combine material value, execution quality and strategic importance? |
| Hypothesis | H7 and H8: high-value weak performers and strategically concentrated dependencies are more decision-relevant than worst raw rates. |
| Why it matters | Seller-management capacity should focus on material and addressable exposure. |
| Priority | Tier 1 / Stage 5D–5E |
| Required tables | Delivered item base, order/fulfillment base, seller/category concentration summary and review base |
| Input grains | Item commercial measures and order operational measures independently summarized to seller-period |
| Target grain | Seller × complete period, with category portfolio attributes |
| Metrics | GMV/orders/growth contribution, reach, on-time rate, handling time, low-review rate, freight burden, category dependence/concentration |
| Dimensions | Seller, category portfolio, seller state, customer-state reach and volume tier |
| Benchmark | Category and volume-matched seller peers; marketplace percentiles and Pareto share |
| Minimum volume | Seller order/review floor from Stage 5B; low-confidence sellers remain Investigate/appendix |
| SQL techniques expected | Separate-grain aggregates, window percentiles, HHI/top-share, Pareto and rule-based quadrants |
| Validation checks | Seller GMV reconciles to delivered total; order metrics not item-weighted accidentally; peer partitions stable |
| Expected output | Transparent seller action portfolio with evidence, confidence and likely owner |
| Possible business implication | Protect strategic reliable sellers or prioritize material weak sellers for intervention |
| Limitation | No margin, contract, seller capacity, tenure or true replaceability data |

### A05 join contract

- **Left input:** seller commercial summary; one row per seller-period.
- **Right input:** seller operational/review/concentration summaries; each one row per seller-period.
- **Expected relationship/output:** 1:1 seller-period.
- **Fanout risk:** item-weighting order-level lateness/reviews or multiplying orders across categories.
- **Required pre-aggregation:** order metrics to seller only under the approved single-/multi-seller attribution rule.
- **Validation:** seller GMV total, distinct seller key and comparison with order-level denominators.

## A06 — Customer-experience driver analysis

| Field | Plan |
|---|---|
| Analysis ID | A06 |
| Decision supported | Select operational hypotheses for CX protection or further testing |
| Business question | Which observable operational conditions are associated with poor review outcomes? |
| Hypothesis | H6, with H10 as a gated secondary factor |
| Why it matters | It links operational risk to an observable customer outcome while preserving non-causal language. |
| Priority | Tier 2 / Stage 5D |
| Required tables | One selected review per order, fulfillment base and order-level item complexity summary |
| Input grains | One row/reviewed order after deterministic review reconciliation |
| Target grain | Delay/operational band × relevant peer segment |
| Metrics | Low-review rate, average review, review coverage, on-time/late rate, delay bands, handling/carrier time, freight burden and seller count |
| Dimensions | Delay band, category, route, order complexity and single/multi-seller flag |
| Benchmark | On-time orders, adjacent severity bands and category/route peers |
| Minimum volume | Reviewed-order floor and review-coverage guardrail from Stage 5B |
| SQL techniques expected | Deterministic review selection, banding, conditional aggregation and stratified comparisons |
| Validation checks | One review/order, score range, coverage, numerator/denominator and sensitivity to review-selection rule |
| Expected output | Association profile and shortlist of mechanisms warranting operational validation |
| Possible business implication | Test severe-delay recovery or investigate operational conditions overrepresented in low reviews |
| Limitation | Reviews are selective and product/service factors are unobserved; no causal claim |

## A07 — Repeat/RFM suitability gate

| Field | Plan |
|---|---|
| Analysis ID | A07 |
| Decision supported | Decide whether customer/RFM work belongs in the headline project |
| Business question | Is repeat behavior sufficiently frequent and comparably observed to support a CRM decision? |
| Hypothesis | H12: conventional RFM may be too sparse/censored to be decision-critical. |
| Why it matters | It prevents analytical novelty from replacing business relevance. |
| Priority | Tier 3 / appendix gate |
| Required tables | Customers, order commercial base and first-purchase cohort summary |
| Input grains | One order/customer identity, then one row per `customer_unique_id` |
| Target grain | First-purchase cohort/customer |
| Metrics | Eligible customers, repeat rate, orders/customer, time to repeat and equal follow-up coverage |
| Dimensions | First-purchase cohort; first-order category/experience only if coverage permits |
| Benchmark | Cohorts with equal observation windows |
| Minimum volume | Adequate eligible cohort/repeat counts determined from distribution |
| SQL techniques expected | Cohorting, window functions, first/next order logic and censoring flags |
| Validation checks | Customer bridge uniqueness, observation-window equality and sensitivity to valid-order population |
| Expected output | Include, narrow or exclude decision for customer segmentation/RFM |
| Possible business implication | Request richer history or keep CRM claims out of the portfolio |
| Limitation | Finite marketplace extract is not full customer lifetime history |

## Stage 5E prioritization work package

Stage 5E will not begin with a weighted score. It will compare qualified A02–A05 candidates using:

- Pareto contribution to commercial value, growth or operational exposure;
- rule-based action posture;
- explicit addressability and likely owner;
- separate confidence tier based on volume, coverage and robustness;
- sensitivity to reasonable peer groups, thresholds and period definitions.

Only if rule-based evidence produces too many indistinguishable candidates will a percentile or weighted composite be proposed. Any weight will require a business rationale, visible component values and sensitivity testing.

## Stage 5F recommendation record

Every recommended action must include:

- evidence and comparison baseline;
- affected segment and scale;
- mechanism and plausible alternative explanation;
- action posture and specific action;
- implementation owner;
- expected KPI and guardrail;
- major assumption and risk;
- confidence level;
- additional data/test required before implementation.

## Stage 5G executive output

The final deliverable will contain no more than five headline insights. Each must include magnitude, comparison, segment, trend or mechanism, business implication, recommended action, risk and next validation step. No estimated opportunity will be described as an implemented result.
