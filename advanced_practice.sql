SELECT * FROM website_sessions;

-- Analyzing Traffic Sources

SELECT 
	website_sessions.utm_content,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id),
	COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rt
FROM website_sessions
	LEFT JOIN orders
    ON  website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.website_session_id BETWEEN 1000 AND 2000
GROUP BY 1
ORDER BY 2 DESC;


-- FINDING TOP TRAFFIC SOURCES

SELECT * FROM website_sessions;

SELECT  
	utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at <'2012-04-12'
GROUP BY 
	utm_source,
    utm_campaign,
    http_referer
ORDER BY 4 DESC;


-- Gsearch conversion rate

SELECT
	COUNT(website_sessions.website_session_id) sessions,
    COUNT(orders.order_id) orders,
    COUNT(orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) sessions_to_order_conv_rt
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-04-14'
	AND utm_source='gsearch' -- website_sessions.utm_source='gsearch'
    AND utm_campaign='nonbrand'; -- website_sessions.utm_campaign='nonbrand'
    
-- Both means the same because there is no ambiguity here


-- week_start_date

SELECT 
	-- YEAR(website_sessions.created_at),
	-- WEEK(website_sessions.created_at)
    MIN(DATE(created_at)) week_start_date,
	COUNT(DISTINCT website_sessions.website_session_id) as sessions
FROM website_sessions
WHERE website_sessions.created_at < '2012-05-10'
AND website_sessions.utm_source='gsearch'
AND website_sessions.utm_campaign='nonbrand' 
GROUP BY 
	YEAR(website_sessions.created_at),
	WEEK(website_sessions.created_at);


-- Gsearch device level performance 

SELECT
	website_sessions.device_type,
    COUNT(DISTINCT website_sessions.website_session_id) as sessions,
    COUNT(DISTINCT orders.order_id) as orders,
    COUNT(orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) as session_to_order_conv_rate
FROM website_sessions
	LEFT JOIN orders
    ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at < '2012-05-11'
AND website_sessions.utm_source='gsearch'
AND website_sessions.utm_campaign='nonbrand'
GROUP BY 1;

-- Gsearch device level trend weekly

SELECT
	-- YEAR(created_at),
    -- WEEK(created_at),
    MIN(DATE(created_at)),
    COUNT(CASE WHEN website_sessions.device_type='desktop' THEN website_sessions.website_session_id ELSE NULL END ) AS dtop_sessions,
    COUNT(CASE WHEN website_sessions.device_type='mobile' THEN website_sessions.website_session_id ELSE NULL END ) AS mob_sessions

FROM website_sessions
WHERE website_sessions.created_at > '2012-04-15' AND website_sessions.created_at < '2012-06-09'
	AND website_sessions.utm_source='gsearch'
	AND website_sessions.utm_campaign='nonbrand'
GROUP BY
	YEAR(created_at),
	WEEK(created_at);
    
    

-- Analyzing Website performance 


-- TOP Website pages

SELECT 
	pageview_url,
	COUNT(DISTINCT website_pageview_id) as sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY 1
ORDER BY 2 DESC;

-- Finding top entries pages

CREATE TEMPORARY TABLE pageView
SELECT 
	website_session_id,
	MIN(website_pageview_id) AS min_pgv
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id;


SELECT 
	website_pageviews.pageview_url AS landing_page_url,
    COUNT(DISTINCT pageView.website_session_id) AS sessions
FROM pageView 
LEFT JOIN website_pageviews
	ON pageView.min_pgv=website_pageviews.website_pageview_id
 GROUP BY 1;
 
 
-- Analyzing Bounce Rates & Landing page

-- STEP 1: finding the first website_pageview_id for relevant sessions
-- STEP 2: identifying the landing page of each sessions
-- STEP 3: counting pageviews for each sessions to identify "bounces"
-- STEP 4: summarizing by counting total sessions and bounced sessions 


CREATE TEMPORARY TABLE pageview
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS first_pg_view
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY
	website_session_id;

SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
INNER JOIN website_sessions
	ON website_sessions.website_session_id=website_pageviews.website_session_id
    AND website_pageviews.created_at < '2012-06-14'
GROUP BY website_pageviews.website_session_id;

CREATE TEMPORARY TABLE sessions_w_landing_page_demo
SELECT 
	pageview.website_session_id,
    website_pageviews.pageview_url AS landing_page
FROM pageview
LEFT JOIN website_pageviews
	ON website_pageviews.website_pageview_id=pageview.first_pg_view; -- website pageview is the landing page 'first page view'


SELECT * FROM sessions_w_landing_page_demo;  -- first_ page view k liye landing page nikala 

CREATE TEMPORARY TABLE bounced_sessions_only
SELECT 
	sessions_w_landing_page_demo.website_session_id, -- UNIQUE 
    sessions_w_landing_page_demo.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM sessions_w_landing_page_demo
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id=sessions_w_landing_page_demo.website_session_id
GROUP BY
	sessions_w_landing_page_demo.website_session_id,
	sessions_w_landing_page_demo.landing_page
HAVING 
	COUNT(website_pageviews.website_pageview_id) = 1;
    

SELECT * FROM bounced_sessions_only; 

-- This will tell us the session which have visited one page or else we are getting NULL if visited more than once
SELECT 
	sessions_w_landing_page_demo.website_session_id,
    bounced_sessions_only.website_session_id
FROM sessions_w_landing_page_demo
LEFT JOIN bounced_sessions_only
	ON sessions_w_landing_page_demo.website_session_id=bounced_sessions_only.website_session_id;

SELECT 
	sessions_w_landing_page_demo.landing_page,
    COUNT(DISTINCT sessions_w_landing_page_demo.website_session_id) AS sessions,
    COUNT(DISTINCT bounced_sessions_only.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bounced_sessions_only.website_session_id)/COUNT(DISTINCT sessions_w_landing_page_demo.website_session_id) AS bounce_rate
FROM sessions_w_landing_page_demo
	LEFT JOIN bounced_sessions_only
		ON sessions_w_landing_page_demo.website_session_id=bounced_sessions_only.website_session_id
GROUP BY 
	sessions_w_landing_page_demo.landing_page;
    
    
-- analysing landing page

-- STEP 1: finding the first website_pageview_id for relevant sessions
-- STEP 2: identifying the landing page of each sessions
-- STEP 3: counting pageviews for each sessions to identify "bounces"
-- STEP 4: summarizing by counting total sessions and bounced sessions 

SELECT * FROM 
website_pageviews 
WHERE pageview_url='/lander-1';
-- 2012-06-19 00:35:54 to 2012-07-28

CREATE TEMPORARY TABLE first_page_view_id
SELECT 
	website_sessions.website_session_id,
    MIN(website_pageview_id) AS min_page_view_id
FROM website_pageviews
	INNER JOIN website_sessions
    ON website_sessions.website_session_id=website_pageviews.website_session_id
    AND website_sessions.created_at < '2012-07-28'
    AND website_pageviews.website_pageview_id > 23504
    AND website_sessions.utm_source='gsearch'
    AND website_sessions.utm_campaign='nonbrand'
GROUP BY website_sessions.website_session_id;


SELECT * FROM first_page_view_id;

CREATE TEMPORARY TABLE sessions_with_landing_page
SELECT 
	first_page_view_id.website_session_id,
    website_pageviews.pageview_url
FROM first_page_view_id
LEFT JOIN website_pageviews
	ON first_page_view_id.min_page_view_id=website_pageviews.website_pageview_id
WHERE website_pageviews.pageview_url IN ('/home','/lander-1');
    
CREATE TEMPORARY TABLE Bounced_only
SELECT 
	sessions_with_landing_page.pageview_url,
    sessions_with_landing_page.website_session_id,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM sessions_with_landing_page
LEFT JOIN website_pageviews
	ON sessions_with_landing_page.website_session_id=website_pageviews.website_session_id
GROUP BY 1,2
HAVING 
     count_of_pages_viewed=1;


SELECT
	sessions_with_landing_page.pageview_url,
    COUNT(DISTINCT sessions_with_landing_page.website_session_id) sessions,
    COUNT(DISTINCT Bounced_only.website_session_id) bounced_sessions,
    COUNT(DISTINCT Bounced_only.website_session_id) /COUNT(DISTINCT sessions_with_landing_page.website_session_id) AS bounce_rate
FROM sessions_with_landing_page
    LEFT JOIN bounced_only
    ON Bounced_only.website_session_id=sessions_with_landing_page.website_session_id
GROUP BY 1;
    

-- Landing page analysis

-- STEP 1: finding the first website_pageview_id for relevant sessions
-- STEP 2: identifying the landing page of each sessions
-- STEP 3: counting pageviews for each sessions to identify "bounces"
-- STEP 4: summarizing by counting total sessions and bounced sessions 

CREATE TEMPORARY TABLE first_pg_view_landing_page
SELECT 
	website_sessions.website_session_id,
    MIN(website_pageviews.website_pageview_id) as min_pg_view_id
FROM website_pageviews
	INNER JOIN website_sessions
    ON website_pageviews.website_session_id=website_sessions.website_session_id
    AND website_sessions.created_at > '2012-06-01' 
    AND website_sessions.created_at < '2012-08-31'
    AND website_sessions.utm_source='gsearch'
    AND website_sessions.utm_campaign='nonbrand'
    -- AND website_pageviews.pageview_url IN ('/home','/lander-1')
GROUP BY 1;

CREATE TEMPORARY TABLE sessions_with_landing_page_non_brand
SELECT
	first_pg_view_landing_page.website_session_id,
	website_pageviews.pageview_url
FROM website_pageviews
	LEFT JOIN first_pg_view_landing_page
		ON first_pg_view_landing_page.min_pg_view_id=website_pageviews.website_pageview_id
WHERE website_pageviews.pageview_url IN ('/home','/lander-1');

CREATE TEMPORARY TABLE Bounce_only_non_brand_traffic_
SELECT 
	sessions_with_landing_page_non_brand.website_session_id,
    sessions_with_landing_page_non_brand.pageview_url,
    COUNT(website_pageviews.website_pageview_id) AS total_count,
    MIN(DATE(website_pageviews.created_at)) date_week
FROM sessions_with_landing_page_non_brand
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id=sessions_with_landing_page_non_brand.website_session_id
GROUP BY 1,2;



SELECT 
MIN(Bounce_only_non_brand_traffic_.date_week) AS week_start_date,
COUNT(Bounce_only_non_brand_traffic_.website_session_id) AS total_sessions,
COUNT(CASE WHEN Bounce_only_non_brand_traffic_.total_count=1 THEN Bounce_only_non_brand_traffic_.website_session_id ELSE NULL END) AS bounce,
COUNT(CASE WHEN Bounce_only_non_brand_traffic_.total_count=1 THEN Bounce_only_non_brand_traffic_.website_session_id ELSE NULL END)
 / COUNT(Bounce_only_non_brand_traffic_.website_session_id) AS bounced_rate,
COUNT(CASE WHEN Bounce_only_non_brand_traffic_.pageview_url='/home' THEN 1 ELSE NULL END) AS home_sessions,
COUNT(CASE WHEN Bounce_only_non_brand_traffic_.pageview_url='/lander-1' THEN 1 ELSE NULL END) AS lander_sessions
FROM Bounce_only_non_brand_traffic_
GROUP BY yearweek(Bounce_only_non_brand_traffic_.date_week);





-- Building conversion funnels 





    



	



	





