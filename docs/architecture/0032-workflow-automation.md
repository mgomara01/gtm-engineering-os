# Step 32 — Workflow Automation and Orchestration

## Decision
Add a governed workflow control plane that composes event triggers, schedules, conditions, integrations, autonomous agents, approval gates, delays, and outbound actions into versioned business processes.

## Runtime guarantees
- Immutable published workflow versions are attached to each run.
- Workspace-scoped idempotency keys prevent duplicate side effects.
- Every run receives a trace ID and retains step-level state, retries, cost, and outcome.
- High-risk actions require an explicit approval step before activation.
- Runtime, cost, retry, and concurrency ceilings are enforced per workflow.
- Failed runs are resumable only from explicitly safe checkpoints.
- Schedule misfires follow declared skip, run-once, or catch-up policy.

## Integration boundaries
Step 32 orchestrates rather than duplicates the capabilities delivered in Steps 17, 18, 26, 27, and 31. Agent execution remains governed by AI Operations; outbound integrations remain governed by the Developer Platform; incidents and failed automation escalation remain governed by Reliability Operations.
