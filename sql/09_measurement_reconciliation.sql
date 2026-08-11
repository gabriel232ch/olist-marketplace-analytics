

-- 1) Output grain: one row per analytics foundation.
SELECT foundation, rows, distinct_keys, rows = distinct_keys AS key_is_unique
FROM (
    SELECT 'order_review_selected' AS foundation,
           COUNT(*) AS rows, COUNT(DISTINCT order_id) AS distinct_keys
    FROM analytics.order_review_selected
    UNION ALL
    SELECT 'order_measurement_base', COUNT(*), COUNT(DISTINCT order_id)
    FROM analytics.order_measurement_base
    UNION ALL
    SELECT 'item_measurement_base', COUNT(*),
           COUNT(DISTINCT (order_id, order_item_id))
    FROM analytics.item_measurement_base
    UNION ALL
    SELECT 'customer_measurement_base', COUNT(*),
           COUNT(DISTINCT customer_unique_id)
    FROM analytics.customer_measurement_base
) checks
ORDER BY foundation;

-- 2a) Output grain: one item-amount reconciliation row.
-- Item and payment checks are intentionally separate statements. This keeps
-- PostgreSQL from building one unnecessarily large UNION plan across several
-- aggregate views on resource-constrained local machines.
WITH raw_item AS MATERIALIZED (
    SELECT COUNT(*) AS rows,
           SUM(NULLIF(price, '')::numeric(12, 2)) AS gmv,
           SUM(NULLIF(freight_value, '')::numeric(12, 2)) AS freight
    FROM raw.order_items
), staging_item AS MATERIALIZED (
    SELECT COUNT(*) AS rows, SUM(price) AS gmv, SUM(freight_value) AS freight
    FROM staging.order_items
), analytics_item AS MATERIALIZED (
    SELECT COUNT(*) AS rows, SUM(item_gmv_proxy) AS gmv, SUM(freight_value) AS freight
    FROM analytics.item_measurement_base
)
SELECT
    'item_all_rows_and_amounts' AS reconciliation,
    r.rows AS raw_rows, s.rows AS staging_rows, a.rows AS analytics_rows,
    r.gmv AS raw_amount_1, s.gmv AS staging_amount_1, a.gmv AS analytics_amount_1,
    r.freight AS raw_amount_2, s.freight AS staging_amount_2, a.freight AS analytics_amount_2,
    (r.rows = s.rows AND s.rows = a.rows
     AND r.gmv = s.gmv AND s.gmv = a.gmv
     AND r.freight = s.freight AND s.freight = a.freight) AS reconciles
FROM raw_item r CROSS JOIN staging_item s CROSS JOIN analytics_item a;

-- 2b) Output grain: one payment-amount reconciliation row.
WITH raw_payment AS MATERIALIZED (
    SELECT COUNT(*) AS rows,
           SUM(NULLIF(payment_value, '')::numeric(12, 2)) AS payment
    FROM raw.order_payments
), staging_payment AS MATERIALIZED (
    SELECT COUNT(*) AS rows, SUM(payment_value) AS payment
    FROM staging.order_payments
), analytics_payment AS MATERIALIZED (
    SELECT SUM(payment_rows) AS rows, SUM(payment_value) AS payment
    FROM analytics.order_measurement_base
)
SELECT
    'payment_all_rows_and_amount' AS reconciliation,
    r.rows AS raw_rows, s.rows AS staging_rows, a.rows AS analytics_rows,
    r.payment AS raw_amount, s.payment AS staging_amount, a.payment AS analytics_amount,
    (r.rows = s.rows AND s.rows = a.rows
     AND r.payment = s.payment AND s.payment = a.payment) AS reconciles
FROM raw_payment r CROSS JOIN staging_payment s CROSS JOIN analytics_payment a;

-- 3) Output grain: one row per core order population.
WITH counts AS MATERIALIZED (
    SELECT
        COUNT(*) AS all_orders,
        COUNT(*) FILTER (WHERE is_delivered_commercial) AS delivered_commercial,
        COUNT(*) FILTER (WHERE is_on_time_eligible) AS on_time_eligible,
        COUNT(*) FILTER (WHERE is_approval_valid) AS approval_valid,
        COUNT(*) FILTER (WHERE is_handling_valid) AS handling_valid,
        COUNT(*) FILTER (
            WHERE is_handling_valid AND is_single_seller_order
        ) AS handling_valid_single_seller,
        COUNT(*) FILTER (WHERE is_carrier_valid) AS carrier_valid,
        COUNT(*) FILTER (WHERE is_lead_time_valid) AS lead_time_valid,
        COUNT(*) FILTER (WHERE is_multi_seller_order) AS multi_seller_item_bearing
    FROM analytics.order_measurement_base
)
SELECT population, orders
FROM counts c
CROSS JOIN LATERAL (
    VALUES
        ('all orders', c.all_orders),
        ('delivered commercial', c.delivered_commercial),
        ('on-time eligible', c.on_time_eligible),
        ('approval-valid', c.approval_valid),
        ('handling-valid', c.handling_valid),
        ('handling-valid single-seller', c.handling_valid_single_seller),
        ('carrier-valid', c.carrier_valid),
        ('lead-time valid', c.lead_time_valid),
        ('multi-seller item-bearing', c.multi_seller_item_bearing)
) populations(population, orders)
ORDER BY population;

-- 4) Output grain: one partition check for on-time eligibility.
SELECT
    COUNT(*) FILTER (WHERE is_on_time_eligible) AS eligible_orders,
    COUNT(*) FILTER (WHERE is_on_time_eligible AND is_on_time) AS on_time_orders,
    COUNT(*) FILTER (WHERE is_on_time_eligible AND NOT is_on_time) AS late_orders,
    COUNT(*) FILTER (WHERE is_on_time_eligible AND is_on_time IS NULL) AS unclassified_orders,
    COUNT(*) FILTER (WHERE is_on_time_eligible)
      = COUNT(*) FILTER (WHERE is_on_time_eligible AND is_on_time)
      + COUNT(*) FILTER (WHERE is_on_time_eligible AND NOT is_on_time) AS partition_reconciles
FROM analytics.order_measurement_base;

-- 5) Output grain: one row per review selection/coverage check.
SELECT check_name, numerator, denominator,
       ROUND(numerator::numeric / NULLIF(denominator, 0), 6) AS ratio
FROM (
    SELECT 'selected reviews / source reviewed orders' AS check_name,
           (SELECT COUNT(*) FROM analytics.order_review_selected) AS numerator,
           (SELECT COUNT(DISTINCT order_id) FROM staging.order_reviews) AS denominator
    UNION ALL
    SELECT 'delivered commercial review coverage',
           COUNT(*) FILTER (WHERE is_delivered_commercial AND has_selected_review),
           COUNT(*) FILTER (WHERE is_delivered_commercial)
    FROM analytics.order_measurement_base
) review_checks;

-- 6) Output grain: one row for delivered commercial item reconciliation.
WITH order_totals AS MATERIALIZED (
    SELECT
        COUNT(*) AS order_rows,
        SUM(item_gmv_proxy) AS order_base_gmv,
        SUM(freight_value) AS order_base_freight
    FROM analytics.order_measurement_base
    WHERE is_delivered_commercial
), item_totals AS MATERIALIZED (
    SELECT
        SUM(item_gmv_proxy) AS item_base_gmv,
        SUM(freight_value) AS item_base_freight
    FROM analytics.item_measurement_base
    WHERE is_delivered_commercial
)
SELECT
    o.order_rows,
    o.order_base_gmv,
    o.order_base_freight,
    i.item_base_gmv,
    i.item_base_freight,
    o.order_base_gmv = i.item_base_gmv
      AND o.order_base_freight = i.item_base_freight AS reconciles
FROM order_totals o CROSS JOIN item_totals i;

-- 7) Output grain: one customer-suitability check.
SELECT
    COUNT(*) AS customer_unique_ids,
    COUNT(*) FILTER (WHERE delivered_orders > 0) AS delivered_customers,
    COUNT(*) FILTER (WHERE is_observed_repeat_customer) AS observed_repeat_customers,
    COUNT(*) FILTER (WHERE has_365_day_followup) AS customers_with_365_day_followup,
    COUNT(*) FILTER (WHERE is_repeat_within_365_days) AS repeat_within_365_days
FROM analytics.customer_measurement_base;

-- 8) Output grain: one row per analytics view created through Stage 5B.
SELECT table_name AS analytics_view
FROM information_schema.views
WHERE table_schema = 'analytics'
ORDER BY table_name;
