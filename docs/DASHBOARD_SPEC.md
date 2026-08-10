# Stage 6 decision dashboard specification

## Implemented Tableau delivery

The native macOS implementation is `tableau/Olist_Marketplace_Portfolio.twbx`, built in Tableau Public Desktop Edition 2026.2.1. It condenses the decision into one 1200 × 800 executive dashboard with four simultaneous views: top category growth, six Fix category-state markets, thirteen Fix routes, and delivery-timing versus low-review rate.

The Tableau workbook uses separate aggregate data sources at category, category-state, route, and delay-band grains. No relationships or joins connect those sources. This preserves each numerator and denominator and prevents one-to-many fanout. The broader three-page Power BI design below remains a documented alternative implementation rather than the current native deliverable.

## Dashboard purpose

Help marketplace, seller-management, logistics, and customer-experience leaders decide:

> What should Olist grow, defend, fix, or investigate—and which seller or route should own the next diagnostic?

The dashboard is a decision interface, not a general exploratory report. Every page uses the same verified purchase-cohort, GMV-proxy, volume, review-selection, and confidence rules as the SQL analysis.

## Model design

Power BI imports seven aggregate views. They are deliberately separate fact-like tables at different grains; they must not be joined to each other.

| Table | Grain | Rows | Primary use |
|---|---|---:|---|
| `dashboard_executive_kpis` | One matched Jan–Aug period | 2 | KPI comparison |
| `dashboard_monthly_trend` | One stable purchase month | 20 | Trend and scale/quality tension |
| `dashboard_category_state` | One ranked category × customer state | 104 | Grow/Defend/Fix/Investigate portfolio |
| `dashboard_seller` | One ranked seller | 93 | Seller intervention portfolio |
| `dashboard_route` | One ranked seller-state → customer-state route | 50 | Logistics root-cause portfolio |
| `dashboard_delay_band` | One delivery-timing band | 5 | Delay/review association |
| `dashboard_growth_contributor` | One category or customer-state contributor | 101 | Growth concentration |

No relationship is required between these aggregate tables. Cross-page filters are implemented separately per page; this prevents ambiguous many-to-many joins and accidental measure fanout.

## Page 1 — Executive overview

### Decision answered

Did Olist scale safely, where did growth concentrate, and what is the immediate resource-allocation implication?

### Visuals

1. KPI comparison cards: current GMV, GMV growth, current orders, order growth, current on-time, and current low-review rate.
2. Monthly line chart: delivered orders and GMV trend, with on-time rate as a separately scaled small multiple—not a dual-axis chart.
3. Matched-period slope/dumbbell: on-time and low-review rates, each with percentage-point change.
4. Ranked horizontal bar: top category or customer-state contribution to GMV change, controlled by `dimension_type`.
5. One action text box summarizing the verified operating sequence; it is static narrative, not a calculated claim.

### Default state

- Current period: Jan–Aug 2018.
- Growth contributor: Category.
- Display top 10 contributors by `growth_rank`.

### Decision cues

- GMV/orders are scale measures.
- On-time/low-review are quality guardrails.
- Keep both visible; do not combine them into a score.

## Page 2 — Opportunity portfolio

### Decision answered

Which category-state markets and sellers should Olist Grow, Defend, Fix, or Investigate?

### Category-state visuals

1. Scatter: current GMV on x, on-time rate on y, bubble size = current orders, color = action posture.
2. Portfolio summary: segments, current GMV exposure, observed late orders, and peer-median gap by action posture.
3. Detail table: segment, posture, confidence, GMV/change, orders, on-time, low-review, local sellers, interstate share, top-seller share, late orders, and scenario gap.

### Seller visuals

1. Scatter: current GMV on x, on-time rate on y, bubble size = current orders, color = action posture.
2. Detail table: seller ID, posture, confidence, GMV/change, orders, on-time, low-review, median/P90 handling, state reach, and scenario gap.

### Filters

- Category-state page: posture, customer state, category, current confidence, growth confidence.
- Seller page/bookmark: posture, current confidence, growth confidence.

### Required tooltip language

“Current GMV exposure is observable item value in this segment; it is not uplift, loss, revenue, or profit.”

## Page 3 — Fulfillment and customer experience

### Decision answered

Which routes contain the greatest delivery exposure, what operating stage should be investigated, and how does delay severity relate to reviews?

### Visuals

1. Route scatter: delivered GMV on x, late rate on y, bubble size = delivered orders, color = action posture.
2. Ranked bar: late orders by route, default top 13 Fix routes.
3. Root-cause table: route, owner signal, orders, GMV, late rate, median/P90 lateness, median handling, median carrier time, and freight burden.
4. Delay-band column chart: low-review rate by ordered delay band; direct labels show reviewed-order denominator.
5. Review-score line or dot plot by delay band as supporting evidence.

### Required annotation

“Review comparisons are observational. Product quality, damage, seller communication, and response selection may also affect ratings.”

## Interaction rules

- Selecting a posture filters the relevant page only.
- Selecting a route filters the root-cause table but does not filter delay bands; delay bands are marketplace-level evidence.
- Do not create cross-fact relationships to make interactions appear global.
- Preserve visible denominators in tooltips for every rate.
- Keep confidence beside impact; do not encode confidence only through opacity.

## Formatting and accessibility

- Use a restrained action palette: Fix = red, Grow = blue, Defend = green, Investigate = amber, Monitor = neutral gray.
- Pair color with posture labels; never rely on color alone.
- Currency labels use `R$` and identify GMV as proxy in subtitles/tooltips.
- Rates display as percentages with one decimal on visuals and two decimals in detail tables.
- Order and seller counts use whole numbers with thousands separators.
- All chart titles state grain and period.
- Keep at least 4.5:1 text contrast; add alt text to each visual.

## Dashboard acceptance gate

- Seven export grains are unique and reconcile to analytics sources.
- Page-level measures use weighted numerators/denominators, never averages of segment rates.
- All published numbers match `16_headline_validation.sql` and `18_dashboard_reconciliation.sql`.
- The default view answers a management decision in under one minute.
- No visual implies profit, causality, implemented impact, or forecast uplift.
- The native Tableau workbook and packaged workbook open locally and preserve the separate-grain model.
- Tableau presentation-mode totals reconcile to `16_headline_validation.sql` and `18_dashboard_reconciliation.sql`.
