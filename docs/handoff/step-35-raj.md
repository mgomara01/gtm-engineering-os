# Raj Deployment Handoff — Step 35

1. Apply `supabase/migrations/0035_platform_administration.sql` after migration 0034.
2. Implement workspace and platform-admin RLS policies before production use.
3. Store all support-access approvals in the audit event stream and enforce automatic expiration server-side.
4. Integrate environment configuration hashes with CI/CD deployment metadata.
5. Connect tenant lifecycle transitions to provisioning, billing, data export, and offboarding workflows.
6. Add alert routing for critical tenant health signals and production promotion blocks.
7. Validate `/admin/platform-administration`, `/tenants`, and `/environments` under platform-admin permissions.
