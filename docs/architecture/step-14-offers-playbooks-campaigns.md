# Step 14 — Offers, Playbooks, Campaigns, and Performance

Step 14 converts scored intelligence into governed GTM execution. Offers define the commercial proposition; immutable offer versions feed immutable playbook versions; campaigns pin a specific playbook version and preserve each member's enrollment score, tier, and audience snapshot.

## Governance boundary

Draft content may be edited. Approved or active versions are immutable and must be cloned to change. Campaigns cannot enroll accounts from a draft playbook. Hard scoring exclusions remain authoritative. Every enrollment stores the reason and source score so later performance analysis is reproducible.

## Execution model

Offer → Offer Version → Playbook → Playbook Version → Ordered Steps → Campaign → Members → Sequence Executions → Performance Events.

Sequence execution should run through application jobs or Trigger.dev. n8n may deliver integration actions, but eligibility, branching, approval, and state transitions remain application logic.

## Production server actions still required

Create and clone versions; submit/approve/reject; activate versions; create campaigns; materialize eligible audiences; enroll members transactionally; generate sequence tasks; pause/resume; record outcomes; attribute opportunities and revenue.
