# Step 22 Deployment Handoff

1. Apply migration `0022_rollout_stabilization.sql` after Step 21 migrations.
2. Create the first cohort and assign named users, owners, scope, target date, and account population.
3. Load immutable source control totals before migration; reconcile target totals and disposition every exception.
4. Configure required training by role and prohibit production execution until blocking modules are passed or formally waived.
5. Run shadow mode, then limited mode; monitor adoption, queue health, consent enforcement, and reconciliation daily.
6. Operate a defined hypercare window with severity SLAs, named owners, root-cause records, and daily review.
7. Graduate only after every blocking stabilization gate has approved evidence. Preserve the graduation decision in the audit log.
