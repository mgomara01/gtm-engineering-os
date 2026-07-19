# Raj Deployment Handoff — Step 32

1. Apply `0032_workflow_automation.sql` after migration 0031.
2. Configure a durable workflow worker and scheduler; do not execute long-running workflows in web request handlers.
3. Use a transactional outbox for event-triggered starts and external side effects.
4. Encrypt workflow inputs containing confidential or restricted fields.
5. Bind all queries and RLS policies to the authenticated workspace.
6. Enforce idempotency before performing external actions.
7. Persist step checkpoints before acknowledgement to the queue.
8. Connect approval notifications to the existing support/notification channels.
9. Route exhausted retries and terminal failures into Step 27 incident operations.
10. Load-test concurrency limits, schedule bursts, cancellation, replay, and recovery before production activation.
