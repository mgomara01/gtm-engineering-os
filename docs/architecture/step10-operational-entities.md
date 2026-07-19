# Step 10 — Operational Entity Layer

Step 10 introduces the global identity layer and workspace-specific account context. Organizations, properties, and people are reusable global entities; lifecycle, ownership, priority, and notes remain workspace-scoped.

## Delivered
- Organization directory and account intelligence pages
- Property and contact relationships
- External identifier/source linkage
- Activity timeline contract
- Supabase directory views and RLS policies
- Demonstration records for browser validation only

## Production boundary
The add-organization screen is intentionally non-writing until server actions, validation, duplicate detection, and an atomic transaction function are deployed. Imported records should create source records first, then resolve to global entities and workspace context.
