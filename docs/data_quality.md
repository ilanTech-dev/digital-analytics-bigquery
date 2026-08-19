# Data Quality and Source Limitations

## Session identifiers

`ga_session_id` should not be treated as globally unique by itself. The session grain therefore uses:

```text
(user_pseudo_id, ga_session_id)
```

## New / returning classification

The classification is applied consistently:

- `ga_session_number = 1` -> `new`
- `ga_session_number > 1` -> `returning`
- missing value -> `unknown`

## Revenue

The public obfuscated GA4 sample does not provide dependable purchase revenue for the selected period.

For that reason:

- revenue is not estimated
- zero is not substituted for an unavailable value
- revenue outputs are returned as `NULL` where retained in a reporting schema

This distinguishes "unknown / unavailable" from a genuine measured value of zero.

## Transaction identifiers

Transaction identifiers in the public dataset are not usable for reliable transaction-level reconciliation. Purchase events are therefore used as purchase proxies.

## Search phrases

The `search_term` parameter is present, but phrase values are obfuscated in the public dataset. Search volume can be measured; meaningful phrase ranking cannot.

## Product data

Rows with missing, blank or `(not set)` product/category values are excluded from product-category reporting where those dimensions are required for the business question.

## Funnel interpretation

Two concepts are deliberately separated:

### Step reach

A session or user is counted at a step when the corresponding event is present.

### Ordered progression

A session is counted at a later funnel step only when preceding events occurred first in timestamp order.

This distinction avoids overstating conversion progression when events are missing, duplicated or recorded out of sequence.
