# Step 33 — Executive Intelligence, Reporting, and Forecasting

Step 33 establishes a governed management-intelligence layer over the operational system. It does not replace source modules; it certifies, aggregates, and contextualizes their outputs for executive decisions.

## Core controls
- Every KPI has a source, owner, target, as-of timestamp, and certification status.
- Forecast scenarios preserve assumptions, confidence, horizon, and model version.
- Reports are versioned definitions with cadence, audience, delivery, and publication history.
- Decision briefs link recommendations to governed metrics and retain decision status.
- Workspace RLS prevents cross-tenant exposure.

## Operating model
Source modules publish certified metric snapshots. The reporting layer assembles snapshots into recurring packs. Forecast scenarios consume immutable snapshots plus explicit assumptions. Decision briefs reference both and create an auditable path from evidence to action.
