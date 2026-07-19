# Raj Deployment Handoff — Step 37

## Objective

Deploy the quality engineering control plane and connect it to CI, staging certification, defect intake, release approval, and UAT operations.

## Database

Apply `supabase/migrations/0037_quality_engineering.sql` after migration 0036. Confirm RLS policies use the existing `is_workspace_member` function and verify all five tables reject cross-workspace access.

## Integration work

1. Feed Vitest, Playwright, API contract, security, and performance results into `quality_suites` after every governed run.
2. Create or update environment certification after deployment validation, storing the actual version and configuration fingerprint.
3. Synchronize blocking defects from the selected issue tracker or make this module the system of record.
4. Require business-area UAT sign-off before setting `uat_approved` on the release candidate.
5. Populate security and performance approvals from Steps 28 and 36.
6. Validate rollback in staging and record evidence before setting `rollback_validated`.
7. Prevent production deployment unless `releaseGateFailures` returns no failures.

## Acceptance tests

- Cross-workspace records are inaccessible.
- Failed required suites block approval.
- An unresolved high-severity defect blocks approval.
- Missing UAT or rollback validation blocks approval.
- A fully approved candidate can transition from `candidate` to `approved` and then `released`.
- All state transitions create governance audit events.
