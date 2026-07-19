# Raj Deployment Checklist — Step 8

## Infrastructure

- Create distinct staging and production Supabase projects.
- Create distinct Vercel projects or environment scopes.
- Configure environment labels and deployment protection.
- Confirm DNS and TLS before production launch.

## Database

- Apply migrations `0001` through `0008` in order.
- Apply seed data only to staging initially.
- Verify the `platform`, `configuration`, and `implementation` schemas are exposed to the authenticated API role as intended.
- Test row-level security with two users assigned to different workspaces.
- Confirm the configuration activation function rejects unapproved versions.

## Authentication

- Configure permitted redirect URLs for staging and production.
- Enforce multifactor authentication for administrators when enabled.
- Disable open public registration unless explicitly approved.
- Create named accounts; do not use shared credentials.

## Application

- Set `NEXT_PUBLIC_APP_ENV` separately in each environment.
- Set Supabase URL and anonymous key.
- Keep service-role keys server-side only.
- Run typecheck, tests, and production build before release.

## Operational acceptance

- Login redirects correctly.
- Unauthorized users cannot query another workspace.
- Workspace selector changes context without exposing other workspace records.
- Alvarez and Intelligent Waterflow retain separate implementation state.
- Active configuration points to an approved version.
- Audit and backup procedures are documented before real data is loaded.
