---
name: understand
description: Structured exploration of an unfamiliar codebase. Produces a navigable architecture map with vertical slices traced input-to-output. Use when the user is ramping up on an unfamiliar repo, expresses confusion about how a codebase is organized, or asks where to start — including phrases like "explore this", "orient me", "what is this repo", "onboard me", "walk me through this codebase", or "I inherited this code".
argument-hint: "[scope/path]"
---

If the user specifies a scope (e.g., `/understand src/auth`), focus exploration on that area rather than the whole repo: $ARGUMENTS

## Step 1 — Detect Archetype

Check root for signature files to determine the exploration strategy:

| Signals                                         | Archetype         | Slice Strategy                                                     |
| ----------------------------------------------- | ----------------- | ------------------------------------------------------------------ |
| `pnpm-workspace.yaml` / `turbo.json` + `apps/`  | Polyglot Monorepo | Map app boundaries; pick one app and recurse with this skill on it |
| `package.json` + Next.js + `src/app/` or `app/` | Next.js App       | Route → page component → data fetching → server/client boundary    |
| `package.json` + React/Vue + `src/components/`  | Frontend SPA      | Visible value → render site → state → data source                  |
| `pubspec.yaml` + `lib/`                         | Flutter/Dart      | Screen → widget tree → store/provider → API client → model         |
| Route handlers + Dockerfile                     | Backend API       | Endpoint → middleware → handler → service → persistence            |
| `dags/`, `pipeline/`, `dbt_project.yml`         | Data Pipeline     | Entity through stages, map schema evolution at each boundary       |
| `pyproject.toml`/`setup.py`, lib structure      | Library/SDK       | Public API → internal modules → core logic                         |
| `main.tf`, `cdk.json`                           | Infra (IaC)       | Core resource → dependents → blast radius                          |
| CLI entry points, `bin/`                        | CLI Tool          | Command → arg parsing → execution → output                         |

## Step 2 — Orientation (parallel agents)

Spawn 2–3 read-only explorer agents in parallel using `subagent_type: Explore`:

1. **I/O Boundaries** — entry points, external calls, data sources/sinks. Where does the system touch the world?
2. **Shape** — key dependencies, config, implicit contracts (magic strings, hardcoded values, assumed conventions).
3. **Activity** — `git log --oneline -50` plus `git shortlog -sn --since="3 months ago"`. Recent themes, hot/frozen zones, single-author files.

## Step 3 — Vertical Slices

Using the archetype's trace strategy, trace 2–3 complete paths from input to output. Each slice should follow the full chain without hand-waving any step. One complete slice is worth more than a shallow survey of everything.

## Output

**What is this** — 2–3 sentences. Archetype, purpose, stack.

**Architecture** — Key directories and what lives where. Only the ones you need to navigate.

**How it flows** — Vertical slices as traced paths: trigger → step → step → output, with `file_path:line_number` references.

**Watch out** — Fragility, coupling, smells, implicit contracts that bite newcomers.

**Unknowns** — What wasn't explored and why. Gaps stated honestly.
