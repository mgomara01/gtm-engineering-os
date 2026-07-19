# Step 24 Raj Handoff

1. Apply migration `0024_platform_extensibility.sql` after Step 23.
2. Implement provisioning as an idempotent server-side job; never provision from the browser.
3. Store exported package payloads in protected object storage and retain checksums in PostgreSQL.
4. Add integration tests proving RLS isolation before marking a workspace ready.
5. Require change-control approval for importing high-risk template differences.
6. Keep every newly provisioned workspace in inactive outbound mode until consent, suppression, credentials, and owner approvals are complete.
