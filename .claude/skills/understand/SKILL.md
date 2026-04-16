---
name: understand
description: Structured exploration of an unfamiliar codebase. Produces a navigable architecture map with vertical slices traced input-to-output. Use when the user says "explore this", "orient me", "what is this repo", "onboard me", "walk me through this codebase", "help me understand this code", "I inherited this code", or "explore this project".
---

# Orient

Produce a navigable map of a codebase — enough to know where to look, what to trace, and what to avoid.

If the user specifies a scope (e.g., `/understand src/auth`), focus exploration on that area rather than the whole repo: $ARGUMENTS

## Step 1 — Detect Archetype

Check root for signature files to determine the exploration strategy:

| Signals                                       | Archetype    | Slice Strategy                                                     |
| --------------------------------------------- | ------------ | ------------------------------------------------------------------ |
| `package.json` + Next.js + `src/app/`         | Next.js App  | Route → page component → data fetching → server/client boundary    |
| `package.json` + React/Vue + `src/components/` | Frontend SPA | Visible value → render site → state → data source                  |
| `pubspec.yaml` + `lib/`                       | Flutter/Dart | Screen → widget tree → store/provider → API client → model        |
| Route handlers + Dockerfile                   | Backend API  | Endpoint → middleware → handler → service → persistence            |
| `dags/`, `pipeline/`, `dbt_project.yml`       | Data Pipeline| Entity through stages, map schema evolution at each boundary       |
| `pyproject.toml`/`setup.py`, lib structure    | Library/SDK  | Public API → internal modules → core logic                         |
| `main.tf`, `cdk.json`                         | Infra (IaC)  | Core resource → dependents → blast radius                          |
| CLI entry points, `bin/`                      | CLI Tool     | Command → arg parsing → execution → output                        |

State classification and proceed. Note ambiguity if present.

## Step 2 — Orientation (parallel agents)

Spawn 2-3 read-only explorer agents:

1. **I/O Boundaries** — entry points, external calls, data sources/sinks. Where does the system touch the world?
2. **Shape** — key dependencies, config, implicit contracts (magic strings, hardcoded values, assumed conventions).
3. **Activity** — `git log --oneline -50`. Recent themes, hot/frozen zones, single-author files.

## Step 3 — Vertical Slices

Using the archetype's trace strategy, trace 2-3 complete paths from input to output. Each slice should follow the full chain without hand-waving any step. One complete slice is worth more than a shallow survey of everything.

## Output

**What is this** — 2-3 sentences. Archetype, purpose, stack.

**Architecture** — Key directories and what lives where. Only the ones you need to navigate.

**How it flows** — Vertical slices as traced paths: trigger → step → step → output, with `file_path:line_number` references.

**Watch out** — Fragility, coupling, smells, implicit contracts that bite newcomers.

**Unknowns** — What wasn't explored and why. Gaps stated honestly.
