# Verified resume bullets

Use only bullets appropriate to the target role and space available. These describe analysis delivered, not recommendations implemented.

## Business Analyst / Business Operations

- Built a decision-oriented PostgreSQL analysis across **9 Olist datasets and 1.55M source rows**, translating marketplace growth, fulfillment, seller, route, and review evidence into transparent Grow/Defend/Fix/Investigate portfolios.
- Decomposed **141.13% matched-period delivered-GMV-proxy growth** and identified that **99.40% of the change was associated with order volume rather than AOV/mix**, while on-time delivery declined **4.23 percentage points**.
- Prioritized **6 high-value category-state markets** representing **2,920 orders, R$409K GMV exposure, and 405 late orders** for fix-before-growth investigation using explicit volume, review-coverage, and peer-performance rules.

## Sales Operations / Seller Management

- Developed a rule-based seller portfolio that identified **10 high-value weak-execution sellers** covering **4,508 orders, R$790K delivered-GMV exposure, and 503 late orders**, with separate handling, route, concentration, and confidence evidence.
- Replaced raw worst-rate rankings with an impact-and-confidence screen requiring **100+ orders and 95%+ review coverage**, producing an interview-defensible seller action portfolio without an opaque weighted score.

## Market / Marketplace Analysis

- Quantified marketplace growth concentration: the **top 10 categories generated 67.58%** of delivered-GMV-proxy change and the **top five customer states generated 76.03%**, supporting targeted protection of major growth engines.
- Identified two medium-confidence controlled-growth candidates—`stationery × SP` and `housewares × MG`—with **1,019 orders, R$103K current GMV exposure, and R$76K observed GMV growth** while passing operational guardrails.

## Logistics / Operations Analytics

- Diagnosed route-level fulfillment risk and found **13 high-late routes with 1,439 late orders**; SP → RJ alone contained **653 late orders (45.38% of Fix-route late exposure)** at a **15.72% late rate**.
- Demonstrated a strong observational relationship between delay severity and low reviews: **9.90% near on-time, 64.79% at 3–7 days late, and 80.21% at 8+ days late**, while explicitly preserving non-causal limitations.

## Analytics Engineering / SQL

- Designed a three-layer PostgreSQL model (`raw`, `staging`, `analytics`) with immutable source landing, typed keys/FKs, deterministic review selection, safe item/order grains, and independent reconciliation of **R$13.59M item GMV, R$2.25M freight, and R$16.01M payments**.
- Authored **19 dependency-ordered SQL scripts** covering profiling, transforms, measurement foundations, decomposition, diagnostics, prioritization, dashboard exports, and independent validation; deployed and reconciled analytics views in PostgreSQL 18.4.

## Short two-bullet version

- Analyzed 9 Olist datasets / 1.55M rows in PostgreSQL, decomposing 141% delivered-GMV-proxy growth and identifying 99.4% of change as order-volume driven while on-time delivery declined 4.23 points.
- Prioritized 6 category-state markets, 10 sellers, and 13 routes for targeted Grow/Defend/Fix/Investigate decisions using reconciled GMV exposure, fulfillment, reviews, supply, and explicit confidence rules.

## Language guardrail

Use **identified**, **estimated**, **prioritized**, **recommended**, and **associated with**. Do not write “increased,” “reduced,” “saved,” or “improved” as an implemented outcome because the portfolio contains no post-action evidence.
