# Stage 1 data manifest

Generated on 2026-07-31 from the public Olist dataset archive used for local validation.

## Source and usage

- Source: Olist, Brazilian E-Commerce Public Dataset
- Dataset page: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
- Listed license: CC BY-NC-SA 4.0
- Portfolio policy: cite the source and license; keep raw files out of Git; do not redistribute the raw archive as part of the public portfolio.
- Raw location: `data/raw/`

## Archive verification

| Check | Result |
|---|---|
| Uploaded archive | `archive.zip 15-21-33-770.zip` |
| Archive size | 44,717,580 bytes |
| Archive SHA-256 | `967e41e04fc306fe604e2a693f488995a8b41e5047418f8a5c8e4abd6deca784` |
| Entries | 9 regular root-level CSV files |
| Uncompressed size | 126,186,995 bytes |
| CRC test | Passed for all entries |
| Unsafe paths | None detected |
| Existing-file overwrite | Disabled |

## Extracted CSV inventory

Record counts below are logical CSV records excluding the header. They were parsed with CSV quoting rules, so embedded line breaks in review comments do not inflate the count.

| File | Bytes | Records | Columns | Unexpected-width records | SHA-256 |
|---|---:|---:|---:|---:|---|
| `olist_customers_dataset.csv` | 9,033,957 | 99,441 | 5 | 0 | `983a422239e1712ded753b3bf9ecf47dc73f144d306029dcfa99e70a226883d2` |
| `olist_geolocation_dataset.csv` | 61,273,883 | 1,000,163 | 5 | 0 | `b514f6fc991b9566aeba02aa5d67e2c3630f034b60a0e05aa0d082a3b66d88d6` |
| `olist_order_items_dataset.csv` | 15,438,671 | 112,650 | 7 | 0 | `0bc4d068c4fe38cbb01bd90e8746e3c613fe7b4baef75fab7b0e329701c3e279` |
| `olist_order_payments_dataset.csv` | 5,777,138 | 103,886 | 5 | 0 | `4f713964f2815dbbaa40b9488268c55aac3627bfce5aa96cf58d1f3616de3cc0` |
| `olist_order_reviews_dataset.csv` | 14,451,670 | 99,224 | 7 | 0 | `012b61c7593e34f51fa614efdf802b9c7056ce6aae5307ddb93236e7cfc797d7` |
| `olist_orders_dataset.csv` | 17,654,914 | 99,441 | 8 | 0 | `8df58ef3d2d7e9944010f7beecd9b75367f5588ec6e3c91cec19ae3345ef9ecf` |
| `olist_products_dataset.csv` | 2,379,446 | 32,951 | 9 | 0 | `3e6569628a17fbc75fd206ee357b59e20364b9afa90f5b6cd5b4d624c58aa9cc` |
| `olist_sellers_dataset.csv` | 174,703 | 3,095 | 4 | 0 | `1f643d2b950373b85735e7794b20986f528d7a000432e7c6f9bcbb44d0846a0e` |
| `product_category_name_translation.csv` | 2,613 | 71 | 2 | 0 | `a81f0d1f27b27e7293f761bc79e3ce8f348ee39c4b3ed3e49bde38f478586278` |
| **Total** | **126,186,995** | **1,550,922** | — | **0** | — |

## Column headers

| File | Columns |
|---|---|
| Customers | `customer_id`, `customer_unique_id`, `customer_zip_code_prefix`, `customer_city`, `customer_state` |
| Geolocation | `geolocation_zip_code_prefix`, `geolocation_lat`, `geolocation_lng`, `geolocation_city`, `geolocation_state` |
| Order items | `order_id`, `order_item_id`, `product_id`, `seller_id`, `shipping_limit_date`, `price`, `freight_value` |
| Payments | `order_id`, `payment_sequential`, `payment_type`, `payment_installments`, `payment_value` |
| Reviews | `review_id`, `order_id`, `review_score`, `review_comment_title`, `review_comment_message`, `review_creation_date`, `review_answer_timestamp` |
| Orders | `order_id`, `customer_id`, `order_status`, `order_purchase_timestamp`, `order_approved_at`, `order_delivered_carrier_date`, `order_delivered_customer_date`, `order_estimated_delivery_date` |
| Products | `product_id`, `product_category_name`, `product_name_lenght`, `product_description_lenght`, `product_photos_qty`, `product_weight_g`, `product_length_cm`, `product_height_cm`, `product_width_cm` |
| Sellers | `seller_id`, `seller_zip_code_prefix`, `seller_city`, `seller_state` |
| Category translation | `product_category_name`, `product_category_name_english` |

The original spelling `lenght` is preserved because raw source columns must not be edited. Friendly corrected aliases can be introduced later in the staging layer.

## Protection checks

- All 9 raw CSV files have read-only mode.
- Git reports every raw CSV as ignored.
- No raw CSV is tracked.
- No credential, key, secret, or environment file was found in the project.
- The uploaded archive remains unchanged outside the project.
