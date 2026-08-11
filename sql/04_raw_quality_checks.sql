

-- 1) Output grain: one row per raw table. 
WITH expected(table_name, expected_rows) AS (
    VALUES
        ('customers', 99441::bigint),
        ('geolocation', 1000163::bigint),
        ('order_items', 112650::bigint),
        ('order_payments', 103886::bigint),
        ('order_reviews', 99224::bigint),
        ('orders', 99441::bigint),
        ('products', 32951::bigint),
        ('sellers', 3095::bigint),
        ('category_translation', 71::bigint)
), actual(table_name, actual_rows) AS (
    SELECT 'customers', COUNT(*) FROM raw.customers
    UNION ALL SELECT 'geolocation', COUNT(*) FROM raw.geolocation
    UNION ALL SELECT 'order_items', COUNT(*) FROM raw.order_items
    UNION ALL SELECT 'order_payments', COUNT(*) FROM raw.order_payments
    UNION ALL SELECT 'order_reviews', COUNT(*) FROM raw.order_reviews
    UNION ALL SELECT 'orders', COUNT(*) FROM raw.orders
    UNION ALL SELECT 'products', COUNT(*) FROM raw.products
    UNION ALL SELECT 'sellers', COUNT(*) FROM raw.sellers
    UNION ALL SELECT 'category_translation', COUNT(*) FROM raw.category_translation
)
SELECT e.table_name, e.expected_rows, a.actual_rows,
       a.actual_rows = e.expected_rows AS row_count_matches
FROM expected e
JOIN actual a ON a.table_name = e.table_name
ORDER BY e.table_name;

-- 2) Output grain: one row per candidate source key. Tests key completeness and duplicate excess.
WITH key_checks(table_name, key_name, rows_with_complete_key, distinct_key_values) AS (
    SELECT 'customers', 'customer_id', COUNT(*), COUNT(DISTINCT customer_id)
    FROM raw.customers WHERE NULLIF(customer_id, '') IS NOT NULL
    UNION ALL
    SELECT 'customers', 'customer_unique_id', COUNT(*), COUNT(DISTINCT customer_unique_id)
    FROM raw.customers WHERE NULLIF(customer_unique_id, '') IS NOT NULL
    UNION ALL
    SELECT 'orders', 'order_id', COUNT(*), COUNT(DISTINCT order_id)
    FROM raw.orders WHERE NULLIF(order_id, '') IS NOT NULL
    UNION ALL
    SELECT 'products', 'product_id', COUNT(*), COUNT(DISTINCT product_id)
    FROM raw.products WHERE NULLIF(product_id, '') IS NOT NULL
    UNION ALL
    SELECT 'sellers', 'seller_id', COUNT(*), COUNT(DISTINCT seller_id)
    FROM raw.sellers WHERE NULLIF(seller_id, '') IS NOT NULL
    UNION ALL
    SELECT 'category_translation', 'product_category_name', COUNT(*), COUNT(DISTINCT product_category_name)
    FROM raw.category_translation WHERE NULLIF(product_category_name, '') IS NOT NULL
    UNION ALL
    SELECT 'order_items', '(order_id, order_item_id)', COUNT(*), COUNT(DISTINCT (order_id, order_item_id))
    FROM raw.order_items
    WHERE NULLIF(order_id, '') IS NOT NULL AND NULLIF(order_item_id, '') IS NOT NULL
    UNION ALL
    SELECT 'order_payments', '(order_id, payment_sequential)', COUNT(*), COUNT(DISTINCT (order_id, payment_sequential))
    FROM raw.order_payments
    WHERE NULLIF(order_id, '') IS NOT NULL AND NULLIF(payment_sequential, '') IS NOT NULL
    UNION ALL
    SELECT 'order_reviews', '(review_id, order_id)', COUNT(*), COUNT(DISTINCT (review_id, order_id))
    FROM raw.order_reviews
    WHERE NULLIF(review_id, '') IS NOT NULL AND NULLIF(order_id, '') IS NOT NULL
)
SELECT table_name, key_name, rows_with_complete_key, distinct_key_values,
       rows_with_complete_key - distinct_key_values AS duplicate_excess_rows,
       rows_with_complete_key = distinct_key_values AS is_unique
FROM key_checks
ORDER BY table_name, key_name;

-- 3) Output grain: one row per selected raw column. Blank and NULL values share one null policy.
SELECT table_name, column_name, null_or_blank_rows
FROM (
    SELECT 'customers' AS table_name, 'customer_id' AS column_name,
           COUNT(*) FILTER (WHERE NULLIF(customer_id, '') IS NULL) AS null_or_blank_rows FROM raw.customers
    UNION ALL SELECT 'customers', 'customer_unique_id', COUNT(*) FILTER (WHERE NULLIF(customer_unique_id, '') IS NULL) FROM raw.customers
    UNION ALL SELECT 'customers', 'customer_zip_code_prefix', COUNT(*) FILTER (WHERE NULLIF(customer_zip_code_prefix, '') IS NULL) FROM raw.customers
    UNION ALL SELECT 'customers', 'customer_city', COUNT(*) FILTER (WHERE NULLIF(customer_city, '') IS NULL) FROM raw.customers
    UNION ALL SELECT 'customers', 'customer_state', COUNT(*) FILTER (WHERE NULLIF(customer_state, '') IS NULL) FROM raw.customers
    UNION ALL SELECT 'orders', 'order_approved_at', COUNT(*) FILTER (WHERE NULLIF(order_approved_at, '') IS NULL) FROM raw.orders
    UNION ALL SELECT 'orders', 'order_delivered_carrier_date', COUNT(*) FILTER (WHERE NULLIF(order_delivered_carrier_date, '') IS NULL) FROM raw.orders
    UNION ALL SELECT 'orders', 'order_delivered_customer_date', COUNT(*) FILTER (WHERE NULLIF(order_delivered_customer_date, '') IS NULL) FROM raw.orders
    UNION ALL SELECT 'products', 'product_category_name', COUNT(*) FILTER (WHERE NULLIF(product_category_name, '') IS NULL) FROM raw.products
    UNION ALL SELECT 'products', 'product_weight_g', COUNT(*) FILTER (WHERE NULLIF(product_weight_g, '') IS NULL) FROM raw.products
    UNION ALL SELECT 'products', 'product_length_cm', COUNT(*) FILTER (WHERE NULLIF(product_length_cm, '') IS NULL) FROM raw.products
    UNION ALL SELECT 'products', 'product_height_cm', COUNT(*) FILTER (WHERE NULLIF(product_height_cm, '') IS NULL) FROM raw.products
    UNION ALL SELECT 'products', 'product_width_cm', COUNT(*) FILTER (WHERE NULLIF(product_width_cm, '') IS NULL) FROM raw.products
    UNION ALL SELECT 'products', 'product_name_lenght', COUNT(*) FILTER (WHERE NULLIF(product_name_lenght, '') IS NULL) FROM raw.products
    UNION ALL SELECT 'products', 'product_description_lenght', COUNT(*) FILTER (WHERE NULLIF(product_description_lenght, '') IS NULL) FROM raw.products
    UNION ALL SELECT 'products', 'product_photos_qty', COUNT(*) FILTER (WHERE NULLIF(product_photos_qty, '') IS NULL) FROM raw.products
    UNION ALL SELECT 'order_reviews', 'review_comment_title', COUNT(*) FILTER (WHERE NULLIF(review_comment_title, '') IS NULL) FROM raw.order_reviews
    UNION ALL SELECT 'order_reviews', 'review_comment_message', COUNT(*) FILTER (WHERE NULLIF(review_comment_message, '') IS NULL) FROM raw.order_reviews
) null_profile
ORDER BY table_name, column_name;

-- 4) Output grain: one row per timestamp column. Regex catches malformed non-empty source values.
SELECT table_name, column_name, min_value, max_value, invalid_format_rows
FROM (
    SELECT 'orders' AS table_name, 'order_purchase_timestamp' AS column_name,
           MIN(NULLIF(order_purchase_timestamp, '')) AS min_value,
           MAX(NULLIF(order_purchase_timestamp, '')) AS max_value,
           COUNT(*) FILTER (WHERE NULLIF(order_purchase_timestamp, '') IS NOT NULL
                            AND order_purchase_timestamp !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') AS invalid_format_rows
    FROM raw.orders
    UNION ALL SELECT 'orders', 'order_approved_at', MIN(NULLIF(order_approved_at, '')), MAX(NULLIF(order_approved_at, '')),
           COUNT(*) FILTER (WHERE NULLIF(order_approved_at, '') IS NOT NULL AND order_approved_at !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') FROM raw.orders
    UNION ALL SELECT 'orders', 'order_delivered_carrier_date', MIN(NULLIF(order_delivered_carrier_date, '')), MAX(NULLIF(order_delivered_carrier_date, '')),
           COUNT(*) FILTER (WHERE NULLIF(order_delivered_carrier_date, '') IS NOT NULL AND order_delivered_carrier_date !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') FROM raw.orders
    UNION ALL SELECT 'orders', 'order_delivered_customer_date', MIN(NULLIF(order_delivered_customer_date, '')), MAX(NULLIF(order_delivered_customer_date, '')),
           COUNT(*) FILTER (WHERE NULLIF(order_delivered_customer_date, '') IS NOT NULL AND order_delivered_customer_date !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') FROM raw.orders
    UNION ALL SELECT 'orders', 'order_estimated_delivery_date', MIN(NULLIF(order_estimated_delivery_date, '')), MAX(NULLIF(order_estimated_delivery_date, '')),
           COUNT(*) FILTER (WHERE NULLIF(order_estimated_delivery_date, '') IS NOT NULL AND order_estimated_delivery_date !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') FROM raw.orders
    UNION ALL SELECT 'order_items', 'shipping_limit_date', MIN(NULLIF(shipping_limit_date, '')), MAX(NULLIF(shipping_limit_date, '')),
           COUNT(*) FILTER (WHERE NULLIF(shipping_limit_date, '') IS NOT NULL AND shipping_limit_date !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') FROM raw.order_items
    UNION ALL SELECT 'order_reviews', 'review_creation_date', MIN(NULLIF(review_creation_date, '')), MAX(NULLIF(review_creation_date, '')),
           COUNT(*) FILTER (WHERE NULLIF(review_creation_date, '') IS NOT NULL AND review_creation_date !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') FROM raw.order_reviews
    UNION ALL SELECT 'order_reviews', 'review_answer_timestamp', MIN(NULLIF(review_answer_timestamp, '')), MAX(NULLIF(review_answer_timestamp, '')),
           COUNT(*) FILTER (WHERE NULLIF(review_answer_timestamp, '') IS NOT NULL AND review_answer_timestamp !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') FROM raw.order_reviews
) date_profile
ORDER BY table_name, column_name;

-- 5) Output grain: one row per operational child-to-parent relationship.
SELECT relationship, child_distinct_keys, matched_parent_keys,
       child_distinct_keys - matched_parent_keys AS unmatched_child_keys
FROM (
    SELECT 'orders.customer_id -> customers.customer_id' AS relationship,
           COUNT(DISTINCT o.customer_id) AS child_distinct_keys,
           COUNT(DISTINCT c.customer_id) AS matched_parent_keys
    FROM raw.orders o LEFT JOIN raw.customers c ON c.customer_id = o.customer_id
    UNION ALL SELECT 'order_items.order_id -> orders.order_id', COUNT(DISTINCT i.order_id), COUNT(DISTINCT o.order_id)
    FROM raw.order_items i LEFT JOIN raw.orders o ON o.order_id = i.order_id
    UNION ALL SELECT 'order_items.product_id -> products.product_id', COUNT(DISTINCT i.product_id), COUNT(DISTINCT p.product_id)
    FROM raw.order_items i LEFT JOIN raw.products p ON p.product_id = i.product_id
    UNION ALL SELECT 'order_items.seller_id -> sellers.seller_id', COUNT(DISTINCT i.seller_id), COUNT(DISTINCT s.seller_id)
    FROM raw.order_items i LEFT JOIN raw.sellers s ON s.seller_id = i.seller_id
    UNION ALL SELECT 'order_payments.order_id -> orders.order_id', COUNT(DISTINCT p.order_id), COUNT(DISTINCT o.order_id)
    FROM raw.order_payments p LEFT JOIN raw.orders o ON o.order_id = p.order_id
    UNION ALL SELECT 'order_reviews.order_id -> orders.order_id', COUNT(DISTINCT r.order_id), COUNT(DISTINCT o.order_id)
    FROM raw.order_reviews r LEFT JOIN raw.orders o ON o.order_id = r.order_id
    UNION ALL SELECT 'products.category -> category_translation.category', COUNT(DISTINCT p.product_category_name), COUNT(DISTINCT t.product_category_name)
    FROM raw.products p LEFT JOIN raw.category_translation t ON t.product_category_name = p.product_category_name
) fk_profile
ORDER BY relationship;

-- 6) Output grain: one row per detailed child-table relationship. This exposes join multiplication risk.
SELECT relationship, parent_keys, repeated_parent_keys, max_children_per_parent
FROM (
    SELECT 'order_items per order' AS relationship, COUNT(*) AS parent_keys,
           COUNT(*) FILTER (WHERE child_count > 1) AS repeated_parent_keys,
           MAX(child_count) AS max_children_per_parent
    FROM (SELECT order_id, COUNT(*) AS child_count FROM raw.order_items GROUP BY order_id) x
    UNION ALL SELECT 'order_payments per order', COUNT(*), COUNT(*) FILTER (WHERE child_count > 1), MAX(child_count)
    FROM (SELECT order_id, COUNT(*) AS child_count FROM raw.order_payments GROUP BY order_id) x
    UNION ALL SELECT 'order_reviews per order', COUNT(*), COUNT(*) FILTER (WHERE child_count > 1), MAX(child_count)
    FROM (SELECT order_id, COUNT(*) AS child_count FROM raw.order_reviews GROUP BY order_id) x
    UNION ALL SELECT 'geolocation observations per ZIP prefix', COUNT(*), COUNT(*) FILTER (WHERE child_count > 1), MAX(child_count)
    FROM (SELECT geolocation_zip_code_prefix, COUNT(*) AS child_count FROM raw.geolocation GROUP BY geolocation_zip_code_prefix) x
) one_to_many_profile
ORDER BY relationship;

-- 7) Output grain: one row per order status. Preserve source lifecycle categories for later denominators.
SELECT order_status, COUNT(*) AS order_rows
FROM raw.orders
GROUP BY order_status
ORDER BY order_rows DESC, order_status;

-- 8) Output grain: one row per raw table and PostgreSQL storage type. Raw landing columns remain text.
SELECT table_name, data_type, COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'raw'
GROUP BY table_name, data_type
ORDER BY table_name, data_type;

-- 9) Output grain: one row for the geolocation full-row duplicate check.
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
                       geolocation_city, geolocation_state)) AS distinct_full_rows,
       COUNT(*) - COUNT(DISTINCT (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
                                  geolocation_city, geolocation_state)) AS duplicate_excess_rows
FROM raw.geolocation;
