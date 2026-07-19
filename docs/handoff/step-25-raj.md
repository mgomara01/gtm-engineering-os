# Step 25 Raj Handoff

1. Apply migration `0025_commercial_operations.sql` in staging.
2. Connect a PCI-compliant billing provider; do not store card data in Supabase.
3. Implement signed billing webhooks with idempotency and replay protection.
4. Aggregate usage from append-only events on a scheduled worker.
5. Enforce entitlements at server-action and worker-dispatch boundaries.
6. Configure SLA calendars, escalation routing, tax treatment, invoice numbering, and revenue-recognition policy.
7. Reconcile subscription, invoice, payment, and general-ledger totals before activation.
