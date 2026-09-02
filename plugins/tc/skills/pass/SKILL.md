---
name: pass
description: End-of-slice closer — recency-check stale-sensitive vendor surfaces, patch leftovers, polish if code-shaped, then a ship-ready report. Structure and cleanliness of pending changes, not a code review. Use when the user says "quick pass", "do a pass", "final pass", "final review", "final double check", "close this out", "plug the gaps", "anything else to clean up", or "pass" on its own — never the word mid-sentence (tests pass, pass a prop). Do not use for a bare status check ("we good", "anything outstanding": answer in a few sentences and offer pass if something looks off), look this up / search online / known issue (that's vet), whether the code is correct (that's review), polish/dry-clean, or package catch-up (that's refresh). Does not commit.
argument-hint: "[skip polish | skip check | <focus>]"
---

# Pass

Closes out a finished slice of work, usually right before a commit. It runs `vet` and `polish` in order and does not rewrite them.

It checks structure, leftovers, cleanliness, and whether anything went stale, then runs the repo's own check. It does not judge whether the change was the right change.

`$ARGUMENTS`: optional `skip polish` / `skip check`, then extra focus. "Quick" is not a skip.

Decide first, then load. Read [../vet/SKILL.md](../vet/SKILL.md) only when step 1 runs. Read [../polish/SKILL.md](../polish/SKILL.md) only when step 3 runs.

## Don't

- Not a code review; that is `review`. Don't hunt bugs, design, or the meaning of the code unless it blocks a pass step (stale API, leftover, polish finding, gate).
- Don't add tests to prove the slice is correct. Don't open a browser to re-prove UI.
- Don't commit or push as part of the closer. If they also said commit or push, do that **after** the ship-ready report, using the git rules. "Final pass" is not permission.
- Don't watch CI. Don't write AGENTS.md. Don't start a second task.
- Not a PR-merge checklist. Slice-local. Whole-branch shape is `/polish branch`.
- Don't add your own size tiers. Polish decides how much to review by size. Vet decides by what could have gone stale, not by how many files changed.
- Don't hunt unused starter deps or unrelated dead files.

## Steps

1. **Vet.** Decide first, then load.
Skip it (don't read `vet`) when nothing could have gone stale: local logic, copy, a rename, in-repo helpers, or the same pattern as the code next door. Say so in one sentence in the report, such as "Nothing here touches a vendor API, so I skipped vet."
If this session already vetted the same thing, don't vet it again; point at that result. A new vendor API touched since then still gets vetted.
Otherwise follow `vet` on just the parts that could have gone stale: new or changed third-party APIs, version pins, anything chosen because it is "current", "latest", or best practice, and plans pasted from another model. Check installed versions first. A one-file API change still gets vetted; a twenty-file rename does not. Vet runs its fetches in a subagent, so wait for its answer, then **patch** what was wrong, plus cheap misses inside the slice. Don't wait for approval here; pass is the one place vet's findings get applied straight away.
2. **Leftovers.** Same pattern this slice introduced, in-scope siblings only. Delete APIs/config/docs the change made dead, old paths left beside their replacement, and docs that are now wrong. Delete scratch this slice added (`console.log`, `debugger`, focused-only tests, a summary or notes file nobody asked for). Prose the slice adds or changes (README, docs, changelog, UI copy, error messages) follows the global External writing rules; fix AI tells in place. If the diff looks like it contains a secret, strip or flag — don't install a scanner. If `git status` mixes a second task, outstanding; don't expand. Stop.
3. **Polish.** If the slice is code-shaped and they didn't pass `skip polish`: follow `polish`. Missing Prettier/ESLint is not a skip — polish skips autofix itself and still runs judgment. Skip only when not code-shaped, or polish already ran this session on those files. Do not skip polish on small TS or Dart. Do not retune polish's size gate.
4. **Ship-ready.** Outstanding items or none. If the slice is code and they didn't pass `skip check`: run the repo's own full check; don't invent a gate the repo doesn't have. Skip the gate if polish just ran it, **or** this exact tree already passed the same gate you'd run now this session (cite the prior result). A typecheck is not the full check. If steps 1–3 edited files after that result, re-run. If there is no check, say so. If `review` has not run on this slice this session, say so in one sentence; don't run it here. End with `✅ Ship-ready.` or `❌ Not yet.` Don't commit.

## Distinct from

| Skill                | This skill                                                       |
| -------------------- | ---------------------------------------------------------------- |
| `vet`                | Checks a claim and waits. Pass vets then patches.                |
| `polish`             | Shape only, offline. Pass may call it.                           |
| `review`             | Whether the code works. Pass is structure and cleanliness.       |
| `refresh`            | Package catch-up. Not a slice closer.                            |
| `tldr`               | Summary. Pass reports ship-ready, it does not recap the session. |

## Report

Write it in the global Communication voice: full sentences, answer first. Open with `✅ Ship-ready.` or `❌ Not yet.` and one sentence on what the slice does in app terms. Then say what this pass did: what vet found and what you patched, which leftovers you removed, whether polish ran or why it didn't, and what the repo check said. A skipped step gets one sentence, not a scoreboard row. Then anything still outstanding, worst first, anything unverified, and anything I need to do. Skip empty parts. Don't recap the session and don't walk the feature diff unless they asked.

```
✅ Ship-ready. The settings page now saves the theme choice and remembers it on reload.

Vet checked the storage API against the installed version and it was current, so nothing to patch. I removed a leftover console.log and the old localStorage helper the change replaced. Polish folded two duplicate save handlers into one. The full check passes. Review hasn't run on this slice.

Nothing outstanding.
```
