-- Strict within-session funnel progression using first event timestamps.
CREATE OR REPLACE TABLE `your-gcp-project.analytics_portfolio.mart_ordered_session_funnel` AS
SELECT
  session_date AS event_date,
  DATE_TRUNC(session_date, WEEK(MONDAY)) AS week_start,
  session_key, user_pseudo_id, country, device_category, operating_system, new_returning_user,
  first_view_item_ts IS NOT NULL AS reached_view_item,
  first_view_item_ts IS NOT NULL AND first_add_to_cart_ts IS NOT NULL
    AND first_add_to_cart_ts >= first_view_item_ts AS reached_add_to_cart,
  first_view_item_ts IS NOT NULL AND first_add_to_cart_ts IS NOT NULL
    AND first_begin_checkout_ts IS NOT NULL
    AND first_add_to_cart_ts >= first_view_item_ts
    AND first_begin_checkout_ts >= first_add_to_cart_ts AS reached_begin_checkout,
  first_view_item_ts IS NOT NULL AND first_add_to_cart_ts IS NOT NULL
    AND first_begin_checkout_ts IS NOT NULL AND first_purchase_ts IS NOT NULL
    AND first_add_to_cart_ts >= first_view_item_ts
    AND first_begin_checkout_ts >= first_add_to_cart_ts
    AND first_purchase_ts >= first_begin_checkout_ts AS reached_purchase
FROM `your-gcp-project.analytics_portfolio.int_sessions`;
