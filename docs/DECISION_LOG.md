# Decision log

| Date | Stage | Decision | Rationale / consequence |
|---|---|---|---|
| 2026-07-31 | 1 | Use PostgreSQL with `raw`, `staging`, and `analytics` schemas. | Separates immutable source landing, typed data, and decision outputs. |
| 2026-08-07 | 2–4 | Preserve all source rows and document anomalies rather than silently cleaning them. | Raw-to-staging reconciliations remain auditable; duration metrics exclude only invalid required intervals. |
| 2026-08-07 | 5A | Optimize for scalable, quality-adjusted marketplace growth—not profit. | The source lacks commission, cost, margin, marketing, inventory, and complete returns economics. |
| 2026-08-07 | 5B | Use Jan–Aug 2017 versus Jan–Aug 2018 purchase cohorts. | These are complete matched months; sparse/partial source months are excluded. |
| 2026-08-07 | 5B | Select the latest answered review per order with deterministic tie-breakers. | Prevents review fanout while retaining multiplicity/conflict flags. |
| 2026-08-07 | 5B | Require 100 orders for ranked evidence and 95% review coverage for review-based headlines. | Controls noisy rates while preserving visible medium/high confidence tiers. |
| 2026-08-07 | 5B | Keep RFM secondary and defer ZIP-distance modeling. | Equal-window repeat is only 4.53%; state routes answer the core decision without unreliable ZIP centroids. |
| 2026-08-07 | 5C | Use a symmetric/Shapley order-volume versus AOV decomposition. | Allocates the interaction exactly and reconstructs observed GMV change. |
| 2026-08-07 | 5D | Use eligible-peer percentiles as operating benchmarks. | Avoids inventing universal “bad” thresholds and keeps comparisons dataset-relative. |
| 2026-08-07 | 5E | Use ordered action rules rather than a weighted score. | Keeps commercial scale, operations, supply risk, and confidence visible and interview-defensible. |
| 2026-08-07 | 5E | Label GMV and peer-median gaps as exposure/scenarios, not benefit. | Prevents unsupported uplift, profit, or causal impact claims. |
| 2026-08-08 | Deployment | Require saved-database reconciliation before Power BI. | The isolated cluster verifies SQL; the local portfolio database must still be the dashboard source of record. |
