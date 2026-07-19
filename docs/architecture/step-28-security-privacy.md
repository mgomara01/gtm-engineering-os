# Step 28 — Security Operations and Privacy Management

Step 28 adds a security operations control plane spanning control assurance, vulnerability and finding management, data classification, privacy requests, and security-event triage. The design joins—but does not collapse—security events with Step 27 incident command.

## Control model
Controls are mapped to frameworks, assigned to owners, periodically tested, and supported by checksum-addressable evidence. Ineffective and untested controls remain visible; exceptions require explicit acceptance, expiration, and accountable approval.

## Findings
Findings are prioritized by severity, known exploitability, and internet exposure. Remediation targets are policy-driven. Risk acceptance is time bounded and cannot silently convert an unresolved finding into a resolved one.

## Data and privacy
Every governed dataset has a classification, accountable owner, personal-data indicator, retention period, and encryption posture. Privacy requests preserve identity-verification evidence, jurisdiction, deadline, disposition, and completion evidence without exposing sensitive identity documents to ordinary operators.

## Security events
Detection records preserve source, time, severity, disposition, and correlation identifiers. Confirmed customer-impacting events escalate into Reliability incidents; evidence remains immutable and separately retained.
