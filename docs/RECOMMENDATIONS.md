# Stage 5F management recommendations

These recommendations describe what Olist could test next. They do not claim an implemented improvement or a causal effect.

## 1. Fix six high-value category-state markets before stimulating more demand

- **Evidence and baseline:** 2,920 orders and R$409,170.12 current GMV exposure; 405 late orders. All six are top-quartile current-value segments and fail the 90.03% on-time P25 or 16.89% low-review P75 guardrail.
- **Priority segments:** `watches_gifts × RJ`, `bed_bath_table × RJ/MG`, `sports_leisure × RJ`, `computers_accessories × RJ`, and `office_furniture × SP`.
- **Action:** pause incremental demand activation in these cells; open seller/category/route drill-downs and create a corrective plan for the dominant failure stage.
- **Owner:** Marketplace lead accountable; seller-management and logistics leads own diagnosed sub-actions.
- **Trigger:** segment remains below 90.03% on-time or above 16.89% low-review for two monthly cohorts with at least 100 trailing orders.
- **Primary KPI:** on-time rate and low-review rate, with numerator and eligible/reviewed denominator.
- **Guardrail:** delivered orders and GMV exposure must not fall materially without an intentional commercial decision; monitor freight burden and review coverage.
- **Validation:** phased pilot by seller or route with pre-period and matched untreated comparison; test category/route mix before attribution.
- **Confidence:** high for observed exposure; medium for addressability.

## 2. Prioritize the SP → RJ lane, then carrier-heavy Northeast/North lanes

- **Evidence and baseline:** SP → RJ has 4,155 orders, R$514,114.29 GMV, and 653 late orders / 15.72% late versus a 7.72% route median and 11.92% P75. It contains 45.38% of late orders across the 13 high-late routes.
- **Action:** audit promise-date calibration, category/seller mix, handoff batching and carrier performance for SP → RJ. In parallel, review clearer carrier-time signals on SP → BA, CE and PA.
- **Owner:** Logistics operations; marketplace analytics supplies route/category/seller controls.
- **Trigger:** trailing route late rate remains above 11.92% with at least 100 delivered orders.
- **Primary KPI:** route late rate and P90 late days.
- **Guardrail:** freight burden, promised lead time, delivered-order conversion and customer review response coverage.
- **Validation:** compare matched seller/category cohorts and, where operationally possible, stagger a carrier or promise-setting change.
- **Confidence:** high for route concentration; medium-low for mechanism because carrier identity and exact distance are absent.

## 3. Protect 13 strong, high-scale category-state engines

- **Evidence and baseline:** 12,561 orders and R$1,575,723.47 current GMV exposure with at/above-median on-time performance and at/below-median low-review incidence. Major engines include `health_beauty × SP`, `sports_leisure × SP`, `housewares × SP`, and `furniture_decor × SP`.
- **Action:** assign service-level monitoring and seller-capacity reviews to preserve reliability as volume grows; avoid indiscriminate interventions that could disrupt healthy supply.
- **Owner:** Marketplace/commercial lead with seller-management support.
- **Trigger:** on-time drops below 93.32% or low-review rises above 13.24% for a sufficiently populated trailing cohort.
- **Primary KPI:** delivered orders and GMV proxy, paired with on-time and low-review guardrails.
- **Guardrail:** seller concentration, interstate share and freight burden.
- **Validation:** monthly cohort dashboard with change alerts and seller concentration drill-downs.
- **Confidence:** high for current posture; durability beyond the extract is unknown.

## 4. Run controlled growth tests in stationery × SP and housewares × MG

- **Evidence and baseline:** together, 1,019 orders, R$102,574.07 current GMV, +R$75,946.92 GMV change and 50 late orders. Both have medium growth confidence and pass strong-execution rules.
- **Action:** test seller development, assortment visibility or merchandising in limited increments, separately by segment.
- **Owner:** Marketplace/commercial lead; seller-management lead checks supply capacity.
- **Trigger:** proceed only while on-time remains at/above 93.32%, low-review at/below 13.24%, and review coverage at/above 95%.
- **Primary KPI:** incremental delivered orders and GMV proxy versus a matched holdout or staggered rollout.
- **Guardrail:** on-time, low-review, seller concentration, freight burden and cancellation/unavailability.
- **Validation:** pre-register duration, treated sellers/products and holdout; do not interpret observational growth as test lift.
- **Confidence:** medium; no TAM, marketing exposure or inventory data exists.

## 5. Create a targeted seller-improvement portfolio, not a worst-rate blacklist

- **Evidence and baseline:** ten high-value weak-execution sellers represent 4,508 orders, R$789,760.59 current GMV exposure and 503 late orders. A peer-median arithmetic scenario gives a 189-order gap. Seller `4869f7a5dfa277a7dca6462dcf3b52b2` is the largest exposure; sellers `7c67...` and `2eb7...` show unusually long handling proxies.
- **Action:** segment the ten sellers into seller-handling, route/carrier, mixed, and review-quality diagnoses; agree on seller-specific corrective tests before changing commercial status.
- **Owner:** Seller-management lead; logistics joins route-driven cases.
- **Trigger:** seller remains top-quartile GMV and below 89.83% on-time or above 16.67% low-review with at least 100 orders and 95% review coverage.
- **Primary KPI:** seller on-time and low-review rate; median/P90 handling where attribution is valid.
- **Guardrail:** delivered GMV/orders, category assortment, state reach and concentration dependence.
- **Validation:** single-seller orders for handling attribution, category/route-matched comparisons, and post-action monitoring.
- **Confidence:** high for prioritization; medium for the correct intervention owner.

## Stage 5F gate

**Passed.** Every action has an evidence baseline, affected scale, owner, trigger, KPI, guardrail, limitation and validation method. No recommendation is described as implemented impact.
