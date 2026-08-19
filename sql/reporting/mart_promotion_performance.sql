-- Front Page Carousel promotion performance.
CREATE OR REPLACE TABLE `your-gcp-project.analytics_portfolio.mart_promotion_performance` AS
WITH promotion_events AS (
  SELECT PARSE_DATE('%Y%m%d',event_date) AS event_date,user_pseudo_id,event_name,
    geo.country AS country,device.category AS device_category,
    CASE
      WHEN (SELECT value.int_value FROM UNNEST(event_params) WHERE key='ga_session_number')=1 THEN 'new'
      WHEN (SELECT value.int_value FROM UNNEST(event_params) WHERE key='ga_session_number')>1 THEN 'returning'
      ELSE 'unknown' END AS new_returning_user,
    item.promotion_name,item.creative_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
    AND event_name IN ('view_promotion','select_promotion')
    AND item.creative_name='Front Page Carousel'
    AND item.promotion_name IS NOT NULL AND item.promotion_name!='(not set)'
), aggregated AS (
  SELECT event_date,country,device_category,new_returning_user,promotion_name,
    COUNTIF(event_name='view_promotion') AS promotion_views,
    COUNTIF(event_name='select_promotion') AS promotion_clicks,
    COUNT(DISTINCT IF(event_name='view_promotion',user_pseudo_id,NULL)) AS unique_viewers,
    COUNT(DISTINCT IF(event_name='select_promotion',user_pseudo_id,NULL)) AS unique_clickers
  FROM promotion_events GROUP BY event_date,country,device_category,new_returning_user,promotion_name
)
SELECT *, SAFE_DIVIDE(promotion_clicks,promotion_views) AS ctr,
  SAFE_DIVIDE(unique_clickers,unique_viewers) AS unique_ctr
FROM aggregated;
