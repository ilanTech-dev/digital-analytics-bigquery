/* Model: mart_user_summary | Grain: one row per user_pseudo_id */
CREATE OR REPLACE TABLE `your-gcp-project.analytics_portfolio.mart_user_summary`
CLUSTER BY user_pseudo_id AS
WITH ranked_sessions AS (
  SELECT user_pseudo_id, session_key, session_date, session_start_timestamp, has_purchase, purchase_count,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id ORDER BY session_start_timestamp, session_key) AS session_sequence
  FROM `your-gcp-project.analytics_portfolio.int_sessions`
),
user_aggregates AS (
  SELECT user_pseudo_id,
    MIN(session_start_timestamp) AS first_visit_timestamp,
    MIN(IF(has_purchase, session_start_timestamp, NULL)) AS first_purchase_timestamp,
    ARRAY_AGG(DISTINCT session_date ORDER BY session_date) AS visit_dates,
    COUNT(*) AS session_count,
    COUNTIF(has_purchase) AS purchasing_session_count,
    SUM(purchase_count) AS purchase_count,
    MIN(IF(has_purchase, session_sequence, NULL)) AS sessions_until_first_purchase
  FROM ranked_sessions GROUP BY user_pseudo_id
)
SELECT user_pseudo_id, first_visit_timestamp, first_purchase_timestamp, visit_dates,
  session_count, purchasing_session_count, purchase_count, sessions_until_first_purchase,
  CAST(NULL AS NUMERIC) AS lifetime_revenue
FROM user_aggregates;
