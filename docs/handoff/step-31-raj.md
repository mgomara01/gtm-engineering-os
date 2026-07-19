# Raj Deployment Handoff — Step 31

1. Apply `supabase/migrations/0031_ai_operations.sql` after migration 0030.
2. Add workspace-scoped RLS policies using the existing membership helper functions before production writes are enabled.
3. Configure approved model-provider credentials only in the server secret store; never persist raw provider secrets in these tables.
4. Connect the Step 17 execution runtime to `ai_agent_runs` and generate one trace ID per attempted execution.
5. Enforce guardrail checks before tool invocation and again before externally visible output or action.
6. Route `require_approval` decisions to `ai_human_reviews`; suspend execution until approved or rejected.
7. Emit cost and token telemetry from the provider response, and reject runs that exceed the configured ceiling.
8. Retain only input/output digests by default. Store full payloads only under an approved evidence-retention policy.
9. Alert on overdue human reviews, failed runs, blocked runs, anomalous cost, and expired agent evaluations.
10. Validate tenant isolation, model fallback, replay resistance, approval race conditions, and kill-switch behavior in staging.
