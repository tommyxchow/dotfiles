---
name: polish
description: Deliberate, thorough cleanup review — four parallel read-only lens agents (reuse, quality, efficiency, altitude) over the changed code, then apply only the high-confidence cleanups behind a verify gate. Heavier than the built-in /simplify, which is a quick inline tidy — prefer /simplify for casual "clean this up" asks. Use polish when asked to "polish", "polish this", "dry clean", "make this less hacky", "reduce duplication", or for a thorough final cleanup pass over current changes before committing. Quality only; it does not hunt correctness bugs (that is /code-review's job). Reviews the union of git changes and files edited this session, across repos.
argument-hint: "[staged | unstaged | branch | all | <focus>]"
---

# Polish — parallel cleanup review

Review the changed code for **reuse, quality, efficiency, and altitude**, then apply the cleanups that are clearly worth it. You are improving the *shape* of working code, not finding bugs — correctness is `/code-review`'s job, and a "cleanup" that would change behavior is out of scope here.

The flow is a breadth-first fan-out (four independent read-only lenses over one shared diff) followed by a single reconcile-and-apply pass you run yourself. Optimize for **precision, not recall**: a short list of cleanups a senior would actually accept beats a long list of nitpicks. A noisy cleanup pass gets ignored.

## Phase 0 — Scope and recon

Build the review pool from the **union** of two sources — sessions span repos and commit mid-flow, so include both every time:

- **Source A — git changes** in the CWD repo. Pick by argument: `staged` → `git diff --cached`; `unstaged` → `git diff`; `branch`/`all` → `git diff @{upstream}...HEAD` (fall back to `git diff main...HEAD`) plus `git diff` if the tree is dirty; no keyword → `git diff HEAD` if anything is staged, else `git diff`. Enumerate untracked files with `git status --short` and read their contents (diff won't show new files).
- **Source B — session-edited files.** Any file you edited earlier this conversation via Edit/Write, in any repo. Scroll your tool history to enumerate them (concrete, not from memory) and read each from disk. These often live outside the CWD — pass them with **absolute paths** and do not `git diff` them.

If both are empty, fall back to files the user explicitly named in recent messages (read them from disk); if there are none, ask what to review rather than guessing.

**Recon (cheap, high-leverage):** read the repo's `AGENTS.md` / `CLAUDE.md` (esp. a "Gotchas" / conventions section) so findings weight to house style instead of generic best practice. This is where **stack-specific** rules live — keep them in the project, not hardcoded in this skill — and where you learn what the framework, compiler, or runtime already handles (a compiler that memoizes, a framework that caches, typed routes) so a lens doesn't "fix" something the toolchain owns. Note the verification command (e.g. `pnpm check`, or the narrowest relevant `pnpm --filter <pkg> test <path>`).

**Phase 0 exit — size gate.** Decide the path before launching anything: if the change is trivial (a line or two, one file), skip the fan-out and run the lenses inline — walk the four lens checklists in `references/checklists.md` against the diff yourself, then apply anything worth fixing with the Phase 3 guards and run the verify gate. Four parallel agents cost ~15× a normal turn and aren't worth it for a typo. Otherwise continue to the four lenses. For a very large diff, shard a lens across file groups (two reuse agents over different dirs) rather than making one agent read everything.

## Phase 1 — Four review lenses (parallel, read-only)

Launch **four read-only review subagents** in a single message so they run concurrently — in Claude Code use **Explore** agents (read-only by construction; they propose, you apply). Optionally run them in the background so the user can keep working; resume to Phase 2 once all four return.

Subagents do **not** inherit this skill's context. Give each one:

- the **scope** (the diff plus Source-B absolute paths),
- the **absolute path** to `references/checklists.md` and which sections to read: **its own lens section** plus the shared **"## Finding format"** and **"## Restraint"** sections (if the path might not resolve in the subagent, paste all three inline — the lens section too, not just the shared pair; the lens table below is a summary, not a substitute for the section),
- the **recon facts** (languages, frameworks, the repo conventions to honor) and any **free-text focus** from the argument,
- an explicit **owned scope and out-of-scope** line (each lens defers overlaps to its sibling — see the checklist), and
- the instruction to **return findings only, in the schema, no fixes, no narration**, capped at the highest-value ~8.

The four lenses (details and per-lens boundaries in `references/checklists.md`):

| Lens | Owns |
|---|---|
| **Reuse** | new code that re-implements an existing helper/util |
| **Quality** | redundant state, copy-paste variation, dead code, nested conditionals, needless JSX wrappers, stringly-typed, type escapes |
| **Efficiency** | wasted work, missed concurrency, hot-path bloat, no-op updates, leaks |
| **Altitude** | bandaid fixes — special-cases on shared infra, symptom-not-cause, wrong layer |

Write the prompts plainly — **do not** say "find ALL issues" or "be thorough"; that language measurably adds noise. Ask for what's clearly worth acting on, and let the Restraint section cap eagerness.

## Phase 2 — Reconcile and gate

Once all four return, **before touching code**:

1. **Dedup on span.** The lenses overlap (reuse vs. altitude especially). Collapse findings that point at the same `file:line`/mechanism into one.
2. **Resolve conflicts.** If two lenses propose different edits for the same location, pick one — never hand yourself two conflicting edits for one span. Priority when they clash: behavior-preservation > reuse > quality > efficiency > altitude.
3. **Severity + confidence gate.** Each finding carries `severity` and `confidence` (see schema). Apply only **high/med severity at high confidence**. Demote the rest to a "noted, skipped" list with the reason. **Defer to the toolchain:** anything ESLint/Prettier already handles is not a finding.

## Phase 3 — Apply and verify

Apply each surviving finding with the **smallest correct edit**, preserving existing style. Guards (this is where you exercise restraint — the agents are tuned to *find*, you decide what's worth it):

1. **Chesterton's Fence** — before deleting/inlining/merging, work out why it exists (perf, platform, ordering, a past bug); `git blame` when intent is unclear. Can't explain it → skip.
2. **Don't over-simplify** — don't inline a helper that names a useful concept, merge unrelated functions, or strip an abstraction that exists for testability. Fewer lines isn't the goal; easier comprehension is.
3. **Behavior must stay identical** — if a cleanup would require editing a test to stay green, it changed behavior, not shape. Skip it (or hand it to `/code-review`).

After applying:

- **Fresh-eyes verify.** Have a fresh-context subagent (or a clean read) review the *resulting* diff against the original intent — does anything outside the intended scope change? Report and revert scope creep.
- **Run the gate.** Run the verification command from recon at the narrowest relevant scope (e.g. `pnpm --filter <pkg> test <path>`, or the repo's full check for broad changes) to confirm behavior is preserved. Behavior preservation is proven by the gate, not asserted. **If the gate fails, revert the offending edit** — cleanups are independent, so one bad fix shouldn't sink the rest — and move it to the skipped list. If the repo has no usable gate, say so and flag the applied cleanups for manual review.

Finish with a brief summary: what was applied, what was skipped and why (or confirm the code was already clean).

## Argument routing

The argument is `$ARGUMENTS` (empty on a bare `/polish`). Parse it:

- **A leading scope keyword** (`staged`/`unstaged`/`branch`/`all`) selects the Phase 0 diff.
- **Any remaining words** — or the whole argument when it isn't a scope keyword — are an **Additional Focus**; pass them verbatim to every lens so findings weight toward that area (so `branch auth` means scope `branch`, focus "auth").
- **Empty** → default scope, no focus weighting.

## Note on posted text

Fix descriptions, the summary, and agent prompts are in-session output. Only text destined for a **posted artifact** (commit message, PR body) follows the global writing rules in `CLAUDE.md` (no em dashes, lowercase teammate voice, lead with the specific change).
