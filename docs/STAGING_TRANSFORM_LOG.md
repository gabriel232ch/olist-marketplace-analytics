# Stage 4 staging transform and quality log

## Execution

- Date: 2026-08-07
- Database: `olist_portfolio` on PostgreSQL 18.4
- Authorized action: load typed `staging.*` from the completed `raw.*` import
- Scripts: [`05_load_staging.sql`](../sql/05_load_staging.sql) followed by [`06_staging_quality_checks.sql`](../sql/06_staging_quality_checks.sql)
- Result: the transform committed successfully. `raw.*` was not changed, and no `analytics.*` objects or data were created.

The first transform attempt rolled back atomically because the initial geolocation numeric definitions were too narrow for observed values. The staging contract was widened to `numeric(22,20)` for latitude and `numeric(19,16)` for longitude, then the same load was rerun successfully. This preserves the source values rather than rounding or dropping rows.

## Transform behavior

`05_load_staging.sql` truncates and reloads only the rebuildable staging layer inside one transaction. It loads parent tables before child tables so foreign keys can validate the relationships. `NULLIF(raw_column, '')` turns the empty strings produced by the raw CSV import into SQL `NULL` before optional fields are cast. IDs and postal prefixes remain text; timestamps become `timestamp`; money-like values become fixed-precision `numeric`; count fields become integers.

The output grains are unchanged from the source audit:

- one row per customer, product, seller, order, or category mapping;
- one row per (`order_id`, `order_item_id`) item line;
- one row per (`order_id`, `payment_sequential`) payment row;
- one row per (`review_id`, `order_id`) review association;
- one row per geolocation observation, with a generated technical key because the source has no natural key.

## Row-count and key results

All nine raw-to-staging row counts matched exactly:

| Staging table | Raw rows | Staging rows |
|---|---:|---:|
| `customers` | 99,441 | 99,441 |
| `products` | 32,951 | 32,951 |
| `sellers` | 3,095 | 3,095 |
| `category_translation` | 71 | 71 |
| `orders` | 99,441 | 99,441 |
| `order_items` | 112,650 | 112,650 |
| `order_payments` | 103,886 | 103,886 |
| `order_reviews` | 99,224 | 99,224 |
| `geolocation_observations` | 1,000,163 | 1,000,163 |

Required single-column keys and composite keys had zero missing or duplicate violations in staging. The operational foreign-key checks also had zero unmatched child keys for orders-to-customers, items-to-orders/products/sellers, payments-to-orders, and reviews-to-orders. Product categories had 73 distinct non-blank values, of which 71 matched the translation table; the two unmatched values are retained for review.

## Independent amount reconciliation

The quality script casts raw text independently and compares it with typed staging values:

| Measure | Raw | Staging | Result |
|---|---:|---:|---|
| Item rows | 112,650 | 112,650 | Match |
| Item price sum (GMV/sales-value proxy) | 13,591,643.70 | 13,591,643.70 | Match |
| Freight sum | 2,251,909.54 | 2,251,909.54 | Match |
| Payment rows | 103,886 | 103,886 | Match |
| Payment value sum | 16,008,872.12 | 16,008,872.12 | Match |

These are source-value reconciliations, not audited revenue or profit. The dataset does not provide a complete cost model.

## Source exceptions retained for later analysis

These checks do not block the typed load, but they must be handled explicitly by later analytics definitions:

- 2 payment rows have `payment_installments = 0` (both are credit-card rows totaling 188.63). Do not silently rewrite them to one installment.
- 166 orders have a carrier date earlier than the purchase timestamp; 165 are delivered and 1 is shipped.
- 23 delivered orders have a customer-delivery timestamp earlier than the carrier timestamp.
- 8 delivered orders lack a customer-delivery timestamp. Other missing delivery dates align with non-delivered statuses: 1,107 shipped, 619 canceled, 609 unavailable, 314 invoiced, 301 processing, 5 created, and 2 approved.
- 610 products have a blank category; two non-blank product categories (`portateis_cozinha_e_preparadores_de_alimentos` and `pc_gamer`) lack an English translation.
- One-to-many relationships remain: orders can have multiple item lines, payment rows, and reviews; geolocation has many observations per ZIP prefix. Future queries must aggregate each child to the intended grain before joining.

## Beginner-friendly interpretation

The raw layer is the untouched landing copy. Staging is a typed, checked working layer: it makes dates and amounts usable, turns blank text into honest `NULL`s, and uses primary/foreign keys to catch orphan rows. A foreign key does not make an item an order; it only confirms which order the item belongs to. Because one order can have many items, payments, and reviews, joining those tables side by side can repeat an order's value. Aggregate each one-to-many table first, then join the one-row-per-order summaries.

## Stage 4 acceptance gate

**Passed with documented source exceptions.** The load committed, all nine row counts reconciled, keys and required fields passed, operational foreign-key coverage passed, raw-to-staging monetary totals matched, and the remaining chronology/payment/category exceptions are recorded above. Analytics transforms have not started.
