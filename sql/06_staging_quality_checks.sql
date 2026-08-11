
-- 1) Output grain: one row per source/staging table pair. Counts must reconcile.
WITH counts(table_name, raw_rows, staging_rows) AS (
    SELECT 'customers', (SELECT COUNT(*) FROM raw.customers), (SELECT COUNT(*) FROM staging.customers)
    UNION ALL SELECT 'products', (SELECT COUNT(*) FROM raw.products), (SELECT COUNT(*) FROM staging.products)
    UNION ALL SELECT 'sellers', (SELECT COUNT(*) FROM raw.sellers), (SELECT COUNT(*) FROM staging.sellers)
    UNION ALL SELECT 'category_translation', (SELECT COUNT(*) FROM raw.category_translation), (SELECT COUNT(*) FROM staging.category_translation)
    UNION ALL SELECT 'orders', (SELECT COUNT(*) FROM raw.orders), (SELECT COUNT(*) FROM staging.orders)
    UNION ALL SELECT 'order_items', (SELECT COUNT(*) FROM raw.order_items), (SELECT COUNT(*) FROM staging.order_items)
    UNION ALL SELECT 'order_payments', (SELECT COUNT(*) FROM raw.order_payments), (SELECT COUNT(*) FROM staging.order_payments)
    UNION ALL SELECT 'order_reviews', (SELECT COUNT(*) FROM raw.order_reviews), (SELECT COUNT(*) FROM staging.order_reviews)
    UNION ALL SELECT 'geolocation', (SELECT COUNT(*) FROM raw.geolocation), (SELECT COUNT(*) FROM staging.geolocation_observations)
)
SELECT table_name, raw_rows, staging_rows,
       staging_rows - raw_rows AS row_difference,
       raw_rows = staging_rows AS row_count_matches
FROM counts
ORDER BY table_name;

-- 2) Output grain: one row per staging key or required-column check.
SELECT check_name, violation_rows
FROM (
    SELECT 'customers.customer_id missing' AS check_name,
           COUNT(*) FILTER (WHERE customer_id IS NULL) AS violation_rows FROM staging.customers
    UNION ALL SELECT 'customers.customer_id duplicate', COUNT(*) - COUNT(DISTINCT customer_id) FROM staging.customers
    UNION ALL SELECT 'products.product_id missing', COUNT(*) FILTER (WHERE product_id IS NULL) FROM staging.products
    UNION ALL SELECT 'products.product_id duplicate', COUNT(*) - COUNT(DISTINCT product_id) FROM staging.products
    UNION ALL SELECT 'sellers.seller_id missing', COUNT(*) FILTER (WHERE seller_id IS NULL) FROM staging.sellers
    UNION ALL SELECT 'sellers.seller_id duplicate', COUNT(*) - COUNT(DISTINCT seller_id) FROM staging.sellers
    UNION ALL SELECT 'orders.order_id missing', COUNT(*) FILTER (WHERE order_id IS NULL) FROM staging.orders
    UNION ALL SELECT 'orders.order_id duplicate', COUNT(*) - COUNT(DISTINCT order_id) FROM staging.orders
    UNION ALL SELECT 'order_items composite key duplicate', COUNT(*) - COUNT(DISTINCT (order_id, order_item_id)) FROM staging.order_items
    UNION ALL SELECT 'order_payments composite key duplicate', COUNT(*) - COUNT(DISTINCT (order_id, payment_sequential)) FROM staging.order_payments
    UNION ALL SELECT 'order_reviews composite key duplicate', COUNT(*) - COUNT(DISTINCT (review_id, order_id)) FROM staging.order_reviews
    UNION ALL SELECT 'geolocation required fields missing',
        COUNT(*) FILTER (WHERE geolocation_zip_code_prefix IS NULL OR geolocation_lat IS NULL
                         OR geolocation_lng IS NULL OR geolocation_city IS NULL OR geolocation_state IS NULL)
        FROM staging.geolocation_observations
) key_profile
ORDER BY check_name;

-- 3) Output grain: one row per staging child-to-parent relationship. Constraints
-- should make unmatched keys zero; the explicit counts make the result auditable.
SELECT relationship, child_distinct_keys, matched_parent_keys,
       child_distinct_keys - matched_parent_keys AS unmatched_child_keys
FROM (
    SELECT 'orders.customer_id -> customers.customer_id' AS relationship,
           COUNT(DISTINCT o.customer_id) AS child_distinct_keys,
           COUNT(DISTINCT c.customer_id) AS matched_parent_keys
    FROM staging.orders o LEFT JOIN staging.customers c ON c.customer_id = o.customer_id
    UNION ALL SELECT 'order_items.order_id -> orders.order_id', COUNT(DISTINCT i.order_id), COUNT(DISTINCT o.order_id)
    FROM staging.order_items i LEFT JOIN staging.orders o ON o.order_id = i.order_id
    UNION ALL SELECT 'order_items.product_id -> products.product_id', COUNT(DISTINCT i.product_id), COUNT(DISTINCT p.product_id)
    FROM staging.order_items i LEFT JOIN staging.products p ON p.product_id = i.product_id
    UNION ALL SELECT 'order_items.seller_id -> sellers.seller_id', COUNT(DISTINCT i.seller_id), COUNT(DISTINCT s.seller_id)
    FROM staging.order_items i LEFT JOIN staging.sellers s ON s.seller_id = i.seller_id
    UNION ALL SELECT 'order_payments.order_id -> orders.order_id', COUNT(DISTINCT p.order_id), COUNT(DISTINCT o.order_id)
    FROM staging.order_payments p LEFT JOIN staging.orders o ON o.order_id = p.order_id
    UNION ALL SELECT 'order_reviews.order_id -> orders.order_id', COUNT(DISTINCT r.order_id), COUNT(DISTINCT o.order_id)
    FROM staging.order_reviews r LEFT JOIN staging.orders o ON o.order_id = r.order_id
    UNION ALL SELECT 'products.category -> category_translation.category', COUNT(DISTINCT p.product_category_name), COUNT(DISTINCT t.product_category_name)
    FROM staging.products p LEFT JOIN staging.category_translation t ON t.product_category_name = p.product_category_name
) fk_profile
ORDER BY relationship;

-- 4) Output grain: one row per typed domain or chronology rule.
SELECT check_name, violation_rows
FROM (
    SELECT 'negative item price' AS check_name, COUNT(*) FILTER (WHERE price < 0) AS violation_rows FROM staging.order_items
    UNION ALL SELECT 'negative freight value', COUNT(*) FILTER (WHERE freight_value < 0) FROM staging.order_items
    UNION ALL SELECT 'negative payment value', COUNT(*) FILTER (WHERE payment_value < 0) FROM staging.order_payments
    UNION ALL SELECT 'payment installments below 1', COUNT(*) FILTER (WHERE payment_installments < 1) FROM staging.order_payments
    UNION ALL SELECT 'review score outside 1..5', COUNT(*) FILTER (WHERE review_score NOT BETWEEN 1 AND 5) FROM staging.order_reviews
    UNION ALL SELECT 'latitude outside -90..90', COUNT(*) FILTER (WHERE geolocation_lat NOT BETWEEN -90 AND 90) FROM staging.geolocation_observations
    UNION ALL SELECT 'longitude outside -180..180', COUNT(*) FILTER (WHERE geolocation_lng NOT BETWEEN -180 AND 180) FROM staging.geolocation_observations
    UNION ALL SELECT 'approved before purchase', COUNT(*) FILTER (WHERE order_approved_at IS NOT NULL AND order_approved_at < order_purchase_timestamp) FROM staging.orders
    UNION ALL SELECT 'carrier before purchase', COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NOT NULL AND order_delivered_carrier_date < order_purchase_timestamp) FROM staging.orders
    UNION ALL SELECT 'customer delivery before purchase', COUNT(*) FILTER (WHERE order_delivered_customer_date IS NOT NULL AND order_delivered_customer_date < order_purchase_timestamp) FROM staging.orders
    UNION ALL SELECT 'customer delivery before carrier', COUNT(*) FILTER (WHERE order_delivered_customer_date IS NOT NULL AND order_delivered_carrier_date IS NOT NULL AND order_delivered_customer_date < order_delivered_carrier_date) FROM staging.orders
) domain_profile
ORDER BY check_name;

-- 5) Output grain: one row per order status. Delivery denominator decisions must
-- keep delivered, canceled, unavailable, and in-process statuses distinct.
SELECT order_status, COUNT(*) AS order_rows,
       COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS missing_customer_delivery_date
FROM staging.orders
GROUP BY order_status
ORDER BY order_rows DESC, order_status;

-- 6) Output grain: one row per amount reconciliation. Raw values are independently
-- cast here so a staging sum is checked against the source, not against itself.
WITH raw_totals AS (
    SELECT
        COUNT(*) AS item_rows,
        SUM(NULLIF(price, '')::numeric(12, 2)) AS item_price_total,
        SUM(NULLIF(freight_value, '')::numeric(12, 2)) AS freight_total
    FROM raw.order_items
), staging_totals AS (
    SELECT
        COUNT(*) AS item_rows,
        SUM(price) AS item_price_total,
        SUM(freight_value) AS freight_total
    FROM staging.order_items
), raw_payments AS (
    SELECT SUM(NULLIF(payment_value, '')::numeric(12, 2)) AS payment_total
    FROM raw.order_payments
), staging_payments AS (
    SELECT SUM(payment_value) AS payment_total
    FROM staging.order_payments
)
SELECT 'order_items' AS measure,
       r.item_rows AS raw_rows, s.item_rows AS staging_rows,
       r.item_price_total AS raw_item_price_total, s.item_price_total AS staging_item_price_total,
       r.freight_total AS raw_freight_total, s.freight_total AS staging_freight_total,
       r.item_rows = s.item_rows AND r.item_price_total = s.item_price_total
           AND r.freight_total = s.freight_total AS reconciles
FROM raw_totals r CROSS JOIN staging_totals s
UNION ALL
SELECT 'order_payments',
       (SELECT COUNT(*) FROM raw.order_payments), (SELECT COUNT(*) FROM staging.order_payments),
       NULL, NULL,
       r.payment_total, s.payment_total,
       r.payment_total = s.payment_total
FROM raw_payments r CROSS JOIN staging_payments s;

-- 7) Output grain: one row per one-to-many child relationship. This remains a
-- warning for future joins, not a failure of the typed load.
SELECT relationship, parent_keys, repeated_parent_keys, max_children_per_parent
FROM (
    SELECT 'order_items per order' AS relationship, COUNT(*) AS parent_keys,
           COUNT(*) FILTER (WHERE child_count > 1) AS repeated_parent_keys,
           MAX(child_count) AS max_children_per_parent
    FROM (SELECT order_id, COUNT(*) AS child_count FROM staging.order_items GROUP BY order_id) x
    UNION ALL SELECT 'order_payments per order', COUNT(*), COUNT(*) FILTER (WHERE child_count > 1), MAX(child_count)
    FROM (SELECT order_id, COUNT(*) AS child_count FROM staging.order_payments GROUP BY order_id) x
    UNION ALL SELECT 'order_reviews per order', COUNT(*), COUNT(*) FILTER (WHERE child_count > 1), MAX(child_count)
    FROM (SELECT order_id, COUNT(*) AS child_count FROM staging.order_reviews GROUP BY order_id) x
    UNION ALL SELECT 'geolocation observations per ZIP prefix', COUNT(*), COUNT(*) FILTER (WHERE child_count > 1), MAX(child_count)
    FROM (SELECT geolocation_zip_code_prefix, COUNT(*) AS child_count FROM staging.geolocation_observations GROUP BY geolocation_zip_code_prefix) x
) one_to_many_profile
ORDER BY relationship;

-- 8) Output grain: one row per category-mapping exception. These are expected
-- source cases and are retained by the left-join policy.
SELECT COALESCE(p.product_category_name, '[blank]') AS product_category_name,
       COUNT(*) AS product_rows
FROM staging.products p
LEFT JOIN staging.category_translation t
    ON t.product_category_name = p.product_category_name
WHERE p.product_category_name IS NULL OR t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY product_rows DESC, product_category_name;
