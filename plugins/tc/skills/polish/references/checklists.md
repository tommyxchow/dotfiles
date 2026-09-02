# Polish review checklists

One section per review lens, plus shared **Finding format** and **Restraint**. A review subagent reads its own lens section plus those two shared sections.

## Contents
- [Finding format](#finding-format)
- [Restraint](#restraint)
- [Reuse](#reuse)
- [Quality](#quality)
- [Efficiency](#efficiency)
- [Altitude](#altitude)

---

## Finding format

Return findings only — no fixes, no prose narration. One row per finding, highest-value first, capped at ~8 (report cap, not a read cap — still review the whole pool):

```
severity | confidence | file:line | finding | cost | proposed fix
```

- **severity** — `high` (real duplication, measurable waste, maintenance hazard) · `med` (clear improvement, low stakes) · `low` (stylistic nit). Don't inflate.
- **confidence** — `high` (worth doing, behavior-preserving) · `med` (likely) · `low` (guess / might be load-bearing). Orchestrator auto-applies only high/med severity at **high** confidence.
- **file:line** — concrete. No vibes-only findings.
- **cost** — what is duplicated, wasted, or harder to maintain — not "could be cleaner."
- **proposed fix** — the smaller equivalent, named specifically.

Clean result is valid — don't manufacture findings to fill the table. Don't stop reading because you already have 8 rows.

## Restraint

Caps eagerness:

- **Quality only — not bugs.** Correctness defect → one line `out-of-scope: route to code review`. Don't launder behavior changes as cleanup.
- **Preserve behavior.** Same inputs → same outputs, side effects, ordering, errors. If a test must change, it's not a cleanup.
- **Defer to the toolchain.** Not a finding if Prettier/ESLint already handle it or Phase 0.5 just fixed it: spacing/quotes/semis, import order/style, class sort/wrap/whitespace/shorthand nits, unused imports ESLint fixes, mechanical `import type` ESLint fixes. Prefer judgment (reuse, altitude, design-shaped duplication) over re-litigating the linter/formatter. If neither tool is runnable in the repo, formatting/import-order stay out of scope entirely (don't hand-fix style).
- **No speculative abstraction.** No YAGNI generalizations, no defensive layers for impossible cases.
- **Deletion beats restructuring.** Removing code (dead code, unused params, redundant state) is the safest, highest-value cleanup class. Method-level restructuring is where cleanups most often make code worse — hold extract/move/split findings to a higher bar than removals.
- **Rule of three for dedupe.** Unify copies only when they encode the same knowledge and the helper has an obvious name. Two similar-looking blocks that could diverge stay duplicated — duplication is cheaper than the wrong abstraction. A helper that needs boolean flags to serve its callers is the wrong abstraction.
- **Never split for length alone.** Long but linear code reads fine. Extract only at a real seam: a nameable concept with a second caller, or a genuine test/ownership boundary.
- **Chesterton's Fence.** Unexplained oddity → `low` confidence, don't assert removable.
- **Skip CLI-/generated-owned surfaces** called out in recon (e.g. copy-in `ui/` Prettier ignores) unless the diff intentionally owns them.
- **Baseline taste is subordinate to the repo.** Portable React/TS defaults yield to `AGENTS.md` and real ESLint/Prettier config. Outside React/TS, skip React-specific taste (Compiler, `useMemo`, JSX nesting, `import type`).

---

## Reuse

**Owns:** new code that re-implements something the codebase already has.
**Out of scope:** internal complexity with no existing equivalent → Quality. Novel hot paths → Efficiency (still report pure duplicates here).

1. **Existing utility/helper** — shared/util or adjacent modules already do this → call that.
2. **Duplicate function** — new function ≡ existing → call existing.
3. **Inline logic with a utility** — hand-rolled path/env/clone/merge/guard → established helper.

---

## Quality

**Owns:** unnecessary complexity inside a single unit.
**Out of scope:** existing helper → Reuse; wrong layer → Altitude; runtime waste → Efficiency.

1. **Redundant state** — mirrored state, cached derivable value, effect that should be a calculation or event handler.
2. **Parameter sprawl & flag args** — another boolean/positional flag → split or options object.
3. **Copy-paste with slight variation** — near-identical blocks → one parameterized helper. Gate: 3+ occurrences, or 2 that are truly identical and stable (see Restraint — rule of three).
4. **Leaky abstraction** — exposing internals or reaching past a module's public surface.
5. **Stringly-typed / magic values** — raw strings/numbers where a string union, `as const` object, or named constant fits. Prefer house style; many repos ban `enum` — don't propose `enum` when recon/lint forbids it.
6. **Unnecessary JSX nesting** — wrapper adds no layout/accessibility value.
7. **Nested conditionals** — 3+ deep → guards, early returns, or lookup table.
8. **Unnecessary comments** — narrates *what*, a docblock that repeats the signature, section dividers, task crumbs. Keep non-obvious *why*.
9. **Dead code** — unreachable, unused, commented-out orphans from this change; an old path left beside its replacement; compatibility re-exports for callers in this repo. (Skip unused imports if the linter already fixes them.)
10. **Type escapes** — casual `any` / `as` / `!` where a real type or narrow works. Deep type design → code review.
11. **Convention drift** — ignores recon patterns (naming, errors, layout). Name the exemplar.
12. **Guards for impossible cases** — null checks on non-nullable values, try/catch that only rethrows or swallows, "just in case" fallbacks → delete and trust the types.
13. **Pass-through wrapper** — a function whose body is one call to another with the same arguments → call the callee directly.
14. **Placeholder names** — `data`, `result`, `temp`, `item2`, `processData`, a new `utils`/`helpers` file → name it for what it is, or move it beside its one caller.

Correctness-shaped checks stay in code review.

---

## Efficiency

**Owns:** wasted runtime work the diff introduces.
**Out of scope:** duplicated source → Reuse; complexity with no runtime cost → Quality.
**Respect the framework (recon):** don't manually memoize when a compiler does; don't hand-roll caches the framework owns.

1. **Unnecessary work** — redundant compute, re-reads, duplicate calls, N+1.
2. **Missed concurrency** — independent async awaited serially → `Promise.all` (or house equivalent).
3. **Hot-path bloat** — new blocking work on startup / per-request / per-render.
4. **Recurring no-op updates** — writes when nothing changed; verify updater callbacks honor same-reference no-ops.
5. **Unnecessary existence checks** — TOCTOU `exists` then `read` → operate and handle errors.
6. **Memory** — unbounded structures, missing cleanup, leaked listeners; closures pinning huge scopes.
7. **Overly broad operations** — full file/table when one slice suffices.
8. **Import / bundle cost** — whole library for one function; barrels that hurt client/edge bundles.

---

## Altitude

**Owns:** right depth vs bandaid / misplaced special case.
**Out of scope:** local duplication → Reuse/Quality. Don't demand abstraction for a real one-off (YAGNI).

1. **Special-case on shared infra** — narrow carve-out on a general mechanism → name the general form (param, strategy, lookup).
2. **Symptom vs root cause** — downstream clamp/re-sort/re-check instead of fixing the source; note other consumers at risk.
3. **Wrong layer** — business logic in UI, formatting in data layer, scattered env/platform branches → name the owning layer.
4. **Repeated local workaround** — Nth try/catch-ignore, retry, or cache-bust → lift into shared mechanism once.
5. **Grab-bag file** — a file grown to hold a second, separable concern (a component plus unrelated helpers, several unrelated endpoints, data access beside UI) → split at the named seam. Length alone is not a finding (see Restraint).
