# Polish review checklists

One section per review lens, plus the shared **Finding format** and **Restraint** rules every lens obeys. A review subagent reads its own lens section plus those two shared sections.

## Contents
- [Finding format](#finding-format) — the output schema (all lenses)
- [Restraint](#restraint) — eagerness cap (all lenses)
- [Reuse](#reuse)
- [Quality](#quality)
- [Efficiency](#efficiency)
- [Altitude](#altitude)

---

## Finding format

Return findings only — no fixes, no prose narration. One row per finding, highest-value first, capped at ~8. Use this exact schema:

```
severity | confidence | file:line | finding | cost | proposed fix
```

- **severity** — `high` (real duplication, measurable waste, or a maintenance hazard) · `med` (clear improvement, low stakes) · `low` (stylistic nit). Be honest; inflating severity defeats the gate.
- **confidence** — `high` (sure it's worth doing and behavior-preserving) · `med` (likely, would want a glance) · `low` (a guess / might be load-bearing). The orchestrator only auto-applies high/med severity at high confidence.
- **file:line** — concrete location. No vibes-only findings.
- **cost** — the concrete reason it matters: what is duplicated, wasted, or harder to maintain. Not "this could be cleaner."
- **proposed fix** — the smaller form that does the same job, named specifically (the existing helper to call, the derived value to use, the guard to add).

If a lens finds nothing worth surfacing, say so. A clean result is a valid result — do not manufacture findings to fill the table.

## Restraint

You are tuned to find cleanups; these cap eagerness so the orchestrator isn't handed noise:

- **Quality only — not bugs.** If you spot a correctness defect (a real null deref, a race, a wrong result), note it in one line as `out-of-scope: route to /code-review` and move on. Do not propose a behavior-changing "fix" as a cleanup.
- **Preserve behavior.** Every finding must be behavior-identical: same inputs → same outputs, side effects, ordering, and error paths. If a fix would require editing a test to stay green, it is not a cleanup.
- **Defer to the toolchain.** Anything the linter/formatter already handles (spacing, import order, quote style) is not a finding.
- **No speculative abstraction.** Don't demand a generalization for a genuine one-off (YAGNI). Don't add layers, defensive code, or tests for cases that can't happen.
- **Respect Chesterton's Fence.** If code looks odd but you can't explain why it's there (perf, platform, ordering, a past bug), flag it `low` confidence rather than asserting it's removable.

---

## Reuse

**Owns:** new code that re-implements something the codebase already has.
**Out of scope (defer to sibling):** internal complexity of new code with no existing equivalent → Quality. Performance of a duplicate → still report here as reuse; let Efficiency own genuinely novel hot paths.

1. **Existing utility/helper** — Grep shared/util modules and files adjacent to the change for a function that already does this. Name the helper to call instead.
2. **Duplicate function** — a new function that does what an existing one does → call the existing one.
3. **Inline logic with a utility** — hand-rolled string slicing, manual path joining, custom `process.env` checks, ad-hoc type guards, bespoke deep-clone/merge → replace with the established helper.

## Quality

**Owns:** unnecessary complexity the diff adds within a single unit of code.
**Out of scope (defer to sibling):** reusing an existing helper → Reuse; wrong-layer / bandaid placement → Altitude; wasted runtime work → Efficiency.

1. **Redundant state** — state mirroring other state, a cached value you could derive, an effect/observer that could be a direct call.
2. **Parameter sprawl & flag args** — bolting another arg onto a function instead of restructuring or grouping; opaque boolean/positional flags at the call site (`fn(x, true, false)`) that would read better split or as an options object.
3. **Copy-paste with slight variation** — near-identical blocks differing by one value → unify behind one parameterized helper.
4. **Leaky abstraction** — exposing internals a caller shouldn't see, or reaching past a module's public surface.
5. **Stringly-typed / magic values** — raw string literals or magic numbers where a string-union, enum, or named constant already exists or should.
6. **Unnecessary JSX nesting** — wrapper `div`/`Box` adding no layout value because the child already takes `className`/style/`flexShrink` props.
7. **Nested conditionals** — ternary chains or if/else/switch nested 3+ deep → flatten with early returns, guard clauses, or a lookup table.
8. **Unnecessary comments** — comments narrating *what* the code does or referencing the task ("now loop over users"). Keep only non-obvious *why* (constraints, workarounds, invariants).
9. **Dead code** — unreachable branches, unused imports/vars/params/functions, commented-out blocks the change orphaned.
10. **Type escapes (typed languages)** — `any`, unsafe `as` casts, or `!` non-null assertions added where a real type, narrowing, or guard would do. (Deep type *design* is `/code-review`'s; flag only the casual escape hatch.)
11. **Convention drift** — new code that ignores the repo's established patterns from recon (naming, error-handling shape, file layout, import style). Name the existing exemplar to match.

> Note: correctness-shaped checks (asymmetric guard application, bash-in-CI working-directory contracts) deliberately live in `/code-review`, not here — they find bugs, not cleanups.

## Efficiency

**Owns:** wasted runtime work the diff introduces.
**Out of scope (defer to sibling):** duplicated *source* → Reuse; structural complexity with no runtime cost → Quality.
**Respect the framework (from recon):** don't optimize what the framework, compiler, or runtime already handles — manual memoization where a compiler does it, hand-rolled caching where the framework caches, polyfills the runtime ships. Recon says what's owned. (React Compiler memoization is one example, not the only one.)

1. **Unnecessary work** — redundant computation, re-reading a file, duplicate API calls, N+1 patterns.
2. **Missed concurrency** — independent async ops `await`ed serially when they could `Promise.all`.
3. **Hot-path bloat** — new blocking work added to startup or a per-request/per-render path.
4. **Recurring no-op updates** — store/state writes inside a poll loop or handler that fire even when nothing changed → add a change-detection guard. If a wrapper takes an updater callback, verify it honors same-reference "no change" returns, or callers' early-return no-ops are silently defeated.
5. **Unnecessary existence checks** — `if (exists(x)) read(x)` (TOCTOU) → operate directly and handle the error.
6. **Memory** — unbounded structures, missing cleanup, leaked listeners. Also long-lived objects built from closures that pin the whole enclosing scope alive → prefer a struct copying only the fields it needs.
7. **Overly broad operations** — reading a whole file for one section, loading all rows to filter for one.
8. **Import / bundle cost** — pulling a whole library for one function (`import _ from 'lodash'` → a named import or a few local lines), or barrel-file imports that defeat tree-shaking. Matters most for client/edge bundles.

## Altitude

**Owns:** whether each change is at the right depth, or patched as a fragile bandaid / misplaced special case.
**Out of scope (defer to sibling):** local duplication → Reuse/Quality. Only flag where generalizing is clearly worth it near the diff (YAGNI — don't demand abstraction for a real one-off).

1. **Special-case on shared infra** — a narrow `if (x === specificCase)` carve-out bolted onto a general mechanism (base class, shared util, render pipeline). If that input class will keep needing carve-outs, name the general form (a parameter, a strategy/lookup, an honester abstraction) the carve-out stands in for.
2. **Symptom vs. root cause** — a fix applied *downstream* of the real problem (clamping, re-normalizing, re-sorting, defensive re-checks) instead of fixing the source. Flag when the same defect could recur at every other consumer, and point at the upstream site that should own it.
3. **Wrong layer** — business logic in a presentation component, formatting in the data layer, environment/platform branches scattered across call sites instead of behind one boundary. Name the layer that should own it.
4. **Repeated local workaround** — the Nth copy of the same compensating pattern (try/catch-and-ignore, retry, manual cache-bust) at yet another call site. The recurrence is the signal the underlying mechanism is missing → propose lifting it into the shared layer once.
