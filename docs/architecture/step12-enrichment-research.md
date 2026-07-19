# Step 12 — Enrichment and Account Research

Step 12 introduces the evidence-backed intelligence layer. It separates external providers, research execution, evidence, proposed findings, signals, and versioned account briefs so AI output cannot silently become operational truth.

## Operating flow

1. A user or workflow creates a research job against an entity.
2. The configured provider or agent gathers permitted evidence.
3. Evidence is retained with source reference, capture time, reliability, and content hash.
4. Findings contain current and proposed values, confidence, and verification state.
5. Governance rules determine whether human review is mandatory.
6. Accepted findings may be written through a future transactional application service.
7. Findings may generate time-bound signals and a versioned account brief.

## Safety boundary

Step 12 screens are review-capable demonstrations. Production writes must use server actions that check permissions, lock the current entity version, create field lineage, write the accepted value, and preserve the review decision in one transaction.

## Provider policy

Provider credentials are referenced through secrets management and never stored directly in PostgreSQL. Provider priority is field-specific. First-party and verified public records should outrank AI inference. AI findings cannot overwrite verified facts without explicit human approval.
