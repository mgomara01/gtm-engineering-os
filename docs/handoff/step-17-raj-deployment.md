# Step 17 Deployment Handoff

1. Apply migration `0017_agent_orchestration.sql` after Step 16.
2. Configure provider secrets only in the deployment secret manager; never store raw credentials in PostgreSQL.
3. Create worker queues for agent runs, evaluations, retries, and review routing.
4. Enforce workspace membership and role checks in server actions in addition to RLS.
5. Configure budget ceilings and hard-stop behavior before enabling scheduled or bulk runs.
6. Test provider timeout, retry, duplicate-run, partial-output, and rollback scenarios.
7. Connect Sentry traces and PostHog operational events without logging confidential prompt payloads.
8. Keep all production write tools disabled until approval and audit transactions are tested.
