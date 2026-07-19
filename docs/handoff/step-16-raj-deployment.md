# Step 16 Raj Deployment Handoff

1. Apply migration `0016_management_analytics.sql` after Step 15.
2. Confirm the `analytics` schema is exposed only through approved server actions or read views.
3. Run RLS tests using at least two workspaces and three roles.
4. Configure scheduled calculation workers with immutable calculation-run IDs and idempotency keys.
5. Store calculation evidence and source timestamps; do not publish partial results as complete.
6. Require approval before activating or changing KPI targets and calculation definitions.
7. Connect revenue attribution only after opportunity and accounting identifiers are reconciled.
8. Enable operating-review export only from approved immutable snapshots.
9. Add monitoring for failed or stale calculation runs and unresolved critical alerts.
10. Replace all demonstration Step 16 records before production acceptance.
