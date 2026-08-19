/*
Model: int_sessions

Grain:
- One row per (user_pseudo_id, ga_session_id).

Purpose:
- Create a reusable session-level model from raw GA4 events.
- Standardise user classification and funnel logic.
- Capture both step-presence flags and first event timestamps.

Source period:
- January 2021.
*/

CREATE OR REPLACE TABLE
  `your-gcp-project.analytics_portfolio.int_sessions`

CLUSTER BY
  user_pseudo_id,
  ga_session_id,
  country,
  device_category

AS

WITH base_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp,
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    (SELECT ep.value.int_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'ga_session_id') AS ga_session_id,
    (SELECT ep.value.int_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'ga_session_number') AS ga_session_number,
    geo.country,
    device.category AS device_category,
    device.operating_system
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210131'
    AND user_pseudo_id IS NOT NULL
),
session_aggregates AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING)) AS session_key,
    ARRAY_AGG(event_date ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS session_date,
    TIMESTAMP_MICROS(MIN(event_timestamp)) AS session_start_timestamp,
    TIMESTAMP_MICROS(MAX(event_timestamp)) AS session_end_timestamp,
    TIMESTAMP_DIFF(TIMESTAMP_MICROS(MAX(event_timestamp)), TIMESTAMP_MICROS(MIN(event_timestamp)), SECOND) AS session_duration_seconds,
    MAX(ga_session_number) AS session_number,
    ARRAY_AGG(country IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS country,
    ARRAY_AGG(device_category IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS device_category,
    ARRAY_AGG(operating_system IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS operating_system,
    COUNT(*) AS event_count,
    COUNTIF(event_name = 'view_item') > 0 AS has_view_item,
    COUNTIF(event_name = 'add_to_cart') > 0 AS has_add_to_cart,
    COUNTIF(event_name = 'begin_checkout') > 0 AS has_begin_checkout,
    COUNTIF(event_name = 'purchase') > 0 AS has_purchase,
    MIN(IF(event_name = 'view_item', event_timestamp, NULL)) AS first_view_item_ts,
    MIN(IF(event_name = 'add_to_cart', event_timestamp, NULL)) AS first_add_to_cart_ts,
    MIN(IF(event_name = 'begin_checkout', event_timestamp, NULL)) AS first_begin_checkout_ts,
    MIN(IF(event_name = 'purchase', event_timestamp, NULL)) AS first_purchase_ts,
    COUNTIF(event_name = 'purchase') AS purchase_count
  FROM base_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
)
SELECT
  session_key, user_pseudo_id, ga_session_id, session_date,
  session_start_timestamp, session_end_timestamp, session_duration_seconds,
  session_number,
  CASE WHEN session_number = 1 THEN 'new' WHEN session_number > 1 THEN 'returning' ELSE 'unknown' END AS new_returning_user,
  country, device_category, operating_system, event_count,
  has_view_item, has_add_to_cart, has_begin_checkout, has_purchase,
  first_view_item_ts, first_add_to_cart_ts, first_begin_checkout_ts, first_purchase_ts,
  purchase_count
FROM session_aggregates;
