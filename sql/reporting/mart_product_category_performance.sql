-- Weekly product-category performance and top-five products.
CREATE OR REPLACE TABLE `your-gcp-project.analytics_portfolio.mart_product_category_performance` AS
WITH purchase_items AS (
  SELECT DATE_TRUNC(PARSE_DATE('%Y%m%d',event_date),WEEK(MONDAY)) AS week_start,
    user_pseudo_id, item.item_category, item.item_name, item.quantity AS quantity
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`, UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131' AND event_name='purchase'
    AND item.item_category IS NOT NULL AND TRIM(item.item_category)!='' AND item.item_category!='(not set)'
    AND item.item_name IS NOT NULL AND TRIM(item.item_name)!='' AND item.item_name!='(not set)'
    AND item.quantity IS NOT NULL AND item.quantity>0
), category_summary AS (
  SELECT week_start,item_category,COUNT(DISTINCT user_pseudo_id) AS total_purchasers,
    SUM(quantity) AS total_items_sold
  FROM purchase_items GROUP BY week_start,item_category
), product_summary AS (
  SELECT week_start,item_category,item_name,SUM(quantity) AS items_sold
  FROM purchase_items GROUP BY week_start,item_category,item_name
), top_products AS (
  SELECT week_start,item_category,
    ARRAY_AGG(STRUCT(item_name AS product_name,items_sold) ORDER BY items_sold DESC,item_name LIMIT 5) AS top_5_selling_products
  FROM product_summary GROUP BY week_start,item_category
)
SELECT c.week_start,c.item_category,c.total_purchasers,c.total_items_sold,
  CAST(NULL AS NUMERIC) AS total_revenue_usd,t.top_5_selling_products
FROM category_summary c LEFT JOIN top_products t USING(week_start,item_category);
