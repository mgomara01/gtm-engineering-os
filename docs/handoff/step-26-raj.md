# Step 26 Raj Handoff

1. Apply `0026_developer_platform.sql` in staging.
2. Implement server-side credential issuance using a cryptographically secure random value; store only an approved password hash plus a non-secret prefix.
3. Add API middleware in this order: request ID, authentication, workspace resolution, status/expiration, scope, entitlement, rate limit, validation, idempotency, handler, audit log.
4. Store production credentials and webhook signing secrets in the approved secret manager, never browser state or ordinary database columns.
5. Add Redis or an equivalent atomic counter store before enforcing distributed rate limits.
6. Deliver webhooks from a durable queue with replay controls, bounded retries, dead-letter review, and endpoint circuit breaking.
7. Define the initial public event and API schema catalog and publish deprecation policy before enabling third-party clients.
8. Run penetration tests covering key leakage, replay, cross-workspace access, scope escalation, quota bypass, SSRF, and webhook signature validation.
