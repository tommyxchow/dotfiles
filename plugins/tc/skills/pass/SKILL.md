---
name: pass
description: 'Closes and commits a finished slice: vet stale-sensitive choices, remove leftovers, polish code, and run the repo check. Use for quick pass, final pass, final double check, close this out, plug the gaps, or pass on its own, not mid-sentence. PR readiness goes to pr; correctness to review; code shape to polish; current facts to vet; packages to refresh. A bare status check uses known results and git status. Never pushes or substitutes for the final task review.'
argument-hint: "[skip polish | skip check | <focus>]"
---

# Pass

Prepares and commits a finished slice. The global completion rule owns acceptance and final correctness review; a pass supplies cleanup and check evidence, not proof that the whole task is complete.

`$ARGUMENTS`: optional `skip polish` / `skip check`, then extra focus. "Quick" is not a skip.

Decide first, then load. Read [../vet/SKILL.md](../vet/SKILL.md) only when step 1 runs. Read [../polish/SKILL.md](../polish/SKILL.md) only when step 3 runs.

## Don't

- Not a code review; that is `review`. Don't hunt bugs, design, or the meaning of the code unless it blocks a pass step (stale API, leftover, polish finding, gate).
- Don't add tests to prove the slice is correct. Don't open a browser to re-prove UI.
- Don't push. Commit only after the report says `✅ Slice ready.`, using the git rules; a `❌ Not yet.` slice stays uncommitted.
- Don't watch CI. Don't write AGENTS.md. Don't start a second task.
- Stay slice-local. `pr check` reports PR readiness; `pr ready` also has approval to flip the draft. "Slice ready" here means clean enough to commit, not a claim that the whole task is correct and complete.
- Don't add your own size tiers. Polish decides how much to review by size. Vet decides by what could have gone stale, not by how many files changed.
- Don't hunt unused starter deps or unrelated dead files.

## Steps

1. **Vet.** Decide first, then load.
Skip it (don't read `vet`) when nothing could have gone stale: local logic, copy, a rename, in-repo helpers, or the same pattern as the code next door.
If this session already vetted the same thing, don't vet it again; point at that result. A new vendor API touched since then still gets vetted.
Otherwise follow `vet` on just the parts that could have gone stale: new or changed third-party APIs, version pins, anything chosen because it is "current", "latest", or best practice, and plans pasted from another model. Check installed versions first. A one-file API change still gets vetted; a twenty-file rename does not. Vet may fan out leaf workers; wait for the reconciled answer, then **patch** what was wrong, plus cheap misses inside the slice. Don't wait for approval here; pass is the one place vet's findings get applied straight away.
2. **Leftovers.** In-scope siblings only: remove APIs/config/docs made dead, old paths left beside replacements, and scratch this slice added (`console.log`, `debugger`, focused-only tests, unasked notes). Fix stale prose under the global External writing rules. If the diff looks like it contains a secret, strip or flag it without installing a scanner. Follow the global change-ownership rule for mixed files and staged work; unrelated dirt alone is not a blocker. Report any discovered correctness issue to the owning build workflow rather than silently treating it as cleanup.
3. **Polish.** If the slice is code-shaped and they didn't pass `skip polish`: follow `polish`, handing it this slice's files as its whole pool rather than its session-wide default, and passing `skip check` through when the user gave it so polish's gate reports skipped instead of running. Missing Prettier/ESLint is not a skip — polish skips autofix itself and still runs judgment. Skip only when not code-shaped, or polish already ran this session on those files. Do not skip polish on small TS or Dart. Do not retune polish's size gate.
4. **Slice ready.** Outstanding items or none. If the slice is code and they didn't pass `skip check`: run the repo's own full check; don't invent a gate the repo doesn't have. Skip the gate if polish just ran it, **or** this exact tree already passed the same gate you'd run now this session (cite the prior result). A typecheck is not the full check. If steps 1–3 edited files after that result, re-run. If there is no check, say so. Don't run `review` here or imply that a pass included one. End with `✅ Slice ready.` or `❌ Not yet.` On `✅`, commit the slice and put the hash in the report.

## Report

Follow the global Communication and Session flow rules. Open with `✅ Slice ready.` or `❌ Not yet.` and what the slice does in app terms. Mention meaningful fixes, verification results, and anything outstanding or unverified that affects confidence. Include the commit hash when committed; omit routine skipped-step narration.

```
✅ Slice ready. The settings page now saves the theme choice and remembers it on reload.

I removed the old localStorage helper and combined two duplicate save handlers. The full check passes. Committed as `<hash>`.
```
