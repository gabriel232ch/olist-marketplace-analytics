# Project charter

## Working title

Olist E-commerce Growth & Fulfillment Optimization

## Portfolio positioning

Primary roles:

- Business Analyst
- Sales Operations
- Business Operations
- Market Analyst

Core story:

> Use multi-table SQL to diagnose commercial performance and fulfillment risk, quantify where intervention matters most, and translate findings into an operating plan.

## Primary decision

Where should Olist allocate commercial and operational resources to generate scalable marketplace growth while protecting fulfillment reliability and customer experience?

The category × customer-state × seller combination remains the central allocation grain. The objective is quality-adjusted marketplace growth, using delivered item GMV and other observable measures as proxies—not profit optimization.

## Supporting questions

1. Where is marketplace value and growth coming from, and how much is explained by order volume versus AOV/product mix?
2. Where do attractive customer demand and sufficient, diversified seller supply coincide?
3. Which commercially important segments are constrained by seller handling, carrier time, late delivery, freight burden, cancellation or weak reviews?
4. Which sellers, categories, geographies and routes should Olist Grow, Defend, Fix, Investigate or Deprioritize?
5. Is observed repeat behavior sufficiently frequent and comparably observed to support a customer strategy, or should it remain secondary?

## Intended stakeholders

- Marketplace operations lead
- Seller management lead
- Logistics operations lead
- Customer growth/CRM lead

## Candidate decisions

- Which sellers enter an SLA improvement program?
- Which category-state lanes require logistics or expectation-setting changes?
- Whether the available customer history is sufficient to support a retention treatment recommendation.
- Which performance indicators require a recurring operating dashboard?

## Analysis units

- Order
- Order item
- Customer
- Seller
- Product/category
- State
- Calendar month

Every output must explicitly state its grain.

## Success criteria

- Reproducible PostgreSQL setup and analysis.
- Verified metric definitions and data-quality tests.
- At least three findings that survive robustness checks.
- Transparent opportunity sizing with stated assumptions.
- Recommendations with target, owner, action, KPI, guardrail, and validation method.
- Recruiter-readable README and dashboard.
- Resume numbers traceable to saved queries.

## Out of scope

- Audited revenue or profit analysis.
- Causal proof without experiments or quasi-experimental evidence.
- Production deployment.
- Machine-learning prediction during the core project.
- Claims that recommendations were implemented.

## Initial hypotheses

These are questions to test, not conclusions:

- Late delivery is associated with lower review scores.
- Delivery risk is concentrated in a limited set of seller-category-state combinations.
- Seller handling time and carrier time contribute differently across regions.
- Commercially important segments are not necessarily those with the highest raw delay rate.
- Customer repeat behavior varies by first-order experience and product mix.
