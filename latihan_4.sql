USE online_retail;

SELECT 
	buyerid,
    shopid,
	MIN(order_time) first_order,
    MAX(order_time) last_order
FROM order_tab
GROUP BY 1, 2 
ORDER BY 1;

-- membeli lebih dari 1 tiap bulan
SELECT 
	MONTH(order_time) bulan,
    buyerid,
    orderid,
    COUNT(orderid)
FROM order_tab
GROUP BY 2, 1
HAVING COUNT(orderid) > 1
ORDER BY 1;

-- pembeli pertama dari tiap toko
WITH ranking AS(SELECT 
	shopid,
    buyerid,
	RANK () OVER(PARTITION BY shopid ORDER BY order_time) ranking
FROM order_tab)

SELECT DISTINCT *
FROM ranking
WHERE ranking = 1;

-- top 10 buyer (gmv) ID and SG
SELECT 
	buyerid,
    SUM(gmv) total_gmv,
    user_tab.country
FROM order_tab
LEFT JOIN user_tab
	USING(buyerid)
WHERE user_tab.country IN ('ID', 'SG')
GROUP BY 1
ORDER BY SUM(gmv) DESC
LIMIT 10;

-- jumlah buyer tiap negara yang itemid nya ganjil/genap
WITH gagen AS (
SELECT 
	ut.country,
    CASE
		WHEN ot.itemid % 2 = 0 THEN 'genap'
        ELSE 'ganjil'
	END ket
FROM order_tab ot
JOIN user_tab ut
	USING (buyerid))
    
SELECT *
FROM gagen;

WITH total_order_per_shop AS(
SELECT 
	shopid,
    COUNT(orderid) total_order
FROM order_tab
GROUP BY 1),

performance_agg AS (
SELECT 
	shopid,
    SUM(total_clicks) total_clicks,
    SUM(impressions) total_impression,
    SUM(item_views) total_view
FROM performance_tab
GROUP BY 1
)

SELECT 
	shopid,
    (total_clicks / total_impression) * 100 ctr,
    (total_order / total_view) * 100 cr
FROM total_order_per_shop
JOIN performance_agg
	USING(shopid)
ORDER BY 3 DESC;


-- case 2
USE mavenfuzzyfactory;

-- conversion rate
SELECT 
	EXTRACT(YEAR_MONTH FROM ws.created_at) bulan,
    COUNT(website_session_id) total_session,
    COUNT(order_id) total_order,
    Round((COUNT(order_id) / COUNT(website_session_id)) * 100, 2) conersion_rate
FROM website_sessions ws
LEFT JOIN orders
	USING (website_session_id)
WHERE 
	utm_source = 'gsearch' AND
	ws.created_at <= '2012-11-30'
GROUP BY 1;

WITH hitung AS(SELECT 
	EXTRACT(YEAR_MONTH FROM ws.created_at) yyyymm,
    COUNT(CASE WHEN utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END ) nonbrand_session,
    COUNT(CASE WHEN utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) nonbrand_order,
    COUNT(CASE WHEN utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) brand_session,
    COUNT(CASE WHEN utm_campaign = 'brand' THEN o.order_id ELSE NULL END) brand_order
FROM website_sessions ws
LEFT JOIN orders o
	USING (website_session_id)
WHERE 
	utm_source = 'gsearch' AND
	ws.created_at <= '2012-11-30'
GROUP BY 1)
    
SELECT 
	yyyymm,
    nonbrand_order,
    nonbrand_session,
	(nonbrand_order / nonbrand_session) * 100 nonbrand_cvr,
    brand_order,
    brand_session,
    (brand_order / brand_session) * 100 brand_cvr
FROM hitung;

SELECT *
FROM website_sessions;

-- case codeflix
SELECT *
FROM codeflix_churn;

#membuat batas bulan
WITH periode AS(
SELECT '2017-01-01' first_day,
		'2017-01-31' last_day
UNION
SELECT '2017-02-01' first_day,
		'2017-02-28' last_day
UNION
SELECT '2017-03-01' first_day,
		'2017-03-31' last_day),
 
#membuat table cross join 
crossjoin_tab AS (
SELECT * FROM codeflix_churn, periode),

active_status AS(SELECT 
	id,
    first_day,
    CASE WHEN (subscription_start < first_day) AND (subscription_end > first_day OR subscription_end IS NULL) THEN 1 ELSE NULL END is_active,
    CASE WHEN (subscription_end BETWEEN first_day AND last_day) THEN 1 ELSE 0 END churn
FROM crossjoin_tab)

SELECT 
	MONTH(first_day),
    SUM(is_active) sum_active,
    SUM(churn) sum_churn,
    ROUND(SUM(churn) / SUM(is_active) * 100, 2) churn_rate
FROM active_status
GROUP BY 1
ORDER BY 1;