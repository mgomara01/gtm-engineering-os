# Raj Deployment — Step 10

1. Deploy migrations through `0010_operational_entities.sql` in staging.
2. Verify `platform.has_workspace_access(uuid)` exists from Step 8.
3. Grant authenticated users SELECT access to the three directory views.
4. Confirm RLS prevents cross-workspace reads on workspace properties, people, identifiers, and activities.
5. Connect the Step 9 commit service so imported organization/property/contact records populate the new tables and external identifiers.
6. Do not enable the create form for production until the atomic create-and-link RPC and duplicate review are implemented.
