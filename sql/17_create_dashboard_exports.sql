-- Stage 6 dashboard export views.
-- These are presentation-safe aggregates only; no new business rules are introduced.

BEGIN;

-- Output grain: one matched Jan-Aug comparison period.
CREATE OR REPLACE VIEW analytics.dashboard_executive_kpis AS
WITH review_metrics AS MATERIALIZED (
    SELECT
        yoy_comparison_period,
        COUNT(*) FILTER (WHERE has_selected_review) AS reviewed_orders,
        COUNT(*) FILTER (
            WHERE has_selected_review AND selected_review_score <= 2
        ) AS low_review_orders
    FROM analytics.order_measurement_base
    WHERE is_delivered_commercial
      AND yoy_comparison_period IN ('2017_JAN_AUG', '2018_JAN_AUG')
    GROUP BY yoy_comparison_period
)
SELECT
    b.yoy_comparison_period,
    CASE b.yoy_comparison_period
        WHEN '2017_JAN_AUG' THEN 'Jan–Aug 2017'
        WHEN '2018_JAN_AUG' THEN 'Jan–Aug 2018'
    END AS period_label,
    CASE b.yoy_comparison_period
        WHEN '2017_JAN_AUG' THEN 1 ELSE 2
    END AS period_sort,
    b.delivered_orders,
    b.delivered_customers,
    b.item_rows,
    b.delivered_gmv_proxy,
    b.delivered_aov_proxy,
    b.active_sellers,
    b.on_time_eligible_orders,
    b.on_time_orders,
    b.on_time_rate,
    r.reviewed_orders,
    r.low_review_orders,
    r.low_review_orders::numeric / NULLIF(r.reviewed_orders, 0) AS low_review_rate,
    b.average_review_score,
    b.review_coverage,
    b.freight_value,
    b.freight_burden
FROM analytics.marketplace_yoy_period_baseline b
JOIN review_metrics r USING (yoy_comparison_period);

-- Output grain: one stable purchase month.
CREATE OR REPLACE VIEW analytics.dashboard_monthly_trend AS
WITH review_metrics AS MATERIALIZED (
    SELECT
        purchase_month,
        COUNT(*) FILTER (WHERE has_selected_review) AS reviewed_orders,
        COUNT(*) FILTER (
            WHERE has_selected_review AND selected_review_score <= 2
        ) AS low_review_orders
    FROM analytics.order_measurement_base
    WHERE is_delivered_commercial
      AND is_stable_period
    GROUP BY purchase_month
)
SELECT
    b.purchase_month,
    b.delivered_orders,
    b.delivered_customers,
    b.delivered_gmv_proxy,
    b.delivered_aov_proxy,
    b.active_sellers,
    b.on_time_eligible_orders,
    b.on_time_orders,
    b.on_time_rate,
    r.reviewed_orders,
    r.low_review_orders,
    r.low_review_orders::numeric / NULLIF(r.reviewed_orders, 0) AS low_review_rate,
    b.average_review_score,
    b.review_coverage,
    b.freight_burden
FROM analytics.marketplace_monthly_baseline b
JOIN review_metrics r USING (purchase_month);

-- Output grain: one ranked category x customer-state segment.
CREATE OR REPLACE VIEW analytics.dashboard_category_state AS
SELECT
    category_name,
    customer_state,
    category_name || ' × ' || customer_state AS segment_label,
    action_posture,
    CASE action_posture
        WHEN 'Fix before growth' THEN 1
        WHEN 'Grow' THEN 2
        WHEN 'Defend' THEN 3
        WHEN 'Investigate supply' THEN 4
        WHEN 'Monitor' THEN 5
        WHEN 'Deprioritize' THEN 6
        ELSE 7
    END AS action_sort,
    current_confidence,
    growth_confidence,
    prior_orders,
    current_orders,
    prior_gmv,
    current_gmv,
    gmv_change,
    gmv_growth_rate,
    contribution_to_market_change,
    current_active_sellers,
    current_local_active_sellers,
    current_top_seller_share,
    current_interstate_gmv_share,
    current_freight_burden,
    current_on_time_eligible_orders,
    current_on_time_rate,
    current_low_review_rate,
    current_average_review_score,
    current_review_coverage,
    observed_late_orders,
    excess_late_orders_to_peer_median_scenario,
    is_high_commercial_scale,
    passes_strong_execution,
    fails_execution_guardrail,
    has_supply_risk_signal
FROM analytics.category_state_priority
WHERE action_posture <> 'Not ranked';

-- Output grain: one ranked seller.
CREATE OR REPLACE VIEW analytics.dashboard_seller AS
SELECT
    seller_id,
    action_posture,
    CASE action_posture
        WHEN 'Fix before growth' THEN 1
        WHEN 'Grow' THEN 2
        WHEN 'Defend' THEN 3
        WHEN 'Investigate' THEN 4
        WHEN 'Monitor' THEN 5
        WHEN 'Deprioritize' THEN 6
        ELSE 7
    END AS action_sort,
    current_confidence,
    growth_confidence,
    prior_orders,
    current_orders,
    prior_gmv,
    current_gmv,
    gmv_change,
    gmv_growth_rate,
    contribution_to_market_change,
    current_state_reach,
    current_categories,
    current_top_category_share,
    current_freight_burden,
    current_on_time_eligible_orders,
    current_on_time_rate,
    current_median_handling_hours,
    current_p90_handling_hours,
    current_low_review_rate,
    current_average_review_score,
    current_review_coverage,
    observed_late_orders,
    excess_late_orders_to_peer_median_scenario,
    is_high_commercial_scale,
    passes_strong_execution,
    fails_execution_guardrail,
    has_operating_or_concentration_signal
FROM analytics.seller_priority
WHERE action_posture <> 'Not ranked';

-- Output grain: one ranked seller-state x customer-state route.
CREATE OR REPLACE VIEW analytics.dashboard_route AS
SELECT
    seller_state,
    customer_state,
    seller_state || ' → ' || customer_state AS route_label,
    action_posture,
    likely_investigation_owner,
    delivered_orders,
    delivered_gmv_proxy,
    on_time_eligible_orders,
    on_time_orders,
    late_orders,
    late_rate,
    median_late_days,
    p90_late_days,
    median_handling_hours,
    p90_handling_hours,
    median_carrier_hours,
    p90_carrier_hours,
    freight_burden,
    current_confidence
FROM analytics.route_priority
WHERE action_posture <> 'Not ranked';

-- Output grain: one current-period delivery-timing band.
CREATE OR REPLACE VIEW analytics.dashboard_delay_band AS
SELECT
    delay_band,
    CASE delay_band
        WHEN 'early_7_plus_days' THEN 'At least 7 days early'
        WHEN 'on_time_within_6_days' THEN 'On time, within 6 days'
        WHEN 'late_1_2_days' THEN '1–2 days late'
        WHEN 'late_3_7_days' THEN '3–7 days late'
        WHEN 'late_8_plus_days' THEN '8+ days late'
    END AS delay_band_label,
    band_order,
    delivered_orders,
    reviewed_orders,
    low_review_orders,
    low_review_rate,
    average_review_score,
    review_coverage,
    average_order_gmv_proxy,
    average_order_freight_burden
FROM analytics.cx_delay_band_diagnostic;

-- Output grain: one category or customer-state growth contributor.
CREATE OR REPLACE VIEW analytics.dashboard_growth_contributor AS
WITH combined AS (
    SELECT
        'Category'::text AS dimension_type,
        category_name AS dimension_value,
        prior_orders,
        current_orders,
        prior_gmv,
        current_gmv,
        gmv_change,
        gmv_growth_rate,
        contribution_to_market_change,
        comparison_confidence
    FROM analytics.category_growth_contribution
    UNION ALL
    SELECT
        'Customer state',
        customer_state,
        prior_orders,
        current_orders,
        prior_gmv,
        current_gmv,
        gmv_change,
        gmv_growth_rate,
        contribution_to_market_change,
        comparison_confidence
    FROM analytics.state_growth_contribution
)
SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY dimension_type
        ORDER BY gmv_change DESC, dimension_value
    ) AS growth_rank
FROM combined;

COMMENT ON VIEW analytics.dashboard_category_state IS
'Power BI export: one decision-eligible category x customer-state row; all rules originate in analytics.category_state_priority.';

COMMENT ON VIEW analytics.dashboard_seller IS
'Power BI export: one decision-eligible seller row; no seller is repeated.';

COMMENT ON VIEW analytics.dashboard_route IS
'Power BI export: one decision-eligible seller-state x customer-state route row.';

COMMIT;
