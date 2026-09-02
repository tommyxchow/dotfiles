---
name: polish
description: End-of-slice cleanup for React/TS apps — Prettier + ESLint autofix on touched files first (when present), then four judgment lenses (reuse, quality, efficiency, altitude), then high-confidence cleanups behind a verify gate. Heavier than a quick tidy-up. Use for "polish", "dry clean", "make this less hacky", or "reduce duplication". Shape only — not a bug hunt; not the pass skill ("we good", "anything outstanding", "final review", "final double check", cleanup-before-commit). Default scope is dirty work plus files edited this session (still in scope after commit); `/polish all` for the full branch slice. Never installs tools.
argument-hint: "[staged | unstaged | branch | all | <focus>]"
---

# Polish — autofix then judgment cleanup

Improve the **shape** of working code. Not bugs (route those to the harness's code reviewer — Bugbot in Cursor, `/review` in Claude Code). Not a full rewrite. Not `pass` (vet + leftovers + ship-ready).

The flow is scope, then Prettier and ESLint prep, then four review lenses, then reconcile, apply, and verify. Report fewer, surer findings rather than many uncertain ones.

Tuned for React + TypeScript (Next.js, Expo, Vite, etc.) with **Prettier + ESLint**. Portable: when the tools are missing, skip autofix and don't invent formatting findings. **Never install** packages or use `npx`/`pnpm dlx`/`npm exec` to fetch tools for polish — only already-installed local binaries (e.g. `pnpm exec prettier` / `node_modules/.bin`).

Harness format-on-save is unreliable across Cursor / Claude Code / OpenCode. Batch autofix first, then spend lens budget on judgment.

## Phase 0 — Scope and recon

**Scope keywords:** only the **first** argument token may be a scope keyword (`staged` / `unstaged` / `branch` / `all`). Everything after that is Additional Focus — so focus text like “all buttons” does not change scope.

Build the review pool:

- **Source A — git changes** in the CWD repo (see Argument routing).
- **Source B — session-edited files** (Edit/Write this conversation, any repo), **except when scope is `branch`** (see below). Absolute paths; don't `git diff` them.

| Scope | Source A | Source B | Untracked |
|---|---|---|---|
| *(default)* | dirty vs HEAD (`git diff HEAD` if staged exists, else `git diff`) | include | include via `git status` |
| `unstaged` | `git diff` | include | include |
| `staged` | `git diff --cached` | include | no |
| `branch` | committed range only: `@{upstream}...HEAD` (fallback `origin/HEAD...HEAD`, then `main...HEAD` / `master...HEAD`) | **exclude** | **exclude** |
| `all` | same range as `branch` **+** dirty vs HEAD (`git diff HEAD` so staged+unstaged are included) | include | include |

If both sources are empty after applying the table, fall back to files the user named; if none, ask.

**Post-commit / clean tree:** If Source A is empty (everything committed, clean working tree) but Source B is non-empty, the pool is still those session-edited files on disk. That is intentional — bare `/polish` means “what we worked on this session,” not “only uncommitted hunks.” Read those files from disk for Phase 0.5 and Phase 1; do not stop with “nothing to polish” / “already clean” just because `git status` is clean.

If the pool clearly mixes unrelated work from another task, prefer Source B (when included) or ask **once** — don't block every run.

**Recon (cheap):**

1. Read `AGENTS.md` / `CLAUDE.md`. House style wins over baseline taste.
2. Note framework/compiler ownership (React Compiler memoization, typed routes, caches).
3. Detect **Prettier + ESLint** (config and/or package.json deps). Also note `format` / `lint` / `check` scripts.
4. Confirm **runnable local binaries** (e.g. `pnpm exec prettier --version`, `pnpm exec eslint --version`, or `node_modules/.bin/*`). Config without a binary means that tool is absent; skip it. Never install to enable autofix.
5. Prefer the repo's own full check; else lint + tests; else say so. Don't invent a gate.
6. Note CLI-/generated-owned paths (e.g. prettierignored `ui/`). Skip unless the diff intentionally owns them.
7. If the pool spans several repos, repeat detection and Phase 0.5 **per repo**. A repo with no tools skips autofix.

**Baseline taste** (when docs are thin; **AGENTS.md + real ESLint/Prettier always override**):

- Prettier owns whitespace/quotes/semis/import order/class sorting — lenses must not re-propose that.
- Prefer `import type` / inline type imports; real types over casual `any` / `as` / `!`.
- Prefer string unions or `as const` objects over `enum`.
- Prefer derived state / event handlers over effect+setState when equivalent.
- Don't default to `useMemo` / `useCallback` / `memo` when React Compiler is on.
- Prefer semantic tokens and `cn`-style helpers when the repo has them.
- Behavior-identical only; correctness problems go to code review.
- **No Prettier and no ESLint:** formatting/import-order/class-order stay **out of scope**. At most one summary note to consider adopting them. Do not hand-fix style.
- **Outside React/TS** (Dart/Flutter, etc.): skip React-specific taste (Compiler, `useMemo`, JSX nesting, `import type`). Still run reuse / dead-code / altitude. Don't invent dartfmt.

**Size gate.** Trivial (≈1 file, few lines): skip fan-out; run checklists inline; still run Phase 0.5 if tools exist. Small (≈2-5 files): one combined inline review covering all four checklist sections — don't spend four subagents on a pool one read can hold. Large: four lenses; shard a lens across dirs only when that prompt would be huge (soft judgment). Parallel *shards* of the same four lenses only — never new lens types. **Empty git diff does not make the run trivial** when Source B still has files — size the gate from the pool file set, not from `git diff` alone. The lens `~8` is a **report cap**, not a read cap: keep looking at the pool; don't stop reviewing because you already have 8 rows; don't manufacture findings to fill 8.

## Phase 0.5 — Prettier + ESLint prep

**Goal:** strip mechanical noise before lenses.

1. If neither tool is runnable in this repo, skip to Phase 1 (the no-toolchain rule applies).
2. Autofix **only pool paths for this repo**:
   - Prefer local CLIs on the file list: `pnpm exec prettier --write <files>`, then `pnpm exec eslint --fix <files>` (or `node_modules/.bin/...`).
   - Project scripts (`pnpm format`, etc.) **only** if they accept the same path list.
   - If a script can't be scoped to the file list, **skip** that step and note it in the summary. **Never** format or lint the whole repo.
3. Unfixable ESLint must not abort polish. Consume logs yourself; don't dump them at the user.
4. **Refresh pool:** post-autofix diff; re-read touched untracked (when in scope); **re-read Source-B paths** autofix may have changed (when Source B is in scope).
5. Drop from lens scope only files that **had a dirty diff** which became purely mechanical (format/import-order/class-order only). **Do not drop** Source-B (or other pool) files that have no remaining git diff — e.g. just committed — those stay in scope for judgment; lenses review current file contents.
6. Leftover ESLint findings: a safe behavior-identical fix may go in Phase 3, a correctness finding gets noted for code review, and pure style is ignored.

**Autofix no-op ≠ done.** If Prettier/ESLint made no changes, still continue to Phase 1 whenever the judgment pool is non-empty. “Already clean” is only for after lenses find nothing worth applying (or a truly trivial pool under the size gate).

Keep the numbers for the summary: how many files autofix touched, and what happened to each leftover lint finding (fixed, skipped, or sent to code review).

## Phase 1 — Four lenses (parallel, read-only)

Exactly four read-only lenses in one message. No extra lens types (Tailwind/imports/types/format).

Each subagent gets: post-0.5 scope; the **absolute path** to this skill's `references/checklists.md` and which sections to read (**its lens** + Finding format + Restraint) — paste those three sections inline if the path may not resolve in the subagent; recon + focus; owned/out-of-scope; **skip list** (Phase 0.5 + Prettier/ESLint-owned nits); findings only, schema, ~8 report cap (not a read cap); never "find ALL".

| Lens | Owns |
|---|---|
| **Reuse** | re-implements an existing helper/util |
| **Quality** | redundant state, copy-paste, dead code, needless guards, nesting, placeholder names, type escapes, convention drift |
| **Efficiency** | wasted work, missed concurrency, hot-path bloat, no-op updates, leaks |
| **Altitude** | bandaids, symptom-vs-cause, wrong layer, grab-bag files |

## Phase 2 — Reconcile

1. Dedup same span across lenses.
2. One edit per span: behavior-preservation > reuse > quality > efficiency > altitude.
3. Apply only **high/med severity at high confidence**.
4. Shape hierarchy: removal-shaped cleanups (dead code, unused params, redundant state) are the safest and go first; extract/move/split-shaped findings need a clearly named seam and payoff now — when in doubt, drop the restructuring, keep the deletion.
5. Drop remaining Prettier/ESLint-shaped findings.

## Phase 3 — Apply and verify

Smallest correct edit. Chesterton's Fence; don't strip named concepts/test seams; behavior-identical (test must change ⇒ not a cleanup).

**Undo rules:** revert only **polish-owned** patches from this run (the cleanups you applied). Never `git restore` / checkout that wipes user-authored hunks or unrelated dirty work.

**Gate:**

1. If useful, note whether the gate was already failing before your cleanups (quick baseline: run once before apply, or record known failure). Don't blame pre-existing failures on polish.
2. After apply: fresh-eyes on the resulting diff; revert polish-owned scope creep.
3. Run recon's gate. If a polish cleanup caused a new failure, revert **that** cleanup and continue with the others. If there is no gate, say so.

**Summary.** Write it in the global Communication voice: a few full sentences, answer first. Say what autofix touched, what you cleaned up and why it is safe, what you left alone and why, and anything correctness-shaped that belongs in code review. If nothing was worth changing, say the code was already clean and stop.

```
Autofix reformatted three files. I removed the unused draft state in the editor and swapped a hand-rolled date formatter for the existing helper; both keep behavior identical and the full check passes. I left the two similar upload handlers duplicated because they are likely to diverge. One thing for code review: the retry loop in the uploader never gives up.
```

## Argument routing

The first token sets the scope (table above). The remaining tokens become Additional Focus for every lens. With no scope keyword, use the default row.

Examples: `/polish` · `/polish all` · `/polish branch` · `/polish all auth forms`

## Note on posted text

In-session prose can use em dashes. Commit/PR text follows the global External writing rules (concise casual teammate voice, no em dashes, no filler).
