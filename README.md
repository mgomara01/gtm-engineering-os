# GTM Engineering Operating System

A reusable, multi-workspace platform for designing, implementing, operating, and improving complete go-to-market systems. Alvarez Plumbing & Air Conditioning is the first configured workspace; Intelligent Waterflow is the second workspace shell.

## Step 8 executable scope

- Supabase email/password authentication with a safe local demo fallback
- Session refresh and protected-route proxy
- Database-backed workspace access view and browser workspace selector
- Role and permission tables
- Workspace-isolated row-level security policies
- Configuration-version activation control
- Functional 12-stage Implementation Manager
- Stage detail, requirements, readiness, decisions, and risk controls
- Local demonstration persistence for implementation progress
- Two isolated demonstration workspaces
- Controlled zero-state operational metrics until business data is imported
- Unit tests, production build, CI, and deployment documentation

## Start locally

```bash
cp .env.example .env.local
npm ci
npm run dev
```

Open `http://localhost:3000`.

When Supabase variables are blank, the login screen enters controlled demo mode. Demo implementation changes are stored only in the browser and are not production records.

## Configure Supabase

1. Create separate staging and production Supabase projects.
2. Apply migrations in numeric order from `supabase/migrations`.
3. Apply `supabase/seed/seed.sql` in staging.
4. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
5. Create users through Supabase Auth.
6. Insert matching `platform.user_profiles` records.
7. Assign users through `platform.user_workspace_roles`.
8. Confirm row-level security with accounts assigned to different workspaces.

## Validate

```bash
npm run typecheck
npm test
npm run build
```

## Security boundary

The application does not store provider secrets in browser-visible fields. Production credentials belong in the deployment secret store. Do not load real customer data into local development.

## Step 10 operational entity layer
The application now includes organization directories, account intelligence detail, property/contact relationships, source identifiers, and activity lineage. See `docs/architecture/step10-operational-entities.md`.

## Step 11 capability

The repository now includes entity normalization, deterministic and fuzzy organization matching, a duplicate-review queue, relationship classification, and the database structures required for reversible merges. Browser actions remain review-oriented until the production transactional merge service is enabled.

## Step 12 capabilities

- Enrichment-provider administration
- Research job queue and evidence review
- Confidence-controlled proposed field updates
- Signals center with recommended actions
- Versioned account briefs embedded in account intelligence
- Consolidated AI review inbox

See `docs/architecture/step12-enrichment-research.md` and `docs/handoff/raj-step12-deployment.md` before enabling production writes.

## Step 13 scoring engine

Step 13 adds versioned scoring models, weighted and AI-assisted factors, hard exclusions, simulation, production score-run storage, factor-level explanations, confidence, evidence references, and account priority tiers. See `docs/architecture/step-13-scoring-engine.md`.


## Step 14

Adds governed offers, versioned multichannel playbooks, campaigns, enrollment snapshots, execution controls, approvals, and playbook performance reporting. See `docs/architecture/step-14-offers-playbooks-campaigns.md`.

## Step 16 — Management Analytics

Step 16 adds governed KPI definitions and results, management alerts, attribution records, executive scorecards, and immutable operating-review snapshots. See `docs/architecture/step-16-management-analytics.md` and `docs/handoff/step-16-raj-deployment.md`.


## Step 19
Governance control plane: immutable audit events, access certification, change control, retention/legal holds, and release-readiness gates.


## Step 21
Production activation controls are documented in `docs/architecture/step-21-production-activation.md`.


## Step 24
Enterprise intelligence, forecasting, optimization recommendations, executive briefs, benchmarking, and closed-loop outcome measurement.


## Step 24 — Platform Extensibility

Adds reusable workspace templates, configuration package portability, tenant provisioning, compatibility validation, and activation safeguards.

## Step 26 — Developer Platform

Adds governed API clients, scoped service accounts, quotas, request telemetry, signed webhooks, idempotency controls, and a versioned API boundary. See `docs/architecture/step-26-developer-platform.md`.

## Step 27 — Reliability Operations

Adds a governed service catalog, SLOs and error budgets, incident command, feature flags, maintenance windows, and operational reliability controls. See `docs/architecture/step-27-reliability-operations.md`.

## Step 28 — Security Operations and Privacy

Adds control assurance, risk-ranked security findings, data classification, privacy-request operations, and security event triage. See `docs/architecture/step-28-security-privacy.md`.


## Step 29 — Enterprise Resilience

Adds recovery planning, RTO/RPO governance, backup and restore assurance, continuity exercises, resilience findings, and third-party risk management. See `docs/architecture/step-29-enterprise-resilience.md`.

## Step 30 — Compliance, Audit, and Policy Management

Adds policy lifecycle governance, regulatory obligations, evidence requests, control attestations, audit engagements, compliance exceptions, and executive readiness reporting. See `docs/architecture/step-30-compliance-audit.md`.


## Step 31 — AI Operations

Adds governed autonomous-agent operations, model inventory, guardrails, human approvals, traceability, and cost controls.

## Step 32 — Workflow Automation and Orchestration

Adds versioned workflow definitions, event and schedule triggers, governed agent/action steps, human approvals, idempotent execution, retries, concurrency limits, execution traces, and operational run controls.


## Step 33 — Executive Intelligence
Adds governed KPIs, forecast scenarios, recurring executive reports, decision briefs, and data-trust scoring.


## Step 34 — Integration Marketplace and Connector Operations

Adds a governed connector catalog, tenant installations, credential lifecycle, field mapping, synchronization health, retry telemetry, and connector operations dashboards.

## Step 35 — Platform Administration

Version 0.36.0 adds tenant lifecycle operations, environment promotion controls, entitlement governance, tenant health signals, configuration approvals, and time-bound support access.

## Step 36 — Performance Engineering and Scalability

Adds workload baselines, latency and frontend budgets, load-test release gates, capacity forecasts, scaling policies, and performance-readiness reporting.

## Step 37 — Quality Engineering and Release Hardening

Version 0.39.0 adds governed test suites, defect severity and release linkage, environment certification, release-candidate gates, independent UAT sign-offs, security and performance approvals, and rollback validation. Administrative routes are available under `/admin/quality-engineering`.


## Step 38 — Production Operations
Deployment governance, observability coverage, alert response, runbooks, on-call rotations, and go-live controls are now included.


## Step 39 — Release Enablement

Governed documentation, onboarding programs, training certification, release communications, and customer launch readiness are available under `/admin/release-enablement`.

## Step 40 — Version 1.0 GA Readiness

The platform now includes evidence-backed release certification, migration and rollback assurance, residual-risk governance, cross-functional acceptance, and mandatory general-availability launch controls. See `docs/step-40-ga-readiness.md` and `docs/raj-step-40-handoff.md`.

## Step 41 — Version 1.0 Production Launch Certification

The platform now includes final GA closure at `/admin/launch-certification`: blocker-resolution evidence, production deployment records, rollback assurance, post-launch checks, launch approvals, and release-artifact integrity. Version 1.0 is certified only when every mandatory control passes.


## Step 42 — Post-GA Operations and Continuous Improvement

Adds adoption analytics, customer-health management, feedback governance, value-realization tracking, and an evidence-backed v1.1 improvement portfolio under `/admin/post-ga-operations`.
