# Step 15 Deployment Notes

1. Apply migration `0015_operational_execution.sql` after Step 14.
2. Validate `platform.is_workspace_member` exists before enabling policies.
3. Implement server actions for task completion, reassignment, opportunity stage changes and approval decisions.
4. Require idempotency keys for workflow-generated tasks.
5. Write governance audit events for every approval and stage transition.
6. Connect notifications only after consent, assignment and escalation rules are approved.
