# Step 14 Deployment Handoff

1. Apply migration `0014_offers_playbooks_campaigns.sql` after Step 13.
2. Confirm the workspace-access helper referenced by RLS exists in the deployed database.
3. Add permission grants for offer, playbook, campaign, approval, and reporting roles.
4. Implement transactional server actions before enabling UI write controls.
5. Configure background execution for due sequence steps and idempotency keys for all external sends.
6. Never allow browser clients to send email/SMS or directly advance campaign state.
7. Validate campaign enrollment snapshots, pause/resume behavior, task generation, and performance attribution in staging.
8. Connect communication providers only after consent, opt-out, suppression, and audit requirements are defined.
