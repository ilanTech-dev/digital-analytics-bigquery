-- Session-level eCommerce funnel step-reach model.
CREATE OR REPLACE TABLE `your-gcp-project.analytics_portfolio.mart_session_step_reach` AS
WITH session_steps AS (
  SELECT session_date AS event_date, DATE_TRUNC(session_date, WEEK(MONDAY)) AS week_start,
    country, device_category, operating_system, new_returning_user, session_key,
    [STRUCT(1 AS step_order,'view_item' AS funnel_step,has_view_item AS reached_step),
     STRUCT(2 AS step_order,'add_to_cart' AS funnel_step,has_add_to_cart AS reached_step),
     STRUCT(3 AS step_order,'begin_checkout' AS funnel_step,has_begin_checkout AS reached_step),
     STRUCT(4 AS step_order,'purchase' AS funnel_step,has_purchase AS reached_step)] AS funnel_steps
  FROM `your-gcp-project.analytics_portfolio.int_sessions`
)
SELECT event_date, week_start, country, device_category, operating_system, new_returning_user,
  session_key, step.step_order, step.funnel_step
FROM session_steps, UNNEST(funnel_steps) AS step
WHERE step.reached_step;
