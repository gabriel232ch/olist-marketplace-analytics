

-- 1) Monthly and matched-period totals must reconcile independently.
SELECT
    SUM(delivered_orders) AS stable_month_orders,
    SUM(delivered_gmv_proxy) AS stable_month_gmv,
    (SELECT COUNT(*)
     FROM analytics.order_measurement_base
     WHERE is_delivered_commercial AND is_stable_period) AS order_base_orders,
    (SELECT SUM(item_gmv_proxy)
     FROM analytics.order_measurement_base
     WHERE is_delivered_commercial AND is_stable_period) AS order_base_gmv,
    SUM(delivered_orders) = (SELECT COUNT(*)
                             FROM analytics.order_measurement_base
                             WHERE is_delivered_commercial AND is_stable_period)
      AND SUM(delivered_gmv_proxy) = (SELECT SUM(item_gmv_proxy)
                                     FROM analytics.order_measurement_base
                                     WHERE is_delivered_commercial AND is_stable_period) AS reconciles
FROM analytics.marketplace_monthly_baseline;

-- 2) Symmetric decomposition must sum exactly to observed GMV change.
SELECT
    gmv_change,
    order_volume_effect,
    aov_mix_effect,
    order_volume_effect + aov_mix_effect AS recomposed_change,
    ROUND(gmv_change - (order_volume_effect + aov_mix_effect), 8) AS difference
FROM analytics.marketplace_yoy_decomposition;

-- 3) Mutually exclusive item-value segment changes must reconcile to market.
SELECT segment, segment_change, market_change,
       segment_change = market_change AS reconciles
FROM (
    SELECT 'category' AS segment, SUM(gmv_change) AS segment_change
    FROM analytics.category_growth_contribution
    UNION ALL
    SELECT 'customer_state', SUM(gmv_change)
    FROM analytics.state_growth_contribution
    UNION ALL
    SELECT 'seller', SUM(gmv_change)
    FROM analytics.seller_growth_contribution
) s
CROSS JOIN (
    SELECT gmv_change AS market_change
    FROM analytics.marketplace_yoy_decomposition
) m;

-- 4) Seller shares and concentration periods must be complete.
SELECT
    c.yoy_comparison_period,
    c.active_sellers,
    c.seller_hhi,
    c.top_1_share,
    c.top_10_share,
    c.top_100_share,
    (SELECT COUNT(DISTINCT seller_id)
     FROM analytics.item_measurement_base i
     WHERE i.is_delivered_commercial
       AND i.yoy_comparison_period = c.yoy_comparison_period) AS independent_active_sellers
FROM analytics.seller_concentration_yoy c
ORDER BY c.yoy_comparison_period;
