# Step 26 — Developer Platform and API Governance

Step 26 establishes a governed machine-access layer for the GTM Engineering OS. It introduces service accounts, one-time API credentials stored only as hashes, approved scopes, layered rate limits, request telemetry, idempotency records, signed webhooks, bounded retries, and a versioned `/api/v1` boundary.

## Security model

A valid API credential is only the first gate. Each request must also pass service-account status and expiration, workspace isolation, scope authorization, commercial entitlement, rate-limit policy, payload validation, and idempotency checks. Privileged scopes require explicit approval and must be recertified.

Secrets must never be stored in plaintext after issuance. Logs retain correlation and authorization outcomes but exclude credentials, authorization headers, personal data, and business payload bodies.

## Webhook contract

Outbound payloads are signed with HMAC-SHA256 over `timestamp.payload`. Receivers must reject stale timestamps and duplicate event identifiers. Delivery retries use bounded exponential backoff, terminate after the configured maximum, and move persistent failures to operator review rather than retrying indefinitely.

## API lifecycle

Breaking changes require a new major path. Additive changes may remain within `v1` when clients can safely ignore new fields. Deprecations require published dates, usage analysis, migration guidance, and a controlled sunset gate.
