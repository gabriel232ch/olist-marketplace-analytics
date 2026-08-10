# Stage 5A hypothesis register

## How to use this register

These are testable propositions, not findings. Priority reflects expected decision value before testing. Minimum-volume thresholds remain unresolved until Stage 5B profiles the actual distributions; no segment will be ranked without showing its numerator, denominator and confidence tier.

## H1 — Marketplace growth concentration

| Field | Definition |
|---|---|
| Hypothesis ID | H1 |
| Business question | Is observable marketplace growth concentrated in a small number of categories, customer states or sellers? |
| Hypothesis | A minority of segments contributes a majority of delivered-GMV change. |
| Why it matters | Concentrated growth changes where commercial protection and expansion resources matter most. |
| Stakeholder | Marketplace/commercial lead; seller-management lead |
| Decision affected | Defend major contributors, diversify dependence, or invest in emerging contributors |
| Required grain | Complete purchase period × category/customer state/seller; item measures aggregated without fanout |
| Required tables | `orders`, `order_items`, `products`, category translation, `customers`, `sellers` |
| Primary KPI | Absolute contribution to delivered-GMV change |
| Diagnostic KPIs | Delivered GMV share, delivered orders, AOV, growth rate, cumulative contribution, top-seller share/HHI |
| Comparison/benchmark | Prior comparable complete period; marketplace total change; Pareto cumulative share |
| Required segmentation | Category, customer state, seller and time; category × state only after baseline |
| Minimum sample requirement | Contribution can be shown for all segments; growth-rate interpretation requires a Stage 5B volume floor |
| Analytical method | GMV decomposition, absolute change, contribution-to-change, Pareto and concentration analysis |
| Expected output | Ranked contribution table plus cumulative-contribution curve and confidence labels |
| What would support it | A small segment set explains a disproportionate share of total positive or negative change |
| What would reject it | Change is broadly distributed and conclusions remain stable across reasonable segment definitions |
| Potential confounders | Partial periods, seasonality, category mix, newly active sellers, cancellations and missing categories |
| Data limitations | No commission revenue, profit, promotions, inventory or external market demand |
| Potential management implication | Protect major contributors, investigate detractors, and monitor concentration exposure |
| Potential new business insight | Growth may depend on fewer marketplace engines than aggregate trends imply |
| Priority | Tier 1 — decision-critical |
| Confidence before testing | High that the data can test concentration; unknown whether concentration is material |

## H2 — Emerging scalable category × state opportunities

| Field | Definition |
|---|---|
| Hypothesis ID | H2 |
| Business question | Are smaller category × customer-state markets growing fast enough, at sufficient scale and with strong execution, to merit expansion? |
| Hypothesis | Some smaller markets contribute meaningful growth while meeting operational guardrails. |
| Why it matters | It can reveal expansion candidates hidden by generic Top-10 rankings. |
| Stakeholder | Marketplace/commercial lead |
| Decision affected | Allocate category-development or seller-supply resources to emerging markets |
| Required grain | Complete period × category × customer state |
| Required tables | `orders`, `order_items`, `products`, translation, `customers`, `sellers`, reconciled reviews |
| Primary KPI | Delivered-GMV contribution to growth, conditional on operational health |
| Diagnostic KPIs | Delivered orders, growth rate, AOV, active sellers, on-time rate, delay severity, review quality, freight burden |
| Comparison/benchmark | Marketplace and category averages; prior comparable period; distribution percentiles after inspection |
| Required segmentation | Category × customer state, with seller depth and concentration |
| Minimum sample requirement | Unresolved; Stage 5B will set a delivered-order floor and confidence bands from observed distributions |
| Analytical method | Contribution analysis followed by rule-based opportunity quadrants and sensitivity checks |
| Expected output | Evidence table classifying qualified markets as Grow, Defend, Fix or Investigate |
| What would support it | Smaller markets show material absolute contribution, sufficient volume and execution at/above defensible peers |
| What would reject it | Apparent growth disappears in complete-period, absolute-contribution or minimum-volume checks |
| Potential confounders | Launch effects, seasonal category demand, seller entry, product-mix change and cross-state supply |
| Data limitations | No total addressable market, marketing exposure, inventory or competitor data |
| Potential management implication | Test seller recruitment, merchandising or demand activation in qualified markets |
| Potential new business insight | Some non-leading markets may be more scalable than larger but operationally weaker markets |
| Priority | Tier 1 — decision-critical |
| Confidence before testing | Medium |

## H3 — Commercially attractive but operationally constrained segments

| Field | Definition |
|---|---|
| Hypothesis ID | H3 |
| Business question | Which commercially material segments should be fixed before additional demand is stimulated? |
| Hypothesis | Some high-value or high-growth segments materially underperform operational benchmarks. |
| Why it matters | Growth investment could amplify customer-experience risk if execution is already weak. |
| Stakeholder | Marketplace/commercial, seller-management and logistics leads |
| Decision affected | Fix-before-growth versus Grow/Defend |
| Required grain | Category × customer state, then seller drill-down; complete purchase cohorts |
| Required tables | `orders`, pre-aggregated items, products, customers, sellers, reconciled reviews |
| Primary KPI | Delivered-GMV exposure in segments failing an operational guardrail |
| Diagnostic KPIs | Late rate, delay days, handling/carrier percentiles, low-review rate, cancellation/unavailability and freight burden |
| Comparison/benchmark | Marketplace, category and volume-matched peer performance |
| Required segmentation | Category × customer state; seller and route diagnostics |
| Minimum sample requirement | Unresolved delivered-order/review floor; expose both impact and confidence |
| Analytical method | Rule-based quadrant, Pareto exposure and root-cause drill-down |
| Expected output | High-impact weak-performance segments with likely owner and diagnostic evidence |
| What would support it | Material segments consistently miss operational peers across more than one quality measure |
| What would reject it | Weak rates are explained by tiny samples, invalid timestamps or composition and vanish under peer comparison |
| Potential confounders | Long-distance routes, category dimensions, multi-seller orders, peak periods and promise-date generosity |
| Data limitations | No carrier identity, SLA contract, inventory status or complaint/refund data |
| Potential management implication | Pause growth stimulation and assign a targeted operational investigation first |
| Potential new business insight | The best commercial-looking market may not be the safest place to add demand now |
| Priority | Tier 1 — decision-critical |
| Confidence before testing | High that the trade-off is testable; mechanism confidence is medium |

## H4 — Route concentration of delivery problems

| Field | Definition |
|---|---|
| Hypothesis ID | H4 |
| Business question | Are delivery problems concentrated in specific seller-state → customer-state routes? |
| Hypothesis | High-volume routes explain a disproportionate share of late deliveries and delay days. |
| Why it matters | Route concentration points to logistics or expectation-setting interventions rather than marketplace-wide action. |
| Stakeholder | Logistics-operations lead |
| Decision affected | Which lanes to investigate, renegotiate, monitor or adjust promises for |
| Required grain | Purchase cohort × seller state × customer state; category as a diagnostic cut |
| Required tables | `orders`, order items, sellers and customers; products for category controls |
| Primary KPI | Route contribution to late-order exposure or total delay days |
| Diagnostic KPIs | Orders, on-time rate, median/P75/P90 carrier time, freight burden, interstate share |
| Comparison/benchmark | Marketplace route average, same-origin/destination peers and volume tier |
| Required segmentation | Seller-state → customer-state route, then seller/category |
| Minimum sample requirement | Unresolved high-volume route floor; low-volume routes may appear only in appendix |
| Analytical method | Pareto, peer comparison and handling-versus-carrier decomposition |
| Expected output | High-impact problem routes with likely stage/owner |
| What would support it | A minority of sufficiently large routes accounts for disproportionate late exposure after mix checks |
| What would reject it | Risk is diffuse or mostly explained by seller/category composition rather than route |
| Potential confounders | Distance, urban/rural mix, category dimensions, seller mix and seasonal congestion |
| Data limitations | No carrier identity, exact route, service level or reliable distance until geolocation is curated |
| Potential management implication | Prioritize lane-level carrier review or promise calibration |
| Potential new business insight | Delivery risk may be a route-system problem rather than a uniformly weak seller problem |
| Priority | Tier 1 — decision-critical |
| Confidence before testing | Medium-high |

## H5 — Fulfillment-stage ownership

| Field | Definition |
|---|---|
| Hypothesis ID | H5 |
| Business question | Can late delivery exposure be separated into approval, seller-handling and carrier stages? |
| Hypothesis | Different high-impact segments have different dominant delay stages, enabling clearer ownership. |
| Why it matters | A single total lead-time metric cannot tell management who should act. |
| Stakeholder | Seller-management and logistics-operations leads |
| Decision affected | Seller SLA improvement, payment/approval investigation, carrier action or promise adjustment |
| Required grain | One fulfillment-valid order; seller attribution uses single-seller primary analysis and multi-seller sensitivity |
| Required tables | `orders`, pre-aggregated order-item seller counts, sellers, customers and products |
| Primary KPI | Median/P75/P90 valid duration by fulfillment stage |
| Diagnostic KPIs | Late rate, delay days, stage share of lead time, orders and invalid-timestamp rate |
| Comparison/benchmark | Marketplace and matched category/route/seller-volume peers |
| Required segmentation | Seller, category, seller-state → customer-state route and order complexity |
| Minimum sample requirement | Unresolved valid-timestamp order floor; publish excluded-anomaly counts |
| Analytical method | Timestamp decomposition, percentile comparisons and contribution to late exposure |
| Expected output | Bottleneck map linking high-impact delay to a plausible operational owner |
| What would support it | Stage-duration patterns differ materially across problem segments and remain after peer cuts |
| What would reject it | Stage differences are small, unstable or dominated by invalid/missing timestamps |
| Potential confounders | Approval method, carrier pickup batching, category bulk, distance and multi-seller orders |
| Data limitations | Handoff is recorded at order level; no carrier ID or internal seller process events |
| Potential management implication | Target the responsible operating team rather than issue a generic seller warning |
| Potential new business insight | Similar total delays may require different actions because their bottlenecks occur at different stages |
| Priority | Tier 1 — decision-critical |
| Confidence before testing | High for valid single-seller orders; medium for multi-seller attribution |

## H6 — Delay severity and review outcomes

| Field | Definition |
|---|---|
| Hypothesis ID | H6 |
| Business question | How are lateness and delay severity associated with customer review outcomes? |
| Hypothesis | Low-review rates rise as delay severity increases, potentially non-linearly beyond material delay bands. |
| Why it matters | It connects operational exposure to an observable customer-experience outcome. |
| Stakeholder | Customer-experience and logistics leads |
| Decision affected | Which delay exposures warrant experience protection or operational testing |
| Required grain | One delivered order with selected order-level review; no review-item fanout |
| Required tables | `orders`, reconciled order reviews; aggregated items for mix and complexity controls |
| Primary KPI | Low-review rate (selected review score 1–2) by delay band |
| Diagnostic KPIs | Average review score, review coverage, on-time rate, delay days and order complexity |
| Comparison/benchmark | On-time delivered orders; adjacent delay bands; category and route peers |
| Required segmentation | Delay band, category, route, freight burden and single/multi-seller flag |
| Minimum sample requirement | Unresolved reviewed-order floor per band/segment; report coverage |
| Analytical method | Descriptive cross-tabs, confidence intervals where practical and stratified comparisons |
| Expected output | Review-outcome gradient with coverage and alternative explanations |
| What would support it | Low reviews are consistently overrepresented in more severe delay bands |
| What would reject it | Review outcomes are flat, inconsistent or explained by review-selection/composition effects |
| Potential confounders | Product quality, seller communication, damaged items, category mix and review response selection |
| Data limitations | Observational association; no complaint text coding, refund data or randomized intervention |
| Potential management implication | Prioritize severe-delay recovery tests and monitor low-review outcomes |
| Potential new business insight | Customer-experience risk may rise sharply after a practical delay threshold rather than linearly |
| Priority | Tier 2 — diagnostic/supporting |
| Confidence before testing | Medium |

## H7 — High-value sellers with weak execution

| Field | Definition |
|---|---|
| Hypothesis ID | H7 |
| Business question | Which commercially important sellers offer the greatest intervention value? |
| Hypothesis | High-value weak-execution sellers represent more addressable exposure than the worst raw-rate sellers. |
| Why it matters | It focuses seller-management effort on material, potentially recoverable marketplace value. |
| Stakeholder | Seller-management lead |
| Decision affected | Protect, fix, develop, monitor or reassess seller relationships |
| Required grain | Seller × complete purchase period |
| Required tables | Items, orders, sellers, products, customers and reconciled reviews |
| Primary KPI | Delivered-GMV exposure combined with operational performance shown as separate axes |
| Diagnostic KPIs | Orders, growth contribution, on-time rate, handling time, low-review rate, reach and freight burden |
| Comparison/benchmark | Volume-matched seller peers, category peers and marketplace percentiles |
| Required segmentation | Seller; category portfolio and customer-state reach |
| Minimum sample requirement | Unresolved seller delivered-order and review floor; confidence tier required |
| Analytical method | Pareto plus commercial-value × execution quadrant; no initial weighted score |
| Expected output | Seller action portfolio with visible evidence and likely owner |
| What would support it | Material sellers fall below peer operational guardrails with sufficient observations |
| What would reject it | Weak sellers are immaterial or performance normalizes after volume/category/route matching |
| Potential confounders | Category, route distance, order complexity, multi-seller attribution and seasonal growth |
| Data limitations | No seller margin, contract, inventory, tenure, capacity or acquisition cost |
| Potential management implication | Prioritize a targeted SLA-improvement or diagnostic program for material sellers |
| Potential new business insight | Intervention value is driven by exposure × performance gap, not worst performance alone |
| Priority | Tier 1 — decision-critical |
| Confidence before testing | High |

## H8 — Strategic seller/category concentration risk

| Field | Definition |
|---|---|
| Hypothesis ID | H8 |
| Business question | Which important categories depend on a small seller base? |
| Hypothesis | Some material categories have high seller concentration and limited apparent replaceability. |
| Why it matters | Concentration creates continuity and bargaining risk even when current performance is strong. |
| Stakeholder | Marketplace/commercial and seller-management leads |
| Decision affected | Protect strategic sellers, diversify supply or monitor dependency |
| Required grain | Category × complete period, with seller contribution distribution |
| Required tables | Items, orders, products, translation and sellers |
| Primary KPI | Seller concentration within category (top-1/top-3 share and HHI) |
| Diagnostic KPIs | Delivered GMV, orders, active sellers, seller growth, performance and geographic reach |
| Comparison/benchmark | Marketplace/category concentration distribution and prior period |
| Required segmentation | Category, then seller and customer-state reach |
| Minimum sample requirement | Material category volume required; threshold set after distribution inspection |
| Analytical method | Concentration metrics, Pareto and seller-removal exposure scenarios with explicit assumptions |
| Expected output | Material categories classified by contribution and supply dependence |
| What would support it | High-value categories rely heavily on very few sellers across periods |
| What would reject it | Seller contribution is diversified or concentrated categories are immaterial/transient |
| Potential confounders | Seller identity fragmentation, product specialization and short observation windows |
| Data limitations | No seller capacity, substitutability, contracts or inventory overlap |
| Potential management implication | Protect critical sellers or recruit diversified supply before scaling demand |
| Potential new business insight | A healthy category can still be strategically fragile because its supply is concentrated |
| Priority | Tier 1 — decision-critical |
| Confidence before testing | High for concentration measurement; medium for replaceability inference |

## H9 — Customer demand versus seller supply mismatch

| Field | Definition |
|---|---|
| Hypothesis ID | H9 |
| Business question | Where is category demand strong relative to local or diversified seller supply? |
| Hypothesis | Some category × customer-state markets combine strong demand with few/local-scarce sellers, high interstate fulfillment, freight burden or weak delivery. |
| Why it matters | It suggests where seller recruitment or supply diversification may unlock safer growth. |
| Stakeholder | Marketplace/commercial, seller-management and logistics leads |
| Decision affected | Recruit/develop sellers, diversify supply, investigate logistics or avoid demand activation |
| Required grain | Category × customer state × complete period; seller supply summarized separately before joining |
| Required tables | Items, orders, products, customers, sellers; optional curated ZIP lookup later |
| Primary KPI | Demand scale/growth versus active seller depth and concentration |
| Diagnostic KPIs | Local seller count/share, interstate share, freight burden, on-time rate, delay severity and reach |
| Comparison/benchmark | Category/state peers, marketplace seller-depth distribution and prior period |
| Required segmentation | Category × customer state; seller state and seller drill-down |
| Minimum sample requirement | Unresolved demand-order and seller-activity floors; confidence labels required |
| Analytical method | Demand-supply evidence matrix, concentration analysis and route diagnostics |
| Expected output | Mismatch markets classified as recruit, logistics-investigate, fix-before-growth or insufficient evidence |
| What would support it | Strong demand coexists with thin/concentrated supply and poorer freight/delivery outcomes |
| What would reject it | Supply depth is adequate or operational outcomes do not differ after category/route comparisons |
| Potential confounders | National specialist sellers, urban density, bulky products, seller capacity and distance |
| Data limitations | No seller capacity/inventory or market potential; ZIP distance remains optional pending curation |
| Potential management implication | Test seller acquisition/development or targeted logistics support in qualified markets |
| Potential new business insight | Growth constraints may come from insufficient supply architecture, not weak customer demand |
| Priority | Tier 1 — decision-critical |
| Confidence before testing | Medium |

## H10 — Multi-seller order complexity

| Field | Definition |
|---|---|
| Hypothesis ID | H10 |
| Business question | Is multi-seller order complexity associated with weaker fulfillment or review outcomes? |
| Hypothesis | Orders involving multiple sellers have worse delivery or review outcomes than comparable single-seller orders. |
| Why it matters | It could identify an order-orchestration or customer-expectation issue. |
| Stakeholder | Marketplace operations and customer-experience leads |
| Decision affected | Whether multi-seller checkout/fulfillment warrants deeper operational investigation |
| Required grain | One order with a distinct-seller count and one reconciled review |
| Required tables | Pre-aggregated order items, orders and reconciled reviews |
| Primary KPI | On-time or low-review rate by single/multi-seller flag |
| Diagnostic KPIs | Total lead time, delay days, items, freight burden, category mix and review coverage |
| Comparison/benchmark | Single-seller orders matched or stratified by volume/category/route where feasible |
| Required segmentation | Seller-count band and order complexity; limited diagnostic cuts only |
| Minimum sample requirement | Must first establish multi-seller prevalence and reviewed delivered-order counts |
| Analytical method | Prevalence gate followed by stratified descriptive comparison |
| Expected output | Go/no-go decision on whether this deserves headline or appendix treatment |
| What would support it | Sufficient multi-seller volume and persistent adverse differences after basic mix controls |
| What would reject it | Multi-seller orders are too rare or differences disappear after composition checks |
| Potential confounders | Item count, category mix, distance, order value and seller quality |
| Data limitations | One order-level delivery timestamp cannot identify which seller caused delay |
| Potential management implication | Investigate orchestration or messaging; do not penalize individual sellers from this result alone |
| Potential new business insight | Complexity at checkout/order level may matter independently of seller performance |
| Priority | Tier 2 if prevalence is sufficient; otherwise Tier 3 appendix |
| Confidence before testing | Low-medium |

## H11 — Order-volume versus AOV/mix growth

| Field | Definition |
|---|---|
| Hypothesis ID | H11 |
| Business question | Is marketplace-value change driven primarily by delivered order volume or AOV/product mix? |
| Hypothesis | Growth drivers differ by period and segment, leading to different commercial actions. |
| Why it matters | More orders may require acquisition/supply action; higher AOV may reflect price or mix and requires a different interpretation. |
| Stakeholder | Marketplace/commercial lead |
| Decision affected | Whether to focus on demand volume, assortment/mix, seller supply or retention investigation |
| Required grain | Marketplace and segment × complete purchase period |
| Required tables | Orders and pre-aggregated items; products/customers/sellers for decomposition |
| Primary KPI | Delivered-GMV change decomposed into delivered-order and AOV effects |
| Diagnostic KPIs | Item value, items per order, customers, observed purchase frequency and category mix |
| Comparison/benchmark | Prior comparable complete period; valid year-over-year window where available |
| Required segmentation | Marketplace, category, customer state and material sellers |
| Minimum sample requirement | Complete comparable periods; segment growth requires Stage 5B volume floor |
| Analytical method | Multiplicative decomposition plus contribution analysis and sensitivity to period selection |
| Expected output | Waterfall/evidence table separating volume and value/mix contributions |
| What would support it | Order and AOV components differ materially across periods or segments |
| What would reject it | Change is negligible or decomposition is unstable because periods are incomplete |
| Potential confounders | Inflation, promotions, assortment change, partial periods and cancellation timing |
| Data limitations | No quantity field beyond item lines, list price, discount, promotion or inflation adjustment |
| Potential management implication | Match the commercial response to the actual growth mechanism |
| Potential new business insight | The same GMV growth rate can conceal very different marketplace dynamics |
| Priority | Tier 1 — decision-critical |
| Confidence before testing | High after reporting-period rules are finalized |

## H12 — Repeat-customer/RFM suitability

| Field | Definition |
|---|---|
| Hypothesis ID | H12 |
| Business question | Is observed repeat behavior sufficient and uncensored enough for customer/RFM analysis to influence strategy? |
| Hypothesis | Repeat purchasing may be too sparse or observation-window-dependent for conventional RFM to be a headline analysis. |
| Why it matters | It prevents a familiar but weak portfolio exercise from distracting from stronger marketplace decisions. |
| Stakeholder | Customer growth/CRM lead |
| Decision affected | Include a bounded repeat analysis, request richer data, or keep RFM out of the headline project |
| Required grain | One `customer_unique_id` with purchase-cohort and observation-window fields |
| Required tables | Customers, orders and pre-aggregated delivered/commercial item value |
| Primary KPI | Share of eligible customers with 2+ valid orders within a comparable observation window |
| Diagnostic KPIs | Orders per customer, time to repeat, cohort coverage, delivered GMV and censoring exposure |
| Comparison/benchmark | Cohorts with equal follow-up windows; not an uncensored all-time ranking |
| Required segmentation | Purchase cohort and, only if supported, first-order experience/category |
| Minimum sample requirement | Adequate eligible cohort size and follow-up; exact rule set after cohort distribution inspection |
| Analytical method | Suitability gate, repeat distribution and equal-window cohort sensitivity |
| Expected output | Explicit decision to include, narrow or exclude RFM/customer segmentation |
| What would support it | Repeat behavior has adequate volume, stable cohort patterns and decision-relevant variation |
| What would reject it | Nearly all customers have one observed order or conclusions depend strongly on unequal follow-up |
| Potential confounders | Guest/account identity, observation censoring, category purchase cycle and missing pre/post history |
| Data limitations | Dataset is a finite marketplace extract, not full customer lifetime history |
| Potential management implication | Avoid unsupported CRM recommendations; request longer customer history if needed |
| Potential new business insight | The most defensible customer conclusion may be that the available data cannot support classic RFM |
| Priority | Tier 3 exploratory gate; promote only if evidence supports it |
| Confidence before testing | High that suitability can be tested; low that RFM will be headline-worthy |

## Prioritization summary

| Tier | Hypotheses |
|---|---|
| Tier 1 | H1, H2, H3, H4, H5, H7, H8, H9, H11 |
| Tier 2 | H6; H10 if prevalence is adequate |
| Tier 3 | H12; H10 if prevalence is inadequate |

Tier-1 status does not guarantee a headline finding. A hypothesis must survive population, benchmark, minimum-volume, reconciliation and robustness checks before it can influence a recommendation.
