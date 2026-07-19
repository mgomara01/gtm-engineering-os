# Step 30 deployment handoff

## Database

Apply `0030_compliance_audit.sql` after migration 0029. Confirm the `compliance` schema and row-level security policies exist for every new table.

## Production integration

- Replace demonstration compliance data with Supabase queries scoped by active workspace.
- Store evidence in a private bucket with signed, short-lived access URLs.
- Connect control IDs to the Step 28 control catalog rather than accepting arbitrary identifiers.
- Add immutable audit events for approvals, evidence acceptance/rejection, attestations, and exception decisions.
- Restrict audit and exception approval actions to assurance, legal, security, and designated executive roles.
- Add scheduled notifications for policy review, evidence due dates, attestation periods, and exception expiry.

## Acceptance tests

- Cross-workspace reads and writes are denied.
- Expired exceptions cannot remain silently approved.
- Evidence cannot be marked accepted by its submitting owner without an authorized reviewer.
- Policy approval creates a versioned, immutable approval event.
- Compliance readiness remains bounded between zero and 100.
