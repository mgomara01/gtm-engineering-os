# Raj Deployment Handoff — Step 29

1. Apply `0029_enterprise_resilience.sql` after Step 28.
2. Confirm `platform.has_workspace_access(uuid)` exists before applying policies.
3. Seed recovery plans only after service owners approve RTO and RPO values.
4. Connect backup telemetry from the production database and object-storage providers.
5. Require evidence links for restore tests and continuity exercises.
6. Import the active vendor register, contracts, SOC reports, DPAs, and breach-notification terms.
7. Configure alerts for overdue Tier 0/1 plan reviews, failed restore tests, overdue critical-vendor assessments, and high-risk findings.
8. Verify workspace isolation with users assigned to different workspaces.
9. Do not represent demo resilience metrics as production assurance.
