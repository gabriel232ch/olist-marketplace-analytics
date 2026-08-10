-- Stage 5G independent headline validation (read-only).
-- Each block uses a different aggregation path or recomputes the published rule.

-- 1) Rebuild the matched marketplace baseline directly from staging tables.
WITH item_order AS (
    SELECT order_id, SUM(price) AS order_gmv
    FROM staging.order_items
    GROUP BY order_id
), period_order AS (
    SELECT
        CASE
            WHEN o.order_purchase_timestamp >= TIMESTAMP '2017-01-01'
             AND o.order_purchase_timestamp < TIMESTAMP '2017-09-01' THEN '2017_JAN_AUG'
            WHEN o.order_purchase_timestamp >= TIMESTAMP '2018-01-01'
             AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01' THEN '2018_JAN_AUG'
        END AS period,
        o.order_id,
        i.order_gmv,
        o.order_delivered_customer_date::date <= o.order_estimated_delivery_date::date AS is_on_time
    FROM staging.orders o
    JOIN item_order i USING (order_id)
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= TIMESTAMP '2017-01-01'
      AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01'
      AND (o.order_purchase_timestamp < TIMESTAMP '2017-09-01'
           OR o.order_purchase_timestamp >= TIMESTAMP '2018-01-01')
)
SELECT
    period,
    COUNT(*) AS delivered_orders,
    ROUND(SUM(order_gmv), 2) AS delivered_gmv,
    ROUND(SUM(order_gmv) / COUNT(*), 2) AS aov,
    COUNT(*) FILTER (WHERE is_on_time) AS on_time_orders,
    COUNT(*) FILTER (WHERE is_on_time IS NOT NULL) AS on_time_eligible,
    ROUND(COUNT(*) FILTER (WHERE is_on_time)::numeric
          / NULLIF(COUNT(*) FILTER (WHERE is_on_time IS NOT NULL), 0) * 100, 2) AS on_time_rate
FROM period_order
GROUP BY period
ORDER BY period;

-- 2) Rebuild selected-review rates at one row per order. The DISTINCT bridge
-- prevents the item-existence join from repeating reviews for multi-item orders.
WITH reviewed_order AS (
    SELECT DISTINCT
        o.order_id,
        CASE
            WHEN o.order_purchase_timestamp < TIMESTAMP '2017-09-01' THEN '2017_JAN_AUG'
            ELSE '2018_JAN_AUG'
        END AS period,
        r.review_score
    FROM staging.orders o
    JOIN staging.order_items i ON i.order_id = o.order_id
    JOIN analytics.order_review_selected r ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= TIMESTAMP '2017-01-01'
      AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01'
      AND (o.order_purchase_timestamp < TIMESTAMP '2017-09-01'
           OR o.order_purchase_timestamp >= TIMESTAMP '2018-01-01')
)
SELECT
    period,
    COUNT(*) AS reviewed_orders,
    COUNT(*) FILTER (WHERE review_score <= 2) AS low_review_orders,
    ROUND(COUNT(*) FILTER (WHERE review_score <= 2)::numeric / COUNT(*) * 100, 2)
      AS low_review_rate
FROM reviewed_order
GROUP BY period
ORDER BY period;

-- 3) Recompute growth concentration directly from the item foundation.
WITH category_period AS (
    SELECT
        category_name,
        yoy_comparison_period,
        SUM(item_gmv_proxy) AS gmv
    FROM analytics.item_measurement_base
    WHERE is_delivered_commercial
      AND yoy_comparison_period IN ('2017_JAN_AUG', '2018_JAN_AUG')
    GROUP BY category_name, yoy_comparison_period
), category_change AS (
    SELECT
        category_name,
        COALESCE(MAX(gmv) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG'), 0)
          - COALESCE(MAX(gmv) FILTER (WHERE yoy_comparison_period='2017_JAN_AUG'), 0)
          AS gmv_change
    FROM category_period
    GROUP BY category_name
), ranked AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY gmv_change DESC) AS rank
    FROM category_change
)
SELECT
    COUNT(*) AS category_labels,
    ROUND(SUM(gmv_change) FILTER (WHERE rank <= 10), 2) AS top_10_change,
    ROUND(SUM(gmv_change), 2) AS marketplace_change,
    ROUND(SUM(gmv_change) FILTER (WHERE rank <= 10) / SUM(gmv_change) * 100, 2)
      AS top_10_share
FROM ranked;

-- 4) Recompute the category-state Fix rule independently from diagnostics.
WITH diagnostic AS MATERIALIZED (
    SELECT * FROM analytics.category_state_diagnostic
), threshold AS (
    SELECT
        percentile_cont(0.75) WITHIN GROUP (ORDER BY current_gmv) AS p75_gmv,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY current_on_time_rate) AS p25_on_time,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY current_low_review_rate) AS p75_low_review,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY current_on_time_rate) AS p50_on_time
    FROM diagnostic
    WHERE current_orders >= 100 AND review_coverage_passes
), expected AS (
    SELECT d.*, t.p50_on_time
    FROM diagnostic d CROSS JOIN threshold t
    WHERE d.current_orders >= 100
      AND d.review_coverage_passes
      AND d.current_gmv >= t.p75_gmv
      AND (d.current_on_time_rate < t.p25_on_time
           OR d.current_low_review_rate > t.p75_low_review)
)
SELECT
    COUNT(*) AS fix_segments,
    SUM(current_orders) AS orders,
    ROUND(SUM(current_gmv), 2) AS gmv_exposure,
    ROUND(SUM(gmv_change), 2) AS observed_gmv_change,
    SUM(ROUND(current_on_time_eligible_orders * (1 - current_on_time_rate))) AS late_orders,
    SUM(GREATEST(ROUND(current_on_time_eligible_orders *
                       (p50_on_time - current_on_time_rate)), 0)) AS peer_median_gap
FROM expected;

-- 5) Recompute high-late route exposure from the diagnostic distribution.
WITH threshold AS (
    SELECT percentile_cont(0.75) WITHIN GROUP (ORDER BY late_rate) AS p75_late
    FROM analytics.route_fulfillment_diagnostic
    WHERE delivered_orders >= 100
)
SELECT
    COUNT(*) AS fix_routes,
    SUM(delivered_orders) AS orders,
    ROUND(SUM(delivered_gmv_proxy), 2) AS gmv_exposure,
    SUM(late_orders) AS late_orders
FROM analytics.route_fulfillment_diagnostic d
CROSS JOIN threshold t
WHERE d.delivered_orders >= 100
  AND d.late_rate > t.p75_late;

-- 6) Rebuild the delay/review association at one order per selected review.
SELECT
    CASE
        WHEN days_vs_estimate <= -7 THEN 'early_7_plus_days'
        WHEN days_vs_estimate BETWEEN -6 AND 0 THEN 'on_time_within_6_days'
        WHEN days_vs_estimate BETWEEN 1 AND 2 THEN 'late_1_2_days'
        WHEN days_vs_estimate BETWEEN 3 AND 7 THEN 'late_3_7_days'
        ELSE 'late_8_plus_days'
    END AS delay_band,
    COUNT(*) AS reviewed_orders,
    COUNT(*) FILTER (WHERE selected_review_score <= 2) AS low_review_orders,
    ROUND(COUNT(*) FILTER (WHERE selected_review_score <= 2)::numeric
          / COUNT(*) * 100, 2) AS low_review_rate
FROM analytics.order_measurement_base
WHERE is_delivered_commercial
  AND yoy_comparison_period = '2018_JAN_AUG'
  AND is_on_time_eligible
  AND has_selected_review
GROUP BY delay_band
ORDER BY MIN(days_vs_estimate);
