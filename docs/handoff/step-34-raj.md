# Step 34 deployment handoff — Raj

1. Apply `0034_integration_marketplace.sql` after Step 33 migrations.
2. Attach the platform's standard workspace membership RLS policies to all workspace-scoped connector tables.
3. Configure the secrets vault and ensure `credential_secret_ref` cannot contain raw secrets.
4. Provision sync workers with per-provider concurrency, timeout, backoff, quota, and dead-letter policies.
5. Configure OAuth callback URLs separately for sandbox and production.
6. Add scheduled health checks and credential-expiration notifications.
7. Validate connector scope grants, webhook verification, cursor recovery, idempotency, and schema-change handling.
8. Run `npm run typecheck`, `npm test`, and `npm run build` before promotion.
