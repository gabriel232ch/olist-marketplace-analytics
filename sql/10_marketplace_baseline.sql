-- Stage 5C marketplace baseline and growth decomposition.
-- Commercial date basis: order purchase cohort.
-- Stable monthly window: 2017-01 through 2018-08.
-- Matched comparison: Jan-Aug 2017 versus Jan-Aug 2018.

BEGIN;

-- Output grain: one stable purchase month.
CREATE OR REPLACE VIEW analytics.marketplace_monthly_baseline AS
WITH order_metrics AS (
    SELECT
        purchase_month,
        COUNT(*) AS delivered_orders,
        COUNT(DISTINCT customer_unique_id) AS delivered_customers,
        SUM(item_rows) AS item_rows,
        SUM(item_gmv_proxy) AS delivered_gmv_proxy,
        SUM(freight_value) AS freight_value,
        COUNT(*) FILTER (WHERE is_on_time_eligible) AS on_time_eligible_orders,
        COUNT(*) FILTER (WHERE is_on_time_eligible AND is_on_time) AS on_time_orders,
        COUNT(*) FILTER (WHERE has_selected_review) AS reviewed_orders,
        AVG(selected_review_score) FILTER (WHERE has_selected_review) AS average_review_score
    FROM analytics.order_measurement_base
    WHERE is_delivered_commercial
      AND is_stable_period
    GROUP BY purchase_month
), seller_metrics AS (
    SELECT
        purchase_month,
        COUNT(DISTINCT seller_id) AS active_sellers
    FROM analytics.item_measurement_base
    WHERE is_delivered_commercial
      AND is_stable_period
    GROUP BY purchase_month
)
SELECT
    o.*,
    s.active_sellers,
    o.delivered_gmv_proxy / NULLIF(o.delivered_orders, 0) AS delivered_aov_proxy,
    o.delivered_orders::numeric / NULLIF(o.delivered_customers, 0) AS orders_per_customer,
    o.on_time_orders::numeric / NULLIF(o.on_time_eligible_orders, 0) AS on_time_rate,
    o.reviewed_orders::numeric / NULLIF(o.delivered_orders, 0) AS review_coverage,
    o.freight_value / NULLIF(o.delivered_gmv_proxy + o.freight_value, 0) AS freight_burden
FROM order_metrics o
JOIN seller_metrics s USING (purchase_month);

-- Output grain: one matched Jan-Aug comparison period.
CREATE OR REPLACE VIEW analytics.marketplace_yoy_period_baseline AS
WITH order_metrics AS (
    SELECT
        yoy_comparison_period,
        COUNT(*) AS delivered_orders,
        COUNT(DISTINCT customer_unique_id) AS delivered_customers,
        SUM(item_rows) AS item_rows,
        SUM(item_gmv_proxy) AS delivered_gmv_proxy,
        SUM(freight_value) AS freight_value,
        COUNT(*) FILTER (WHERE is_on_time_eligible) AS on_time_eligible_orders,
        COUNT(*) FILTER (WHERE is_on_time_eligible AND is_on_time) AS on_time_orders,
        COUNT(*) FILTER (WHERE has_selected_review) AS reviewed_orders,
        AVG(selected_review_score) FILTER (WHERE has_selected_review) AS average_review_score
    FROM analytics.order_measurement_base
    WHERE is_delivered_commercial
      AND yoy_comparison_period IN ('2017_JAN_AUG', '2018_JAN_AUG')
    GROUP BY yoy_comparison_period
), seller_metrics AS (
    SELECT
        yoy_comparison_period,
        COUNT(DISTINCT seller_id) AS active_sellers
    FROM analytics.item_measurement_base
    WHERE is_delivered_commercial
      AND yoy_comparison_period IN ('2017_JAN_AUG', '2018_JAN_AUG')
    GROUP BY yoy_comparison_period
)
SELECT
    o.*,
    s.active_sellers,
    o.delivered_gmv_proxy / NULLIF(o.delivered_orders, 0) AS delivered_aov_proxy,
    o.delivered_orders::numeric / NULLIF(o.delivered_customers, 0) AS orders_per_customer,
    o.on_time_orders::numeric / NULLIF(o.on_time_eligible_orders, 0) AS on_time_rate,
    o.reviewed_orders::numeric / NULLIF(o.delivered_orders, 0) AS review_coverage,
    o.freight_value / NULLIF(o.delivered_gmv_proxy + o.freight_value, 0) AS freight_burden
FROM order_metrics o
JOIN seller_metrics s USING (yoy_comparison_period);

-- Output grain: one marketplace decomposition row.
-- Symmetric/Shapley allocation splits the interaction equally and sums exactly:
-- volume effect = (orders_2-orders_1) * average(AOV_1,AOV_2)
-- AOV effect    = (AOV_2-AOV_1) * average(orders_1,orders_2)
CREATE OR REPLACE VIEW analytics.marketplace_yoy_decomposition AS
WITH periods AS (
    SELECT
        MAX(delivered_orders) FILTER (WHERE yoy_comparison_period = '2017_JAN_AUG') AS prior_orders,
        MAX(delivered_orders) FILTER (WHERE yoy_comparison_period = '2018_JAN_AUG') AS current_orders,
        MAX(delivered_gmv_proxy) FILTER (WHERE yoy_comparison_period = '2017_JAN_AUG') AS prior_gmv,
        MAX(delivered_gmv_proxy) FILTER (WHERE yoy_comparison_period = '2018_JAN_AUG') AS current_gmv,
        MAX(delivered_aov_proxy) FILTER (WHERE yoy_comparison_period = '2017_JAN_AUG') AS prior_aov,
        MAX(delivered_aov_proxy) FILTER (WHERE yoy_comparison_period = '2018_JAN_AUG') AS current_aov
    FROM analytics.marketplace_yoy_period_baseline
)
SELECT
    p.*,
    current_gmv - prior_gmv AS gmv_change,
    current_orders - prior_orders AS order_change,
    current_aov - prior_aov AS aov_change,
    (current_orders - prior_orders)
      * ((prior_aov + current_aov) / 2.0) AS order_volume_effect,
    (current_aov - prior_aov)
      * ((prior_orders + current_orders) / 2.0) AS aov_mix_effect
FROM periods p;

-- Output grain: one category across the two matched periods.
CREATE OR REPLACE VIEW analytics.category_growth_contribution AS
WITH segment_period AS (
    SELECT
        category_name,
        yoy_comparison_period,
        SUM(item_gmv_proxy) AS delivered_gmv_proxy,
        COUNT(DISTINCT order_id) AS delivered_orders,
        COUNT(DISTINCT seller_id) AS active_sellers
    FROM analytics.item_measurement_base
    WHERE is_delivered_commercial
      AND yoy_comparison_period IN ('2017_JAN_AUG', '2018_JAN_AUG')
    GROUP BY category_name, yoy_comparison_period
), pivoted AS (
    SELECT
        category_name,
        COALESCE(MAX(delivered_gmv_proxy) FILTER (WHERE yoy_comparison_period = '2017_JAN_AUG'), 0) AS prior_gmv,
        COALESCE(MAX(delivered_gmv_proxy) FILTER (WHERE yoy_comparison_period = '2018_JAN_AUG'), 0) AS current_gmv,
        COALESCE(MAX(delivered_orders) FILTER (WHERE yoy_comparison_period = '2017_JAN_AUG'), 0) AS prior_orders,
        COALESCE(MAX(delivered_orders) FILTER (WHERE yoy_comparison_period = '2018_JAN_AUG'), 0) AS current_orders,
        COALESCE(MAX(active_sellers) FILTER (WHERE yoy_comparison_period = '2017_JAN_AUG'), 0) AS prior_sellers,
        COALESCE(MAX(active_sellers) FILTER (WHERE yoy_comparison_period = '2018_JAN_AUG'), 0) AS current_sellers
    FROM segment_period
    GROUP BY category_name
), market AS (
    SELECT gmv_change FROM analytics.marketplace_yoy_decomposition
)
SELECT
    p.*,
    current_gmv - prior_gmv AS gmv_change,
    (current_gmv - prior_gmv) / NULLIF(prior_gmv, 0) AS gmv_growth_rate,
    (current_gmv - prior_gmv) / NULLIF(m.gmv_change, 0) AS contribution_to_market_change,
    CASE
        WHEN LEAST(prior_orders, current_orders) >= 400 THEN 'high'
        WHEN LEAST(prior_orders, current_orders) >= 100 THEN 'medium'
        WHEN LEAST(prior_orders, current_orders) >= 30 THEN 'exploratory'
        ELSE 'insufficient'
    END AS comparison_confidence
FROM pivoted p CROSS JOIN market m;

-- Output grain: one customer state across the two matched periods.
CREATE OR REPLACE VIEW analytics.state_growth_contribution AS
WITH segment_period AS (
    SELECT
        customer_state,
        yoy_comparison_period,
        SUM(item_gmv_proxy) AS delivered_gmv_proxy,
        COUNT(DISTINCT order_id) AS delivered_orders,
        COUNT(DISTINCT customer_unique_id) AS delivered_customers
    FROM analytics.item_measurement_base
    WHERE is_delivered_commercial
      AND yoy_comparison_period IN ('2017_JAN_AUG', '2018_JAN_AUG')
    GROUP BY customer_state, yoy_comparison_period
), pivoted AS (
    SELECT
        customer_state,
        COALESCE(MAX(delivered_gmv_proxy) FILTER (WHERE yoy_comparison_period = '2017_JAN_AUG'), 0) AS prior_gmv,
        COALESCE(MAX(delivered_gmv_proxy) FILTER (WHERE yoy_comparison_period = '2018_JAN_AUG'), 0) AS current_gmv,
        COALESCE(MAX(delivered_orders) FILTER (WHERE yoy_comparison_period = '2017_JAN_AUG'), 0) AS prior_orders,
        COALESCE(MAX(delivered_orders) FILTER (WHERE yoy_comparison_period = '2018_JAN_AUG'), 0) AS current_orders,
        COALESCE(MAX(delivered_customers) FILTER (WHERE yoy_comparison_period = '2017_JAN_AUG'), 0) AS prior_customers,
        COALESCE(MAX(delivered_customers) FILTER (WHERE yoy_comparison_period = '2018_JAN_AUG'), 0) AS current_customers
    FROM segment_period
    GROUP BY customer_state
), market AS (
    SELECT gmv_change FROM analytics.marketplace_yoy_decomposition
)
SELECT
    p.*,
    current_gmv - prior_gmv AS gmv_change,
    (current_gmv - prior_gmv) / NULLIF(prior_gmv, 0) AS gmv_growth_rate,
    (current_gmv - prior_gmv) / NULLIF(m.gmv_change, 0) AS contribution_to_market_change,
    CASE
        WHEN LEAST(prior_orders, current_orders) >= 400 THEN 'high'
        WHEN LEAST(prior_orders, current_orders) >= 100 THEN 'medium'
        WHEN LEAST(prior_orders, current_orders) >= 30 THEN 'exploratory'
        ELSE 'insufficient'
    END AS comparison_confidence
FROM pivoted p CROSS JOIN market m;

-- Output grain: one seller across the two matched periods.
CREATE OR REPLACE VIEW analytics.seller_growth_contribution AS
WITH segment_period AS (
    SELECT
        seller_id,
        yoy_comparison_period,
        SUM(item_gmv_proxy) AS delivered_gmv_proxy,
        COUNT(DISTINCT order_id) AS delivered_orders
    FROM analytics.item_measurement_base
    WHERE is_delivered_commercial
      AND yoy_comparison_period IN ('2017_JAN_AUG', '2018_JAN_AUG')
    GROUP BY seller_id, yoy_comparison_period
), pivoted AS (
    SELECT
        seller_id,
        COALESCE(MAX(delivered_gmv_proxy) FILTER (WHERE yoy_comparison_period = '2017_JAN_AUG'), 0) AS prior_gmv,
        COALESCE(MAX(delivered_gmv_proxy) FILTER (WHERE yoy_comparison_period = '2018_JAN_AUG'), 0) AS current_gmv,
        COALESCE(MAX(delivered_orders) FILTER (WHERE yoy_comparison_period = '2017_JAN_AUG'), 0) AS prior_orders,
        COALESCE(MAX(delivered_orders) FILTER (WHERE yoy_comparison_period = '2018_JAN_AUG'), 0) AS current_orders
    FROM segment_period
    GROUP BY seller_id
), market AS (
    SELECT gmv_change FROM analytics.marketplace_yoy_decomposition
)
SELECT
    p.*,
    current_gmv - prior_gmv AS gmv_change,
    (current_gmv - prior_gmv) / NULLIF(prior_gmv, 0) AS gmv_growth_rate,
    (current_gmv - prior_gmv) / NULLIF(m.gmv_change, 0) AS contribution_to_market_change,
    CASE
        WHEN LEAST(prior_orders, current_orders) >= 400 THEN 'high'
        WHEN LEAST(prior_orders, current_orders) >= 100 THEN 'medium'
        WHEN LEAST(prior_orders, current_orders) >= 30 THEN 'exploratory'
        ELSE 'insufficient'
    END AS comparison_confidence
FROM pivoted p CROSS JOIN market m;

-- Output grain: one matched period.
CREATE OR REPLACE VIEW analytics.seller_concentration_yoy AS
WITH seller_period AS (
    SELECT
        yoy_comparison_period,
        seller_id,
        SUM(item_gmv_proxy) AS seller_gmv
    FROM analytics.item_measurement_base
    WHERE is_delivered_commercial
      AND yoy_comparison_period IN ('2017_JAN_AUG', '2018_JAN_AUG')
    GROUP BY yoy_comparison_period, seller_id
), shares AS (
    SELECT
        *,
        seller_gmv / SUM(seller_gmv) OVER (PARTITION BY yoy_comparison_period) AS seller_share,
        ROW_NUMBER() OVER (
            PARTITION BY yoy_comparison_period
            ORDER BY seller_gmv DESC, seller_id
        ) AS seller_rank
    FROM seller_period
)
SELECT
    yoy_comparison_period,
    COUNT(*) AS active_sellers,
    SUM(seller_share * seller_share) AS seller_hhi,
    MAX(seller_share) FILTER (WHERE seller_rank = 1) AS top_1_share,
    SUM(seller_share) FILTER (WHERE seller_rank <= 10) AS top_10_share,
    SUM(seller_share) FILTER (WHERE seller_rank <= 100) AS top_100_share
FROM shares
GROUP BY yoy_comparison_period;

COMMIT;
