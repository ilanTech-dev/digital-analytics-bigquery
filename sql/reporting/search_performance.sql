-- Daily search volume. Search phrases are obfuscated in the public dataset.
WITH search_events AS (
  SELECT PARSE_DATE('%Y%m%d',event_date) AS search_date,user_pseudo_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key='search_term') AS search_phrase
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name='view_search_results' AND _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
)
SELECT search_date,search_phrase,COUNT(*) AS total_searches,
  COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM search_events
WHERE search_phrase IS NOT NULL
GROUP BY search_date,search_phrase
ORDER BY search_date,total_searches DESC,search_phrase;
