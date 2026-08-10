# Tableau workbook guide

## Deliverables

- `Olist_Marketplace_Portfolio.twbx` is the portable workbook. It packages the aggregate extracts with the Tableau workbook.
- The editable `.twb` source is not included in this public copy because its CSV connections contain local machine paths.
- `images/tableau-executive-dashboard.jpg` is the verified presentation-mode preview.

The workbook was built and visually checked in Tableau Public Desktop Edition 2026.2.1 on macOS. It has not been published to a Tableau Public profile.

## Executive dashboard

The 1200 × 800 dashboard answers the portfolio's central decision with four views:

| View | Output grain | Business purpose |
|---|---|---|
| Top 10 category GMV change | One category | Shows where matched-period marketplace scale increased most. |
| Fix category-state GMV exposure | One selected category × customer-state segment | Shows the six material markets that should be fixed before additional demand activation. |
| Fix routes by late orders | One selected seller-state → customer-state route | Shows where late-order exposure is concentrated and where route diagnosis should start. |
| Delivery timing vs low-review rate | One delivery-timing band | Shows the observational association between delivery severity and low reviews. |

Each view uses its own aggregate data source. The sources are deliberately not joined or related because their grains differ. Joining a category row to several route or delay-band rows would duplicate values and overstate totals.

The supporting worksheet **All category growth contributors** is a descending horizontal bar chart containing 74 category rows only. Customer-state contributors are excluded from its packaged extract so state codes such as `SP` and `MG` do not appear in a category view.

## Reconciliation targets

These values reproduce the saved PostgreSQL analytics and independent validation queries:

- Top 10 category GMV change: **R$2,854,957.51**.
- All 74 category contributors: **R$4,224,668.99**, reconciling to total matched-period marketplace GMV change.
- Six Fix segments: **2,920 orders**, **R$409,170.12 GMV exposure**, **405 observed late orders**, and a **210-order peer-median scenario gap**.
- Thirteen Fix routes: **8,893 delivered orders**, **R$1,189,322.92 GMV exposure**, and **1,439 late orders**.
- Delivery timing: **5 mutually exclusive bands**; low-review rate ranges from **9.14%** for orders at least seven days early to **80.21%** for orders at least eight days late.

GMV is summed item price and is a sales-value proxy, not Olist revenue, margin, or profit. Review comparisons are observational; product quality, damage, seller communication, and response selection may also affect ratings.

## Open and review

1. Open `Olist_Marketplace_Portfolio.twbx` in Tableau Public Desktop Edition.
2. Select **Olist Marketplace Priority Dashboard | Jan–Aug 2018**.
3. Use Presentation Mode for the recruiter-facing view.
4. Treat the unjoined sources as a grain-safety control; do not create cross-source relationships merely to enable global filtering.
