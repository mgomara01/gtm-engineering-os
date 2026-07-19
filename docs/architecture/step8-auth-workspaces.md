# Step 8: Authentication, Workspace Access, and Implementation Workflow

## Authentication

The application uses Supabase Auth when public Supabase configuration is present. `apps/web/proxy.ts` refreshes the user session and redirects unauthenticated users to `/login`. When credentials are absent, local development uses an explicit demonstration path and does not imply production authentication.

## Workspace access

Workspace selection is derived from `platform.user_workspace_access`, which joins authenticated user assignments, roles, workspaces, and the active implementation plan. The selected workspace ID is stored in a same-site browser cookie. Server-rendered pages verify that the requested workspace remains within the accessible set.

## Authorization

`platform.roles`, `platform.permissions`, and `platform.role_permissions` define the role model. Database row-level security remains the authoritative workspace boundary. Interface visibility is supplemental and must never replace database enforcement.

## Configuration versions

Only approved configuration versions may be activated. Activation retires the prior active version, records the active version on the workspace, and preserves historical records against their original configuration version.

## Implementation workflow

The first functional workflow contains implementation plans, twelve ordered stages, stage requirements, decisions, risks, and readiness assessments. The dashboard view calculates deliverable completion, open control items, and readiness. Production mutations will be added through validated server actions in the next increment.

## Demonstration mode

The browser demonstration stores progress in local storage under a workspace-specific key. This proves workspace separation and interaction design without representing local changes as database records.
