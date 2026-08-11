

-- 1) Output grain: one row per purchase month.
-- Business purpose: identify partial/censored months and select comparable periods.
SELECT
    date_trunc('month', order_purchase_timestamp)::date AS purchase_month,
    COUNT(*) AS placed_orders,
    COUNT(*) FILTER (WHERE order_status = 'delivered') AS delivered_orders,
    COUNT(*) FILTER (
        WHERE order_status IN ('shipped', 'invoiced', 'processing', 'created', 'approved')
    ) AS unresolved_orders,
    COUNT(*) FILTER (WHERE order_status IN ('canceled', 'unavailable')) AS canceled_or_unavailable_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_status IN ('shipped', 'invoiced', 'processing', 'created', 'approved')
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS unresolved_rate_pct
FROM staging.orders
GROUP BY 1
ORDER BY 1;

-- 2) Output grain: one row per proposed population/interval.
-- Business purpose: expose every denominator and excluded chronology row.
WITH item_orders AS (
    SELECT
        order_id,
        COUNT(*) AS item_rows,
        COUNT(DISTINCT seller_id) AS seller_count
    FROM staging.order_items
    GROUP BY order_id
)
SELECT population_name, eligible_orders
FROM (
    SELECT 'P0 all-order audit' AS population_name, COUNT(*) AS eligible_orders
    FROM staging.orders

    UNION ALL
    SELECT 'P2 delivered commercial', COUNT(*)
    FROM staging.orders o
    JOIN item_orders i USING (order_id)
    WHERE o.order_status = 'delivered'

    UNION ALL
    SELECT 'P3 on-time eligible', COUNT(*)
    FROM staging.orders o
    JOIN item_orders i USING (order_id)
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
      AND o.order_delivered_customer_date >= o.order_purchase_timestamp

    UNION ALL
    SELECT 'P4a approval-valid', COUNT(*)
    FROM staging.orders
    WHERE order_status = 'delivered'
      AND order_approved_at IS NOT NULL
      AND order_approved_at >= order_purchase_timestamp

    UNION ALL
    SELECT 'P4b handling-valid', COUNT(*)
    FROM staging.orders o
    JOIN item_orders i USING (order_id)
    WHERE o.order_status = 'delivered'
      AND o.order_approved_at IS NOT NULL
      AND o.order_delivered_carrier_date IS NOT NULL
      AND o.order_delivered_carrier_date >= o.order_approved_at
      AND o.order_delivered_carrier_date >= o.order_purchase_timestamp

    UNION ALL
    SELECT 'P4b handling-valid single-seller', COUNT(*)
    FROM staging.orders o
    JOIN item_orders i USING (order_id)
    WHERE o.order_status = 'delivered'
      AND i.seller_count = 1
      AND o.order_approved_at IS NOT NULL
      AND o.order_delivered_carrier_date IS NOT NULL
      AND o.order_delivered_carrier_date >= o.order_approved_at
      AND o.order_delivered_carrier_date >= o.order_purchase_timestamp

    UNION ALL
    SELECT 'P4c carrier-valid', COUNT(*)
    FROM staging.orders
    WHERE order_status = 'delivered'
      AND order_delivered_carrier_date IS NOT NULL
      AND order_delivered_customer_date IS NOT NULL
      AND order_delivered_customer_date >= order_delivered_carrier_date

    UNION ALL
    SELECT 'P4d lead-time valid', COUNT(*)
    FROM staging.orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_delivered_customer_date >= order_purchase_timestamp

    UNION ALL
    SELECT 'item-bearing multi-seller orders', COUNT(*)
    FROM item_orders
    WHERE seller_count > 1
) populations
ORDER BY population_name;

-- 3) Output grain: one review-profile summary row.
-- Business purpose: decide whether latest answered review is a stable,
-- deterministic one-review-per-order rule and quantify sensitivity.
WITH review_order_profile AS (
    SELECT
        order_id,
        COUNT(*) AS review_rows,
        COUNT(DISTINCT review_score) AS distinct_scores,
        MAX(review_answer_timestamp) AS latest_answer_timestamp
    FROM staging.order_reviews
    GROUP BY order_id
), latest_ties AS (
    SELECT r.order_id, COUNT(*) AS latest_rows
    FROM staging.order_reviews r
    JOIN review_order_profile p
      ON p.order_id = r.order_id
     AND p.latest_answer_timestamp = r.review_answer_timestamp
    GROUP BY r.order_id
), ranked AS (
    SELECT
        r.*,
        ROW_NUMBER() OVER (
            PARTITION BY r.order_id
            ORDER BY r.review_answer_timestamp DESC,
                     r.review_creation_date DESC,
                     r.review_id DESC
        ) AS selection_rank,
        AVG(r.review_score::numeric) OVER (PARTITION BY r.order_id) AS order_average_score,
        MIN(r.review_score) OVER (PARTITION BY r.order_id) AS order_minimum_score
    FROM staging.order_reviews r
), selected AS (
    SELECT * FROM ranked WHERE selection_rank = 1
)
SELECT
    COUNT(*) AS reviewed_orders,
    COUNT(*) FILTER (WHERE p.review_rows > 1) AS multiple_review_orders,
    COUNT(*) FILTER (WHERE p.distinct_scores > 1) AS conflicting_score_orders,
    COUNT(*) FILTER (WHERE t.latest_rows > 1) AS latest_timestamp_tie_orders,
    COUNT(*) FILTER (WHERE s.review_score <> s.order_minimum_score) AS latest_differs_from_minimum,
    COUNT(*) FILTER (WHERE s.review_score <> ROUND(s.order_average_score)) AS latest_differs_from_rounded_average,
    ROUND(AVG(s.review_score), 4) AS latest_selected_average_score,
    ROUND(AVG(s.order_average_score), 4) AS all_review_order_average_score
FROM review_order_profile p
JOIN latest_ties t USING (order_id)
JOIN selected s USING (order_id);

-- 4) Output grain: one row per decision segment type.
-- Business purpose: set evidence-based minimum-volume/confidence policies.
WITH delivered_items AS (
    SELECT
        i.order_id,
        COALESCE(t.product_category_name_english,
                 p.product_category_name,
                 '[unknown]') AS category_name,
        c.customer_state,
        i.seller_id,
        s.seller_state
    FROM staging.order_items i
    JOIN staging.orders o USING (order_id)
    JOIN staging.customers c ON c.customer_id = o.customer_id
    JOIN staging.products p ON p.product_id = i.product_id
    LEFT JOIN staging.category_translation t
      ON t.product_category_name = p.product_category_name
    JOIN staging.sellers s ON s.seller_id = i.seller_id
    WHERE o.order_status = 'delivered'
), category_state AS (
    SELECT category_name, customer_state, COUNT(DISTINCT order_id) AS order_count
    FROM delivered_items
    GROUP BY category_name, customer_state
), seller AS (
    SELECT seller_id, COUNT(DISTINCT order_id) AS order_count
    FROM delivered_items
    GROUP BY seller_id
), route AS (
    SELECT seller_state, customer_state, COUNT(DISTINCT order_id) AS order_count
    FROM delivered_items
    GROUP BY seller_state, customer_state
), stacked AS (
    SELECT 'category_x_customer_state' AS segment_type, order_count FROM category_state
    UNION ALL SELECT 'seller', order_count FROM seller
    UNION ALL SELECT 'seller_state_x_customer_state', order_count FROM route
)
SELECT
    segment_type,
    COUNT(*) AS segment_count,
    MIN(order_count) AS minimum_orders,
    percentile_cont(0.25) WITHIN GROUP (ORDER BY order_count) AS p25_orders,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY order_count) AS median_orders,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY order_count) AS p75_orders,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY order_count) AS p90_orders,
    percentile_cont(0.95) WITHIN GROUP (ORDER BY order_count) AS p95_orders,
    MAX(order_count) AS maximum_orders,
    COUNT(*) FILTER (WHERE order_count >= 30) AS segments_ge_30,
    COUNT(*) FILTER (WHERE order_count >= 100) AS segments_ge_100,
    COUNT(*) FILTER (WHERE order_count >= 400) AS segments_ge_400
FROM stacked
GROUP BY segment_type
ORDER BY segment_type;

-- 5) Output grain: one row per review-coverage segment distribution.
-- Business purpose: ensure review comparisons have both volume and coverage.
WITH selected_review AS (
    SELECT order_id
    FROM (
        SELECT
            order_id,
            ROW_NUMBER() OVER (
                PARTITION BY order_id
                ORDER BY review_answer_timestamp DESC,
                         review_creation_date DESC,
                         review_id DESC
            ) AS selection_rank
        FROM staging.order_reviews
    ) ranked
    WHERE selection_rank = 1
), segments AS (
    SELECT DISTINCT
        i.order_id,
        COALESCE(t.product_category_name_english,
                 p.product_category_name,
                 '[unknown]') AS category_name,
        c.customer_state
    FROM staging.order_items i
    JOIN staging.orders o USING (order_id)
    JOIN staging.customers c ON c.customer_id = o.customer_id
    JOIN staging.products p ON p.product_id = i.product_id
    LEFT JOIN staging.category_translation t
      ON t.product_category_name = p.product_category_name
    WHERE o.order_status = 'delivered'
), coverage AS (
    SELECT
        category_name,
        customer_state,
        COUNT(*) AS eligible_orders,
        COUNT(r.order_id) AS reviewed_orders,
        COUNT(r.order_id)::numeric / NULLIF(COUNT(*), 0) AS review_coverage
    FROM segments s
    LEFT JOIN selected_review r USING (order_id)
    GROUP BY category_name, customer_state
)
SELECT
    COUNT(*) FILTER (WHERE eligible_orders >= 100) AS segments_ge_100_orders,
    MIN(review_coverage) FILTER (WHERE eligible_orders >= 100) AS minimum_coverage_ge_100,
    percentile_cont(0.10) WITHIN GROUP (ORDER BY review_coverage)
        FILTER (WHERE eligible_orders >= 100) AS p10_coverage_ge_100,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY review_coverage)
        FILTER (WHERE eligible_orders >= 100) AS median_coverage_ge_100,
    COUNT(*) FILTER (WHERE eligible_orders >= 100 AND review_coverage >= 0.90) AS segments_ge_100_and_90pct_coverage
FROM coverage;

-- 6) Output grain: one customer-repeat suitability summary row.
-- Business purpose: decide whether repeat/RFM should remain secondary.
WITH delivered_customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        MIN(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id
        ) AS first_purchase_timestamp
    FROM staging.orders o
    JOIN staging.customers c USING (customer_id)
    WHERE o.order_status = 'delivered'
), customer_profile AS (
    SELECT
        customer_unique_id,
        MIN(first_purchase_timestamp) AS first_purchase_timestamp,
        COUNT(*) AS delivered_orders,
        COUNT(*) FILTER (
            WHERE order_purchase_timestamp <= first_purchase_timestamp + INTERVAL '365 days'
        ) AS orders_within_365_days
    FROM delivered_customer_orders
    GROUP BY customer_unique_id
)
SELECT
    COUNT(*) AS delivered_customers,
    COUNT(*) FILTER (WHERE delivered_orders >= 2) AS observed_repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delivered_orders >= 2) / COUNT(*), 2) AS observed_repeat_rate_pct,
    COUNT(*) FILTER (WHERE first_purchase_timestamp < DATE '2017-09-01') AS customers_with_365_day_followup,
    COUNT(*) FILTER (
        WHERE first_purchase_timestamp < DATE '2017-09-01'
          AND orders_within_365_days >= 2
    ) AS repeat_customers_within_365_days,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE first_purchase_timestamp < DATE '2017-09-01'
              AND orders_within_365_days >= 2
        ) / NULLIF(COUNT(*) FILTER (WHERE first_purchase_timestamp < DATE '2017-09-01'), 0),
        2
    ) AS repeat_rate_with_equal_365_day_followup_pct,
    MAX(delivered_orders) AS maximum_delivered_orders_per_customer
FROM customer_profile;
