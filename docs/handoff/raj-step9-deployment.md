# Raj Handoff — Step 9

1. Apply migration `0009_data_ingestion.sql` after the Step 8 migrations.
2. Confirm the `data.manage` permission exists and is assigned to GTM Administrator, GTM Engineer, and Technical Administrator roles.
3. Create a private Supabase Storage bucket for source imports.
4. Configure upload size, malware scanning, retention, and backup policies.
5. Implement the production commit endpoint as a transaction: batch → file → rows → mappings → operational records → lineage.
6. Implement rollback as compensating database actions; retain immutable source rows and audit events.
7. Test RLS using one user with access to Alvarez only and another with access to Intelligent Waterflow only.
8. Do not place customer files in source control or seed data.
