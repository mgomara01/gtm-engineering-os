# Step 21 — Production Activation

Step 21 closes the gap between a production-ready application and controlled live execution. It introduces queue-backed workers, bounded retries, dead-letter isolation, channel-specific consent, suppressions, and staged activation.

## Activation modes

- `inactive`: no live work is dispatched.
- `shadow`: workers process non-destructive work and compare outcomes without external effects.
- `limited`: approved providers and audiences operate under volume caps.
- `active`: normal governed operation.
- `paused`: emergency stop preserving queue state and audit evidence.

## Dispatch policy

Every outbound job must pass workspace access, idempotency, consent, suppression, provider-health, budget, and approval checks before dispatch. Consent is channel-specific. A global suppression overrides consent. Policy failures are terminal and cannot be replayed from the dead-letter queue.

## Worker guarantees

Workers use transactional job claims, heartbeats, bounded exponential retries, idempotency keys, immutable failure snapshots, and dead-letter queues. Cursor or operational state advances only after canonical persistence succeeds.

## Go-live sequence

Activate in shadow mode, validate queue and reconciliation metrics, move to limited mode with volume caps, verify provider and compliance evidence, then approve active mode. Every transition is recorded in `activation.activation_events`.
