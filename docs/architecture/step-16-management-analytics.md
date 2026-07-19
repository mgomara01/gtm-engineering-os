# Step 16 — Management Analytics and Operating Reviews

Step 16 adds the measurement and management layer across the GTM Engineering OS. It deliberately separates KPI definitions, immutable calculation runs, results, exceptions, attribution, and published operating-review snapshots.

## Core contracts

1. KPI definitions are workspace-owned and versioned.
2. Every result points to a calculation run and preserves source evidence.
3. Threshold exceptions create management alerts; alerts do not silently modify operational data.
4. Revenue attribution stores the model, weight, and supporting evidence.
5. Operating reviews are immutable snapshots after approval and publication.
6. Demonstration metrics are explicitly marked and cannot be represented as production results.

## Application routes

- `/analytics` — management scorecard and exceptions
- `/analytics/kpis` — KPI catalog and governance
- `/analytics/alerts` — management alert center
- `/operating-review` — executive operating review

## Production services still required

- Scheduled calculation runner with idempotency keys
- Approved KPI calculation DSL or server-side calculation registry
- Atomic alert acknowledgement and resolution actions
- Attribution reconciliation against CRM/accounting outcomes
- Review snapshot creation, approval, export, and retention
- Integration tests for RLS and cross-workspace isolation
