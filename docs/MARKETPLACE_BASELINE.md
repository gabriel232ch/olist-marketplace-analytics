# Stage 5C marketplace baseline and growth decomposition

## Decision period and grain

The baseline compares delivered commercial purchase cohorts from **January–August 2017** with the same months in **2018**. Each period row is one marketplace total. Category, customer-state and seller contributions are item-GMV allocations that reconcile to the marketplace change.

Delivered item GMV is a marketplace sales-value proxy. It is not Olist revenue, profit, margin or net sales after returns.

## Reconciled baseline

| Metric | Jan–Aug 2017 | Jan–Aug 2018 | Change |
|---|---:|---:|---:|
| Delivered orders | 21,998 | 52,783 | +139.94% |
| Delivered customers | 21,404 | 51,612 | +141.13% observed in-period customers |
| Delivered item rows | 24,943 | 60,324 | — |
| Delivered GMV proxy | R$2,993,456.13 | R$7,218,125.12 | R$4,224,668.99 / +141.13% |
| Delivered AOV proxy | R$136.08 | R$136.75 | +0.49% |
| Active sellers | 1,153 | 2,330 | +102.08% |
| On-time delivery | 96.50% | 92.27% | −4.23 percentage points |
| Average selected review | 4.233 | 4.142 | −0.091 |
| Low-review rate | 10.59% (2,312 / 21,837 reviewed) | 13.37% (7,015 / 52,468 reviewed) | +2.78 points |
| Freight burden | 13.81% | 14.59% | +0.78 points |

The customer row reports period customer counts for context. Limited history prevents a durable customer-lifetime growth or retention claim.

## GMV growth decomposition

The exact symmetric decomposition is:

- order-volume effect = `(current orders − prior orders) × average(prior AOV, current AOV)`;
- AOV/mix effect = `(current AOV − prior AOV) × average(prior orders, current orders)`.

| Component | Value | Share of GMV change |
|---|---:|---:|
| Order-volume effect | R$4,199,528.13 | 99.40% |
| AOV/mix effect | R$25,140.86 | 0.60% |
| Reconstructed change | R$4,224,668.99 | 100.00% |

The two components reconcile exactly to observed GMV change. This means the marketplace expanded mainly by processing more delivered orders, not by materially raising observable item value per order.

## Where growth came from

- The top 10 of 74 category labels contributed R$2,854,957.51, or **67.58%** of marketplace GMV change.
- The top 5 of 27 customer states contributed R$3,212,003.83, or **76.03%** of change.
- São Paulo alone contributed R$1,840,066.51, or **43.56%** of change.
- The top 100 of 2,810 sellers in the contribution view supplied R$2,665,844.73, or **63.10%** of change.

The leading category contributors were health and beauty (R$512,202.80), watches and gifts (R$486,717.34), sports and leisure (R$300,441.93), computers and accessories (R$281,638.03), and bed/bath/table (R$277,914.03).

Current seller value became less concentrated despite seller-level growth concentration: seller HHI fell from 0.006071 to 0.003639 and the top-10 seller GMV share fell from 17.21% to 13.05%.

## Interpretation

The business gained substantial observable scale, but delivery and review guardrails weakened. The evidence supports protecting major growth engines while diagnosing operationally weak pockets before adding demand. It does not establish that volume growth caused the operational decline; category, seller, route, promise-date and seasonal mix also changed.

## Stage 5C gate

**Passed in the isolated PostgreSQL 18 validation database.** Stable-period totals, the symmetric volume/AOV decomposition, and category/state/seller contributions reconcile exactly. Partial source months are excluded from the matched comparison.
