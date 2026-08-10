# SQL execution guide

Run files in numeric order against PostgreSQL database `olist_portfolio`. Object-building scripts are transactional and reconciliation scripts are read-only.

## Foundation and import

| Script | Purpose | State |
|---|---|---|
| `01_create_schemas.sql` | Create `raw`, `staging`, and `analytics` schemas | Executed in saved database |
| `02_create_raw_tables.sql` | Create nine source-shaped text landing tables | Executed in saved database |
| `03_create_staging_tables.sql` | Create nine typed staging tables | Executed in saved database |
| `04_raw_quality_checks.sql` | Validate imported raw rows, keys, nulls, timestamps, FKs, statuses, and fanout risks | Passed |
| `05_load_staging.sql` | Atomically cast and load typed staging tables | Executed in saved database |
| `06_staging_quality_checks.sql` | Validate staging keys, FKs, chronology, amounts, mappings, and fanout risks | Passed |

The nine CSV files are imported through the documented TablePlus client-side process before `04`; no raw file path or credentials are embedded in SQL.

## Analytics and validation

| Script | Output grain / purpose | Type |
|---|---|---|
| `07_measurement_rule_profile.sql` | Period, population, review, volume, coverage, and RFM suitability profile | Read-only |
| `08_create_measurement_foundations.sql` | One rule row; one selected review/order/item/customer foundation row at declared grains | DDL views |
| `09_measurement_reconciliation.sql` | Keys, populations, amounts, review coverage, and partition checks | Read-only |
| `10_marketplace_baseline.sql` | Marketplace month/period, decomposition, contribution, and concentration views | DDL views |
| `11_marketplace_baseline_reconciliation.sql` | Stable-window, period, decomposition, and allocation checks | Read-only |
| `12_opportunity_diagnostics.sql` | Category-state, seller, route, delay-band, and order-complexity diagnostics | DDL views |
| `13_opportunity_diagnostic_reconciliation.sql` | Diagnostic GMV, coverage, and partition checks | Read-only |
| `14_create_priority_portfolios.sql` | Rule-based category-state, seller, and route portfolios | DDL views |
| `15_priority_reconciliation.sql` | Grain, population, eligibility, scenario, and posture checks | Read-only |
| `16_headline_validation.sql` | Independent rebuild of all resume-level headline numbers | Read-only |
| `17_create_dashboard_exports.sql` | Seven presentation-safe Power BI export views | DDL views |
| `18_dashboard_reconciliation.sql` | Dashboard object, grain, population, headline, and scenario checks | Read-only |
| `19_export_dashboard_csvs.sql` | `psql` client-side export of seven curated aggregate CSVs | Export |

## Analytics dependency sequence

```text
07 profile
  → 08 measurement foundations
  → 09 measurement checks
  → 10 marketplace baseline
  → 11 baseline checks
  → 12 diagnostics
  → 13 diagnostic checks
  → 14 priority portfolios
  → 15 portfolio checks
  → 16 independent headline validation
  → 17 dashboard export views
  → 18 dashboard checks
  → 19 curated aggregate CSV exports
```

## Grain and fanout rules

- `order_measurement_base`: one row per `order_id` after item/payment aggregation and deterministic review selection.
- `item_measurement_base`: one row per `(order_id, order_item_id)`; order outcome fields repeat and require distinct-order or pre-aggregated use.
- `category_state_diagnostic`: one row per category × customer state; segment order measures are aggregated before seller-supply measures join.
- `seller_portfolio_diagnostic`: one row per seller; primary handling metrics use valid single-seller orders.
- `route_fulfillment_diagnostic`: one row per seller state × customer state.
- Priority views preserve their diagnostic grains and keep impact, operations, and confidence separate.

Never join payment, review, geolocation, and item children together at raw grain. Never sum distinct-order metrics across overlapping item segments as if they were additive.

## Validation expectation

The complete analytics sequence passed in an isolated PostgreSQL 18 validation database rebuilt from the immutable CSVs. Before Power BI, run the same sequence in the saved local database and confirm the outputs documented in `docs/MEASUREMENT_FOUNDATION_LOG.md`, `docs/MARKETPLACE_BASELINE.md`, `docs/OPPORTUNITY_DIAGNOSTICS.md`, and `docs/PRIORITIZATION_RESULTS.md`.
