
-- Current decision period: Jan-Aug 2018; growth comparator: Jan-Aug 2017.
-- No composite opportunity score is created in this stage.

BEGIN;

-- Output grain: one category x customer-state segment.
CREATE OR REPLACE VIEW analytics.category_state_diagnostic AS
WITH segment_order AS (
    SELECT
        i.category_name,
        i.customer_state,
        i.yoy_comparison_period,
        i.order_id,
        MIN(i.customer_unique_id) AS customer_unique_id,
        SUM(i.item_gmv_proxy) AS segment_gmv,
        SUM(i.freight_value) AS segment_freight,
        COUNT(DISTINCT i.seller_id) AS sellers_in_order_segment,
        BOOL_OR(i.seller_state = i.customer_state) AS has_local_seller,
        SUM(i.item_gmv_proxy) FILTER (WHERE i.seller_state <> i.customer_state) AS interstate_gmv,
        BOOL_AND(i.is_on_time_eligible) AS is_on_time_eligible,
        BOOL_AND(i.is_on_time) AS is_on_time,
        MIN(i.delay_days) AS delay_days,
        BOOL_AND(i.is_lead_time_valid) AS is_lead_time_valid,
        MIN(i.lead_time_hours) AS lead_time_hours,
        BOOL_AND(i.has_selected_review) AS has_selected_review,
        MIN(i.selected_review_score) AS selected_review_score
    FROM analytics.item_measurement_base i
    WHERE i.is_delivered_commercial
      AND i.yoy_comparison_period IN ('2017_JAN_AUG', '2018_JAN_AUG')
    GROUP BY i.category_name, i.customer_state,
             i.yoy_comparison_period, i.order_id
), seller_segment AS (
    SELECT
        category_name,
        customer_state,
        yoy_comparison_period,
        seller_id,
        SUM(item_gmv_proxy) AS seller_gmv
    FROM analytics.item_measurement_base
    WHERE is_delivered_commercial
      AND yoy_comparison_period IN ('2017_JAN_AUG', '2018_JAN_AUG')
    GROUP BY category_name, customer_state, yoy_comparison_period, seller_id
), seller_shares AS (
    SELECT
        *,
        seller_gmv / SUM(seller_gmv) OVER (
            PARTITION BY category_name, customer_state, yoy_comparison_period
        ) AS seller_share
    FROM seller_segment
), seller_metrics AS (
    SELECT
        category_name,
        customer_state,
        yoy_comparison_period,
        COUNT(*) AS active_sellers,
        SUM(seller_share * seller_share) AS seller_hhi,
        MAX(seller_share) AS top_seller_share
    FROM seller_shares
    GROUP BY category_name, customer_state, yoy_comparison_period
), local_sellers AS (
    SELECT
        category_name,
        customer_state,
        yoy_comparison_period,
        COUNT(DISTINCT seller_id) FILTER (
            WHERE seller_state = customer_state
        ) AS local_active_sellers
    FROM analytics.item_measurement_base
    WHERE is_delivered_commercial
      AND yoy_comparison_period IN ('2017_JAN_AUG', '2018_JAN_AUG')
    GROUP BY category_name, customer_state, yoy_comparison_period
), segment_period AS (
    SELECT
        s.category_name,
        s.customer_state,
        s.yoy_comparison_period,
        COUNT(*) AS delivered_orders,
        COUNT(DISTINCT s.customer_unique_id) AS delivered_customers,
        SUM(s.segment_gmv) AS delivered_gmv_proxy,
        SUM(s.segment_freight) AS freight_value,
        COUNT(*) FILTER (WHERE s.is_on_time_eligible) AS on_time_eligible_orders,
        COUNT(*) FILTER (WHERE s.is_on_time_eligible AND s.is_on_time) AS on_time_orders,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY s.delay_days)
            FILTER (WHERE s.is_on_time_eligible AND NOT s.is_on_time) AS median_late_days,
        percentile_cont(0.90) WITHIN GROUP (ORDER BY s.delay_days)
            FILTER (WHERE s.is_on_time_eligible AND NOT s.is_on_time) AS p90_late_days,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY s.lead_time_hours)
            FILTER (WHERE s.is_lead_time_valid) AS median_lead_hours,
        COUNT(*) FILTER (WHERE s.has_selected_review) AS reviewed_orders,
        COUNT(*) FILTER (
            WHERE s.has_selected_review AND s.selected_review_score <= 2
        ) AS low_review_orders,
        AVG(s.selected_review_score) FILTER (WHERE s.has_selected_review) AS average_review_score,
        SUM(COALESCE(s.interstate_gmv, 0)) AS interstate_gmv
    FROM segment_order s
    GROUP BY s.category_name, s.customer_state, s.yoy_comparison_period
), combined AS (
    SELECT
        p.*,
        m.active_sellers,
        l.local_active_sellers,
        m.seller_hhi,
        m.top_seller_share,
        p.delivered_gmv_proxy / NULLIF(p.delivered_orders, 0) AS segment_aov_proxy,
        p.freight_value / NULLIF(p.delivered_gmv_proxy + p.freight_value, 0) AS freight_burden,
        p.interstate_gmv / NULLIF(p.delivered_gmv_proxy, 0) AS interstate_gmv_share,
        p.on_time_orders::numeric / NULLIF(p.on_time_eligible_orders, 0) AS on_time_rate,
        p.reviewed_orders::numeric / NULLIF(p.delivered_orders, 0) AS review_coverage,
        p.low_review_orders::numeric / NULLIF(p.reviewed_orders, 0) AS low_review_rate
    FROM segment_period p
    JOIN seller_metrics m USING (category_name, customer_state, yoy_comparison_period)
    JOIN local_sellers l USING (category_name, customer_state, yoy_comparison_period)
), pivoted AS (
    SELECT
        category_name,
        customer_state,
        COALESCE(MAX(delivered_orders) FILTER (WHERE yoy_comparison_period='2017_JAN_AUG'), 0) AS prior_orders,
        COALESCE(MAX(delivered_orders) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG'), 0) AS current_orders,
        COALESCE(MAX(delivered_gmv_proxy) FILTER (WHERE yoy_comparison_period='2017_JAN_AUG'), 0) AS prior_gmv,
        COALESCE(MAX(delivered_gmv_proxy) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG'), 0) AS current_gmv,
        MAX(delivered_customers) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_customers,
        MAX(active_sellers) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_active_sellers,
        MAX(local_active_sellers) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_local_active_sellers,
        MAX(seller_hhi) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_seller_hhi,
        MAX(top_seller_share) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_top_seller_share,
        MAX(segment_aov_proxy) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_aov_proxy,
        MAX(freight_burden) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_freight_burden,
        MAX(interstate_gmv_share) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_interstate_gmv_share,
        MAX(on_time_eligible_orders) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_on_time_eligible_orders,
        MAX(on_time_rate) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_on_time_rate,
        MAX(median_late_days) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_median_late_days,
        MAX(p90_late_days) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_p90_late_days,
        MAX(median_lead_hours) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_median_lead_hours,
        MAX(reviewed_orders) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_reviewed_orders,
        MAX(review_coverage) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_review_coverage,
        MAX(low_review_rate) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_low_review_rate,
        MAX(average_review_score) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_average_review_score
    FROM combined
    GROUP BY category_name, customer_state
), market AS (
    SELECT gmv_change FROM analytics.marketplace_yoy_decomposition
)
SELECT
    p.*,
    current_gmv - prior_gmv AS gmv_change,
    (current_gmv - prior_gmv) / NULLIF(prior_gmv, 0) AS gmv_growth_rate,
    (current_gmv - prior_gmv) / NULLIF(m.gmv_change, 0) AS contribution_to_market_change,
    CASE
        WHEN current_orders >= 400 THEN 'high'
        WHEN current_orders >= 100 THEN 'medium'
        WHEN current_orders >= 30 THEN 'exploratory'
        ELSE 'insufficient'
    END AS current_confidence,
    CASE
        WHEN LEAST(prior_orders, current_orders) >= 400 THEN 'high'
        WHEN LEAST(prior_orders, current_orders) >= 100 THEN 'medium'
        WHEN LEAST(prior_orders, current_orders) >= 30 THEN 'exploratory'
        ELSE 'insufficient'
    END AS growth_confidence,
    (current_review_coverage >= 0.95) AS review_coverage_passes
FROM pivoted p CROSS JOIN market m;

-- Output grain: one seller across the matched periods with current operations.
CREATE OR REPLACE VIEW analytics.seller_portfolio_diagnostic AS
WITH seller_order AS (
    SELECT
        i.seller_id,
        i.yoy_comparison_period,
        i.order_id,
        MIN(i.customer_state) AS customer_state,
        SUM(i.item_gmv_proxy) AS seller_order_gmv,
        SUM(i.freight_value) AS seller_order_freight,
        BOOL_AND(i.is_on_time_eligible) AS is_on_time_eligible,
        BOOL_AND(i.is_on_time) AS is_on_time,
        MIN(i.delay_days) AS delay_days,
        BOOL_AND(i.is_single_seller_order) AS is_single_seller_order,
        BOOL_AND(i.is_handling_valid) AS is_handling_valid,
        MIN(i.handling_hours) AS handling_hours,
        BOOL_AND(i.has_selected_review) AS has_selected_review,
        MIN(i.selected_review_score) AS selected_review_score
    FROM analytics.item_measurement_base i
    WHERE i.is_delivered_commercial
      AND i.yoy_comparison_period IN ('2017_JAN_AUG', '2018_JAN_AUG')
    GROUP BY i.seller_id, i.yoy_comparison_period, i.order_id
), seller_period AS (
    SELECT
        seller_id,
        yoy_comparison_period,
        COUNT(*) AS delivered_orders,
        COUNT(DISTINCT customer_state) AS customer_state_reach,
        SUM(seller_order_gmv) AS delivered_gmv_proxy,
        SUM(seller_order_freight) AS freight_value,
        COUNT(*) FILTER (WHERE is_on_time_eligible) AS on_time_eligible_orders,
        COUNT(*) FILTER (WHERE is_on_time_eligible AND is_on_time) AS on_time_orders,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY delay_days)
          FILTER (WHERE is_on_time_eligible AND NOT is_on_time) AS median_late_days,
        percentile_cont(0.90) WITHIN GROUP (ORDER BY delay_days)
          FILTER (WHERE is_on_time_eligible AND NOT is_on_time) AS p90_late_days,
        COUNT(*) FILTER (
            WHERE is_single_seller_order AND is_handling_valid
        ) AS handling_valid_single_seller_orders,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY handling_hours)
          FILTER (WHERE is_single_seller_order AND is_handling_valid) AS median_handling_hours,
        percentile_cont(0.90) WITHIN GROUP (ORDER BY handling_hours)
          FILTER (WHERE is_single_seller_order AND is_handling_valid) AS p90_handling_hours,
        COUNT(*) FILTER (WHERE has_selected_review) AS reviewed_orders,
        COUNT(*) FILTER (WHERE has_selected_review AND selected_review_score <= 2) AS low_review_orders,
        AVG(selected_review_score) FILTER (WHERE has_selected_review) AS average_review_score
    FROM seller_order
    GROUP BY seller_id, yoy_comparison_period
), category_mix AS (
    SELECT
        seller_id,
        category_name,
        SUM(item_gmv_proxy) AS category_gmv
    FROM analytics.item_measurement_base
    WHERE is_delivered_commercial
      AND yoy_comparison_period = '2018_JAN_AUG'
    GROUP BY seller_id, category_name
), category_shares AS (
    SELECT
        *,
        category_gmv / SUM(category_gmv) OVER (PARTITION BY seller_id) AS category_share
    FROM category_mix
), category_metrics AS (
    SELECT
        seller_id,
        COUNT(*) AS current_categories,
        MAX(category_share) AS current_top_category_share,
        SUM(category_share * category_share) AS current_category_hhi
    FROM category_shares
    GROUP BY seller_id
), pivoted AS (
    SELECT
        seller_id,
        COALESCE(MAX(delivered_orders) FILTER (WHERE yoy_comparison_period='2017_JAN_AUG'), 0) AS prior_orders,
        COALESCE(MAX(delivered_orders) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG'), 0) AS current_orders,
        COALESCE(MAX(delivered_gmv_proxy) FILTER (WHERE yoy_comparison_period='2017_JAN_AUG'), 0) AS prior_gmv,
        COALESCE(MAX(delivered_gmv_proxy) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG'), 0) AS current_gmv,
        MAX(customer_state_reach) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_state_reach,
        MAX(freight_value) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_freight,
        MAX(on_time_eligible_orders) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_on_time_eligible_orders,
        MAX(on_time_orders) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_on_time_orders,
        MAX(median_late_days) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_median_late_days,
        MAX(p90_late_days) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_p90_late_days,
        MAX(handling_valid_single_seller_orders) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_handling_valid_orders,
        MAX(median_handling_hours) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_median_handling_hours,
        MAX(p90_handling_hours) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_p90_handling_hours,
        MAX(reviewed_orders) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_reviewed_orders,
        MAX(low_review_orders) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_low_review_orders,
        MAX(average_review_score) FILTER (WHERE yoy_comparison_period='2018_JAN_AUG') AS current_average_review_score
    FROM seller_period
    GROUP BY seller_id
), market AS (
    SELECT gmv_change FROM analytics.marketplace_yoy_decomposition
)
SELECT
    p.*,
    c.current_categories,
    c.current_top_category_share,
    c.current_category_hhi,
    current_gmv - prior_gmv AS gmv_change,
    (current_gmv - prior_gmv) / NULLIF(prior_gmv, 0) AS gmv_growth_rate,
    (current_gmv - prior_gmv) / NULLIF(m.gmv_change, 0) AS contribution_to_market_change,
    current_freight / NULLIF(current_gmv + current_freight, 0) AS current_freight_burden,
    current_on_time_orders::numeric / NULLIF(current_on_time_eligible_orders, 0) AS current_on_time_rate,
    current_reviewed_orders::numeric / NULLIF(current_orders, 0) AS current_review_coverage,
    current_low_review_orders::numeric / NULLIF(current_reviewed_orders, 0) AS current_low_review_rate,
    CASE
        WHEN current_orders >= 400 THEN 'high'
        WHEN current_orders >= 100 THEN 'medium'
        WHEN current_orders >= 30 THEN 'exploratory'
        ELSE 'insufficient'
    END AS current_confidence,
    CASE
        WHEN LEAST(prior_orders, current_orders) >= 400 THEN 'high'
        WHEN LEAST(prior_orders, current_orders) >= 100 THEN 'medium'
        WHEN LEAST(prior_orders, current_orders) >= 30 THEN 'exploratory'
        ELSE 'insufficient'
    END AS growth_confidence
FROM pivoted p
LEFT JOIN category_metrics c USING (seller_id)
CROSS JOIN market m;

-- Output grain: one seller-state x customer-state route in Jan-Aug 2018.
CREATE OR REPLACE VIEW analytics.route_fulfillment_diagnostic AS
WITH route_order AS (
    SELECT
        i.seller_state,
        i.customer_state,
        i.order_id,
        SUM(i.item_gmv_proxy) AS route_order_gmv,
        SUM(i.freight_value) AS route_order_freight,
        BOOL_AND(i.is_on_time_eligible) AS is_on_time_eligible,
        BOOL_AND(i.is_on_time) AS is_on_time,
        MIN(i.delay_days) AS delay_days,
        BOOL_AND(i.is_single_seller_order) AS is_single_seller_order,
        BOOL_AND(i.is_handling_valid) AS is_handling_valid,
        MIN(i.handling_hours) AS handling_hours,
        BOOL_AND(i.is_carrier_valid) AS is_carrier_valid,
        MIN(i.carrier_hours) AS carrier_hours
    FROM analytics.item_measurement_base i
    WHERE i.is_delivered_commercial
      AND i.yoy_comparison_period = '2018_JAN_AUG'
    GROUP BY i.seller_state, i.customer_state, i.order_id
)
SELECT
    seller_state,
    customer_state,
    COUNT(*) AS delivered_orders,
    SUM(route_order_gmv) AS delivered_gmv_proxy,
    SUM(route_order_freight) AS freight_value,
    COUNT(*) FILTER (WHERE is_on_time_eligible) AS on_time_eligible_orders,
    COUNT(*) FILTER (WHERE is_on_time_eligible AND is_on_time) AS on_time_orders,
    COUNT(*) FILTER (WHERE is_on_time_eligible AND NOT is_on_time) AS late_orders,
    COUNT(*) FILTER (WHERE is_on_time_eligible AND NOT is_on_time)::numeric
      / NULLIF(COUNT(*) FILTER (WHERE is_on_time_eligible), 0) AS late_rate,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY delay_days)
      FILTER (WHERE is_on_time_eligible AND NOT is_on_time) AS median_late_days,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY delay_days)
      FILTER (WHERE is_on_time_eligible AND NOT is_on_time) AS p90_late_days,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY handling_hours)
      FILTER (WHERE is_single_seller_order AND is_handling_valid) AS median_handling_hours,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY handling_hours)
      FILTER (WHERE is_single_seller_order AND is_handling_valid) AS p90_handling_hours,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY carrier_hours)
      FILTER (WHERE is_carrier_valid) AS median_carrier_hours,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY carrier_hours)
      FILTER (WHERE is_carrier_valid) AS p90_carrier_hours,
    SUM(route_order_freight)
      / NULLIF(SUM(route_order_gmv) + SUM(route_order_freight), 0) AS freight_burden,
    CASE
        WHEN COUNT(*) >= 400 THEN 'high'
        WHEN COUNT(*) >= 100 THEN 'medium'
        WHEN COUNT(*) >= 30 THEN 'exploratory'
        ELSE 'insufficient'
    END AS current_confidence
FROM route_order
GROUP BY seller_state, customer_state;

-- Output grain: one delivery-timing band in Jan-Aug 2018 reviewed orders.
CREATE OR REPLACE VIEW analytics.cx_delay_band_diagnostic AS
WITH banded AS (
    SELECT
        CASE
            WHEN days_vs_estimate <= -7 THEN 'early_7_plus_days'
            WHEN days_vs_estimate BETWEEN -6 AND 0 THEN 'on_time_within_6_days'
            WHEN days_vs_estimate BETWEEN 1 AND 2 THEN 'late_1_2_days'
            WHEN days_vs_estimate BETWEEN 3 AND 7 THEN 'late_3_7_days'
            ELSE 'late_8_plus_days'
        END AS delay_band,
        CASE
            WHEN days_vs_estimate <= -7 THEN 1
            WHEN days_vs_estimate BETWEEN -6 AND 0 THEN 2
            WHEN days_vs_estimate BETWEEN 1 AND 2 THEN 3
            WHEN days_vs_estimate BETWEEN 3 AND 7 THEN 4
            ELSE 5
        END AS band_order,
        *
    FROM analytics.order_measurement_base
    WHERE is_delivered_commercial
      AND yoy_comparison_period = '2018_JAN_AUG'
      AND is_on_time_eligible
)
SELECT
    delay_band,
    band_order,
    COUNT(*) AS delivered_orders,
    COUNT(*) FILTER (WHERE has_selected_review) AS reviewed_orders,
    COUNT(*) FILTER (WHERE has_selected_review AND selected_review_score <= 2) AS low_review_orders,
    COUNT(*) FILTER (WHERE has_selected_review AND selected_review_score <= 2)::numeric
      / NULLIF(COUNT(*) FILTER (WHERE has_selected_review), 0) AS low_review_rate,
    AVG(selected_review_score) FILTER (WHERE has_selected_review) AS average_review_score,
    COUNT(*) FILTER (WHERE has_selected_review)::numeric / COUNT(*) AS review_coverage,
    AVG(item_gmv_proxy) AS average_order_gmv_proxy,
    AVG(freight_value / NULLIF(item_gmv_proxy + freight_value, 0)) AS average_order_freight_burden
FROM banded
GROUP BY delay_band, band_order;

-- Output grain: one single/multi-seller order-complexity group in Jan-Aug 2018.
CREATE OR REPLACE VIEW analytics.multi_seller_diagnostic AS
SELECT
    CASE WHEN is_multi_seller_order THEN 'multi_seller' ELSE 'single_seller' END AS seller_complexity,
    COUNT(*) AS delivered_orders,
    COUNT(*) FILTER (WHERE is_on_time_eligible) AS on_time_eligible_orders,
    COUNT(*) FILTER (WHERE is_on_time_eligible AND is_on_time) AS on_time_orders,
    COUNT(*) FILTER (WHERE is_on_time_eligible AND NOT is_on_time)::numeric
      / NULLIF(COUNT(*) FILTER (WHERE is_on_time_eligible), 0) AS late_rate,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY lead_time_hours)
      FILTER (WHERE is_lead_time_valid) AS median_lead_hours,
    COUNT(*) FILTER (WHERE has_selected_review) AS reviewed_orders,
    COUNT(*) FILTER (WHERE has_selected_review AND selected_review_score <= 2)::numeric
      / NULLIF(COUNT(*) FILTER (WHERE has_selected_review), 0) AS low_review_rate,
    AVG(selected_review_score) FILTER (WHERE has_selected_review) AS average_review_score,
    AVG(item_gmv_proxy) AS average_order_gmv_proxy,
    AVG(freight_value / NULLIF(item_gmv_proxy + freight_value, 0)) AS average_order_freight_burden
FROM analytics.order_measurement_base
WHERE is_delivered_commercial
  AND yoy_comparison_period = '2018_JAN_AUG'
GROUP BY is_multi_seller_order;

COMMIT;
