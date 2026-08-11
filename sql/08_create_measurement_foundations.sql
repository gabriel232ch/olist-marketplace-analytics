
-- Core grains:
--   analytics.order_review_selected: one row per reviewed order_id
--   analytics.order_measurement_base: one row per order_id
--   analytics.item_measurement_base: one row per (order_id, order_item_id)
--   analytics.customer_measurement_base: one row per customer_unique_id

BEGIN;

-- Output grain: exactly one row containing the approved measurement rules.
CREATE OR REPLACE VIEW analytics.measurement_parameters AS
SELECT
    DATE '2017-01-01' AS stable_period_start,
    DATE '2018-09-01' AS stable_period_end_exclusive,
    DATE '2017-01-01' AS yoy_prior_start,
    DATE '2017-09-01' AS yoy_prior_end_exclusive,
    DATE '2018-01-01' AS yoy_current_start,
    DATE '2018-09-01' AS yoy_current_end_exclusive,
    400::integer AS high_confidence_min_orders,
    100::integer AS medium_confidence_min_orders,
    30::integer AS exploratory_min_orders,
    0.95::numeric(4, 3) AS headline_review_coverage_min;

COMMENT ON VIEW analytics.measurement_parameters IS
'One-row Stage 5B contract for stable periods, matched Jan-Aug comparison windows, volume confidence bands, and review coverage.';

-- Output grain: one deterministic selected review per reviewed order.
-- Latest answer timestamp is the primary rule; creation timestamp and review_id
-- are deterministic tie-breakers. Profiling found zero latest-timestamp ties.
CREATE OR REPLACE VIEW analytics.order_review_selected AS
WITH review_profile AS (
    SELECT
        order_id,
        COUNT(*) AS review_rows_for_order,
        COUNT(DISTINCT review_score) AS distinct_review_scores
    FROM staging.order_reviews
    GROUP BY order_id
), ranked_reviews AS (
    SELECT
        r.*,
        ROW_NUMBER() OVER (
            PARTITION BY r.order_id
            ORDER BY r.review_answer_timestamp DESC,
                     r.review_creation_date DESC,
                     r.review_id DESC
        ) AS selection_rank
    FROM staging.order_reviews r
)
SELECT
    r.order_id,
    r.review_id,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    r.review_creation_date,
    r.review_answer_timestamp,
    p.review_rows_for_order,
    p.distinct_review_scores,
    (p.review_rows_for_order > 1) AS has_multiple_review_rows,
    (p.distinct_review_scores > 1) AS has_conflicting_review_scores
FROM ranked_reviews r
JOIN review_profile p USING (order_id)
WHERE r.selection_rank = 1;

COMMENT ON VIEW analytics.order_review_selected IS
'One row per reviewed order_id using the latest answered review with deterministic tie-breakers; preserves multiplicity/conflict flags.';

-- Output grain: one order. Every one-to-many child is summarized before join.
CREATE OR REPLACE VIEW analytics.order_measurement_base AS
WITH item_summary AS (
    SELECT
        i.order_id,
        COUNT(*) AS item_rows,
        COUNT(DISTINCT i.product_id) AS product_count,
        COUNT(DISTINCT i.seller_id) AS seller_count,
        COUNT(DISTINCT CASE
            WHEN p.product_category_name IS NULL THEN '[unknown]'
            WHEN t.product_category_name_english IS NOT NULL
                THEN t.product_category_name_english
            ELSE '[unmapped] ' || p.product_category_name
        END) AS category_count,
        SUM(i.price) AS item_gmv_proxy,
        SUM(i.freight_value) AS freight_value
    FROM staging.order_items i
    JOIN staging.products p ON p.product_id = i.product_id
    LEFT JOIN staging.category_translation t
      ON t.product_category_name = p.product_category_name
    GROUP BY i.order_id
), payment_summary AS (
    SELECT
        order_id,
        COUNT(*) AS payment_rows,
        SUM(payment_value) AS payment_value
    FROM staging.order_payments
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    date_trunc('month', o.order_purchase_timestamp)::date AS purchase_month,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    CASE WHEN o.order_delivered_customer_date IS NOT NULL
        THEN date_trunc('month', o.order_delivered_customer_date)::date
    END AS delivery_month,
    o.order_estimated_delivery_date,
    (o.order_purchase_timestamp >= DATE '2017-01-01'
     AND o.order_purchase_timestamp < DATE '2018-09-01') AS is_stable_period,
    CASE
        WHEN o.order_purchase_timestamp >= DATE '2017-01-01'
         AND o.order_purchase_timestamp < DATE '2017-09-01' THEN '2017_JAN_AUG'
        WHEN o.order_purchase_timestamp >= DATE '2018-01-01'
         AND o.order_purchase_timestamp < DATE '2018-09-01' THEN '2018_JAN_AUG'
        ELSE 'NOT_YOY_COMPARABLE'
    END AS yoy_comparison_period,
    COALESCE(i.item_rows, 0) AS item_rows,
    COALESCE(i.product_count, 0) AS product_count,
    COALESCE(i.seller_count, 0) AS seller_count,
    COALESCE(i.category_count, 0) AS category_count,
    i.item_gmv_proxy,
    i.freight_value,
    COALESCE(p.payment_rows, 0) AS payment_rows,
    p.payment_value,
    (i.order_id IS NOT NULL) AS has_items,
    (p.order_id IS NOT NULL) AS has_payment,
    (o.order_status = 'delivered' AND i.order_id IS NOT NULL) AS is_delivered_commercial,
    (o.order_status = 'canceled') AS is_canceled,
    (o.order_status = 'unavailable') AS is_unavailable,
    (COALESCE(i.seller_count, 0) = 1) AS is_single_seller_order,
    (COALESCE(i.seller_count, 0) > 1) AS is_multi_seller_order,
    (o.order_status = 'delivered'
     AND i.order_id IS NOT NULL
     AND o.order_delivered_customer_date IS NOT NULL
     AND o.order_estimated_delivery_date IS NOT NULL
     AND o.order_delivered_customer_date >= o.order_purchase_timestamp) AS is_on_time_eligible,
    CASE WHEN o.order_status = 'delivered'
              AND i.order_id IS NOT NULL
              AND o.order_delivered_customer_date IS NOT NULL
              AND o.order_estimated_delivery_date IS NOT NULL
              AND o.order_delivered_customer_date >= o.order_purchase_timestamp
        THEN o.order_delivered_customer_date::date <= o.order_estimated_delivery_date::date
    END AS is_on_time,
    CASE WHEN o.order_status = 'delivered'
              AND i.order_id IS NOT NULL
              AND o.order_delivered_customer_date IS NOT NULL
              AND o.order_estimated_delivery_date IS NOT NULL
              AND o.order_delivered_customer_date >= o.order_purchase_timestamp
        THEN o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date
    END AS days_vs_estimate,
    CASE WHEN o.order_status = 'delivered'
              AND i.order_id IS NOT NULL
              AND o.order_delivered_customer_date IS NOT NULL
              AND o.order_estimated_delivery_date IS NOT NULL
              AND o.order_delivered_customer_date >= o.order_purchase_timestamp
        THEN GREATEST(
            o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date,
            0
        )
    END AS delay_days,
    (o.order_status = 'delivered'
     AND o.order_approved_at IS NOT NULL
     AND o.order_approved_at >= o.order_purchase_timestamp) AS is_approval_valid,
    CASE WHEN o.order_status = 'delivered'
              AND o.order_approved_at IS NOT NULL
              AND o.order_approved_at >= o.order_purchase_timestamp
        THEN EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp)) / 3600.0
    END AS approval_hours,
    (o.order_status = 'delivered'
     AND o.order_approved_at IS NOT NULL
     AND o.order_delivered_carrier_date IS NOT NULL
     AND o.order_delivered_carrier_date >= o.order_approved_at
     AND o.order_delivered_carrier_date >= o.order_purchase_timestamp) AS is_handling_valid,
    CASE WHEN o.order_status = 'delivered'
              AND o.order_approved_at IS NOT NULL
              AND o.order_delivered_carrier_date IS NOT NULL
              AND o.order_delivered_carrier_date >= o.order_approved_at
              AND o.order_delivered_carrier_date >= o.order_purchase_timestamp
        THEN EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at)) / 3600.0
    END AS handling_hours,
    (o.order_status = 'delivered'
     AND o.order_delivered_carrier_date IS NOT NULL
     AND o.order_delivered_customer_date IS NOT NULL
     AND o.order_delivered_customer_date >= o.order_delivered_carrier_date) AS is_carrier_valid,
    CASE WHEN o.order_status = 'delivered'
              AND o.order_delivered_carrier_date IS NOT NULL
              AND o.order_delivered_customer_date IS NOT NULL
              AND o.order_delivered_customer_date >= o.order_delivered_carrier_date
        THEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_delivered_carrier_date)) / 3600.0
    END AS carrier_hours,
    (o.order_status = 'delivered'
     AND o.order_delivered_customer_date IS NOT NULL
     AND o.order_delivered_customer_date >= o.order_purchase_timestamp) AS is_lead_time_valid,
    CASE WHEN o.order_status = 'delivered'
              AND o.order_delivered_customer_date IS NOT NULL
              AND o.order_delivered_customer_date >= o.order_purchase_timestamp
        THEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 3600.0
    END AS lead_time_hours,
    r.review_id AS selected_review_id,
    r.review_score AS selected_review_score,
    r.review_creation_date AS selected_review_creation_date,
    r.review_answer_timestamp AS selected_review_answer_timestamp,
    COALESCE(r.review_rows_for_order, 0) AS review_rows_for_order,
    COALESCE(r.has_multiple_review_rows, false) AS has_multiple_review_rows,
    COALESCE(r.has_conflicting_review_scores, false) AS has_conflicting_review_scores,
    (r.order_id IS NOT NULL) AS has_selected_review
FROM staging.orders o
JOIN staging.customers c ON c.customer_id = o.customer_id
LEFT JOIN item_summary i ON i.order_id = o.order_id
LEFT JOIN payment_summary p ON p.order_id = o.order_id
LEFT JOIN analytics.order_review_selected r ON r.order_id = o.order_id;

COMMENT ON VIEW analytics.order_measurement_base IS
'One row per order_id. Items, payments, and reviews are pre-aggregated/selected before joining; includes population, period, anomaly, fulfillment, and coverage flags.';

-- Output grain: one item line. Order-level outcome fields repeat by design and
-- must be counted with DISTINCT order_id when used at a segment grain.
CREATE OR REPLACE VIEW analytics.item_measurement_base AS
SELECT
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    o.customer_unique_id,
    o.customer_state,
    s.seller_state,
    p.product_category_name AS product_category_name_portuguese,
    t.product_category_name_english,
    CASE
        WHEN p.product_category_name IS NULL THEN '[unknown]'
        WHEN t.product_category_name_english IS NOT NULL
            THEN t.product_category_name_english
        ELSE '[unmapped] ' || p.product_category_name
    END AS category_name,
    i.shipping_limit_date,
    i.price AS item_gmv_proxy,
    i.freight_value,
    o.order_status,
    o.order_purchase_timestamp,
    o.purchase_month,
    o.is_stable_period,
    o.yoy_comparison_period,
    o.is_delivered_commercial,
    o.seller_count AS order_seller_count,
    o.is_single_seller_order,
    o.is_multi_seller_order,
    o.is_on_time_eligible,
    o.is_on_time,
    o.days_vs_estimate,
    o.delay_days,
    o.is_handling_valid,
    o.handling_hours,
    o.is_carrier_valid,
    o.carrier_hours,
    o.is_lead_time_valid,
    o.lead_time_hours,
    o.has_selected_review,
    o.selected_review_score
FROM staging.order_items i
JOIN analytics.order_measurement_base o ON o.order_id = i.order_id
JOIN staging.products p ON p.product_id = i.product_id
LEFT JOIN staging.category_translation t
  ON t.product_category_name = p.product_category_name
JOIN staging.sellers s ON s.seller_id = i.seller_id;

COMMENT ON VIEW analytics.item_measurement_base IS
'One row per (order_id, order_item_id) for category x customer-state x seller allocation. Order outcomes repeat across items and are non-additive.';

-- Output grain: one persistent customer identity. This is a suitability base,
-- not a headline RFM model.
CREATE OR REPLACE VIEW analytics.customer_measurement_base AS
WITH delivered_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        item_gmv_proxy,
        MIN(order_purchase_timestamp) OVER (
            PARTITION BY customer_unique_id
        ) AS first_delivered_purchase_timestamp
    FROM analytics.order_measurement_base
    WHERE is_delivered_commercial
), customer_delivered AS (
    SELECT
        customer_unique_id,
        MIN(first_delivered_purchase_timestamp) AS first_delivered_purchase_timestamp,
        MAX(order_purchase_timestamp) AS last_delivered_purchase_timestamp,
        COUNT(*) AS delivered_orders,
        SUM(item_gmv_proxy) AS delivered_gmv_proxy,
        COUNT(*) FILTER (
            WHERE order_purchase_timestamp
                  <= first_delivered_purchase_timestamp + INTERVAL '365 days'
        ) AS delivered_orders_within_365_days
    FROM delivered_orders
    GROUP BY customer_unique_id
), placed AS (
    SELECT customer_unique_id, COUNT(*) AS placed_orders
    FROM analytics.order_measurement_base
    GROUP BY customer_unique_id
)
SELECT
    p.customer_unique_id,
    p.placed_orders,
    COALESCE(d.delivered_orders, 0) AS delivered_orders,
    d.delivered_gmv_proxy,
    d.first_delivered_purchase_timestamp,
    d.last_delivered_purchase_timestamp,
    (COALESCE(d.delivered_orders, 0) >= 2) AS is_observed_repeat_customer,
    (d.first_delivered_purchase_timestamp < DATE '2017-09-01') AS has_365_day_followup,
    CASE WHEN d.first_delivered_purchase_timestamp < DATE '2017-09-01'
        THEN d.delivered_orders_within_365_days >= 2
    END AS is_repeat_within_365_days
FROM placed p
LEFT JOIN customer_delivered d USING (customer_unique_id);

COMMENT ON VIEW analytics.customer_measurement_base IS
'One row per customer_unique_id with placed/delivered counts and equal-365-day follow-up flags; intended for RFM/repeat suitability testing only.';

COMMIT;
