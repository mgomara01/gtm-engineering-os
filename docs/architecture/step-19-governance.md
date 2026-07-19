# Step 19 — Governance, Audit, Retention, and Release Readiness

Step 19 introduces the platform control plane for immutable audit evidence, periodic access certification, privilege exceptions, governed changes, retention/disposition, legal holds, and production release gates.

## Hard controls

- Audit events are append-only and protected by a database trigger.
- Every governed object remains workspace scoped and protected by RLS.
- High-risk changes require completed approvals and a rollback plan.
- Retention workers must evaluate legal holds before disposition.
- Blocking release gates prevent production activation.
- Demonstration screens are read-only; mutations require transactional server actions and audit emission.

## Audit chain

Actor → action → resource → correlation ID → before/after evidence → approval or exception → immutable event.
