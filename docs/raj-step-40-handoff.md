# Raj Deployment Handoff — Step 40

## Deployment order

1. Apply `supabase/migrations/0040_ga_readiness.sql` after migration 0039.
2. Confirm workspace RLS policies are extended using the platform's standard workspace policy template.
3. Seed certification, migration, acceptance, residual-risk, and launch-gate records for the release candidate.
4. Verify `/admin/ga-readiness`, `/admin/ga-readiness/certification`, and `/admin/ga-readiness/launch`.
5. Require release-management approval before changing the release from conditional to GA certified.

## Production acceptance

- All mandatory certifications passed or explicitly waived.
- Migration dry run, rollback, and reconciliation complete.
- No open critical or high residual risks.
- All six functional acceptances recorded.
- All required launch gates ready.
