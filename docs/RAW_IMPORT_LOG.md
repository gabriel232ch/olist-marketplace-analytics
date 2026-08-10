# Stage 3 raw import and quality log

## Scope and outcome

Completed 2026-08-07 in TablePlus against local PostgreSQL 18.4, database `olist_portfolio`.

- All nine immutable CSVs were imported into their matching `raw.*` tables.
- The post-import row-count reconciliation matches `docs/DATA_MANIFEST.md` for every file.
- Read-only key, null/blank, timestamp, status, foreign-key, type, and one-to-many checks were run.
- The nine `staging.*` tables remain empty. No staging transform, `INSERT ... SELECT`, or analytics load was executed.

The PostgreSQL server could not read a Mac filesystem path for server-side `COPY` (permission denied). The import therefore used TablePlus's client-side CSV wizard. The wizard completed successfully for every file; the row-count reconciliation below is the independent completion check.

## Import reconciliation

| Source CSV | Raw table | Expected rows | Actual rows | Match |
|---|---|---:|---:|:---:|
| `olist_customers_dataset.csv` | `raw.customers` | 99,441 | 99,441 | Yes |
| `olist_geolocation_dataset.csv` | `raw.geolocation` | 1,000,163 | 1,000,163 | Yes |
| `olist_order_items_dataset.csv` | `raw.order_items` | 112,650 | 112,650 | Yes |
| `olist_order_payments_dataset.csv` | `raw.order_payments` | 103,886 | 103,886 | Yes |
| `olist_order_reviews_dataset.csv` | `raw.order_reviews` | 99,224 | 99,224 | Yes |
| `olist_orders_dataset.csv` | `raw.orders` | 99,441 | 99,441 | Yes |
| `olist_products_dataset.csv` | `raw.products` | 32,951 | 32,951 | Yes |
| `olist_sellers_dataset.csv` | `raw.sellers` | 3,095 | 3,095 | Yes |
| `product_category_name_translation.csv` | `raw.category_translation` | 71 | 71 | Yes |

The large geolocation file imported successfully at 1,000,163 rows. Source files under `data/raw/` were not edited.

## Storage and missing-value handling

The raw landing design intentionally stores every imported column as PostgreSQL `text`. The `information_schema` check returned only `text` columns across all nine raw tables. Type parsing belongs in staging so that source values remain auditable.

The quality queries use `NULLIF(column, '')` so SQL `NULL` and an empty source field share the same missing-value policy. In this TablePlus client-side load, empty fields are represented as empty strings in the text landing tables; for example, products has 610 empty category strings and 0 SQL `NULL` category values. The future staging transform must apply `NULLIF` before optional casts.

Selected missing/blank counts match the Stage 2A source audit:

- Orders: `order_approved_at` 160; `order_delivered_carrier_date` 1,783; `order_delivered_customer_date` 2,965.
- Products: category, name length, description length, photo count 610 each; weight, length, height, and width 2 each.
- Reviews: comment title 87,656; comment message 58,247.
- Required identifiers and customer location fields tested: 0 missing/blank rows.

## Key and duplicate results

- Unique source keys: `customer_id`, `order_id`, `product_id`, `seller_id`, and translation `product_category_name`.
- Unique composite keys: (`order_id`, `order_item_id`), (`order_id`, `payment_sequential`), and (`review_id`, `order_id`).
- `customer_unique_id` is intentionally not a row key: 96,096 distinct values across 99,441 rows (3,345 duplicate excess rows), representing repeat purchases by the same customer identity.
- The raw geolocation check returned 1,000,163 total rows, 738,332 distinct full rows, and 261,831 exact duplicate excess rows; geolocation has no natural raw primary key.
- The Stage 2A audit also records repeated `review_id` values; neither `review_id` alone nor a geolocation row should be promoted to a raw primary key.

## Timestamp and status checks

All non-blank timestamp values matched `YYYY-MM-DD HH:MM:SS` (0 invalid-format rows). Observed ranges:

| Source column | Minimum | Maximum |
|---|---|---|
| Orders `order_purchase_timestamp` | 2016-09-04 21:15:19 | 2018-10-17 17:30:18 |
| Orders `order_approved_at` | 2016-09-15 12:16:38 | 2018-09-03 17:40:06 |
| Orders `order_delivered_carrier_date` | 2016-10-08 10:34:01 | 2018-09-11 19:48:28 |
| Orders `order_delivered_customer_date` | 2016-10-11 13:46:32 | 2018-10-17 13:22:46 |
| Orders `order_estimated_delivery_date` | 2016-09-30 00:00:00 | 2018-11-12 00:00:00 |
| Items `shipping_limit_date` | 2016-09-19 00:15:34 | 2020-04-09 22:35:08 |
| Reviews `review_creation_date` | 2016-10-02 00:00:00 | 2018-08-31 00:00:00 |
| Reviews `review_answer_timestamp` | 2016-10-07 18:32:28 | 2018-10-29 12:27:35 |

Order status counts are delivered 96,478; shipped 1,107; canceled 625; unavailable 609; invoiced 314; processing 301; created 5; approved 2. Missing delivery milestones are expected for non-delivered statuses and must not be treated as zero-duration deliveries.

## Relationship coverage and join risks

All tested operational child keys matched their parent keys:

| Relationship | Distinct child keys | Matched parent keys | Unmatched |
|---|---:|---:|---:|
| `orders.customer_id` → `customers.customer_id` | 99,441 | 99,441 | 0 |
| `order_items.order_id` → `orders.order_id` | 98,666 | 98,666 | 0 |
| `order_items.product_id` → `products.product_id` | 32,951 | 32,951 | 0 |
| `order_items.seller_id` → `sellers.seller_id` | 3,095 | 3,095 | 0 |
| `order_payments.order_id` → `orders.order_id` | 99,440 | 99,440 | 0 |
| `order_reviews.order_id` → `orders.order_id` | 98,673 | 98,673 | 0 |

Category translation is intentionally incomplete. There are 73 non-blank product category values; 71 map to the translation table. The two unmapped values are `portateis_cozinha_e_preparadores_de_alimentos` (10 products) and `pc_gamer` (3 products). The 610 blank category fields are a separate optional-data case. Keep products with a `LEFT JOIN`.

One-to-many checks show why detailed children must be aggregated before an order-level join:

| Child relationship | Parent keys with children | Repeated parent keys | Maximum children |
|---|---:|---:|---:|
| Items per order | 98,666 | 9,803 | 21 |
| Payments per order | 99,440 | 2,961 | 29 |
| Reviews per order | 98,673 | 547 | 3 |
| Geolocation observations per ZIP prefix | 19,015 | 17,972 | 1,146 |

For example, two item rows joined directly to three payment rows can produce six rows for one order. Summarize each child to the intended grain first. Raw geolocation must be deduplicated or aggregated to one documented ZIP-prefix record before joining to customers or sellers.

## Stage 3 acceptance gate

**Passed.** Raw row counts reconcile to the manifest, the documented source exceptions are understood, tested operational relationships have complete coverage, and all staging tables remain at zero rows. The next authorized step is to design and execute the staging transforms; no staging transform was started in this stage.
