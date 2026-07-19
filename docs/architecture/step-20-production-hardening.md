# Step 20 — Production Hardening and Launch Readiness

Step 20 converts the repository from a feature-complete demonstration foundation into a deployable system with explicit operational controls.

## Controls added

- Liveness and readiness HTTP endpoints.
- Required environment-variable contract with public/server separation.
- Release gates that block production activation on unresolved security, recovery, queue, or consent controls.
- Backup policies, recovery-test evidence, deployment history, rollback references, and incident records.
- Independent demo-mode switch and production feature flags.
- Release workflow with type, unit, build, and high-severity dependency checks.
- Production environment contract executed only in the protected production environment.

## Health endpoints

- `/api/health/live` confirms the web process is alive.
- `/api/health/ready` returns HTTP 200 only when required environment variables are configured; otherwise HTTP 503.

## Production activation rule

A deployment is not operationally approved merely because the build succeeds. Production activation requires all blocking release gates, required environment checks, and tested recovery controls to pass.
