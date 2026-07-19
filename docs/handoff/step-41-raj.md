# Raj Handoff — Step 41 / Version 1.0

## Objective

Deploy the Version 1.0 release and preserve a complete certification record. Step 41 is the final release-closure layer, not a simulated readiness dashboard.

## Deployment sequence

1. Apply Supabase migrations through `0041_launch_certification.sql` in a controlled pre-production rehearsal.
2. Run `npm run typecheck`, `npm test`, and `npm run build` against the exact release commit.
3. Promote the blue-green production target and retain the prior target for rollback.
4. Execute all required post-launch checks: application health, error rate, P95 latency, migration reconciliation, and authentication smoke test.
5. Record release-manager, technical-authority, and executive authorization.
6. Verify checksums for source, migrations, runbook, release notes, and certification evidence.
7. Declare Version 1.0 generally available only when the certification engine returns 100% and `canDeclareGA` is true.

## Rollback trigger

Rollback immediately for a failed critical health check, unreconciled migration exception, authentication failure, or sustained breach of the release latency/error thresholds.
