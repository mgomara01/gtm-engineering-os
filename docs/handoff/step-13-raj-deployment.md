# Raj Deployment Notes — Step 13

1. Apply migration `0013_scoring_engine.sql` after Step 12.
2. Confirm all scoring tables have RLS enabled and workspace policies resolve correctly.
3. Implement score execution as a server-side transaction or durable job; never calculate authoritative production scores only in the browser.
4. Persist input snapshots and hashes so identical inputs can be reproduced.
5. Require approval before activating a model version.
6. Run a shadow simulation against known Alvarez accounts before replacing existing priority logic.
7. Add integration tests for hard exclusions, 100% weight enforcement, historical version retention, and cross-workspace denial.
