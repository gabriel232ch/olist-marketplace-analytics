-- Stage 5D diagnostic reconciliation (read-only).

-- 1) Mutually exclusive commercial allocations reconcile to period GMV.
SELECT allocation, prior_gmv, current_gmv, market_prior_gmv, market_current_gmv,
       prior_gmv = market_prior_gmv AND current_gmv = market_current_gmv AS reconciles
FROM (
    SELECT 'category_state' AS allocation,
           SUM(prior_gmv) AS prior_gmv, SUM(current_gmv) AS current_gmv
    FROM analytics.category_state_diagnostic
    UNION ALL
    SELECT 'seller', SUM(prior_gmv), SUM(current_gmv)
    FROM analytics.seller_portfolio_diagnostic
) a
CROSS JOIN (
    SELECT
        MAX(prior_gmv) AS market_prior_gmv,
        MAX(current_gmv) AS market_current_gmv
    FROM analytics.marketplace_yoy_decomposition
) m;

-- 2) Current route allocation reconciles to Jan-Aug 2018 GMV.
SELECT
    SUM(delivered_gmv_proxy) AS route_gmv,
    (SELECT current_gmv FROM analytics.marketplace_yoy_decomposition) AS market_current_gmv,
    SUM(delivered_gmv_proxy)
      = (SELECT current_gmv FROM analytics.marketplace_yoy_decomposition) AS reconciles
FROM analytics.route_fulfillment_diagnostic;

-- 3) Current category-state order metrics have visible review/fulfillment coverage.
SELECT
    COUNT(*) AS segment_rows,
    COUNT(*) FILTER (WHERE current_orders >= 100) AS segments_ge_100,
    COUNT(*) FILTER (
        WHERE current_orders >= 100 AND review_coverage_passes
    ) AS segments_ge_100_with_review_coverage,
    MIN(current_review_coverage) FILTER (WHERE current_orders >= 100) AS minimum_review_coverage_ge_100
FROM analytics.category_state_diagnostic;

-- 4) CX delay bands partition current on-time-eligible orders.
SELECT
    SUM(delivered_orders) AS banded_orders,
    (SELECT COUNT(*)
     FROM analytics.order_measurement_base
     WHERE is_delivered_commercial
       AND yoy_comparison_period='2018_JAN_AUG'
       AND is_on_time_eligible) AS eligible_orders,
    SUM(delivered_orders) = (SELECT COUNT(*)
                             FROM analytics.order_measurement_base
                             WHERE is_delivered_commercial
                               AND yoy_comparison_period='2018_JAN_AUG'
                               AND is_on_time_eligible) AS reconciles
FROM analytics.cx_delay_band_diagnostic;

-- 5) Single/multi-seller groups partition current delivered orders.
-- The independent expected count comes from staging orders plus item existence,
-- avoiding a second expansion of the order measurement foundation.
WITH expected AS (
    SELECT COUNT(*) AS market_orders
    FROM staging.orders o
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= TIMESTAMP '2018-01-01'
      AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01'
      AND EXISTS (
          SELECT 1
          FROM staging.order_items i
          WHERE i.order_id = o.order_id
      )
)
SELECT
    SUM(delivered_orders) AS complexity_orders,
    MAX(expected.market_orders) AS market_orders,
    SUM(delivered_orders) = MAX(expected.market_orders) AS reconciles
FROM analytics.multi_seller_diagnostic
CROSS JOIN expected;
