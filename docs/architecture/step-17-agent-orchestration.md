# Step 17 — Agent Orchestration and Governance

Step 17 introduces the control plane for AI agents. Agent definitions are workspace-owned, prompts and schemas are immutable versions, and each run records the exact version, inputs, outputs, evidence, cost, latency, confidence, and review requirement.

## Release controls

A prompt or model change is published only as a new approved version. Production activation should require evaluation thresholds, policy-compliance thresholds, an authorized approver, and an immutable audit event. High-risk agents always require human approval before operational writes.

## Cost and reliability

Budget events support reservation, actual-cost posting, release, and adjustment. Run monitoring separates model failure from provider failure and business-rule rejection. Production workers should enforce per-run limits, monthly workspace and agent budgets, retries with exponential backoff, idempotency keys, circuit breakers, and dead-letter handling.
