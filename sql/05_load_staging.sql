-- Stage 4 typed staging transform.
-- Purpose: convert the audited text landing layer into typed, constrained tables.
-- This script changes staging.* only; raw.* remains immutable.
-- A failed cast or constraint violation rolls back the entire load.

BEGIN;

-- Stage 2B created numeric(17,16) before the raw profile exposed two
-- three-integer-digit longitude values. Widen the typed contract so the
-- source remains lossless; this is idempotent on later rebuilds.
ALTER TABLE staging.geolocation_observations
    ALTER COLUMN geolocation_lng TYPE numeric(19, 16);
ALTER TABLE staging.geolocation_observations
    ALTER COLUMN geolocation_lat TYPE numeric(22, 20);

-- The staging layer is rebuildable. Keep the refresh atomic and reset the
-- generated geolocation key only after all existing rows are removed.
TRUNCATE TABLE
    staging.order_reviews,
    staging.order_payments,
    staging.order_items,
    staging.orders,
    staging.category_translation,
    staging.products,
    staging.sellers,
    staging.customers,
    staging.geolocation_observations
RESTART IDENTITY;

-- Output grain: one typed row per customer source record.
INSERT INTO staging.customers (
    customer_id, customer_unique_id, customer_zip_code_prefix,
    customer_city, customer_state
)
SELECT
    NULLIF(customer_id, ''),
    NULLIF(customer_unique_id, ''),
    NULLIF(customer_zip_code_prefix, ''),
    NULLIF(customer_city, ''),
    NULLIF(customer_state, '')
FROM raw.customers;

-- Output grain: one typed row per product.
INSERT INTO staging.products (
    product_id, product_category_name, product_name_lenght,
    product_description_lenght, product_photos_qty, product_weight_g,
    product_length_cm, product_height_cm, product_width_cm
)
SELECT
    NULLIF(product_id, ''),
    NULLIF(product_category_name, ''),
    NULLIF(product_name_lenght, '')::integer,
    NULLIF(product_description_lenght, '')::integer,
    NULLIF(product_photos_qty, '')::integer,
    NULLIF(product_weight_g, '')::integer,
    NULLIF(product_length_cm, '')::integer,
    NULLIF(product_height_cm, '')::integer,
    NULLIF(product_width_cm, '')::integer
FROM raw.products;

-- Output grain: one typed row per seller.
INSERT INTO staging.sellers (
    seller_id, seller_zip_code_prefix, seller_city, seller_state
)
SELECT
    NULLIF(seller_id, ''),
    NULLIF(seller_zip_code_prefix, ''),
    NULLIF(seller_city, ''),
    NULLIF(seller_state, '')
FROM raw.sellers;

-- Output grain: one typed Portuguese-to-English category mapping.
INSERT INTO staging.category_translation (
    product_category_name, product_category_name_english
)
SELECT
    NULLIF(product_category_name, ''),
    NULLIF(product_category_name_english, '')
FROM raw.category_translation;

-- Output grain: one typed row per order.
INSERT INTO staging.orders (
    order_id, customer_id, order_status, order_purchase_timestamp,
    order_approved_at, order_delivered_carrier_date,
    order_delivered_customer_date, order_estimated_delivery_date
)
SELECT
    NULLIF(order_id, ''),
    NULLIF(customer_id, ''),
    NULLIF(order_status, ''),
    NULLIF(order_purchase_timestamp, '')::timestamp,
    NULLIF(order_approved_at, '')::timestamp,
    NULLIF(order_delivered_carrier_date, '')::timestamp,
    NULLIF(order_delivered_customer_date, '')::timestamp,
    NULLIF(order_estimated_delivery_date, '')::timestamp
FROM raw.orders;

-- Output grain: one typed item line per (order_id, order_item_id).
INSERT INTO staging.order_items (
    order_id, order_item_id, product_id, seller_id, shipping_limit_date,
    price, freight_value
)
SELECT
    NULLIF(order_id, ''),
    NULLIF(order_item_id, '')::integer,
    NULLIF(product_id, ''),
    NULLIF(seller_id, ''),
    NULLIF(shipping_limit_date, '')::timestamp,
    NULLIF(price, '')::numeric(12, 2),
    NULLIF(freight_value, '')::numeric(12, 2)
FROM raw.order_items;

-- Output grain: one typed payment sequence per (order_id, payment_sequential).
INSERT INTO staging.order_payments (
    order_id, payment_sequential, payment_type, payment_installments,
    payment_value
)
SELECT
    NULLIF(order_id, ''),
    NULLIF(payment_sequential, '')::integer,
    NULLIF(payment_type, ''),
    NULLIF(payment_installments, '')::integer,
    NULLIF(payment_value, '')::numeric(12, 2)
FROM raw.order_payments;

-- Output grain: one typed review-to-order association per (review_id, order_id).
INSERT INTO staging.order_reviews (
    review_id, order_id, review_score, review_comment_title,
    review_comment_message, review_creation_date, review_answer_timestamp
)
SELECT
    NULLIF(review_id, ''),
    NULLIF(order_id, ''),
    NULLIF(review_score, '')::smallint,
    NULLIF(review_comment_title, ''),
    NULLIF(review_comment_message, ''),
    NULLIF(review_creation_date, '')::timestamp,
    NULLIF(review_answer_timestamp, '')::timestamp
FROM raw.order_reviews;

-- Output grain: one typed geolocation observation. The generated key is
-- technical only; ZIP prefixes intentionally remain repeated at this grain.
INSERT INTO staging.geolocation_observations (
    geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
    geolocation_city, geolocation_state
)
SELECT
    NULLIF(geolocation_zip_code_prefix, ''),
    NULLIF(geolocation_lat, '')::numeric(22, 20),
    NULLIF(geolocation_lng, '')::numeric(19, 16),
    NULLIF(geolocation_city, ''),
    NULLIF(geolocation_state, '')
FROM raw.geolocation;

COMMIT;
