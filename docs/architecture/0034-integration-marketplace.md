# ADR 0034 — Integration Marketplace and Connector Operations

## Decision
Provide a governed connector control plane that separates immutable connector definitions from workspace-scoped installations, credential references, mappings, sync jobs, and alerts.

## Controls
- Credentials are stored in the approved secrets vault; the database stores references only.
- Each installation is isolated by workspace and environment.
- Connector scopes are explicit and reviewed under least privilege.
- Sync jobs use durable cursors, idempotent writes, bounded retries, and dead-letter handling.
- Schema changes invalidate affected mappings and create actionable alerts.
- Marketplace certification requires security review, test coverage, ownership, and versioned release notes.

## Operational model
Health checks evaluate authorization, provider reachability, quota availability, latency, and schema compatibility. Operations staff can identify degraded installations, expiring credentials, partial syncs, and failed records from a unified console.
