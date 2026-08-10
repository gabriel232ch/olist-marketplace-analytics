# Stage 5A analytics framework

## Purpose and boundary

This framework converts the verified Olist data foundation into a decision-oriented analytics engagement. Stage 5A defines what management must decide, which hypotheses deserve evidence, and how analyses will connect to action. It does not create analytics tables or views, execute headline analytical SQL, rank segments, or state findings.

The working logic is:

> decision → hypothesis → evidence → insight → implication → action

## Primary business decision

> **Where should Olist allocate commercial and operational resources to generate scalable marketplace growth while protecting fulfillment reliability and customer experience?**

The earlier category × state × seller question remains the core allocation grain, but it now sits inside a broader marketplace-growth decision rather than treating delivery risk as the only objective.

### Objective and measurable proxies

The objective is **scalable, quality-adjusted marketplace growth**. It is not represented by one opaque score at the start of the analysis.

- Commercial attractiveness will be measured selectively with delivered item GMV, delivered orders, growth contribution, AOV or item-value mix, customer demand, seller availability, and geographic reach.
- Operational sustainability will be measured selectively with on-time delivery, delay severity, valid seller-handling and carrier time, cancellation/unavailability, review outcomes, freight burden, and seller concentration.
- Impact and confidence will remain separate. A large estimated opportunity supported by little data must not automatically outrank a smaller, better-supported opportunity.

Delivered item GMV is a marketplace-value proxy. It is not Olist commission revenue, audited revenue, gross margin, contribution margin, or profit.

### Constraints and unavailable economics

The dataset does not provide Olist commission revenue, product or inventory cost, gross margin, marketing spend, seller acquisition cost, complete refunds/returns, carrier service levels, inventory availability, promotion exposure, or experimental treatment data. Therefore:

- the project will prioritize marketplace value and operational quality, not profit;
- observed associations will not be described as causal effects;
- opportunity sizing will expose its benchmark and assumptions;
- recommendations will identify additional information required before implementation.

## Stakeholders and decisions

| Stakeholder | Decision supported | Evidence required |
|---|---|---|
| Marketplace/commercial lead | Where to grow, defend, investigate, or deprioritize demand | Delivered GMV and order contribution, growth, customer demand, supply depth, operational guardrails |
| Seller-management lead | Which sellers to protect, develop, fix, recruit around, or reassess | Seller value, growth, execution, category importance, geographic reach, concentration and replaceability proxies |
| Logistics-operations lead | Which routes and fulfillment stages need intervention | Route volume, late rate, delay severity, handling versus carrier time, freight burden, confidence |
| Customer-experience lead | Which operational conditions warrant experience protection or investigation | Review coverage, low-review rate, lateness bands, fulfillment stages, order complexity and alternative explanations |
| Analytics/BI owner | Which definitions and monitoring views are safe to operationalize | Stable populations, visible denominators, reconciliations, anomaly flags, volume/confidence labels |

## MECE issue tree

The first three Level-1 branches are the mutually exclusive diagnostic questions: value creation, scalability conditions, and execution constraints. The fourth branch is intentionally the decision synthesis; it does not introduce a separate set of facts. This prevents seller or category performance from being analyzed twice under different labels.

```text
L0  Where should Olist allocate commercial and operational resources for
    scalable, quality-adjusted marketplace growth?

├─ L1 A. Where is marketplace value and growth coming from?
│  ├─ L2 A1. How large and durable is marketplace demand?
│  │  ├─ L3 Delivered GMV = delivered orders × delivered AOV
│  │  ├─ L3 Orders = observed customers × observed purchase frequency
│  │  └─ L3 Separate complete-period trend from partial/censored periods
│  ├─ L2 A2. What explains GMV change?
│  │  ├─ L3 Order-volume contribution
│  │  ├─ L3 AOV / item-value / items-per-order contribution
│  │  └─ L3 Category and product-mix contribution
│  └─ L2 A3. Where is change concentrated?
│     ├─ L3 Category and customer geography
│     ├─ L3 Seller and seller portfolio
│     └─ L3 New versus repeat demand only if observation supports it
│
├─ L1 B. Where do attractive demand and scalable supply coincide?
│  ├─ L2 B1. Which category × customer-state markets are attractive?
│  │  ├─ L3 Scale and contribution to growth
│  │  ├─ L3 AOV / item-value and customer reach
│  │  └─ L3 Operational quality as a growth guardrail
│  ├─ L2 B2. Is seller supply sufficient and diversified?
│  │  ├─ L3 Active seller count and local seller availability
│  │  ├─ L3 Top-seller share / HHI concentration
│  │  └─ L3 Interstate fulfillment, freight burden and geographic reach
│  └─ L2 B3. What type of opportunity is present?
│     ├─ L3 Scalable growth opportunity
│     ├─ L3 Mature / defend segment
│     └─ L3 Operationally constrained or weak segment
│
├─ L1 C. What prevents attractive demand from scaling safely?
│  ├─ L2 C1. Where does the fulfillment process break down?
│  │  ├─ L3 Purchase → approval
│  │  ├─ L3 Approval → carrier handoff
│  │  └─ L3 Carrier handoff → delivery and promise → actual
│  ├─ L2 C2. Where is the problem concentrated?
│  │  ├─ L3 Seller and category
│  │  ├─ L3 Seller-state → customer-state route
│  │  └─ L3 Freight burden and order complexity
│  └─ L2 C3. What customer-experience outcome is associated with it?
│     ├─ L3 Review score / low-review rate
│     ├─ L3 Delay severity bands and threshold effects
│     └─ L3 Coverage, confounders and non-causal interpretation
│
└─ L1 D. Which participants and markets require action?
   ├─ L2 D1. Combine evidence without hiding it in an opaque score
   │  ├─ L3 Commercial impact
   │  ├─ L3 Operational health / addressability
   │  └─ L3 evidence confidence
   ├─ L2 D2. Assign an interpretable action posture
   │  ├─ L3 Grow or Defend
   │  ├─ L3 Fix or Investigate
   │  └─ L3 Deprioritize only with adequate evidence
   └─ L2 D3. Specify an operating decision
      ├─ L3 Target, owner and action
      ├─ L3 KPI, trigger and guardrail
      └─ L3 Risk, assumption and validation required
```

## Analysis priorities

Priority is based on **Impact × Actionability × Evidence Quality**, used as a decision rubric rather than a fabricated numerical product.

| Tier | Analysis | Why it belongs here |
|---|---|---|
| Tier 1 — decision-critical | A01 Marketplace growth decomposition | Establishes what actually drives or drags observable marketplace value and prevents rate-only storytelling. |
| Tier 1 — decision-critical | A02 Category × geography opportunity map | Directly identifies where commercial and operational resources could be allocated. |
| Tier 1 — decision-critical | A03 Supply–demand mismatch | Tests whether attractive demand lacks sufficient or diversified seller supply and identifies a plausible commercial lever. |
| Tier 1 — decision-critical | A04 Fulfillment root-cause decomposition | Separates seller-handling from carrier/logistics problems so ownership is actionable. |
| Tier 1 — decision-critical | A05 Seller portfolio | Translates value, execution and strategic dependence into grow/defend/fix/investigate decisions. |
| Tier 2 — diagnostic/supporting | A06 Customer-experience driver analysis | Explains whether operational problems are associated with poor reviews; it supports, but cannot alone prove, an intervention. |
| Tier 2 — diagnostic/supporting | Concentration and route drill-downs | Validate mechanisms behind A02–A05; they are not separate headline stories unless material. |
| Tier 3 — exploratory/appendix | A07 Repeat-customer/RFM suitability test | Determines whether sparse repeat behavior supports a meaningful customer strategy before RFM is included. |
| Tier 3 — exploratory/appendix | Payment-method popularity, generic Top-10 lists, isolated review distributions | They do not normally change the allocation decision and should remain appendix checks unless tied to a Tier-1 hypothesis. |

## Integrated business analyses

### A01 — Marketplace growth decomposition

- **Question:** What is actually driving or dragging delivered marketplace value?
- **Method:** Compare complete purchase cohorts; decompose delivered GMV into delivered orders and AOV, then quantify absolute contribution to change by category, customer state and seller. Separate large contribution from high percentage growth on a small base.
- **Insight created:** Identifies whether change reflects customer/order volume, price/item mix, or concentration in particular marketplace segments.
- **Decision:** Where commercial teams should investigate growth, defend a major contributor, or avoid reacting to noisy growth rates.

### A02 — Category × geography opportunity map

- **Question:** Where does attractive demand coincide with scalable marketplace conditions?
- **Method:** At category × customer-state grain, preserve scale, growth contribution, seller depth, concentration, fulfillment quality, review quality and freight burden as separate evidence columns. Apply minimum-volume and confidence rules before assigning an action posture.
- **Insight created:** Distinguishes Grow, Defend, Fix-before-growth and low-priority markets without assuming the largest segment is best.
- **Decision:** Where marketplace resources should expand demand, protect service, or pause growth activity.

### A03 — Supply–demand mismatch

- **Question:** Where is customer demand stronger than available or diversified seller supply?
- **Method:** Compare demand by category × customer state with active seller count, local seller availability, concentration, interstate share, freight burden and delivery performance. Approximate distance is optional and only allowed after a defensible one-row-per-ZIP lookup is designed and coverage is reported.
- **Insight created:** Separates a demand opportunity from a supply-depth, geographic or concentration constraint.
- **Decision:** Where to recruit/develop sellers, diversify supply, or investigate logistics economics.

### A04 — Fulfillment root-cause decomposition

- **Question:** Where do delays originate, and who is the likely intervention owner?
- **Method:** For valid timestamps, calculate approval, handling, carrier, total lead time and promised-versus-actual delay using median, P75, P90, late rate and severity. Compare high-volume sellers, categories and seller-state → customer-state routes with appropriate peers.
- **Insight created:** Distinguishes seller-processing symptoms from carrier/route symptoms and prevents extreme low-volume cases from leading the story.
- **Decision:** Whether seller management, logistics operations or expectation-setting should own the next investigation.

### A05 — Seller portfolio

- **Question:** Which sellers should Olist grow, protect, fix, investigate or reassess?
- **Method:** Combine seller commercial contribution and growth with on-time performance, valid handling time, reviews, freight burden, reach and category dependence. Use rule-based quadrants and Pareto context before considering any composite score.
- **Insight created:** Identifies high-value weak performers and strategically important reliable sellers, rather than simply naming the worst late-rate sellers.
- **Decision:** Seller-development, SLA-improvement, retention, diversification or monitoring priorities.

### A06 — Customer-experience driver analysis

- **Question:** Which observable operational factors are most strongly associated with poor review outcomes?
- **Method:** Start with review coverage and descriptive comparisons across lateness/severity bands, handling time, carrier time, freight burden and order complexity. Adjust comparisons through segmentation where feasible; do not claim causality.
- **Insight created:** Shows where low reviews are overrepresented and whether the association is consistent with a plausible operational mechanism.
- **Decision:** Which experience-protection hypotheses warrant operational testing or richer data.

## Prioritization method

The default decision method is a combination of:

1. **Minimum-volume and confidence screening** to prevent tiny segments from being ranked as facts.
2. **Pareto analysis** to show where most marketplace value, growth contribution or operational exposure is concentrated.
3. **Rule-based quadrants** to keep scale/growth and operational health visible and interpretable.
4. **Impact × Actionability × Confidence** as the final management rubric, with each dimension shown separately.

Percentiles may normalize peer comparisons after distributions are inspected. A weighted composite score is deferred unless stakeholders can justify the weights and sensitivity testing shows that reasonable alternatives do not reverse the priorities.

Provisional action postures are:

- **Grow:** attractive demand and execution, sufficient volume/confidence, and a plausible lever to add scalable supply or demand.
- **Defend:** material marketplace contribution and sound execution where protecting reliability matters more than stimulating demand.
- **Fix before growth:** material/attractive segment with operational weakness that could make more demand risky.
- **Investigate:** plausible mismatch, mechanism or emerging opportunity with insufficient evidence for action.
- **Deprioritize:** low commercial relevance and weak conditions after adequate observation—not merely a small sample.

Final thresholds are deliberately unresolved until Stage 5B profiles the actual distributions.

## Required “So What?” chain

Every candidate headline must complete this chain:

| Step | Required question |
|---|---|
| Observation | What happened, at what grain and magnitude? |
| Diagnosis | What observable mechanism is consistent with it, and what alternatives remain? |
| Business implication | Why does it matter for scalable marketplace growth or customer experience? |
| Decision | Which management choice could change because of the evidence? |
| Action | What could Olist plausibly do, who owns it, and what KPI/guardrail would be monitored? |
| Validation | What additional evidence, test or operational data is required before implementation? |

An analysis that cannot reach at least the business-implication step is not a headline analysis.

## Comparison, volume and uncertainty rules

- No rate is interpreted without a benchmark: marketplace, category, state, volume-matched seller peer, route peer, prior complete period, valid year-over-year period, or distribution percentile.
- Report numerator and denominator beside rates. Keep segment impact and estimate confidence in separate columns.
- Inspect count distributions before setting minimum volume. Label low-confidence results and keep them out of ranked recommendations.
- Use absolute contribution alongside percentage growth; new or tiny segments can have extreme growth rates without material impact.
- Use medians and upper percentiles alongside averages for skewed delivery-time measures.
- Treat observational comparisons as associations and record plausible confounders such as category mix, route distance, order complexity and incomplete periods.

## Analytical-grain contract

Every future material query must document:

| Field | Requirement |
|---|---|
| Left input | Table/view name, grain and key |
| Right input | Table/view name, grain and key |
| Relationship | Expected 1:1, 1:M, M:1 or M:M relationship |
| Output grain | What one result row represents after the join |
| Fanout risk | Which measures could be duplicated |
| Required pre-aggregation | How each child reaches the target grain before joining |
| Validation | Row-count/key check and independent measure reconciliation |

Payments, reviews, geolocation observations and item detail must never be joined together at raw child grain for headline metrics. Order-level children must first become one row per `order_id`; geolocation must first become one defensible record per ZIP prefix.

## Recommendation and executive-synthesis standards

Each recommendation must record evidence, affected segment, mechanism, expected KPI, owner, trigger, guardrail, major assumption, risk, confidence, and additional information required. Allowed portfolio language includes “identified,” “estimated,” “prioritized,” “associated with,” “consistent with,” and “recommended.”

Stage 5G will present no more than five headline insights using:

> Situation → complication → insight → recommendation → evidence → risk → next action

The final synthesis must answer: **What should Olist do, where should it do it, why, and what evidence supports that conclusion?**

## Stage 5A completion gate

Stage 5A is complete only when the primary decision, stakeholder decisions, MECE issue tree, analysis tiers, integrated business cases, hypothesis register, measurement decisions and unresolved items, workplan, grain contract, and “So What?” standard are documented. Analytics objects and headline queries begin only after this design gate passes.
