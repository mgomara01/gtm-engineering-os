# Step 11 — Entity Resolution

Step 11 adds a controlled identity-resolution layer between ingestion and the global entity model.

## Processing sequence

1. Normalize organization names, domains, phones, and addresses.
2. Apply exact external-identifier, domain, and phone rules.
3. Calculate fuzzy name and address similarity.
4. Assign a confidence score and recommendation.
5. Auto-link only at 95 or higher when deterministic evidence exists.
6. Route scores from 80 through 94 to human review.
7. Treat lower scores as new records unless a reviewer identifies a relationship.

## Review controls

The comparison screen exposes source values, match evidence, and field-level conflicts. Reviewers may merge, keep separate, defer, or classify a relationship. Fuzzy similarity alone does not perform a merge.

## Reversible merge model

Production merge execution must run in one database transaction. Before modifying relationships, the service writes a complete `merge_snapshot` to `ingestion.merge_actions`. The merged entity is retained as an inactive tombstone, aliases and external identifiers move to the survivor, workspace links are reconciled, and reversal remains available to an administrator.

## Relationship classification

Similar records that are not duplicates may be classified as parent, subsidiary, affiliate, owner, manager, franchise, partner, vendor, or other. Relationship classification is distinct from merging.
