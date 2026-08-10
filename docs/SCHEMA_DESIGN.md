# PostgreSQL schema design and analytics architecture

## Purpose and boundary

This document began as a schema design artifact. The project uses PostgreSQL schemas for immutable source landing, typed staging, and decision-ready analytics. The executable setup scripts are [01_create_schemas.sql](../sql/01_create_schemas.sql), [02_create_raw_tables.sql](../sql/02_create_raw_tables.sql), [03_create_staging_tables.sql](../sql/03_create_staging_tables.sql), and [05_load_staging.sql](../sql/05_load_staging.sql).

The design keeps the raw source faithful, makes typed data-quality decisions visible in staging, and prevents business queries from accidentally multiplying order values through one-to-many joins.

## Three-layer model

| Schema | Purpose | Grain and control rules |
|---|---|---|
| `raw` | Landing copy of each CSV, one table per source file | Exact source column names; all fields stored as `text`; no primary keys or foreign keys; no cleanup in place. This layer is reloadable and auditable against the manifest. |
| `staging` | Typed, constrained analysis input | One typed table per operational source; timestamps, numeric fields, nulls, keys, and foreign keys are made explicit. The geolocation observation table receives a generated technical key because the source has no natural key. |
| `analytics` | Decision-ready views or marts | Created only after staging checks pass. Every object must state its output grain, denominator, date basis, and join path. It should not expose raw one-to-many joins to dashboard users. |

The database itself must be created while connected to the default PostgreSQL database/user. The schema scripts run only after connecting to `olist_portfolio`; `CREATE DATABASE` is intentionally not included in the project SQL because it is a one-time environment action and cannot be treated like a normal table transaction.

## Raw design

The nine raw tables mirror the nine CSV headers, including the source spelling `product_name_lenght` and `product_description_lenght`. Every raw column is `text` so an import preserves the source value and cannot silently turn a leading-zero ZIP prefix into a different identifier. Raw tables intentionally have no constraints: quality checks must be able to see malformed or missing values before a typed load rejects them.

Raw table names:

`raw.customers`, `raw.geolocation`, `raw.order_items`, `raw.order_payments`, `raw.order_reviews`, `raw.orders`, `raw.products`, `raw.sellers`, and `raw.category_translation`.

The intended source grains and candidate keys are recorded in [DATA_AUDIT.md](DATA_AUDIT.md). In short: `order_id`, `product_id`, `seller_id`, and `customer_id` are unique in their files; item and payment tables use composite keys; reviews use (`review_id`, `order_id`); geolocation has no natural key.

## Staging design

The staging tables below are the typed contract for analysis. `NOT NULL` is used only where Stage 2A found complete source coverage and where the field is required to identify the row. Optional source timestamps, product attributes, and review comments remain nullable.

| Table | One row represents | Key | Important relationships |
|---|---|---|---|
| `staging.customers` | One customer source record | `customer_id` | `customer_unique_id` is not unique; use it for repeat-customer grouping. |
| `staging.orders` | One order | `order_id` | `customer_id` references customers. |
| `staging.products` | One product | `product_id` | Category name is optional and is not forced to match the translation table. |
| `staging.sellers` | One seller | `seller_id` | Seller ZIP is a text reference, not a strict geolocation FK. |
| `staging.category_translation` | One Portuguese category mapping | `product_category_name` | Two non-null product categories have no mapping; later joins must be left joins when completeness matters. |
| `staging.order_items` | One item line in an order | (`order_id`, `order_item_id`) | FKs to orders, products, and sellers. |
| `staging.order_payments` | One payment sequence in an order | (`order_id`, `payment_sequential`) | FK to orders. |
| `staging.order_reviews` | One review-to-order association | (`review_id`, `order_id`) | FK to orders; either individual column can repeat. |
| `staging.geolocation_observations` | One typed geolocation observation | Generated `geolocation_observation_id` | No raw FK; repeated ZIP prefixes are expected. |

Suggested typed columns are directly represented in the draft staging DDL:

- IDs, cities, states, categories, and payment types: `text`.
- ZIP prefixes: `text` to preserve leading zeroes.
- Timestamps: `timestamp`.
- Price, freight, and payment: fixed-precision `numeric`; latitude `numeric(22,20)` and longitude `numeric(19,16)` preserve the observed source precision.
- Counts and dimensions: `integer`.
- Review score: `smallint`.

The draft deliberately does not add business-rule checks such as a review score range, delivery-status/date consistency, or a selected geolocation representative. Those rules should be added after the import validation results are reviewed so they do not conceal source exceptions.

## Analytics design (implemented)

Analytics objects are created only after staging passes its gate. The objects below are implemented through the numbered analytics scripts and reconciled with [ANALYTICS_FRAMEWORK.md](ANALYTICS_FRAMEWORK.md), [METRIC_DICTIONARY.md](METRIC_DICTIONARY.md), and [ANALYSIS_WORKPLAN.md](ANALYSIS_WORKPLAN.md).

| Object | Output grain | Business purpose | Required protection |
|---|---|---|---|
| `analytics.order_summary` | One row per `order_id` | Order status, purchase month, item count, GMV proxy, freight value, payment total, and review summary | Aggregate items, payments, and reviews separately before joining. |
| `analytics.order_fulfillment` | One row per delivered/eligible `order_id` | Approval-to-carrier, carrier-to-customer, total delivery time, estimated-date comparison | Publish denominators and exclude undelivered orders from delivery-rate KPIs. |
| `analytics.item_fulfillment` | One row per (`order_id`, `order_item_id`) | Category × seller × customer-state lane analysis | Bring order-level dates to item grain only after order-level delivery flags are defined. |
| `analytics.customer_order_summary` | One row per `customer_unique_id` | First order, order count, repeat flag, and value summary | Use the persistent identifier, not the order-specific `customer_id`. |
| `analytics.category_state_seller_priority` | One row per category × customer state × seller | Decision prioritization by scale, delivery risk, review outcomes, and confidence | Define minimum volume thresholds and preserve the underlying evidence columns. |

No headline KPI should be selected solely because it is easy to aggregate. Final definitions belong in [METRIC_DICTIONARY.md](METRIC_DICTIONARY.md), with independent reconciliation queries before any resume number is used.

## Key and constraint rationale for a SQL learner

- A primary key identifies one row. `order_id` is a primary key in `staging.orders`; `order_id` alone is not a primary key in items or payments because those files have multiple rows per order.
- A composite key combines columns when neither column is unique alone. (`order_id`, `order_item_id`) identifies an item line; (`order_id`, `payment_sequential`) identifies a payment row.
- A foreign key checks that a child value points to a parent row. It does not change the child grain. An item still remains an item after it references its order.
- A raw landing table has no keys because the first job is to observe the file. Staging is where typed casts and relational constraints become testable.
- The analytics layer is where one-to-many detail is summarized to a decision grain. This is the main defense against counting the same order value multiple times.
