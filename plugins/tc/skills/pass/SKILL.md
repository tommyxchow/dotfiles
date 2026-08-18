---
name: pass
description: End-of-slice closer — vet checkable claims in the diff, patch Wrong/Partly, plug in-scope leftovers, polish if the slice is JS/TS-shaped, then a ship-ready report. Use when the user says "pass", "final pass", "final review", "final double check", "close this out", "plug the gaps", "we good", "anything outstanding", or "anything else to clean up". Do not use for bare "double check", "verify", or "look this up" (that's vet), polish/dry-clean, or package catch-up (that's refresh). Does not commit.
argument-hint: "[skip polish | skip check | <focus>]"
---

# Pass

Closer for a finished slice. Sequencer: reuse `vet` and `polish`. Don't rewrite them.

`$ARGUMENTS`: optional `skip polish` / `skip check`, then extra focus.

Read and follow sibling [../vet/SKILL.md](../vet/SKILL.md) for step 1. Read and follow [../polish/SKILL.md](../polish/SKILL.md) for step 3 when polish runs.

## Don't

- Don't fire on bare "double check" / "verify" / "look this up" / "search online" — that's `vet`.
- Don't fire on "polish" / "dry clean" / "make this less hacky" — that's `polish`.
- Don't commit or push as part of the closer. If they also said commit or push, do that **after** the ship-ready report, using the git rules. "We good?" is not permission.
- Don't watch CI. Don't write AGENTS.md. Don't start a second task.
- Not a PR-merge checklist. Slice-local, usually right before they ask to commit. Whole-branch shape is `/polish branch`; bugs are code review / Bugbot.
- Don't run polish again if it already ran this session on the same files.
- Don't hunt unused starter deps or unrelated dead files.

## Steps

1. **Vet.** Follow `vet` on checkable claims in the diff (installed versions first). If the last few messages pasted another model's plan ("chatgpt said", "wdyt"), audit that too. Then **patch** Wrong/Partly (and cheap in-scope Missing). Don't wait for approval — that's the seam.
2. **Leftovers.** Same pattern this slice introduced, in-scope siblings only. Delete APIs/config/docs the change made dead. Stop.
3. **Polish.** If the slice is code-shaped and they didn't pass `skip polish`: follow `polish` when Prettier or ESLint is in the repo, or they asked to polish. Otherwise skip.
4. **Ship-ready.** Outstanding items or none. Repo gate if the slice is code and they didn't pass `skip check`: `pnpm check`, else `flutter analyze` + tests, else say so. Skip the gate if polish just ran it. End with ship-ready yes/no. Don't commit.

## Distinct from

| Skill | This skill |
|---|---|
| `vet` | Checks a claim and waits. Pass vets then patches. |
| `polish` | Shape only, offline. Pass may call it. |
| `refresh` | Package catch-up. Not a slice closer. |
| `tldr` | Summary. Pass reports ship-ready, it does not recap the session. |

## Report

Brief. Worst first. No recap.
