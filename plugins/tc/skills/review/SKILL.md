---
name: review
description: Local code review of pending changes before a commit or PR. Finds real defects only, ranked worst first with a concrete failure scenario each and verified before reporting: bugs, security holes and leaks, performance problems, unhandled edge cases, and missing pieces. Follows the repo's own review guidelines and tooling first, then the global preferences, and plugs the gaps. Use when the user says review, code review, review this, review the diff, is this correct, check the code, or double check the code. Report-only unless the user says fix. Not style, cleanup, or simplification (that's polish), not the end-of-slice closer (that's pass), not claim checking against docs (that's vet). Scope defaults to dirty work plus files edited this session; `branch`, `all`, or `pr <number|url>` widen it.
argument-hint: "[staged | unstaged | branch | all | pr <number|url>] [fix] [<focus>]"
---

# Review

Find what is wrong or missing in a change before anyone else does. Real defects only: something a user, an attacker, or the next deploy would hit. Shape, naming, duplication, and comments belong to `polish`; leftovers and the ship-ready gate belong to `pass`.

`$ARGUMENTS`: an optional scope keyword first (`staged`, `unstaged`, `branch`, `all`, `pr <number|url>`), an optional `fix`, then focus text. Bare `review` uses the default scope and reports only.

## 1. Recon, kept cheap

1. **Pool.** Build it the way `polish` does: dirty work plus files edited this session by default, or whatever the scope keyword says. `pr` reads the PR diff and description with the repo's PR tool. Read the diff once; open the rest of a file only where the diff touches it.
2. **Intent.** Know what the change was supposed to do before judging it: the task in this conversation, the PR body, or the commit messages. A review without the intent finds the wrong things.
3. **The repo's own rules come first.** Look for a review checklist or guideline: `CONTRIBUTING.md`, a PR template, a review section in `AGENTS.md`, `CLAUDE.md`, or `docs/`, and any reviewer config the repo already runs (a review bot config, Danger, a `review` or `check` script). If the repo defines what a review checks, that list is the checklist, and the lenses below only fill what it does not cover. If the repo has review tooling that runs locally, run it, read its output, and don't repeat what it already reported. The global preferences are the fallback, never the override.
4. **Cheapest bug finder first.** If the repo has a quick typecheck, lint, or test command, run it once on the pool and read the failures before reading the diff. Don't invent a gate the repo doesn't have, and don't run a slow full suite here; `pass` owns the ship gate.

## 2. Size the run

- **Small** (one concern, a handful of files): one read of the diff with every lens in mind. No fan-out.
- **Large** (several concerns or many files): triage first, then fan out read-only reviewers in parallel, one per lens or one per area, each with its diff slice, the intent, the repo's rules, the finding rule below, and a cap of about eight findings. Never ask any of them to find everything. Then reconcile.

**Triage, on a large run only.** Depth is finite, so spend it where a defect would cost something. Read closely anything touching auth or permissions, money, a data migration, a server path, newly accepted external input, or concurrency, plus wherever the change's actual purpose lives. Move fast over generated files, lockfiles, mass renames, formatting-only churn, test fixtures, and vendored code. Then **say the split in two lines before the findings**, because a silent triage hides its own mistakes and this one can file the thing the user cared about under boring:

```
Read closely: the session handling, the payments webhook, the migration.
Skimmed: 40 files of regenerated types, the test fixture renames.
```

Read the diff, not the repo. Open the callers of a changed function, the types it uses, and its tests, and stop there unless a finding needs more. Don't search the web; if a finding hinges on how a vendor API behaves, do one targeted check or hand it to `vet`.

## 3. Lenses

Every finding needs a concrete failure scenario: which input or state, and what goes wrong. If you can't write that sentence, it isn't a finding.

- **Correctness.** Wrong condition, off-by-one, wrong coercion, a null path the types don't rule out, an unawaited promise or unhandled rejection, state that can go stale, a changed function whose other callers weren't updated.
- **Edge cases.** Empty, one, huge, unicode, duplicate, concurrent, timed out, partially failed, retried, out of order, time zones and DST, the boundary value itself.
- **Security.** A missing auth or ownership check on any server path touched, untrusted input reaching a query, command, path, or HTML, secrets in code, logs, URLs, or the client bundle, data in a response the caller shouldn't get, unsafe defaults such as open CORS or open redirects, privilege escalation.
- **Performance.** Only what a user or a bill would notice: N+1, unbounded loops or payloads, missing pagination, work on a hot path or the main thread, memory that grows without bound. No micro-optimization.
- **Missing.** A case the task implies that the diff never handles, error handling absent where the user would see it, the migration, config, env var, feature flag, or docs the change needs, and tests for new behavior, named by the case rather than by a coverage number.
- **Unasked behavior change.** Something changed that the task didn't ask for, which the author may not have noticed.

## 4. Verify before reporting

For every finding that would be high or medium: trace the scenario through the callers, types, and tests to confirm it is reachable, and run a quick test or script when that is cheap. Mark it confirmed (reproduced or fully traced) or likely (traced, not run). Drop anything that stays a guess. A review with three sure findings beats one with ten maybes.

## 5. Report

Dedup, rank worst first by severity then confidence, and write it in the global Communication voice. Open with one line: `✅ No blockers.` or `❌ N issues, worst first.` Then one item per finding: bold what and where, then the scenario in a sentence, then the fix in a sentence, and "traced, not run" when that is the case. Nothing that was fine, no style, no "consider". If the repo's own checklist ran, say what it added in one sentence. If the change is clean, say so and stop.

```
❌ 2 issues, worst first.

- **Anyone can delete another user's photo** in the photo delete route. The handler checks that a session exists but never that the photo belongs to that user, so any signed-in user can delete any photo by id. Look the photo up and compare its owner to the session user before deleting.
- **The upload progress bar sticks at 99 % after a retry** in the uploader hook. On retry the byte counter keeps the failed attempt's bytes, so the total passes the file size and the bar is clamped. Reset the counter when a retry starts. Traced, not run.

The repo's PR checklist in CONTRIBUTING.md also asks for a changelog line, and this change has none.
```

`fix`, or "review and fix": apply the fixes worst first, each with a regression test where the behavior is testable, then rerun the quick check and report what changed. Never fix silently during a plain review.

## Distinct from

| Skill          | This skill                                                                   |
| -------------- | ---------------------------------------------------------------------------- |
| `polish`       | Shape of working code. Review is whether it works.                           |
| `pass`         | Leftovers and the ship gate. Pass says when review hasn't run; it doesn't run it. |
| `vet`          | Claims against docs. Review reads code and sends a vendor-API question to vet. |
| PR review bots | Run after push. Review runs before, so the bot finds less.                   |
