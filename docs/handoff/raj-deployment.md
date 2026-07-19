# Raj Deployment Boundary

Raj owns production account setup, Supabase project creation, secrets, domain/DNS, Vercel linkage, ServiceTitan and QuickBooks credentials, backup verification, monitoring, and production deployment approval.

## Initial deployment sequence

1. Create separate Supabase projects for staging and production.
2. Apply migrations in numeric order.
3. Apply seed data in staging only, then validate before production.
4. Configure Vercel projects and environment variables.
5. Enable Supabase email authentication and MFA policy.
6. Validate row-level security with executive, administrator, and sales-user test accounts.
7. Configure Sentry and PostHog.
8. Run `npm ci`, `npm run typecheck`, `npm test`, and `npm run build`.
9. Deploy staging and execute smoke tests.
10. Approve production release after data-security review.
