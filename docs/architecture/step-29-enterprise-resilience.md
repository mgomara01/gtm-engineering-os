# Step 29 — Enterprise Resilience

Step 29 establishes a workspace-isolated operating model for business continuity, disaster recovery, backup assurance, continuity exercises, and third-party risk.

## Core controls

- Recovery plans bind business services to recovery tiers, owners, RTOs, RPOs, runbooks, review cycles, and alternate operating procedures.
- Backup controls record frequency, retention, encryption, immutability, successful execution, and restore-test evidence.
- Continuity exercises capture scenarios, participants, measured recovery time, outcomes, and corrective findings.
- Third-party records track critical dependencies, sensitive-data access, inherent and residual risk, assurance evidence, breach-notification terms, contracts, and reassessment dates.
- Resilience findings unify recovery, backup, exercise, and vendor gaps into owned remediation work.

## Governance rules

Tier 0 and Tier 1 services require tested runbooks and alternate procedures. Backup success alone is not sufficient; restore tests are required. Critical providers with restricted data access must have current assurance evidence and contractual incident-notification commitments. Overdue assessments and failed exercises require documented mitigation or executive risk acceptance.

## Security model

All resilience tables carry `workspace_id`, have row-level security enabled, and use the platform workspace-access predicate. Production writes should be routed through privileged server-side services and recorded in the governance audit log.
