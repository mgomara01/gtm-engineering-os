# Production Release Runbook

1. Freeze the release commit and create a version tag.
2. Run `npm ci` and `npm run verify:release` from a clean checkout.
3. Confirm `npm audit --audit-level=high` passes.
4. Apply migrations to staging and execute browser smoke tests.
5. Review `/admin/launch`; no blocking gate may fail.
6. Validate production secrets through the protected release workflow.
7. Back up the production database and record the restore point.
8. Deploy the immutable build artifact.
9. Verify `/api/health/live` and `/api/health/ready`.
10. Run workspace isolation, login, import-preview, scoring, and approval smoke tests.
11. Keep outbound, agent-write, and production-import switches disabled until their individual gates are approved.
12. Record deployment SHA, version, readiness snapshot, and rollback target.
