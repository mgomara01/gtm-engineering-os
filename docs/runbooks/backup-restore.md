# Backup and Restore Runbook

1. Confirm Supabase point-in-time recovery or scheduled database backups are active.
2. Export Storage object inventory and configuration metadata.
3. Create an isolated recovery project.
4. Restore the selected database recovery point.
5. Apply migrations only if the restored point predates the target release.
6. Verify workspace counts, entity counts, active configuration versions, audit continuity, and external cursor positions.
7. Restore Storage objects and compare checksums.
8. Disable outbound communication and automated writes in the recovery environment.
9. Record actual RPO, RTO, evidence, defects, and remediation in `operations.recovery_tests`.
10. Obtain infrastructure and application-owner sign-off.
