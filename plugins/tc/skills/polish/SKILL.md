---
name: polish
metadata:
  opencode/slash: "true"
description: 'Behavior-preserving cleanup using existing format/lint tools and four lenses: reuse, quality, efficiency, altitude. Tuned for React/TS, with non-React checks usable elsewhere. Use for polish, clean up the code, code cleanup, dry clean, make this less hacky, or reduce duplication; a bare cleanup with no code named is repo hygiene (cleanup), not this; `quick` is inline, removal-shaped cleanups only. Correctness goes to review; slice completion to pass; PR readiness to pr. Default scope is dirty work plus session edits, including after commit; all includes the branch and pending work. Never installs tools.'
argument-hint: "[quick] [staged | unstaged | branch | all | <focus>]"
---

# Polish — autofix then judgment cleanup

This skill improves the **shape** of working code. It scopes the work, runs the existing formatter and linter as prep, reviews through four lenses, then applies and verifies the high-confidence cleanups. If you discover a correctness defect, send it to `tdd` as a review finding. Never disguise a behavior change as polish.

The skill is tuned for React + TypeScript (Next.js, Expo, Vite, etc.) with **Prettier + ESLint**, and it is portable: when the tools are missing, skip autofix and don't invent formatting findings. Use only local binaries that are already installed (e.g. `pnpm exec prettier` / `node_modules/.bin`). **Never install** packages or use `npx`/`pnpm dlx`/`npm exec` to fetch tools for polish.

Format-on-save in the harness is unreliable across Cursor / Claude Code / OpenCode, so batch the autofix first, then spend the lens reviews on judgment.

## Phase 0 — Scope and recon

**Scope keywords:** `quick` may come first (see the size gate). After it, the first token may be `staged`, `unstaged`, `branch`, or `all`, and the rest is focus text. `/polish all buttons` means branch-wide scope focused on buttons. Use `/polish buttons` to keep the default scope.

Build the pool, the set of files this run covers, by following [references/scope.md](references/scope.md). That file covers Sources A and B for each scope, the base rule, the caller-supplied pool, the post-commit case, and the ownership filter. Read it before Phase 0.5, because the size gate below sizes the work from that pool.

**Recon (cheap):**

1. Read `AGENTS.md` / `CLAUDE.md`. The repo's house style wins over the baseline taste below.
2. Note what the framework or compiler already owns (React Compiler memoization, typed routes, caches).
3. Detect **Prettier + ESLint** from their config and/or the package.json deps. Also note any `format` / `lint` / `check` scripts.
4. Confirm the **runnable local binaries** (e.g. `pnpm exec prettier --version`, `pnpm exec eslint --version`, or `node_modules/.bin/*`). A config without a binary means that tool is absent, so skip it. Never install anything to enable autofix.
5. Pick the gate, the check Phase 3 runs after applying cleanups. Prefer the repo's own full check. If there is none, use lint + tests, and if those are missing too, say so. Don't invent a gate.
6. Note paths that a CLI or generator owns (e.g. prettierignored `ui/`). Skip them unless the diff intentionally owns them.
7. If the pool spans several repos, repeat detection and Phase 0.5 **per repo**. A repo with no tools skips autofix.

**Baseline taste** applies when the repo's docs are thin. **AGENTS.md and the real ESLint/Prettier config always override it.**

- Prettier owns whitespace, quotes, semis, import order, and class sorting, so the lenses must not propose those changes again.
- Prefer `import type` / inline type imports.
- Prefer real types over casual `any` / `as` / `!`.
- Prefer string unions or `as const` objects over `enum`.
- Prefer derived state or event handlers over effect+setState when the two are equivalent.
- Don't default to `useMemo` / `useCallback` / `memo` when React Compiler is on.
- Prefer semantic tokens and `cn`-style helpers when the repo has them.
- Make only behavior-identical changes. Correctness problems go to code review.
- **No Prettier and no ESLint:** formatting, import order, and class order stay **out of scope**. Add at most one note in the summary suggesting the repo consider adopting them, and don't hand-fix style.
- **Outside React/TS** (Dart/Flutter, etc.): skip the React-specific taste (Compiler, `useMemo`, JSX nesting, `import type`). Still run the reuse, dead-code, and altitude checks. Don't invent dartfmt.

**Size gate.** With `quick`, whether it comes from the user or is handed down by `pass`, run inline whatever the size, with no fan-out to subagents, and make removal-shaped cleanups only (dead code, unused params, redundant state, needless guards). Don't extract, move, or split. Without `quick`, size the pool:

- A trivial pool (≈1 file, few lines) skips fan-out and runs the checklists inline. It still runs Phase 0.5 if tools exist.
- A small pool (≈2-5 files) gets one combined inline review covering all four checklist sections, because one read can hold the pool and four subagents would be wasted on it.
- A large pool gets the four lenses. Shard a lens across dirs only when its prompt would be huge, which is a soft judgment call. Shards are parallel copies of the same four lenses only; don't add new lens types.

Size from the pool file set, not `git diff` (see the post-commit case in `references/scope.md`). The lens `~8` is a **report cap**, not a read cap. Keep looking at the pool, and don't stop reviewing because you already have 8 rows. Don't manufacture findings to fill 8.

## Phase 0.5 — Prettier + ESLint prep

**Goal:** strip mechanical noise before the lenses run.

1. If neither tool is runnable in this repo, skip to Phase 1 (the no-toolchain rule applies).
2. Autofix **only the pool paths for this repo**:
   - Prefer running the local CLIs on the file list: `pnpm exec prettier --write <files>`, then `pnpm exec eslint --fix <files>` (or `node_modules/.bin/...`).
   - Use project scripts (`pnpm format`, etc.) **only** if they accept the same path list.
   - If a script can't be scoped to the file list, **skip** that step and note it in the summary. **Never** format or lint the whole repo.
3. Don't let unfixable ESLint findings abort polish. Read the logs yourself instead of dumping them on the user.
4. **Refresh pool:** inspect the post-autofix diff for ownership and scope. Undo only autofix-owned changes outside the pool. Re-read touched untracked and Source-B paths when they are in scope.
5. Drop a file from lens scope only when it **had a dirty diff** that became purely mechanical (format, import-order, or class-order changes only). Pool files with no git diff stay (see the post-commit case in `references/scope.md`), and the lenses review current file contents.
6. For leftover ESLint findings, a safe behavior-identical fix may go in Phase 3, a correctness finding gets noted for code review, and pure style is ignored.

Keep the numbers for the summary: how many files autofix touched, and what happened to each leftover lint finding (fixed, skipped, or sent to code review).

## Phase 1 — Four lenses (parallel, read-only)

Run this phase only when the size gate chose fan-out. Launch the four read-only lenses in one message, with at most four workers in total, so a sharded lens counts against that cap rather than adding to it. Trivial and small pools run the same four checklists inline. Don't add extra lens types (Tailwind/imports/types/format).

Give each subagent the post-0.5 scope and the **absolute path** to this skill's `references/checklists.md`, with the sections it should read (**its lens** + Finding format + Restraint). If the path may not resolve in the subagent, paste those three sections inline. Also give it the recon results and the focus, what is owned and what is out of scope, and a **skip list** (Phase 0.5 + Prettier/ESLint-owned nits). Ask for findings only, in the schema, with the ~8 report cap (not a read cap). Never ask it to "find ALL".

| Lens | Owns |
|---|---|
| **Reuse** | re-implements an existing helper/util, including a semantic duplicate spelled differently |
| **Quality** | redundant state, copy-paste, dead code, needless guards, nesting, placeholder names, type escapes, convention drift, needlessly dense or clever code |
| **Efficiency** | wasted work, missed concurrency, hot-path bloat, no-op updates, leaks |
| **Altitude** | bandaids, symptom-vs-cause, wrong layer, grab-bag files |

## Phase 2 — Reconcile

1. Deduplicate findings on the same span across lenses.
2. Make one edit per span, choosing by this precedence: behavior-preservation > reuse > quality > efficiency > altitude.
3. Apply only findings with **high/med severity at high confidence**.
4. Follow the shape hierarchy. Removal-shaped cleanups (dead code, unused params, redundant state) are the safest and go first. Extract/move/split-shaped findings need a clearly named seam and a payoff now. When in doubt, drop the restructuring and keep the deletion.
5. Drop any remaining Prettier/ESLint-shaped findings.

## Phase 3 — Apply and verify

Make the smallest correct edit. Respect Chesterton's Fence, meaning don't remove something before you know why it is there. Don't strip named concepts or test seams. Keep behavior identical: if a test must change, it is not a cleanup.

**Undo rules:** revert only the **polish-owned** patches from this run, meaning the cleanups you applied. Never run a `git restore` / checkout that wipes user-authored hunks or unrelated dirty work.

**Gate:**

1. If useful, note whether the gate was already failing before your cleanups. For a quick baseline, run it once before applying, or record a known failure. Don't blame pre-existing failures on polish.
2. After applying, read the resulting diff with fresh eyes and revert polish-owned scope creep.
3. Run recon's gate. If you applied nothing and this same tree already passed that gate this session, such as the run `tdd` just finished, cite that result instead of running it twice. Anything you applied means the gate runs, unless the caller passed `skip check`; then report the gate as skipped at the user's request and say what would have run. If a polish cleanup caused a new failure, revert **that** cleanup and continue with the others. If there is no gate, say so.

**Summary.** Write it in the global Communication voice: a few full sentences, answer first. Say what autofix touched, what you cleaned up and why it is safe, what you left alone and why, and anything correctness-shaped that belongs in code review. If nothing was worth changing, say the code was already clean and stop.

```
Autofix reformatted three files. I removed the unused draft state in the editor and swapped a hand-rolled date formatter for the existing helper; both keep behavior identical and the full check passes. I left the two similar upload handlers duplicated because they are likely to diverge. One thing for code review: the retry loop in the uploader never gives up.
```
