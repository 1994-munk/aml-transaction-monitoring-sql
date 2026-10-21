# AML Transaction Monitoring & SQL Audit Engine

An advanced relational database project designed to flag suspicious financial activities and enforce data integrity compliance rules.

## Features
- **Structuring (Smurfing) Detection:** Uses conditional window aggregations to isolate accounts splitting large transfers just below reporting thresholds.
- **Velocity & Layering Checks:** Implements time-delta window functions (`LAG`/`LEAD`) to track rapid fund movements in and out of accounts within tight timeframes.
- **Risk Scoring & Outlier Analysis:** Calculates rolling standard deviations to identify behavioral anomalies.
- **Performance Optimized:** Includes custom indexes and query execution plans optimized for multi-million row datasets.

## Database Schema
- `accounts`: User profile and risk tier metadata.
- `transactions`: Core ledger storing timestamps, amounts, currencies, and routing channels.
- `audit_logs`: System and pipeline validation checks.
