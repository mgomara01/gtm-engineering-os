# Raj Deployment — Step 12

1. Apply `0012_enrichment_research.sql` after the Step 11 migration.
2. Confirm the authenticated database role can access the `intelligence` schema.
3. Add provider credentials to the deployment secret manager; store only credential references in the database.
4. Configure per-provider rate limits, timeout, maximum cost, and permitted fields.
5. Implement research execution as background jobs with idempotency keys.
6. Implement acceptance as an atomic server transaction: validate reviewer permission, lock current record, record lineage, update the accepted field, close the finding, and append an audit event.
7. Prevent prompt or provider logs from retaining secrets or restricted personal data.
8. Test RLS with users belonging to Alvarez only, Intelligent Waterflow only, both workspaces, and neither workspace.
9. Set alerts for failed jobs, provider cost thresholds, low acceptance rates, and evidence with expired source access.
