# Step 27 Raj Handoff

1. Apply `0027_reliability_operations.sql` after Step 26.
2. Register every production service with a named owner, tier, dependency map, and tested runbook.
3. Connect SLO measurements to the approved metrics source; do not calculate production reliability from browser demonstration data.
4. Configure multi-window burn-rate alerts for Tier 0 and Tier 1 services and route alerts to the on-call schedule.
5. Establish SEV1–SEV4 response targets, incident commander rotation, executive escalation, and customer communication templates.
6. Require post-incident reviews for SEV1/SEV2 and recurring SEV3 incidents; track corrective actions to closure.
7. Evaluate production feature flags in a trusted server-side boundary with immutable audit events for every change.
8. Enforce expiration dates, kill switches, progressive rollout, and automatic rollback triggers for high-risk releases.
9. Integrate maintenance windows with change control and prohibit overlapping work on the same critical service without explicit approval.
