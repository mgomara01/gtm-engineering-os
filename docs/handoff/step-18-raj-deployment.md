# Step 18 Deployment Handoff

1. Apply migration `0018_integrations_sync.sql` after Step 17.
2. Configure a production secret manager and persist only secret references in `integrations.connections`.
3. Deploy queue-backed workers for ServiceTitan, accounting, Microsoft Graph, and webhook processing.
4. Enforce idempotency, transactional cursor advancement, bounded retries, and dead-letter queues.
5. Register webhook endpoints behind TLS and validate signatures before persisting payloads.
6. Configure monitoring for freshness, failed jobs, rejected records, reconciliation exceptions, and queue depth.
7. Test RLS with users from two workspaces before enabling any production connector.
8. Do not enable outbound email/SMS until consent, suppression, rate-limit, and approval controls are tested.
9. Reconcile connector counts to source-system control totals before declaring a connector production-ready.
