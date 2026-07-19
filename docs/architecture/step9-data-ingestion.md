# Step 9 — Controlled Data Ingestion

The Step 9 workflow introduces a five-stage ingestion pipeline: upload, mapping, validation, preview, and commit. Excel and CSV files are parsed in the browser for immediate profiling. Production commits are represented by immutable batch, file, source-row, mapping, and field-lineage records in PostgreSQL.

## Integrity controls

- Raw source rows are never overwritten.
- Mapping decisions are stored with the import batch.
- Validation errors and possible duplicates are disclosed before commit.
- Rollback changes batch state and reverses accepted operational writes; it does not erase source evidence.
- Workspace RLS applies to every ingestion table.
- Demonstration mode stores batch manifests locally and does not claim database persistence.

## Production service boundary

The UI is complete, but production commit actions require a server-side import service using Supabase Storage and database transactions. Large files should move parsing to a background job and use chunked inserts. The browser implementation is suitable for workflow validation and moderate pilot files.
