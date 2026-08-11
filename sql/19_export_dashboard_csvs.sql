

\copy (SELECT * FROM analytics.dashboard_executive_kpis ORDER BY period_sort) TO 'dashboard/data/executive_kpis.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT * FROM analytics.dashboard_monthly_trend ORDER BY purchase_month) TO 'dashboard/data/monthly_trend.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT * FROM analytics.dashboard_category_state ORDER BY action_sort, current_gmv DESC, segment_label) TO 'dashboard/data/category_state.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT * FROM analytics.dashboard_seller ORDER BY action_sort, current_gmv DESC, seller_id) TO 'dashboard/data/seller.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT * FROM analytics.dashboard_route ORDER BY CASE action_posture WHEN 'Fix route' THEN 1 WHEN 'Defend route' THEN 2 ELSE 3 END, delivered_gmv_proxy DESC, route_label) TO 'dashboard/data/route.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT * FROM analytics.dashboard_delay_band ORDER BY band_order) TO 'dashboard/data/delay_band.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT * FROM analytics.dashboard_growth_contributor ORDER BY dimension_type, growth_rank) TO 'dashboard/data/growth_contributor.csv' WITH (FORMAT csv, HEADER true)
