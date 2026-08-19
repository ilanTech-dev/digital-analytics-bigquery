# Architecture

## 1. Source Layer

The source is Google's public GA4 obfuscated eCommerce export:

```text
bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
```

The case study uses January 2021 data.

## 2. Intermediate Layer

`int_sessions.sql` converts raw GA4 events to one row per:

```text
(user_pseudo_id, ga_session_id)
```

This composite key is used because `ga_session_id` is not guaranteed to be globally unique across users.

The model includes:

- session start and end timestamps
- session duration
- session number
- country
- device category
- operating system
- event count
- eCommerce funnel flags
- first timestamp for each funnel step
- purchase count

## 3. Reporting Layer

### User summary

One row per user with first observed visit, first purchase, visit dates, session count, purchasing-session count, purchase count and sessions until first purchase.

### User step reach

Preserves user-level rows for each eCommerce step reached, supporting distinct-user funnel reporting.

### Session step reach

Preserves session-level rows for each eCommerce step reached, supporting distinct-session funnel reporting.

### Ordered session funnel

Uses the first timestamp of each funnel step to measure strict within-session progression:

```text
view_item
  -> add_to_cart
  -> begin_checkout
  -> purchase
```

A later step only counts as reached when the preceding steps occurred in order.

### Product category performance

Aggregates purchases by Monday-starting week and product category. It also retains the top five selling products as an `ARRAY<STRUCT>`.

### Promotion performance

Measures homepage carousel views, selections, unique viewers, unique selectors, CTR and unique CTR.

### Search performance

Reports daily search volume and unique searching users. The public dataset obfuscates the actual search phrase values.

## 4. Portfolio Focus

The repository intentionally separates analytical modelling from dashboard tooling. The objective is to demonstrate the underlying behavioural logic, reporting grain and data-quality decisions in a form that can be reviewed directly in GitHub.
