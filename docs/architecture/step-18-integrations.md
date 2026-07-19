# Step 18 — Integration Control Plane

Step 18 adds governed external-system connectivity without moving business logic into connectors.

## Core design

Connection metadata is workspace-owned. Credentials are never stored in application tables; only an external secret-manager reference is persisted. Every sync receives an idempotency key, immutable request/result snapshots, record counts, cursor state, and per-record outcomes.

## Runtime sequence

1. Scheduler, webhook, or operator creates a sync job.
2. Worker obtains credentials from the approved secret manager.
3. Connector reads from the external source using the stored cursor.
4. Source records are normalized and passed to existing ingestion/entity-resolution services.
5. The worker writes per-record results and advances the cursor only after a successful transaction.
6. Reconciliation checks compare external and internal state.
7. Exceptions enter the reconciliation queue; connectors never silently overwrite verified data.

## Controls

- Workspace RLS on all integration records.
- Idempotency keys prevent duplicate sync execution.
- Webhook provider event IDs and replay keys prevent duplicate delivery processing.
- Signed webhook payloads are mandatory where the provider supports signatures.
- Cursor advancement is transactional.
- Failed and partial jobs retain diagnostic snapshots.
- Retries use bounded exponential backoff and dead-letter handling.
- Outbound communication requires consent and suppression checks outside the connector itself.

## Production boundary

The included pages and schema are operational contracts. Production workers should run in Trigger.dev or a dedicated queue. n8n may coordinate external events, but canonical mapping, entity resolution, approval, and persistence remain application services.
