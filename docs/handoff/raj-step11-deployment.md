# Raj Deployment — Step 11

1. Deploy migration `0011_entity_resolution.sql` after Step 10.
2. Confirm `pg_trgm` and `unaccent` extensions are enabled by migration 0001.
3. Grant the application role access to the `ingestion.merge_candidate_directory` view.
4. Run `ingestion.queue_organization_candidates(workspace_id)` first in staging.
5. Review candidate volume and tune the minimum similarity threshold before production scheduling.
6. Do not enable automatic merge execution until the transactional merge and reversal functions receive integration tests against a production-like copy.
7. Restrict merge and reversal actions to GTM administrators and technical administrators.
8. Add monitoring for queue growth, merge reversals, and candidates older than seven days.
