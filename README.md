# GA4 + BigQuery Digital Analytics Case Study

This repository demonstrates an end-to-end digital analytics workflow using Google's public GA4 obfuscated eCommerce dataset in BigQuery.

The project focuses on the kinds of analytical problems commonly found in product, growth and commercial analytics:

- session modelling from raw GA4 events
- customer journey and funnel analysis
- user and session-level behavioural reporting
- product-category performance
- promotion performance and CTR
- search behaviour
- data-quality validation and explicit treatment of source limitations

## Dataset

Source:

```text
bigquery-public-data.ga4_obfuscated_sample_ecommerce
```

The case study uses January 2021 data. The public dataset contains obfuscated commercial fields. Where revenue, transaction identifiers or search terms are unavailable, the models preserve that limitation rather than inventing values.

## Architecture

```text
GA4 event export
      |
      v
int_sessions
      |
      +-------------------------+
      |            |            |
      v            v            v
user_summary   user_step     session_step
               reach          reach
                              |
                              v
                     ordered_session_funnel

Independent reporting models:
- product_category_performance
- promotion_performance
- search_performance
```

## Validation & Findings

All models were executed against the public BigQuery dataset and reconciled back to their source data.

### Session and user modelling

- 118,380 session rows = 118,380 unique composite session keys
- 94,790 unique users
- 0 null session keys
- full date coverage from 2021-01-01 through 2021-01-31
- user summary reconciles to 118,380 sessions and 1,204 purchase events
- 1,069 purchasing users across 1,115 purchasing sessions

### Funnel measurement

Simple event-presence reporting identified:

| Step | Sessions reaching step |
|---|---:|
| View item | 23,105 |
| Add to cart | 4,537 |
| Begin checkout | 2,159 |
| Purchase | 1,115 |

A stricter within-session ordered funnel produced:

| Step | Ordered sessions |
|---|---:|
| View item | 23,105 |
| Add to cart | 4,525 |
| Begin checkout | 1,500 |
| Purchase | 809 |

The ordered model therefore observes 809 complete `view_item -> add_to_cart -> begin_checkout -> purchase` journeys, compared with 1,115 sessions containing a purchase event. This distinction is intentional: event presence and observable sequential progression answer different analytical questions. Missing intermediate events may reflect alternative journeys, cross-session behaviour or instrumentation limitations rather than invalid purchases.

Ordered stage-to-stage conversion rates were:

- view item -> add to cart: 19.58%
- add to cart -> begin checkout: 33.15%
- begin checkout -> purchase: 53.93%
- full observed ordered funnel: 3.50% of product-view sessions

### Product performance

The product-category model reconciles exactly to the qualifying raw purchase-item quantity: 3,378 items in source data and 3,378 items after aggregation. The model also demonstrates nested BigQuery `ARRAY<STRUCT>` output for the top five products within each category/week.

### Promotion performance

The promotion model produced 40,500 recorded views and 2,682 selections, for an overall CTR of 6.62%. Eight highly segmented rows produced CTR above 100%; all had very small denominators (maximum 6 recorded views). These values are retained rather than capped because repeated selections or incomplete view instrumentation can legitimately produce clicks exceeding recorded views at a narrow reporting grain.

### Search behaviour

Daily search volumes and unique searching users are measurable, but the public dataset returns `<obfuscated>` for the search phrase itself. The query therefore reports the observable metrics without claiming phrase-level insight that the source cannot support.

## Repository Structure

```text
.
├── README.md
├── docs/
│   ├── architecture.md
│   └── data_quality.md
└── sql/
    ├── intermediate/
    │   └── int_sessions.sql
    └── reporting/
        ├── mart_user_summary.sql
        ├── mart_user_step_reach.sql
        ├── mart_session_step_reach.sql
        ├── mart_ordered_session_funnel.sql
        ├── mart_product_category_performance.sql
        ├── mart_promotion_performance.sql
        └── search_performance.sql
```

## Design Principles

- Define table grain before writing SQL.
- Reuse validated business logic.
- Keep user and session analysis separate.
- Make assumptions explicit.
- Reconcile reporting outputs back to source data.
- Use `SAFE_DIVIDE` for ratio metrics.
- Preserve `NULL` where commercial values are unavailable.
- Distinguish simple step reach from strict ordered funnel progression.

## Notes

The SQL uses a placeholder destination project:

```text
your-gcp-project.analytics_portfolio
```

Replace `your-gcp-project` with your own Google Cloud project before running the `CREATE OR REPLACE TABLE` statements.

## Author

Ilan Cohen
