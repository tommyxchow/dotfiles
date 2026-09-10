---
name: pass
description: 'End-of-slice closer — recency-check stale-sensitive vendor surfaces, patch leftovers, polish if code-shaped, then a slice-ready report and commit. Structure and cleanliness of pending changes, not a code review. Use when the user says "quick pass", "do a pass", "final pass", "final double check", "close this out", "plug the gaps", "anything else to clean up", or "pass" on its own — never the word mid-sentence (tests pass, pass a prop). When a PR exists for this branch, "final review", "is this ready", and "close out the pr" are the pr skill, not this one. Do not use for a bare status check ("we good", "anything outstanding": answer in a few sentences and offer pass if something looks off), look this up / search online / known issue (that''s vet), whether the code is correct (that''s review), polish/dry-clean, or package catch-up (that''s refresh). Commits when the slice is ready; never pushes.'
argument-hint: "[skip polish | skip check | <focus>]"
---

# Pass

Closes out a finished slice of work and commits it once it is clean. It runs `vet` and `polish` in order and does not rewrite them.

It checks structure, leftovers, cleanliness, and whether anything went stale, then runs the repo's own check. It does not judge whether the change was the right change.

`$ARGUMENTS`: optional `skip polish` / `skip check`, then extra focus. "Quick" is not a skip.

Decide first, then load. Read [../vet/SKILL.md](../vet/SKILL.md) only when step 1 runs. Read [../polish/SKILL.md](../polish/SKILL.md) only when step 3 runs.

## Don't

- Not a code review; that is `review`. Don't hunt bugs, design, or the meaning of the code unless it blocks a pass step (stale API, leftover, polish finding, gate).
- Don't add tests to prove the slice is correct. Don't open a browser to re-prove UI.
- Don't push. Commit only after the report says `✅ Slice ready.`, using the git rules; a `❌ Not yet.` slice stays uncommitted.
- Don't watch CI. Don't write AGENTS.md. Don't start a second task.
- Not a PR-merge checklist. Slice-local. Whole-branch shape is `/polish branch`; whether the branch is ready for review is `pr ready`, which proves the acceptance checklist and runs the whole-PR review. "Slice ready" here means clean and committed, not correct and complete.
- Don't add your own size tiers. Polish decides how much to review by size. Vet decides by what could have gone stale, not by how many files changed.
- Don't hunt unused starter deps or unrelated dead files.

## Steps

1. **Vet.** Decide first, then load.
Skip it (don't read `vet`) when nothing could have gone stale: local logic, copy, a rename, in-repo helpers, or the same pattern as the code next door.
If this session already vetted the same thing, don't vet it again; point at that result. A new vendor API touched since then still gets vetted.
Otherwise follow `vet` on just the parts that could have gone stale: new or changed third-party APIs, version pins, anything chosen because it is "current", "latest", or best practice, and plans pasted from another model. Check installed versions first. A one-file API change still gets vetted; a twenty-file rename does not. Vet may fan out leaf workers; wait for the reconciled answer, then **patch** what was wrong, plus cheap misses inside the slice. Don't wait for approval here; pass is the one place vet's findings get applied straight away.
2. **Leftovers.** Same pattern this slice introduced, in-scope siblings only. Delete APIs/config/docs the change made dead, old paths left beside their replacement, and docs that are now wrong. Delete scratch this slice added (`console.log`, `debugger`, focused-only tests, a summary or notes file nobody asked for). Prose the slice adds or changes (README, docs, changelog, UI copy, error messages) follows the global External writing rules; fix AI tells in place. If the diff looks like it contains a secret, strip or flag — don't install a scanner. If `git status` mixes a second task, stage only the files this slice touched and name the others in the report. A single file holding both this slice's change and the user's own gets named too, not stopped on. The global git rules cover all of it, so a dirty tree is never by itself a reason to stop.
3. **Polish.** If the slice is code-shaped and they didn't pass `skip polish`: follow `polish`. Missing Prettier/ESLint is not a skip — polish skips autofix itself and still runs judgment. Skip only when not code-shaped, or polish already ran this session on those files. Do not skip polish on small TS or Dart. Do not retune polish's size gate.
4. **Slice ready.** Outstanding items or none. If the slice is code and they didn't pass `skip check`: run the repo's own full check; don't invent a gate the repo doesn't have. Skip the gate if polish just ran it, **or** this exact tree already passed the same gate you'd run now this session (cite the prior result). A typecheck is not the full check. If steps 1–3 edited files after that result, re-run. If there is no check, say so. Don't run `review` here or imply that a pass included one. End with `✅ Slice ready.` or `❌ Not yet.` On `✅`, commit the slice and put the hash in the report.

## Distinct from

| Skill                | This skill                                                       |
| -------------------- | ---------------------------------------------------------------- |
| `vet`                | Checks a claim and waits. Pass vets then patches.                |
| `polish`             | Shape only, offline. Pass may call it.                           |
| `review`             | Whether the code works. Pass is structure and cleanliness.       |
| `refresh`            | Package catch-up. Not a slice closer.                            |
| `pr`                 | Branch-level: acceptance evidence, whole-PR review, the draft and ready flip. Pass is one slice, and pr calls it. |
| `tldr`               | Summary. Pass reports slice-ready, it does not recap the session. |

## Report

Follow the global Communication and Session flow rules. Open with `✅ Slice ready.` or `❌ Not yet.` and what the slice does in app terms. Mention meaningful fixes, verification results, and anything outstanding or unverified that affects confidence. Include the commit hash when committed; omit routine skipped-step narration.

```
✅ Slice ready. The settings page now saves the theme choice and remembers it on reload.

I removed the old localStorage helper and combined two duplicate save handlers. The full check passes. Committed as `<hash>`.
```
