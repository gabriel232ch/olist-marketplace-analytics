
-- 1) Output grains are unique.
SELECT
    'category_state' AS portfolio,
    COUNT(*) AS rows,
    COUNT(DISTINCT (category_name, customer_state)) AS distinct_keys,
    COUNT(*) = COUNT(DISTINCT (category_name, customer_state)) AS unique_grain
FROM analytics.category_state_priority
UNION ALL
SELECT
    'seller', COUNT(*), COUNT(DISTINCT seller_id),
    COUNT(*) = COUNT(DISTINCT seller_id)
FROM analytics.seller_priority
UNION ALL
SELECT
    'route', COUNT(*), COUNT(DISTINCT (seller_state, customer_state)),
    COUNT(*) = COUNT(DISTINCT (seller_state, customer_state))
FROM analytics.route_priority;

-- 2) Priority views preserve their diagnostic populations and GMV allocations.
SELECT
    'category_state' AS portfolio,
    p.rows,
    d.rows AS diagnostic_rows,
    p.gmv,
    d.gmv AS diagnostic_gmv,
    p.rows = d.rows AND p.gmv = d.gmv AS reconciles
FROM (
    SELECT COUNT(*) AS rows, SUM(current_gmv) AS gmv
    FROM analytics.category_state_priority
) p
CROSS JOIN (
    SELECT COUNT(*) AS rows, SUM(current_gmv) AS gmv
    FROM analytics.category_state_diagnostic
) d
UNION ALL
SELECT
    'seller', p.rows, d.rows, p.gmv, d.gmv,
    p.rows = d.rows AND p.gmv = d.gmv
FROM (
    SELECT COUNT(*) AS rows, SUM(current_gmv) AS gmv
    FROM analytics.seller_priority
) p
CROSS JOIN (
    SELECT COUNT(*) AS rows, SUM(current_gmv) AS gmv
    FROM analytics.seller_portfolio_diagnostic
) d
UNION ALL
SELECT
    'route', p.rows, d.rows, p.gmv, d.gmv,
    p.rows = d.rows AND p.gmv = d.gmv
FROM (
    SELECT COUNT(*) AS rows, SUM(delivered_gmv_proxy) AS gmv
    FROM analytics.route_priority
) p
CROSS JOIN (
    SELECT COUNT(*) AS rows, SUM(delivered_gmv_proxy) AS gmv
    FROM analytics.route_fulfillment_diagnostic
) d;

-- 3) Ranked postures cannot contain ineligible segments.
SELECT
    COUNT(*) FILTER (WHERE action_posture <> 'Not ranked') AS ranked_rows,
    COUNT(*) FILTER (
        WHERE action_posture <> 'Not ranked'
          AND (current_orders < 100 OR NOT review_coverage_passes)
    ) AS ineligible_ranked_rows
FROM analytics.category_state_priority;

SELECT
    COUNT(*) FILTER (WHERE action_posture <> 'Not ranked') AS ranked_rows,
    COUNT(*) FILTER (
        WHERE action_posture <> 'Not ranked'
          AND (current_orders < 100 OR current_review_coverage < 0.95)
    ) AS ineligible_ranked_rows
FROM analytics.seller_priority;

SELECT
    COUNT(*) FILTER (WHERE action_posture <> 'Not ranked') AS ranked_rows,
    COUNT(*) FILTER (
        WHERE action_posture <> 'Not ranked'
          AND delivered_orders < 100
    ) AS ineligible_ranked_rows
FROM analytics.route_priority;

-- 4) Scenario gaps are non-negative and never exceed eligible orders.
SELECT
    'category_state' AS portfolio,
    COUNT(*) FILTER (
        WHERE excess_late_orders_to_peer_median_scenario < 0
           OR excess_late_orders_to_peer_median_scenario > current_on_time_eligible_orders
    ) AS invalid_scenarios
FROM analytics.category_state_priority
UNION ALL
SELECT
    'seller',
    COUNT(*) FILTER (
        WHERE excess_late_orders_to_peer_median_scenario < 0
           OR excess_late_orders_to_peer_median_scenario > current_on_time_eligible_orders
    )
FROM analytics.seller_priority;

-- 5) Show posture counts and commercial exposure without treating exposure as uplift.
SELECT
    action_posture,
    COUNT(*) AS segment_rows,
    SUM(current_orders) AS current_orders,
    ROUND(SUM(current_gmv), 2) AS current_gmv_exposure,
    SUM(observed_late_orders) AS observed_late_orders,
    SUM(excess_late_orders_to_peer_median_scenario) AS peer_median_gap_scenario
FROM analytics.category_state_priority
GROUP BY action_posture
ORDER BY action_posture;

SELECT
    action_posture,
    COUNT(*) AS seller_rows,
    SUM(current_orders) AS current_orders,
    ROUND(SUM(current_gmv), 2) AS current_gmv_exposure,
    SUM(observed_late_orders) AS observed_late_orders,
    SUM(excess_late_orders_to_peer_median_scenario) AS peer_median_gap_scenario
FROM analytics.seller_priority
GROUP BY action_posture
ORDER BY action_posture;
