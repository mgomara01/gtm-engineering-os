# BUILD_STATUS.md — gtm-engineering-os Publication & Validation

Last updated: 2026-07-19

## Summary

`gtm-engineering-os-full-repo.zip` was extracted, its full git history (3
commits, 423 tracked files) was pushed to the previously-empty
`https://github.com/mgomara01/gtm-engineering-os`, one real build-breaking
defect was found and fixed (see Defect 1), and the full validation pipeline
(typecheck → unit tests → production build → smoke test) passed with no
forced-success shortcuts. Two items need your decision before this is
production-ready (see "Remaining manual actions").

## Commands run, in order, with exit codes

| # | Command | Exit | Notes |
|---|---|---|---|
| 1 | Staged `gtm-engineering-os-full-repo.zip` (1,314,005 bytes) from local device | — | via device bridge |
| 2 | `unzip` into working directory | 0 | |
| 3 | Verified `.git`, `package.json`, `apps`, `supabase`, `scripts`, `.github` present | — | all present, plus `docs`, `packages`, `tests` |
| 4 | `git status` / `git log --oneline -10` / `git rev-list --all --count` / `git ls-files \| wc -l` / `git branch -a` / `git remote -v` | — | clean tree, 3 commits, 423 files, `main` only, origin already correct |
| 5 | `git remote remove origin && git remote add origin https://github.com/mgomara01/gtm-engineering-os.git` | 0 | reset to same target |
| 6 | `git branch -M main` | 0 | no-op |
| 7 | Installed GitHub CLI v2.96.0 | 0 | |
| 8 | `gh auth login` (loopback web flow) | fail | structural — loopback OAuth callback (`127.0.0.1:<port>`) is unreachable from a browser on a different machine than this sandbox. Not retryable; see Defect 2. |
| 9 | `gh auth login --with-token` | fail | this sandbox blocks GraphQL calls to `api.github.com` except a pinned set of PR-review operations (`HTTP 403 ... only the pinned set of PR-review operations is served`); `gh auth login` calls GraphQL to verify identity |
| 10 | `git ls-remote` with token in URL (plain git, not `gh`) | 0 | confirmed target repo was empty (no output) |
| 11 | `git push` main → origin (first attempt) | fail | rejected: PAT lacked `workflow` scope, required because the repo includes `.github/workflows/ci.yml` |
| 12 | `git push` main → origin (after user added `workflow` scope) | 0 | `* [new branch] main -> main` |
| 13 | `git push -u origin main` (named remote, cached credentials) | 0 | `Everything up-to-date`; set `main` to track `origin/main` |
| 14 | `git ls-remote origin` | 0 | confirmed `refs/heads/main` present on GitHub |
| 15 | `npm ci` (first attempt) | timeout/hang | see Defect 1 |
| 16 | Fixed `package-lock.json`, `npm ci` (retry) | 0 | 551 packages installed in 21s |
| 17 | `npm run typecheck` | 0 | clean, no errors |
| 18 | `npm test` | 0 | 227 tests passed across 38 files |
| 19 | `npm run build:raw` (plain `next build`, no wrapper) | 0 | completed and exited on its own — confirms Defect 3 does not reproduce in this environment |
| 20 | `npm run build` (the repo's actual production build command) | 0 | took the normal completion path ("Production build completed normally and required artifacts were verified"), not the wrapper's forced-kill fallback; all 6 required Next.js artifacts present |
| 21 | `npm run start` + smoke tests | 0 | see Smoke Test Results |
| 22 | `npm run check:prod-env` with no env vars set | 1 (expected) | correctly reports the 4 missing production variables and exits non-zero rather than crashing |

## Defects found and fixes made

### Defect 1 — `package-lock.json` pointed at an unreachable internal registry (real, CI-breaking)

All 652 `"resolved"` URLs in `package-lock.json` pointed to
`https://packages.applied-caas-gateway1.internal.api.openai.org/artifactory/api/npm/npm-public/...`
— an internal-only hostname from whatever environment originally generated
the lockfile. This is not specific to this sandbox: GitHub's own Actions
runners (which run `.github/workflows/ci.yml`) would also be unable to
resolve/reach that host, so **CI as committed would fail `npm ci` on every
run.**

**Fix:** rewrote all 652 `resolved` URLs to point at
`https://registry.npmjs.org/` instead, preserving package name, version, and
filename exactly (verified via diff — only the host segment changed).
Package identity and npm's integrity hashes are unaffected, since integrity
is content-addressed and independent of source host. `npm ci` then
completed in 21 seconds. **This fix is committed** (see commit below).

### Defect 2 — `gh auth login` cannot complete in a headless/remote sandbox (environmental, not a repo defect)

`gh auth login`'s default and `--web` flows both use a loopback OAuth
callback (`http://127.0.0.1:<port>/callback`) that requires the CLI and the
browser to be on the same machine. This sandbox is architecturally separate
from your browser, so that flow can never complete here. Resolved by using
`gh auth login --with-token` semantics instead (a PAT, provided by you,
piped directly into git operations — never written to disk, logged, or
committed). No repo change needed; noting this for future automation in
similar sandboxed environments.

### Defect 3 — custom `build-next.mjs` wrapper (present in repo, not newly introduced)

`scripts/build-next.mjs` (the actual `npm run build` command) wraps `next
build` in a watchdog that verifies required build artifacts exist and, only
if the child process fails to exit on its own after printing its completion
report, force-terminates it. This looks like a workaround for a known
class of Next.js issues where the build process doesn't exit cleanly.

**Verification done:** ran the raw `next build` directly (`npm run
build:raw`, no wrapper) — it exited on its own with code 0, no hang, no
lingering processes, in this environment. Then ran the real `npm run build`
and confirmed it took the **normal completion path** (`child.on('exit')`
with code 0 → "Production build completed normally and required artifacts
were verified"), not the forced-kill fallback. So in this environment the
build does not hang, and no forced-success shortcut was invoked to produce
a passing result. The watchdog itself is pre-existing repo code, not
something introduced during this session, and was left as-is since it acts
purely as a safety net that never fired.

## Test results

- **Typecheck:** 0 errors (`tsc --noEmit -p apps/web/tsconfig.json`)
- **Unit tests:** 227 passed / 227, across 38 files, 10.6s (Vitest 3.2.4)
- **Production build:** exit 0, all 6 required Next.js artifacts present (`BUILD_ID`, `build-manifest.json`, `routes-manifest.json`, `prerender-manifest.json`, `required-server-files.json`, `server/app-paths-manifest.json`)

## Smoke test results (`npm run start`, no Supabase credentials configured)

| Route | Result |
|---|---|
| `/` | 200 |
| `/login` | 200 |
| `/work` | 200 |
| `/analytics` | 200 |
| `/executive` | 200 |
| `/admin/usage` | 200 |
| `/unauthorized` | 200 |
| `/auth/callback` (no code param) | 307 redirect (handled, not a crash) |
| `/this-route-does-not-exist` | 404 |
| `/api/health/live` | 200, `{"status":"ok",...}` |
| `/api/health/ready` | **503**, `{"status":"not_ready","configured":0,"total":3,"missing":[...]}` — correct graceful degradation, no crash |
| `/api/v1/health` | 200, `{"status":"operational",...}` |
| `npm run check:prod-env` (no env vars) | exits 1 with a clear list of missing variables |

No server errors in logs during any of the above. Missing-env-var handling
and Supabase-unconfigured handling both behave as designed (explicit
"not_ready" / "missing variables" responses, not silent failures or
crashes).

## Config and security review

- **`.env.example`**: no secret values present, correctly separates
  `NEXT_PUBLIC_*` (browser-safe) from server-only keys
  (`SUPABASE_SERVICE_ROLE_KEY`, `APP_ENCRYPTION_KEY`, etc.)
- **`.gitignore`**: correctly excludes `.env`, `.env.local`, `node_modules`,
  `.next`, `coverage`, `playwright-report`, `test-results`
- **GitHub Actions**: `ci.yml` runs `npm ci` → `typecheck` → `test` →
  `build` on every push/PR to `main` (Node 20); `release.yml` adds `npm
  audit --audit-level=high` and a tag-gated production-env contract check.
  Both are reasonable; Defect 1's fix directly unblocks `ci.yml`.
- **Deployment config**: no `Dockerfile` / `vercel.json` / `netlify.toml` —
  this is a zero-config Next.js app that relies on host auto-detection
  (e.g., Vercel). Not a defect, just noting the absence.
- **Supabase migrations**: 42 migration files, sequential and readable.
  Note: two files share the number `0021` (`0021_controlled_pilot.sql` and
  `0021_production_activation.sql`). Supabase orders migrations by full
  filename, so this is not currently ambiguous (`c` sorts before `p`), but
  it's a numbering inconsistency worth cleaning up next time these are
  touched.
- **Row-level security — flagged for your review:** of 210 tables created
  across all migrations, 177 have `ENABLE ROW LEVEL SECURITY`; **33 do
  not.** Most look like they could be intentional (static reference data
  such as `agents.models`, `agents.providers`), but several are clearly
  sensitive and warrant a deliberate decision rather than a silent fix:
  `developer.api_credentials`, `platform.user_profiles`,
  `platform.user_workspace_roles`, `platform.roles` /
  `platform.role_permissions` / `platform.permissions`,
  `entities.organizations` and related contact/address tables, and
  `security.control_evidence`. I did not add RLS policies myself — the
  correct policy per table depends on your intended access model (which
  roles should see what), and guessing wrong risks either a false sense of
  security or breaking legitimate server-side access patterns. Full list of
  33 tables is in this session; ask me to enumerate again if useful.
- **Secrets:** no secret values were displayed, committed, or uploaded at
  any point in this session. The GitHub PAT you provided was piped directly
  into `git`/`gh` invocations and never written to a file, log, or commit.

## Commit and push

Committed and pushed to `main`:
- `package-lock.json` — Defect 1 fix (652 resolved URLs repointed to the public npm registry)
- `BUILD_STATUS.md` — this file

## Remaining manual actions

1. **Row-level security decision (Defect finding above).** Review the 33
   tables without RLS and decide, per table, whether it's intentionally
   public/reference data or needs a policy. This is a product/security
   decision, not a mechanical fix.
2. **Duplicate migration number `0021`.** Not urgent (no ordering
   ambiguity today), but worth renaming one of the two files next time
   migrations are touched, to avoid confusion.
3. **Revoke the PAT** you generated for this session
   (https://github.com/settings/tokens) once you've confirmed everything
   here looks right — it's already served its purpose.
4. **Set real Supabase credentials** (and the other production env vars)
   before deploying anywhere users will hit it for real; today the app
   correctly runs in a "not configured" state rather than crashing, which
   is the right default but isn't a production state.
