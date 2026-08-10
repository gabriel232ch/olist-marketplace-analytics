-- Stage 5E rule-based prioritization portfolios.
-- Decision period: Jan-Aug 2018; comparison: Jan-Aug 2017.
-- Impact, operating health, and confidence remain visible as separate fields.
-- Scenario quantities are benchmark gaps, not forecasts or causal impact claims.

BEGIN;

-- Output grain: one category x customer-state segment.
CREATE OR REPLACE VIEW analytics.category_state_priority AS
WITH diagnostic AS MATERIALIZED (
    SELECT * FROM analytics.category_state_diagnostic
), qualified AS (
    SELECT *
    FROM diagnostic
    WHERE current_orders >= 100
      AND review_coverage_passes
), thresholds AS (
    SELECT
        percentile_cont(0.25) WITHIN GROUP (ORDER BY current_gmv) AS p25_gmv,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY current_gmv) AS p50_gmv,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY current_gmv) AS p75_gmv,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY current_on_time_rate) AS p25_on_time,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY current_on_time_rate) AS p50_on_time,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY current_low_review_rate) AS p50_low_review,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY current_low_review_rate) AS p75_low_review,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY current_interstate_gmv_share) AS p75_interstate,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY current_top_seller_share) AS p75_top_seller,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY gmv_change)
          FILTER (WHERE gmv_change > 0 AND growth_confidence IN ('medium', 'high'))
          AS p50_positive_change
    FROM qualified
), classified AS (
    SELECT
        d.*,
        t.*,
        (d.current_gmv >= t.p75_gmv) AS is_high_commercial_scale,
        (d.current_on_time_rate >= t.p50_on_time
         AND d.current_low_review_rate <= t.p50_low_review) AS passes_strong_execution,
        (d.current_on_time_rate < t.p25_on_time
         OR d.current_low_review_rate > t.p75_low_review) AS fails_execution_guardrail,
        (d.current_local_active_sellers = 0
         OR d.current_interstate_gmv_share > t.p75_interstate
         OR d.current_top_seller_share > t.p75_top_seller) AS has_supply_risk_signal
    FROM diagnostic d
    CROSS JOIN thresholds t
)
SELECT
    category_name,
    customer_state,
    prior_orders,
    current_orders,
    prior_gmv,
    current_gmv,
    gmv_change,
    gmv_growth_rate,
    contribution_to_market_change,
    current_customers,
    current_active_sellers,
    current_local_active_sellers,
    current_seller_hhi,
    current_top_seller_share,
    current_interstate_gmv_share,
    current_freight_burden,
    current_on_time_eligible_orders,
    current_on_time_rate,
    current_median_late_days,
    current_p90_late_days,
    current_reviewed_orders,
    current_review_coverage,
    current_low_review_rate,
    current_average_review_score,
    current_confidence,
    growth_confidence,
    review_coverage_passes,
    is_high_commercial_scale,
    passes_strong_execution,
    fails_execution_guardrail,
    has_supply_risk_signal,
    ROUND(current_on_time_eligible_orders * (1 - current_on_time_rate)) AS observed_late_orders,
    GREATEST(
        ROUND(current_on_time_eligible_orders * (p50_on_time - current_on_time_rate)),
        0
    ) AS excess_late_orders_to_peer_median_scenario,
    CASE
        WHEN current_orders < 100 OR NOT review_coverage_passes THEN 'Not ranked'
        WHEN current_gmv >= p75_gmv
         AND (current_on_time_rate < p25_on_time
              OR current_low_review_rate > p75_low_review)
            THEN 'Fix before growth'
        WHEN current_gmv >= p75_gmv
         AND current_on_time_rate >= p50_on_time
         AND current_low_review_rate <= p50_low_review
            THEN 'Defend'
        WHEN current_gmv < p75_gmv
         AND gmv_change >= p50_positive_change
         AND growth_confidence IN ('medium', 'high')
         AND current_on_time_rate >= p50_on_time
         AND current_low_review_rate <= p50_low_review
            THEN 'Grow'
        WHEN current_gmv >= p50_gmv
         AND (current_local_active_sellers = 0
              OR current_interstate_gmv_share > p75_interstate
              OR current_top_seller_share > p75_top_seller)
            THEN 'Investigate supply'
        WHEN current_gmv < p25_gmv
         AND gmv_change < 0
         AND growth_confidence IN ('medium', 'high')
         AND (current_on_time_rate < p25_on_time
              OR current_low_review_rate > p75_low_review)
            THEN 'Deprioritize'
        ELSE 'Monitor'
    END AS action_posture
FROM classified;

COMMENT ON VIEW analytics.category_state_priority IS
'One row per category x customer-state segment. Rule-based posture uses >=100 current orders, >=95% review coverage, peer percentiles, and separate confidence labels; benchmark-gap scenarios are not forecasts.';

-- Output grain: one seller across the matched periods.
CREATE OR REPLACE VIEW analytics.seller_priority AS
WITH diagnostic AS MATERIALIZED (
    SELECT * FROM analytics.seller_portfolio_diagnostic
), qualified AS (
    SELECT *
    FROM diagnostic
    WHERE current_orders >= 100
      AND current_review_coverage >= 0.95
), thresholds AS (
    SELECT
        percentile_cont(0.25) WITHIN GROUP (ORDER BY current_gmv) AS p25_gmv,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY current_gmv) AS p50_gmv,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY current_gmv) AS p75_gmv,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY current_on_time_rate) AS p25_on_time,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY current_on_time_rate) AS p50_on_time,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY current_low_review_rate) AS p50_low_review,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY current_low_review_rate) AS p75_low_review,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY current_median_handling_hours) AS p75_handling,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY current_top_category_share) AS p75_top_category,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY gmv_change)
          FILTER (WHERE gmv_change > 0 AND growth_confidence IN ('medium', 'high'))
          AS p50_positive_change
    FROM qualified
), classified AS (
    SELECT
        d.*,
        t.*,
        (d.current_gmv >= t.p75_gmv) AS is_high_commercial_scale,
        (d.current_on_time_rate >= t.p50_on_time
         AND d.current_low_review_rate <= t.p50_low_review) AS passes_strong_execution,
        (d.current_on_time_rate < t.p25_on_time
         OR d.current_low_review_rate > t.p75_low_review) AS fails_execution_guardrail,
        (d.current_median_handling_hours > t.p75_handling
         OR d.current_top_category_share > t.p75_top_category) AS has_operating_or_concentration_signal
    FROM diagnostic d
    CROSS JOIN thresholds t
)
SELECT
    seller_id,
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
    current_category_hhi,
    current_freight_burden,
    current_on_time_eligible_orders,
    current_on_time_rate,
    current_median_late_days,
    current_p90_late_days,
    current_handling_valid_orders,
    current_median_handling_hours,
    current_p90_handling_hours,
    current_reviewed_orders,
    current_review_coverage,
    current_low_review_rate,
    current_average_review_score,
    current_confidence,
    growth_confidence,
    is_high_commercial_scale,
    passes_strong_execution,
    fails_execution_guardrail,
    has_operating_or_concentration_signal,
    ROUND(current_on_time_eligible_orders * (1 - current_on_time_rate)) AS observed_late_orders,
    GREATEST(
        ROUND(current_on_time_eligible_orders * (p50_on_time - current_on_time_rate)),
        0
    ) AS excess_late_orders_to_peer_median_scenario,
    CASE
        WHEN current_orders < 100 OR current_review_coverage < 0.95 THEN 'Not ranked'
        WHEN current_gmv >= p75_gmv
         AND (current_on_time_rate < p25_on_time
              OR current_low_review_rate > p75_low_review)
            THEN 'Fix before growth'
        WHEN current_gmv >= p75_gmv
         AND current_on_time_rate >= p50_on_time
         AND current_low_review_rate <= p50_low_review
            THEN 'Defend'
        WHEN current_gmv < p75_gmv
         AND gmv_change >= p50_positive_change
         AND growth_confidence IN ('medium', 'high')
         AND current_on_time_rate >= p50_on_time
         AND current_low_review_rate <= p50_low_review
            THEN 'Grow'
        WHEN current_gmv >= p50_gmv
         AND (current_median_handling_hours > p75_handling
              OR current_top_category_share > p75_top_category)
            THEN 'Investigate'
        WHEN current_gmv < p25_gmv
         AND gmv_change < 0
         AND growth_confidence IN ('medium', 'high')
         AND (current_on_time_rate < p25_on_time
              OR current_low_review_rate > p75_low_review)
            THEN 'Deprioritize'
        ELSE 'Monitor'
    END AS action_posture
FROM classified;

COMMENT ON VIEW analytics.seller_priority IS
'One row per seller. Rule-based posture keeps commercial scale, operations, confidence, and concentration evidence separate; no weighted score is used.';

-- Output grain: one seller-state x customer-state route in Jan-Aug 2018.
CREATE OR REPLACE VIEW analytics.route_priority AS
WITH diagnostic AS MATERIALIZED (
    SELECT * FROM analytics.route_fulfillment_diagnostic
), qualified AS (
    SELECT *
    FROM diagnostic
    WHERE delivered_orders >= 100
), thresholds AS (
    SELECT
        percentile_cont(0.50) WITHIN GROUP (ORDER BY delivered_gmv_proxy) AS p50_gmv,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY delivered_gmv_proxy) AS p75_gmv,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY late_rate) AS p50_late,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY late_rate) AS p75_late,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY median_handling_hours) AS p75_handling,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY median_carrier_hours) AS p75_carrier
    FROM qualified
), classified AS (
    SELECT d.*, t.*
    FROM diagnostic d
    CROSS JOIN thresholds t
)
SELECT
    seller_state,
    customer_state,
    delivered_orders,
    delivered_gmv_proxy,
    freight_value,
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
    current_confidence,
    CASE
        WHEN delivered_orders < 100 THEN 'Not ranked'
        WHEN late_rate > p75_late THEN 'Fix route'
        WHEN delivered_gmv_proxy >= p75_gmv AND late_rate <= p50_late THEN 'Defend route'
        ELSE 'Monitor route'
    END AS action_posture,
    CASE
        WHEN delivered_orders < 100 OR late_rate <= p75_late THEN 'Routine monitoring'
        WHEN median_handling_hours > p75_handling
         AND median_carrier_hours > p75_carrier THEN 'Joint seller and logistics diagnosis'
        WHEN median_handling_hours > p75_handling THEN 'Seller-management diagnosis'
        WHEN median_carrier_hours > p75_carrier THEN 'Logistics/carrier diagnosis'
        ELSE 'Promise-setting and mix diagnosis'
    END AS likely_investigation_owner
FROM classified;

COMMENT ON VIEW analytics.route_priority IS
'One row per seller-state x customer-state route. Routes require >=100 delivered orders; ownership labels are diagnostic signals, not proven causes.';

COMMIT;
