# Step 23 Deployment Handoff

1. Apply migration `0023_enterprise_intelligence.sql` after Step 22.
2. Configure scheduled forecast and trend-analysis workers through the existing queue framework.
3. Store model artifacts and large source snapshots in governed object storage; retain hashes in PostgreSQL.
4. Require minimum sample sizes, backtesting, confidence calibration, and owner approval before publishing forecasts.
5. Route all accepted recommendations through change control. Do not allow direct model writes to production configuration.
6. Reconcile forecast actuals to approved CRM/accounting definitions before reporting accuracy.
7. Schedule weekly brief generation in draft state; executives approve immutable snapshots.
