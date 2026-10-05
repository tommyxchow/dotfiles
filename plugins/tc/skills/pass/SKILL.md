---
name: pass
metadata:
  opencode/slash: "true"
description: 'Closes and commits a finished slice: apply the confirmed findings of a review that ran this session, vet stale-sensitive choices, remove leftovers, polish code, and run the repo check. Use for quick pass, final pass, close this out (no PR open), plug the gaps, `finalize`, or pass on its own, not mid-sentence. `quick` keeps the findings and the local check and trims vet and polish to essentials. `finalize` is the final step: the full review in a fresh context first (it reports; `pr check` when the local head matches an open PR with nothing pending), then this; "final double check", "review and pass", "review/pass", or "pass/review", with or without final, mean the same. PR readiness goes to pr; correctness to review; code shape to polish; current facts to vet; packages to refresh. A bare status check uses known results and git status. Never pushes or substitutes for the final task review.'
argument-hint: "[quick] [skip polish | skip check | <focus>]"
---

# Pass

Prepares and commits a finished slice. The global completion rule is responsible for acceptance and the final correctness review. A pass applies what that review confirmed and supplies cleanup and check evidence; it is not proof that the whole task is complete.

`$ARGUMENTS` can hold an optional `quick`, an optional `skip polish` / `skip check`, and then any extra focus. `quick` is the lighter run marked in the steps, not a skip: the findings and the local check stay.

Under `finalize`, or review and pass in either order, the review skill's final review runs first as its last section says, and these steps then apply what it confirmed; the "don't run a review here" lines below mean inside the pass steps, not that one.

Decide which steps run first, then load only what they need. Read [../vet/SKILL.md](../vet/SKILL.md) only when step 2 runs. Read [../polish/SKILL.md](../polish/SKILL.md) only when step 4 runs.

## Don't

- A pass is not a code review; that is `review`. Don't look for bugs or examine the design or the meaning of the code unless it blocks a pass step, such as a stale API, a leftover, a polish finding, or the gate. Step 1 applies findings a review already confirmed, which is not bug hunting.
- Don't add tests to prove the slice is correct. The only new tests are step 1's.
- Don't push.
- Commit only after the report says `✅ Ready to commit.`, following the git rules. A `❌ Not yet.` slice stays uncommitted.
- Stay within this slice. Here, "Ready to commit" means the slice is clean enough to commit. It is not a claim that the whole task is correct and complete.
- Don't add your own size tiers. Polish decides how much to review by size. Vet decides by what could have gone stale, not by how many files changed. `quick` is the one tier this skill sets, and it hands the same word to polish.
- Don't look for unused starter dependencies or unrelated dead files.

## Steps

1. **Findings.** If a `review` ran this session and left confirmed findings on this tree, apply them now under review's `fix` rule: make the smallest change that removes the failure scenario, add a test for the corrected behavior where it is testable, and work from the worst finding down. Likely findings stay reported, not fixed. If no review ran this session, skip this step, and don't run one here.
2. **Vet.** Skip it when nothing could have gone stale: local logic, copy, a rename, in-repo helpers, or the same pattern as the code next door.
   If this session already vetted the same thing, point to that result instead of vetting again. A new vendor API touched since then still gets vetted.
   Otherwise follow `vet` on just the parts that could have gone stale: new or changed third-party APIs, version pins, anything chosen because it is "current", "latest", or best practice, and plans pasted from another model. On `quick`, vet only a new or changed vendor API, and hand vet `quick` too. A one-file API change still gets vetted, and a twenty-file rename does not. Wait for vet's reconciled answer, then **patch** what was wrong, plus any cheap-to-fix misses inside the slice. Don't wait for approval here, because pass is the one place where vet's findings get applied straight away.
3. **Leftovers.** Work only on in-scope siblings. Remove APIs, config, and docs that were made dead, old paths left beside their replacements, tests that describe a behavior this change replaced, and scratch this slice added (`console.log`, `debugger`, focused-only tests, notes nobody asked for). Fix stale prose under the global External writing rules. If the diff looks like it contains a secret, strip or flag it without installing a scanner. Follow the global change ownership rule for mixed files and staged work. Unrelated dirty files alone are not a blocker. Report any correctness issue you discover as a review finding for `tdd` rather than silently treating it as cleanup.
4. **Polish.** Follow `polish` unless the user passed `skip polish`, the slice is not code-shaped, or polish already ran this session on those files. Hand it this slice's files as its whole pool rather than its session-wide default. Pass `quick` through when this run is quick. Pass `skip check` through when the user gave it, so that polish's gate reports skipped instead of running. A missing Prettier or ESLint is not a reason to skip, and neither is a small TS or Dart slice.
5. **Ready to commit.** List the outstanding items, or say there are none. If the slice is code and the user didn't pass `skip check`, run the local check from the global instructions. When this exact tree already passed that check this session, cite that result, whether polish just ran it or an earlier run did. Any edit in steps 1–4 since then means you run it again, and `quick` always runs it. A typecheck alone is not the local check. If a review this session found nothing on this tree and nothing changed since the last pass, the whole pass is one line saying so, with no re-reading files or rerunning the check. If there is no check, say so. Don't run `review` here or imply that a pass included one. End with `✅ Ready to commit.` or `❌ Not yet.` On `✅`, commit the slice.

## Report

Follow the global Communication and Session flow rules. Open with `✅ Ready to commit.` or `❌ Not yet.` and what the slice does in app terms. A quick run says "quick" in that line. Mention meaningful fixes, verification results, and anything outstanding or unverified that affects confidence. Include the commit hash when you committed.

```
✅ Ready to commit. The settings page now saves the theme choice and remembers it on reload.

I removed the old localStorage helper and combined two duplicate save handlers. The local check passes. Committed as `<hash>`.
```
