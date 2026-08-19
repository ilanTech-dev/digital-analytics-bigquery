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

The public dataset contains obfuscated commercial fields. Where revenue, transaction identifiers or search terms are unavailable, the models preserve that limitation rather than inventing values.

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
