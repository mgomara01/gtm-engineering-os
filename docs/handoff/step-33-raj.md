# Step 33 deployment handoff

1. Apply `0033_executive_intelligence.sql` after migration 0032.
2. Confirm `workspace_members` and RLS helper behavior in the target Supabase project.
3. Register metric publishers from Commercial, Workflow, Security, Compliance, and AI Operations.
4. Configure the weekly operating brief schedule and board-report delivery channels.
5. Validate timezone behavior in America/New_York.
6. Run unit tests, typecheck, and production build before release.
7. Seed no production metrics from demo fixtures; connect certified source queries first.
