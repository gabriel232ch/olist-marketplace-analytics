-- Stage 6 dashboard export reconciliation (read-only).

-- 1) Expected dashboard views exist.
SELECT
    COUNT(*) AS dashboard_views,
    COUNT(*) = 7 AS expected_view_count
FROM information_schema.views
WHERE table_schema = 'analytics'
  AND table_name LIKE 'dashboard_%';

-- 2) Every export preserves its declared grain.
SELECT
    'executive_kpis' AS export,
    COUNT(*) AS rows,
    COUNT(DISTINCT yoy_comparison_period) AS distinct_keys,
    COUNT(*) = COUNT(DISTINCT yoy_comparison_period) AS unique_grain
FROM analytics.dashboard_executive_kpis
UNION ALL
SELECT
    'monthly_trend', COUNT(*), COUNT(DISTINCT purchase_month),
    COUNT(*) = COUNT(DISTINCT purchase_month)
FROM analytics.dashboard_monthly_trend
UNION ALL
SELECT
    'category_state', COUNT(*), COUNT(DISTINCT (category_name, customer_state)),
    COUNT(*) = COUNT(DISTINCT (category_name, customer_state))
FROM analytics.dashboard_category_state
UNION ALL
SELECT
    'seller', COUNT(*), COUNT(DISTINCT seller_id),
    COUNT(*) = COUNT(DISTINCT seller_id)
FROM analytics.dashboard_seller
UNION ALL
SELECT
    'route', COUNT(*), COUNT(DISTINCT (seller_state, customer_state)),
    COUNT(*) = COUNT(DISTINCT (seller_state, customer_state))
FROM analytics.dashboard_route
UNION ALL
SELECT
    'delay_band', COUNT(*), COUNT(DISTINCT delay_band),
    COUNT(*) = COUNT(DISTINCT delay_band)
FROM analytics.dashboard_delay_band
UNION ALL
SELECT
    'growth_contributor', COUNT(*), COUNT(DISTINCT (dimension_type, dimension_value)),
    COUNT(*) = COUNT(DISTINCT (dimension_type, dimension_value))
FROM analytics.dashboard_growth_contributor;

-- 3) Export populations match the validated decision populations.
SELECT
    (SELECT COUNT(*) FROM analytics.dashboard_executive_kpis) AS period_rows,
    (SELECT COUNT(*) FROM analytics.dashboard_monthly_trend) AS stable_months,
    (SELECT COUNT(*) FROM analytics.dashboard_category_state) AS ranked_category_states,
    (SELECT COUNT(*) FROM analytics.dashboard_seller) AS ranked_sellers,
    (SELECT COUNT(*) FROM analytics.dashboard_route) AS ranked_routes,
    (SELECT COUNT(*) FROM analytics.dashboard_delay_band) AS delay_bands,
    (SELECT COUNT(*) FROM analytics.dashboard_growth_contributor
     WHERE dimension_type = 'Category') AS category_contributors,
    (SELECT COUNT(*) FROM analytics.dashboard_growth_contributor
     WHERE dimension_type = 'Customer state') AS state_contributors;

-- 4) Executive export reproduces matched-period headlines.
SELECT
    yoy_comparison_period,
    delivered_orders,
    ROUND(delivered_gmv_proxy, 2) AS delivered_gmv,
    ROUND(delivered_aov_proxy, 2) AS aov,
    ROUND(on_time_rate * 100, 2) AS on_time_rate_pct,
    reviewed_orders,
    low_review_orders,
    ROUND(low_review_rate * 100, 2) AS low_review_rate_pct,
    ROUND(freight_burden * 100, 2) AS freight_burden_pct
FROM analytics.dashboard_executive_kpis
ORDER BY period_sort;

-- 5) Portfolio exports match source posture counts and exposure.
SELECT
    'category_state' AS export,
    COUNT(*) AS rows,
    SUM(current_orders) AS orders,
    ROUND(SUM(current_gmv), 2) AS current_gmv,
    SUM(observed_late_orders) AS late_orders
FROM analytics.dashboard_category_state
UNION ALL
SELECT
    'seller', COUNT(*), SUM(current_orders), ROUND(SUM(current_gmv), 2),
    SUM(observed_late_orders)
FROM analytics.dashboard_seller
UNION ALL
SELECT
    'route', COUNT(*), SUM(delivered_orders), ROUND(SUM(delivered_gmv_proxy), 2),
    SUM(late_orders)
FROM analytics.dashboard_route;

-- 6) Delay bands partition the current on-time-eligible denominator.
-- The expected denominator is rebuilt directly from staging to keep this
-- independent and avoid expanding the executive foundation a second time.
WITH expected AS MATERIALIZED (
    SELECT COUNT(*) AS eligible_orders
    FROM staging.orders o
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= TIMESTAMP '2018-01-01'
      AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
      AND o.order_delivered_customer_date >= o.order_purchase_timestamp
      AND EXISTS (
          SELECT 1
          FROM staging.order_items i
          WHERE i.order_id = o.order_id
      )
)
SELECT
    SUM(delivered_orders) AS banded_orders,
    MAX(expected.eligible_orders) AS eligible_orders,
    SUM(delivered_orders) = MAX(expected.eligible_orders) AS reconciles
FROM analytics.dashboard_delay_band
CROSS JOIN expected;

-- 7) Dashboard exports contain no unranked rows or invalid scenario gaps.
SELECT
    COUNT(*) FILTER (WHERE action_posture = 'Not ranked') AS unranked_rows,
    COUNT(*) FILTER (
        WHERE excess_late_orders_to_peer_median_scenario < 0
           OR excess_late_orders_to_peer_median_scenario > current_on_time_eligible_orders
    ) AS invalid_scenarios
FROM analytics.dashboard_category_state;

SELECT
    COUNT(*) FILTER (WHERE action_posture = 'Not ranked') AS unranked_rows,
    COUNT(*) FILTER (
        WHERE excess_late_orders_to_peer_median_scenario < 0
           OR excess_late_orders_to_peer_median_scenario > current_on_time_eligible_orders
    ) AS invalid_scenarios
FROM analytics.dashboard_seller;
