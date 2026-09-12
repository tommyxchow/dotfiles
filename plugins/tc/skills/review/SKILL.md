---
name: review
description: 'Finds concrete defects and missing behavior in code changes, verified and ranked worst first. Use for review, code review, review the diff, is this correct, or double check the code. Reports only unless asked to fix or called by the build completion workflow. PR readiness questions go to pr; shape cleanup to polish; final cleanup to pass; factual claims to vet. Default scope is dirty work plus session edits; `branch` is committed changes only, `all` includes pending work, and `pr <number|url>` reviews the published PR.'
argument-hint: "[staged | unstaged | branch | all | pr <number|url>] [fix] [<focus>]"
---

# Review

Find real defects: something a user, an attacker, or the next deploy would hit. Use the task's intent and repo rules, then verify each finding before reporting it.

`$ARGUMENTS`: an optional scope keyword first (`staged`, `unstaged`, `branch`, `all`, `pr <number|url>`), an optional `fix`, then focus text. Bare `review` uses the default scope and reports only.

## 1. Recon, kept cheap

1. **Pool.** Use `polish`'s scope table and task-ownership filter. `branch` is committed changes only; `all` includes pending and untracked task changes. A caller-supplied base or diff replaces discovery. On direct-to-default-branch work, use the recorded task-start commit, not the current branch tip as its own base. `pr` reads the published diff and description; local verification requires matching `HEAD` and no dirty changes affecting that verification. Otherwise report the mismatch and review the published diff without claiming local results prove it. Read the diff once; open context where needed.
2. **Intent.** Know what the change was supposed to do before judging it: the acceptance checklist when the plan has one, then the task in this conversation, the PR body, or the commit messages. A review without the intent finds the wrong things, and a checklist item with no code behind it is a finding.
3. **The repo's own rules come first.** Look for a review checklist or guideline: `CONTRIBUTING.md`, a PR template, a review section in `AGENTS.md`, `CLAUDE.md`, or `docs/`, and any reviewer config the repo already runs (a review bot config, Danger, a `review` or `check` script). If the repo defines what a review checks, that list is the checklist, and the lenses below only fill what it does not cover. If the repo has review tooling that runs locally, run it, read its output, and don't repeat what it already reported. The global preferences are the fallback, never the override.
4. **Cheapest bug finder first.** If the repo has a quick typecheck, lint, or test command, run it once on the pool and read the failures before reading the diff. If this exact tree already passed that command this session, such as the run `tdd` just finished, cite that result instead of rerunning. Don't invent a gate the repo doesn't have, and don't run a slow full suite here; `pass` owns the ship gate.

## 2. Size the run

- **Small** (one concern, a handful of files): one read of the diff with every lens in mind. No fan-out.
- **Large** (several concerns or many files): triage first, then fan out read-only reviewers in parallel, one per lens or one per area, each with its diff slice, the intent, the repo's rules, the finding rule below, and a cap of about eight findings. Never ask any of them to find everything. Then reconcile.

**Triage, on a large run only.** Depth is finite, so spend it where a defect would cost something. Read closely anything touching auth or permissions, money, a data migration, a schema or API contract, a server path, newly accepted external input, or concurrency, plus wherever the change's actual purpose lives. Move fast over generated files, lockfiles, mass renames, formatting-only churn, test fixtures, and vendored code. Then **say the split in two lines before the findings**, because a silent triage hides its own mistakes and this one can file the thing the user cared about under boring:

```
Read closely: the session handling, the payments webhook, the migration.
Skimmed: 40 files of regenerated types, the test fixture renames.
```

Read the diff, not the repo. Open the callers of a changed function, the types it uses, and its tests, and stop there unless a finding needs more. Don't search the web; if a finding hinges on how a vendor API behaves, do one targeted check or hand it to `vet`.

## 3. Lenses

Every finding needs a concrete failure scenario: which input or state, and what goes wrong. If you can't write that sentence, it isn't a finding.

- **Correctness.** Wrong condition, off-by-one, wrong coercion, a null path the types don't rule out, an unawaited promise or unhandled rejection, state that can go stale, a changed function whose other callers weren't updated.
- **Edge cases.** Empty, one, huge, unicode, duplicate, concurrent, timed out, partially failed, retried, out of order, time zones and DST, the boundary value itself.
- **Security.** A missing auth or ownership check on a protected operation, failure to enforce a public endpoint's intended access policy, untrusted input reaching a query, command, path, or HTML, secrets in code, logs, URLs, or the client bundle, data in a response the caller shouldn't get, unsafe CORS or open redirects, privilege escalation.
- **Performance.** Only what a user or a bill would notice: N+1, unbounded loops or payloads, missing pagination, work on a hot path or the main thread, memory that grows without bound. No micro-optimization.
- **Missing.** A case the task implies that the diff never handles, an acceptance criterion with nothing behind it, the empty, loading, or error state of new UI, error handling absent where the user would see it, and the migration, config, env var, feature flag, or docs the change needs. On tests: none for new behavior, one named by a coverage number rather than by the case, one that cannot catch a relevant incorrect behavior, or a bug fix that adds no regression test. Passing with an empty implementation is not enough to reject a negative assertion such as "no event is sent without consent."
- **Unasked behavior change.** Something changed that the task didn't ask for, which the author may not have noticed. Small necessary refactors are allowed by the global Git rules; flag unrelated or risky restructuring that should have been separated.
- **Unreadable hot path.** Normally style is polish's job, but a piece of logic a reviewer can't follow in one read (a dense one-liner, a nested ternary, a clever trick) on a path that matters is worth one finding here, because nobody can review what they can't read.

## 4. Verify before reporting

For every finding that would be high or medium: trace the scenario through the callers, types, and tests to confirm it is reachable, and run a quick test or script when that is cheap. Mark it confirmed (reproduced or fully traced) or likely (traced, not run). Drop anything that stays a guess. If the proposed fix is another guard, default, or catch-all, and no real caller reaches that state, drop it too; a missing auth check or a user-visible error path still counts, because those have a caller. A review with three sure findings beats one with ten maybes.

## 5. Report

Dedup, rank worst first by severity then confidence, and write it in the global Communication voice. Open with one line: `✅ No blockers.` or `❌ N issues, worst first.` Then one item per finding: bold what and where, then the scenario in a sentence, then the fix in a sentence, and "traced, not run" when that is the case. Nothing that was fine, no style, no "consider". If the repo's own checklist ran, say what it added in one sentence. If the change is clean, say so and stop.

```
❌ 2 issues, worst first.

- **Anyone can delete another user's photo** in the photo delete route. The handler checks that a session exists but never that the photo belongs to that user, so any signed-in user can delete any photo by id. Look the photo up and compare its owner to the session user before deleting.
- **The upload progress bar sticks at 99 % after a retry** in the uploader hook. On retry the byte counter keeps the failed attempt's bytes, so the total passes the file size and the bar is clamped. Reset the counter when a retry starts. Traced, not run.

The repo's PR checklist in CONTRIBUTING.md also asks for a changelog line, and this change has none.
```

`fix`, or "review and fix": apply the fixes worst first, each with a regression test where the behavior is testable, then rerun the quick check and report what changed. A fix is the smallest change that removes the failure scenario: no new abstraction layer, no defensive branch for a case the types already rule out, no test for something that cannot happen. A reviewer asked to find gaps reports some even when the work is sound, so a finding that needs a big fix is worth re-reading before you build around it. Never fix silently during a plain review.
