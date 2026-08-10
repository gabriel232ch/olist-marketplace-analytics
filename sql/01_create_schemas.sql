-- Stage 2B setup script; executed on 2026-08-07 against olist_portfolio.
-- Creates schemas only; no source data is loaded.

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS analytics;
