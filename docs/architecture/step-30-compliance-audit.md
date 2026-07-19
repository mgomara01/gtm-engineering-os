# Step 30 — Compliance, Audit, and Policy Management

Step 30 turns the platform's governance, security, privacy, reliability, and resilience controls into a continuously auditable assurance system.

## Capabilities

- Versioned policy lifecycle with approval, review, and acknowledgement tracking
- Regulatory and contractual obligation register with control and evidence mapping
- Evidence request workflow with reporting periods, ownership, due dates, and acceptance state
- Periodic control-owner attestations with effectiveness and exception reporting
- Audit engagement workspace with fieldwork, remediation, findings, and opinion status
- Time-bounded compliance exceptions with compensating controls and executive approval
- Executive compliance-readiness calculation across policy, obligation, evidence, attestation, and exception posture

## Control boundary

All records are workspace-scoped and protected by row-level security. Evidence artifacts should be stored in an approved private object store and referenced by immutable metadata; browser-visible demo URLs are not production evidence repositories.

## Operating model

1. Legal and compliance owners maintain the obligation register.
2. Control owners attest to control operation for each required period.
3. Assurance personnel request and validate evidence independently.
4. Exceptions require explicit risk ownership, compensating controls, an expiration date, and remediation.
5. Audit readiness is an operational signal, not a substitute for auditor judgment.
