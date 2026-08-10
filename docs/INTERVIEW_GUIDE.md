# Interview defense guide

## 60-second project story

I used the Olist public e-commerce dataset to answer where marketplace and operations teams should allocate resources for scalable growth without ignoring delivery risk. I built a three-schema PostgreSQL pipeline, audited grain and fanout risks, and used matched Jan–Aug 2017/2018 purchase cohorts. I found that delivered GMV proxy rose 141%, with 99.4% of the change associated with order volume, while on-time delivery fell 4.23 points. I then built transparent category-state, seller, and route portfolios using 100-order and 95%-review-coverage gates. The analysis prioritized six high-value markets for fix-before-growth, two controlled-growth candidates, ten seller interventions, and thirteen high-late routes. Every headline number has an independent validation query, and I label GMV as a marketplace-value proxy and findings as observational.

## Core technical questions

### 1. What is the grain of the main analytics foundations?

- `order_measurement_base`: one row per `order_id`.
- `item_measurement_base`: one row per `(order_id, order_item_id)`.
- `customer_measurement_base`: one row per `customer_unique_id`.
- Category-state priority: one row per category × customer state.
- Seller priority: one row per seller.
- Route priority: one row per seller state × customer state.

The grain determines which measures can be summed and whether order outcomes repeat.

### 2. What was the largest join risk?

Orders have one-to-many items, payments, and reviews. Joining all children at raw grain would multiply rows and overstate GMV/payment/review measures. I aggregated items and payments to one row per order and selected one deterministic review before joining. Item-level segmentation is separate and pre-aggregated to the target segment grain.

### 3. Why use purchase cohorts rather than delivery month?

The business question concerns demand and the later outcome of orders placed in a period. Purchase cohorts keep GMV, fulfillment, and reviews attached to when demand occurred and reduce right-censoring confusion. Delivery month would answer workload throughput and needs a separate label.

### 4. Why compare Jan–Aug rather than full calendar years?

The source is complete and stable from January 2017 through August 2018. September/October 2018 are partial and 2016 is sparse. Matched Jan–Aug windows control calendar-month coverage and avoid presenting partial-period growth as fact.

### 5. How were multiple reviews handled?

I selected the latest `review_answer_timestamp` per order with review creation time and review ID as deterministic descending tie-breakers. There were 547 multiple-review orders, 202 conflicting-score orders, and zero latest-timestamp ties. The latest-selected and per-order-average scores were almost identical, supporting the rule.

### 6. Why require 100 orders and 95% review coverage?

At 100 observations, the worst-case approximate 95% margin of error for a proportion is about ±10 percentage points. That is adequate for medium-confidence ranking when the denominator remains visible. Review-based headlines also need 95% coverage so differential nonresponse is less likely to drive comparisons. These are evidence rules, not universal operating standards.

### 7. How did you prevent growth-rate noise?

I showed absolute GMV change and contribution to marketplace change beside growth rate. Growth interpretation also requires prior and current volume confidence. New or tiny segments may be interesting but are not ranked as proven scalable opportunities.

### 8. How was GMV growth decomposed?

I used a symmetric/Shapley allocation:

- volume effect = order change × average of prior/current AOV;
- AOV/mix effect = AOV change × average of prior/current orders.

The two effects sum exactly to observed GMV change and split the interaction symmetrically.

### 9. Why not use a weighted opportunity score?

A score would hide whether a result came from commercial scale, execution, supply risk, or confidence, and the dataset offers no defensible business weights. Ordered rules keep the evidence separate. Fix overrides Grow when a high-value segment fails an execution guardrail.

### 10. What does the 210-order scenario mean?

It is the arithmetic difference between observed late orders in the six Fix segments and the count implied if each segment matched the eligible peer median on-time rate. It is not a forecast, preventable-loss estimate, causal effect, or guaranteed improvement.

## Business questions

### 11. What is the most important recommendation?

Fix the six high-value weak-execution category-state markets before stimulating more demand. Four are Rio de Janeiro demand cells, and the route evidence makes SP → RJ the first logistics/promise-setting investigation.

### 12. What should the marketplace team grow?

Test `stationery × SP` and `housewares × MG` in controlled increments. They have medium growth confidence, meaningful absolute growth, and strong execution. I would require fulfillment/review guardrails and a matched holdout or staggered rollout before calling any result lift.

### 13. What should seller management do?

Use the ten-seller Fix portfolio, then assign each seller to seller-handling, route/carrier, mixed, or review-quality diagnosis. Do not blacklist the worst raw rate; prioritize material exposure with adequate evidence.

### 14. Why is SP → RJ not automatically a carrier problem?

Its late rate is high and exposure is large, but median handling and carrier times do not exceed their route P75 thresholds. Promise-date generosity, category/seller mix, distance, and carrier performance all remain plausible. SP → BA/CE/PA show clearer carrier-time signals.

### 15. What does the delay/review result prove?

It shows a strong association, not causation. Low reviews increase sharply after three days late, but product quality, damage, communication, category mix, and response selection could contribute. It supports a recovery/intervention test.

## Limitations to volunteer

- GMV is item sales value, not Olist revenue or profit.
- No commission, cost, margin, inventory, marketing exposure, or seller capacity.
- No carrier identity, SLA, exact route, or reliable distance measure.
- No complete returns/refunds or complaints.
- Observational comparisons cannot establish causal effects.
- Sparse repeat purchasing and finite history make RFM secondary.

## Follow-up data to request

1. Carrier and service-level identifiers.
2. Promised-date generation logic.
3. Seller inventory/capacity and handling events.
4. Commission, promotion, and marketing exposure.
5. Returns, refunds, complaints, and recovery actions.
6. Experiment assignment or phased rollout data.

## Whiteboard explanation

Draw the flow:

```text
orders
  ├─ aggregate items → order GMV / seller count
  ├─ aggregate payments → payment total
  └─ rank reviews → one selected review
        ↓
one-row-per-order measurement base
        ↓
separate category-state / seller / route aggregates
        ↓
volume + coverage screen → peer rules → action posture
```

Emphasize that child tables become safe at the target grain before joining.
