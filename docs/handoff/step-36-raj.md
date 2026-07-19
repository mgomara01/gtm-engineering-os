# Raj Deployment Handoff — Step 36

1. Apply `supabase/migrations/0036_performance_engineering.sql` after migration 0035.
2. Populate service baselines from production APM and infrastructure metrics.
3. Connect CI to create load-test records and fail promotion on blocking test failures.
4. Schedule daily capacity-forecast refreshes and alert when headroom drops below 20%.
5. Integrate browser performance telemetry for LCP, INP, CLS, bundle size, and server latency.
6. Restrict scaling-policy and blocking-budget updates to platform administrators.
7. Validate RLS using two separate workspaces before production activation.
