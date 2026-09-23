# Polish review checklists

This file has one section per review lens, plus the shared **Finding format** and **Restraint** sections. A review subagent reads its own lens section plus those two shared sections.

## Contents
- [Finding format](#finding-format)
- [Restraint](#restraint)
- [Reuse](#reuse)
- [Quality](#quality)
- [Efficiency](#efficiency)
- [Altitude](#altitude)

---

## Finding format

Return findings only, with no fixes and no prose narration. Report at most ~8, highest-value first. That is a report cap, not a read cap, so still review the whole pool. Write one row per finding:

```
severity | confidence | file:line | finding | cost | proposed fix
```

- **severity**: `high` for real duplication, measurable waste, or a maintenance hazard; `med` for a clear improvement with low stakes; `low` for a stylistic nit. Don't inflate severity.
- **confidence**: `high` when the change is worth doing and behavior-preserving; `med` when it is likely; `low` when it is a guess or the code might be load-bearing. The orchestrator auto-applies only high/med severity at **high** confidence.
- **file:line**: a concrete location. Don't report a finding that rests only on a general impression.
- **cost**: what is duplicated, wasted, or harder to maintain, not "could be cleaner."
- **proposed fix**: the smaller equivalent, named specifically.

A clean result is valid, so don't manufacture findings to fill the table. Don't stop reading because you already have 8 rows.

## Restraint

These rules keep the review from being too eager:

- **Quality only — not bugs.** If any lens finds a correctness defect, return its concrete failure scenario as a review finding for `tdd`. Don't apply its fix as a behavior-preserving cleanup.
- **Preserve behavior.** The same inputs must produce the same outputs, side effects, ordering, and errors. If a test must change, it is not a cleanup.
- **Defer to the toolchain.** Something Prettier/ESLint already handles, or that Phase 0.5 just fixed, is not a finding. That covers spacing/quotes/semis, import order/style, class sort/wrap/whitespace/shorthand nits, unused imports ESLint fixes, and mechanical `import type` ESLint fixes. Spend the review on judgment (reuse, altitude, design-shaped duplication) rather than arguing again with the linter/formatter. If neither tool is runnable in the repo, formatting and import order stay out of scope entirely, so don't hand-fix style.
- **No speculative abstraction.** Don't propose YAGNI generalizations (building for needs the code doesn't have) or defensive layers for impossible cases.
- **Deletion beats restructuring.** Removing code (dead code, unused params, redundant state) is the safest, highest-value cleanup class. Method-level restructuring is where cleanups most often make code worse, so require more of extract/move/split findings than of removals before proposing them.
- **Rule of three for dedupe.** Unify copies only when they encode the same knowledge and the helper has an obvious name. Two similar-looking blocks that could diverge stay duplicated, because duplication is cheaper than the wrong abstraction. A helper that needs boolean flags to serve its callers is the wrong abstraction.
- **Never split for length alone.** Long but linear code reads fine. Extract only at a real seam: a nameable concept with a second caller, or a genuine test/ownership boundary.
- **Chesterton's Fence.** Give an unexplained oddity `low` confidence, and don't claim it is removable.
- **Skip CLI-/generated-owned surfaces** called out in recon (e.g. copy-in `ui/` Prettier ignores) unless the diff intentionally owns them.
- **Baseline taste is subordinate to the repo.** Portable React/TS defaults yield to `AGENTS.md` and the real ESLint/Prettier config. Outside React/TS, skip React-specific taste (Compiler, `useMemo`, JSX nesting, `import type`).

---

## Reuse

**Owns:** new code that re-implements something the codebase already has.
**Out of scope:** internal complexity with no existing equivalent goes to Quality. Novel hot paths go to Efficiency, but still report pure duplicates here.

1. **Existing utility/helper**: shared/util or adjacent modules already do this. Call that instead.
2. **Duplicate function**: a new function is equivalent to an existing one. Call the existing one.
3. **Inline logic with a utility**: hand-rolled path/env/clone/merge/guard logic where an established helper exists. Use the helper.
4. **Semantic duplicate**: same intent as existing code, different implementation, so it does not read as a copy. Examples are a second date formatter with different steps, a second retry loop with its own backoff, or a permission rule spelled a new way. Search by what the code does, not by how it looks. Two implementations of one rule drift, and only one of them gets the next fix.

---

## Quality

**Owns:** unnecessary complexity inside a single unit.
**Out of scope:** an existing helper goes to Reuse, a wrong layer to Altitude, and runtime waste to Efficiency.

1. **Redundant state**: mirrored state, a cached value that could be derived, or an effect that should be a calculation or event handler.
2. **Parameter sprawl & flag args**: another boolean/positional flag. Split, or use an options object.
3. **Copy-paste with slight variation**: near-identical blocks that could be one parameterized helper. The threshold is 3+ occurrences, or 2 that are truly identical and stable (see the rule of three in Restraint).
4. **Leaky abstraction**: code that exposes internals or reaches past a module's public surface.
5. **Stringly-typed / magic values**: raw strings/numbers where a string union, `as const` object, or named constant fits. Prefer house style. Many repos ban `enum`, so don't propose `enum` when recon/lint forbids it.
6. **Unnecessary JSX nesting**: a wrapper that adds no layout/accessibility value.
7. **Nested conditionals**: nesting 3+ deep. Use guards, early returns, or a lookup table.
8. **Unnecessary comments**: a comment that narrates *what*, a docblock that repeats the signature, section dividers, and leftover notes about the task. Keep comments that give a non-obvious *why*.
9. **Dead code**: unreachable, unused, or commented-out orphans from this change; an old path left beside its replacement; compatibility re-exports for callers in this repo. Skip unused imports if the linter already fixes them.
10. **Type escapes**: casual `any` / `as` / `!` where a real type or narrowing works. Deep type design goes to code review.
11. **Convention drift**: code that ignores the patterns found in recon (naming, errors, layout). Name the existing example it should match.
12. **Guards for impossible cases**: null checks on non-nullable values, a try/catch that only rethrows or swallows, and "just in case" fallbacks. Delete them and trust the types.
13. **Pass-through wrapper**: a function whose body is one call to another with the same arguments. Call the callee directly.
14. **Placeholder names**: `data`, `result`, `temp`, `item2`, `processData`, or a new `utils`/`helpers` file. Name it for what it is, or move it beside its one caller.
15. **Needlessly dense or clever code**: a chained one-liner, nested ternary, or bitwise trick where a plain few lines with named steps would read at a glance; single-letter or abbreviated names outside a tiny loop; code compressed to save lines rather than to say something. The goal is code a reviewer can read when seeing only this hunk, so expand it. Length added this way is not a finding.

Correctness-shaped checks stay in code review.

---

## Efficiency

**Owns:** wasted runtime work the diff introduces.
**Out of scope:** duplicated source goes to Reuse, and complexity with no runtime cost goes to Quality.
**Respect the framework (recon):** don't manually memoize when a compiler does, and don't hand-roll caches the framework owns.

1. **Unnecessary work**: redundant compute, re-reads, duplicate calls, or N+1.
2. **Missed concurrency**: independent async work awaited serially. Use `Promise.all` (or the house equivalent).
3. **Hot-path bloat**: new blocking work on startup, per request, or per render.
4. **Recurring no-op updates**: writes when nothing changed. Verify that updater callbacks honor same-reference no-ops.
5. **Unnecessary existence checks**: a TOCTOU (time-of-check to time-of-use) `exists` then `read`. Do the operation and handle its errors.
6. **Memory**: unnecessary retention whose removal preserves observable behavior. Leaked listeners, missing lifecycle cleanup, or unbounded growth that changes behavior belong in a correctness finding.
7. **Overly broad operations**: working on a full file/table when one slice suffices.
8. **Import / bundle cost**: a whole library imported for one function, or barrels that hurt client/edge bundles.

---

## Altitude

**Owns:** whether a change sits at the right depth, versus a bandaid or a misplaced special case.
**Out of scope:** local duplication goes to Reuse/Quality. Don't demand abstraction for a real one-off (YAGNI).

1. **Special-case on shared infra**: a narrow carve-out on a general mechanism. Name the general form (param, strategy, lookup).
2. **Symptom vs root cause**: a downstream clamp/re-sort/re-check instead of a fix at the source. Note other consumers at risk.
3. **Wrong layer**: business logic in UI, formatting in the data layer, or scattered env/platform branches. Name the owning layer.
4. **Repeated local workaround**: the Nth try/catch-ignore, retry, or cache-bust. Lift it into a shared mechanism once.
5. **Grab-bag file**: a file that has grown to hold a second, separable concern (a component plus unrelated helpers, several unrelated endpoints, data access beside UI). Split it at the named seam. Length alone is not a finding (see Restraint).
