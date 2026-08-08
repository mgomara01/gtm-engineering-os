-- Step 46: first-pass GTM scoring for ingestion.external_signals. Computed
-- at write time (see upsertExternalSignals in external-signals.ts) from
-- source-specific business rules -- see apps/web/lib/signal-scoring.ts for
-- the rationale. Entity resolution (linking a signal to a specific account
-- or opportunity) remains a separate, later pass -- this is priority
-- triage over the raw feed, not a finished lead.
alter table ingestion.external_signals add column if not exists opportunity_score numeric(5,2);
alter table ingestion.external_signals add column if not exists priority_tier text;
create index if not exists idx_external_signals_score on ingestion.external_signals(workspace_id,opportunity_score desc);
