# Raj Handoff — Step 21

1. Apply migration `0021_production_activation.sql` in staging.
2. Deploy queue workers separately from the web application and configure heartbeat alerts.
3. Store provider credentials in the approved secret manager; persist only secret references.
4. Configure dead-letter retention, alert thresholds, and replay permissions.
5. Import consent evidence and active suppressions before enabling outbound providers.
6. Run shadow mode for at least one complete sync and campaign cycle.
7. Conduct a production-like database and storage restore; attach evidence to the recovery-test record.
8. Approve limited mode with documented volume caps and rollback owner.
9. Move to active only after compliance, infrastructure, and business owners sign the activation event.
