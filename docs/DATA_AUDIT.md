# Stage 2A source data audit

## Scope and method

This is a read-only profile of the nine immutable CSV files in `data/raw/`, completed on 2026-07-31. No PostgreSQL tables were created, no data was imported, and no DDL was written.

CSV values arrive as strings. The **suggested parsing types** below describe how a future PostgreSQL import can interpret valid source values; they are not a table definition. All non-null numeric and timestamp values passed the stated format checks. The category-translation file has a UTF-8 byte-order mark (BOM) before its first header; a BOM-aware reader exposes the column as `product_category_name`.

## Grain, candidate keys, and duplicate tests

`Duplicate excess rows` means `non-null rows - distinct candidate-key values`. It is zero only when that candidate is unique. `Full-row duplicate excess` tests whether every source value in the row repeats exactly.

| CSV | Rows | Intended source grain | Candidate key test | Full-row duplicate excess | Conclusion |
|---|---:|---|---|---:|---|
| Customers | 99,441 | One Olist `customer_id` record (an order-linked customer identity) | `customer_id`: 99,441 distinct, 0 excess; `customer_unique_id`: 96,096 distinct, 3,345 excess | 0 | Use `customer_id` as the source-row key. `customer_unique_id` identifies a person across repeat purchases, not a unique row. |
| Geolocation | 1,000,163 | One supplied geolocation observation | ZIP prefix: 19,015 distinct, 981,148 excess; all five source fields: 738,332 distinct, 261,831 excess | 261,831 | No natural primary key in the raw file. It must be deduplicated/aggregated before a ZIP-prefix lookup is used. |
| Order items | 112,650 | One item line within an order | `order_id`: 98,666 distinct, 13,984 excess; (`order_id`, `order_item_id`): 112,650 distinct, 0 excess | 0 | Composite key is unique; an order can have many item lines. |
| Order payments | 103,886 | One payment sequence within an order | `order_id`: 99,440 distinct, 4,446 excess; (`order_id`, `payment_sequential`): 103,886 distinct, 0 excess | 0 | Composite key is unique; an order can have multiple payment records. |
| Order reviews | 99,224 | One review-to-order association | `review_id`: 98,410 distinct, 814 excess; `order_id`: 98,673 distinct, 551 excess; (`review_id`, `order_id`): 99,224 distinct, 0 excess | 0 | Use the composite source key for audit purposes. Neither individual ID is unique. |
| Orders | 99,441 | One commerce order | `order_id`: 99,441 distinct, 0 excess; `customer_id`: 99,441 distinct, 0 excess | 0 | `order_id` is the business key. `customer_id` happens to be one-to-one in this extract but is semantically the customer link. |
| Products | 32,951 | One product | `product_id`: 32,951 distinct, 0 excess | 0 | `product_id` is unique. |
| Sellers | 3,095 | One seller | `seller_id`: 3,095 distinct, 0 excess | 0 | `seller_id` is unique. |
| Category translation | 71 | One Portuguese-to-English category mapping | `product_category_name`: 71 distinct, 0 excess | 0 | Portuguese category name is unique in this mapping. |

Additional duplicate-risk detail: 9,803 orders have more than one item line (maximum 21); 2,961 orders have more than one payment row (maximum 29); 547 orders have more than one review row (maximum 3). Also, 789 `review_id` values occur on more than one order (maximum 3). These are source facts, so joins must aggregate items, payments, and reviews to the intended reporting grain before combining them.

## Columns, suggested parsing types, and nulls

For postal prefixes, use `text` in a future staging layer even though every non-null source value is numeric-looking. That preserves leading zeroes such as `02140` and avoids changing the business identifier. IDs, city names, states, categories, and payment types are also text.

### Customers — one row per `customer_id`

| Column | Suggested parsing type | Null rows |
|---|---|---:|
| `customer_id` | text | 0 |
| `customer_unique_id` | text | 0 |
| `customer_zip_code_prefix` | text postal prefix (up to 5 digits) | 0 |
| `customer_city` | text | 0 |
| `customer_state` | text | 0 |

### Geolocation — one supplied location observation; no raw key

| Column | Suggested parsing type | Null rows |
|---|---|---:|
| `geolocation_zip_code_prefix` | text postal prefix (up to 5 digits) | 0 |
| `geolocation_lat` | numeric(22,20) to preserve the observed two-integer-digit values and 20 fractional digits | 0 |
| `geolocation_lng` | numeric(19,16) to preserve the observed three-integer-digit outliers and 16 fractional digits | 0 |
| `geolocation_city` | text | 0 |
| `geolocation_state` | text | 0 |

### Order items — one row per (`order_id`, `order_item_id`)

| Column | Suggested parsing type | Null rows |
|---|---|---:|
| `order_id` | text | 0 |
| `order_item_id` | integer | 0 |
| `product_id` | text | 0 |
| `seller_id` | text | 0 |
| `shipping_limit_date` | timestamp | 0 |
| `price` | numeric(6,2) | 0 |
| `freight_value` | numeric(5,2) | 0 |

### Order payments — one row per (`order_id`, `payment_sequential`)

| Column | Suggested parsing type | Null rows |
|---|---|---:|
| `order_id` | text | 0 |
| `payment_sequential` | integer | 0 |
| `payment_type` | text | 0 |
| `payment_installments` | integer | 0 |
| `payment_value` | numeric(7,2) | 0 |

### Order reviews — one row per (`review_id`, `order_id`)

| Column | Suggested parsing type | Null rows |
|---|---|---:|
| `review_id` | text | 0 |
| `order_id` | text | 0 |
| `review_score` | integer | 0 |
| `review_comment_title` | text | 87,656 |
| `review_comment_message` | text | 58,247 |
| `review_creation_date` | timestamp | 0 |
| `review_answer_timestamp` | timestamp | 0 |

Blank review text is expected in this source and should remain nullable; do not equate a missing comment with a negative review.

### Orders — one row per `order_id`

| Column | Suggested parsing type | Null rows |
|---|---|---:|
| `order_id` | text | 0 |
| `customer_id` | text | 0 |
| `order_status` | text | 0 |
| `order_purchase_timestamp` | timestamp | 0 |
| `order_approved_at` | timestamp | 160 |
| `order_delivered_carrier_date` | timestamp | 1,783 |
| `order_delivered_customer_date` | timestamp | 2,965 |
| `order_estimated_delivery_date` | timestamp | 0 |

### Products — one row per `product_id`

| Column | Suggested parsing type | Null rows |
|---|---|---:|
| `product_id` | text | 0 |
| `product_category_name` | text | 610 |
| `product_name_lenght` | integer | 610 |
| `product_description_lenght` | integer | 610 |
| `product_photos_qty` | integer | 610 |
| `product_weight_g` | integer | 2 |
| `product_length_cm` | integer | 2 |
| `product_height_cm` | integer | 2 |
| `product_width_cm` | integer | 2 |

The source spelling `lenght` is retained. A later staging layer may introduce correctly spelled aliases without altering raw fields.

### Sellers — one row per `seller_id`

| Column | Suggested parsing type | Null rows |
|---|---|---:|
| `seller_id` | text | 0 |
| `seller_zip_code_prefix` | text postal prefix (up to 5 digits) | 0 |
| `seller_city` | text | 0 |
| `seller_state` | text | 0 |

### Category translation — one row per Portuguese category name

| Column | Suggested parsing type | Null rows |
|---|---|---:|
| `product_category_name` | text | 0 |
| `product_category_name_english` | text | 0 |

## Timestamp coverage and status context

Every non-null timestamp conforms to `YYYY-MM-DD HH:MM:SS`.

| Source column | Minimum | Maximum | Null rows |
|---|---|---|---:|
| Order items `shipping_limit_date` | 2016-09-19 00:15:34 | 2020-04-09 22:35:08 | 0 |
| Reviews `review_creation_date` | 2016-10-02 00:00:00 | 2018-08-31 00:00:00 | 0 |
| Reviews `review_answer_timestamp` | 2016-10-07 18:32:28 | 2018-10-29 12:27:35 | 0 |
| Orders `order_purchase_timestamp` | 2016-09-04 21:15:19 | 2018-10-17 17:30:18 | 0 |
| Orders `order_approved_at` | 2016-09-15 12:16:38 | 2018-09-03 17:40:06 | 160 |
| Orders `order_delivered_carrier_date` | 2016-10-08 10:34:01 | 2018-09-11 19:48:28 | 1,783 |
| Orders `order_delivered_customer_date` | 2016-10-11 13:46:32 | 2018-10-17 13:22:46 | 2,965 |
| Orders `order_estimated_delivery_date` | 2016-09-30 00:00:00 | 2018-11-12 00:00:00 | 0 |

Order-status counts are: delivered 96,478; shipped 1,107; canceled 625; unavailable 609; invoiced 314; processing 301; created 5; approved 2. Missing delivery milestones are therefore not automatically data errors: they can be valid for orders that were not delivered. Future delivery KPIs must define their denominator, usually delivered orders with the required timestamps, rather than silently treating missing dates as zero duration.

## Relationship coverage and join risks

For the first six relationships below, every distinct non-null child key matches a parent key. Because the child key fields have no nulls, their row-level coverage is also 100%.

| Child → parent | Matched distinct child keys | Relationship cardinality / risk |
|---|---:|---|
| `orders.customer_id` → `customers.customer_id` | 99,441 / 99,441 | One-to-one in this extract. For customer-level analysis, group `customer_id` rows by `customer_unique_id` to represent repeat buyers. |
| `order_items.order_id` → `orders.order_id` | 98,666 / 98,666 | Many items per order. Joining items to orders creates one row per item, not one row per order. 775 orders have no item row. |
| `order_items.product_id` → `products.product_id` | 32,951 / 32,951 | Many item rows per product. |
| `order_items.seller_id` → `sellers.seller_id` | 3,095 / 3,095 | Many item rows per seller. |
| `order_payments.order_id` → `orders.order_id` | 99,440 / 99,440 | Many payment rows per order. One order has no payment row. |
| `order_reviews.order_id` → `orders.order_id` | 98,673 / 98,673 | Zero-to-many review rows per order. 768 orders have no review row. |
| `products.product_category_name` → translation `product_category_name` | 71 / 73 non-null category values | Not complete: 13 products use two unmapped categories (`pc_gamer`: 3; `portateis_cozinha_e_preparadores_de_alimentos`: 10). Keep those products with a left join. |

Geolocation is a useful reference source but not an enforceable raw foreign key. It has 1,000,163 rows for only 19,015 ZIP prefixes, so joining it directly to customers or sellers would multiply rows. Among distinct ZIP prefixes, 14,837 of 14,994 customer prefixes match (157 do not; 278 customer rows), and 2,239 of 2,246 seller prefixes match (7 do not; 7 seller rows). A later staging step should build one documented location record per ZIP prefix before any location join.

## Beginner-friendly join rules

**Grain** means “what one output row represents.” Before a join, say the grain aloud. For example, `orders` starts at one row per order, but adding `order_items` changes the result to one row per item. A count of rows after that join is an item count, not an order count.

**One-to-many** means one parent row can find several children. Here, an order can have several items, payments, and reviews. If you join all three detailed tables together, their counts can multiply each other. For an order with two items and three payment rows, the combined join can yield six rows. To calculate an order-level KPI, first summarize each child table to one row per `order_id`, then join those summaries to `orders`.

**Foreign-key coverage** asks whether a child value has a matching parent. Coverage is complete for the operational links above, so missing joins will not explain an item, payment, or review disappearing. Completeness does not make a join safe by itself: its grain can still be wrong.

**Optional links** mean that a parent may have no child record. Orders without items, payments, or reviews are real source cases. Use a left join when they must remain in the denominator, then explicitly decide how to treat missing child measures.

## Stage 2A conclusions and guardrails

- The operational source model is suitable for a staged PostgreSQL import after a future schema-design gate.
- `order_id`, `product_id`, `seller_id`, and `customer_id` are unique source identifiers in their respective files; item and payment rows require composite keys.
- Do not use `review_id` alone as a key and do not join raw geolocation directly.
- Do not inner join category translation if product completeness matters; two source categories are unmapped and 610 products have no category.
- No business KPI has been calculated or interpreted in this stage.
