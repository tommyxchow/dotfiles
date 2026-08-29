---
name: pass
description: End-of-slice closer — recency-check stale-sensitive vendor surfaces, patch leftovers, polish if code-shaped, then a ship-ready report. Structure and cleanliness of pending changes, not a code review. Use when the user says "quick pass", "do a pass", "final pass", "final review", "final double check", "close this out", "plug the gaps", "we good", "anything outstanding", "anything else to clean up", or "pass" on its own — never the word mid-sentence (tests pass, pass a prop). Do not use for look this up / search online / known issue (that's vet), whether the code is correct (that's Bugbot / code review), polish/dry-clean, or package catch-up (that's refresh). Does not commit.
argument-hint: "[skip polish | skip check | <focus>]"
---

# Pass

Closer for a finished slice, usually right before a commit. Sequencer: reuse `vet` and `polish`. Don't rewrite them.

Structure, leftovers, cleanliness, recency, then the repo gate. Not whether the change is the right change.

`$ARGUMENTS`: optional `skip polish` / `skip check`, then extra focus. "Quick" is not a skip.

Decide first, then load. Read [../vet/SKILL.md](../vet/SKILL.md) only when step 1 runs. Read [../polish/SKILL.md](../polish/SKILL.md) only when step 3 runs.

## Don't

- Don't fire on "look this up" / "search online" / "is this still true" / "is anyone else hitting this" / known issue / workaround — that's `vet`.
- Don't fire on "polish" / "dry clean" / "make this less hacky" — that's `polish`.
- Bare "double check" / "verify" that the code is correct is Bugbot / `/review`, not this skill and not `vet`.
- Not a code review. Don't hunt bugs, design, or the meaning of the code unless it blocks a pass step (stale API, leftover, polish finding, gate).
- Don't add tests to prove the slice is correct. Don't open a browser to re-prove UI.
- Don't commit or push as part of the closer. If they also said commit or push, do that **after** the ship-ready report, using the git rules. "We good?" is not permission.
- Don't watch CI. Don't write AGENTS.md. Don't start a second task.
- Not a PR-merge checklist. Slice-local. Whole-branch shape is `/polish branch`.
- Don't run polish again if it already ran this session on the same files.
- Don't add a pass-level trivial/small/large ladder. Polish owns size. Vet scales by stale-sensitive surfaces, not file count.
- Don't hunt unused starter deps or unrelated dead files.

## Steps

1. **Vet.** Decide first, then load.
Skip (don't read `vet`) when nothing could have gone stale: local logic, copy, rename, in-repo helpers, same pattern as next door. One clause: `Vet: skipped (no stale-sensitive surface)`.
If this session already vetted the same surface, don't re-vet; cite it. A new vendor surface since that vet still runs.
Else follow `vet` on those surfaces only (it isolates fetches in a subagent; wait for the section 4 answer, then patch) — new/changed third-party APIs, version pins, "current" / "latest" / best-practice choices, pasted other-model plans. Installed versions first. A 1-file API change still vets; a 20-file rename does not. Then **patch** what was wrong (and cheap in-scope misses). Don't wait for approval — that's the seam.
2. **Leftovers.** Same pattern this slice introduced, in-scope siblings only. Delete APIs/config/docs the change made dead, and docs that are now wrong. Delete scratch this slice added (`console.log`, `debugger`, focused-only tests). If the diff looks like it contains a secret, strip or flag — don't install a scanner. If `git status` mixes a second task, outstanding; don't expand. Stop.
3. **Polish.** If the slice is code-shaped and they didn't pass `skip polish`: follow `polish`. Missing Prettier/ESLint is not a skip — polish skips autofix itself and still runs judgment. Skip only when not code-shaped, or polish already ran this session on those files. Do not skip polish on small TS or Dart. Do not retune polish's size gate.
4. **Ship-ready.** Outstanding items or none. If the slice is code and they didn't pass `skip check`: run the repo's own full check; don't invent a gate the repo doesn't have. Skip the gate if polish just ran it, **or** this exact tree already passed the same gate you'd run now this session (cite the prior result). A typecheck is not the full check. If steps 1–3 edited files after that result, re-run. No check → say so. End with `✅ Ship-ready.` or `❌ Not yet.` Don't commit.

## Distinct from

| Skill                | This skill                                                       |
| -------------------- | ---------------------------------------------------------------- |
| `vet`                | Checks a claim and waits. Pass vets then patches.                |
| `polish`             | Shape only, offline. Pass may call it.                           |
| Bugbot / `/review`   | Meaning of the code. Pass is structure and cleanliness.          |
| `refresh`            | Package catch-up. Not a slice closer.                            |
| `tldr`               | Summary. Pass reports ship-ready, it does not recap the session. |

## Report

`✅ Ship-ready.` or `❌ Not yet` first, in app terms. Then what this pass did: vet outcome and anything patched, leftovers plugged, polish applied or skipped, gate result. Skipped steps stay one clause, not a scoreboard. Outstanding worst-first, unverified, and what I need to do — skip empty parts. No session recap. Don't walk the feature diff unless they asked.
