# Step 19 Deployment Handoff

1. Apply migration `0019_governance_controls.sql` after Step 18.
2. Confirm `platform.is_workspace_member(uuid)` exists before applying RLS policies.
3. Add database tests proving audit UPDATE and DELETE operations fail.
4. Build privileged server actions for access certification, change approval, legal holds, and release gates.
5. Require MFA for security administrators, agent publishers, integration administrators, and production approvers.
6. Route disposition jobs through a queue; snapshot eligible IDs, test holds, execute in bounded batches, and persist evidence.
7. Export audit events to the approved security log destination with correlation IDs preserved.
8. Do not activate production outbound campaigns until the blocking consent-enforcement gate passes.
