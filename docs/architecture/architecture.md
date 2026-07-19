# GTM Engineering OS Architecture

Version 1 is a modular monolith built with Next.js, TypeScript, PostgreSQL/Supabase, and provider-agnostic AI services. Global real-world entities are separated from workspace-specific intelligence and execution. Every material business record is scoped by `workspace_id`; database row-level security is mandatory.

## Core boundaries

- Platform: users, workspaces, roles, permissions
- Configuration: business model, ICPs, offers, scoring, pipelines
- Entities: organizations, properties, people, workspace context
- Ingestion: source records, mappings, lineage, merges
- Intelligence: research, signals, evidence, briefs
- GTM: playbooks, campaigns, opportunities, tasks, activities
- Agents: model routing, versions, runs, evidence, reviews
- Governance: approvals, audits, retention, overrides
