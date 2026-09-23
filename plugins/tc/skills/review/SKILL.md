---
name: review
metadata:
  opencode/slash: "true"
description: 'Finds concrete defects and missing behavior in code changes, verified and ranked worst first. Use for review, code review, review the diff, is this correct, or double check the code. Reports only unless the request says fix; "review and pass", with or without final, means this reports and pass then applies the confirmed findings. PR readiness questions go to pr; shape cleanup to polish; final cleanup to pass; factual claims to vet. Default scope is dirty work plus session edits; `branch` is committed changes only, `all` includes pending work, and `pr <number|url>` reviews the published PR. `quick` is one read of the essentials and never counts as the final review; `deep` or `deeper` is the expensive tier: fan-out whatever the size, one hop wider, every high or medium finding reproduced.'
argument-hint: "[quick | deep] [staged | unstaged | branch | all | pr <number|url>] [fix] [<focus>]"
---

# Review

Find real defects, meaning something a user, an attacker, or the next deploy would hit. Use the task's intent and the repo's rules, and verify each finding before you report it.

`$ARGUMENTS` takes an optional depth first (`quick`, or `deep` / `deeper` for the expensive tier), then an optional scope keyword (`staged`, `unstaged`, `branch`, `all`, `pr <number|url>`), then an optional `fix`, and then focus text. A bare `review` uses the default scope and reports only.

**The final task review runs in a fresh context.** When this review is the one the global completion rule asks for, run it in a fresh-context subagent whatever the diff's size, because the session that wrote the code reads it as it meant it, not as it is. Hand the subagent the base, the scope, the acceptance checklist or task statement, and this skill's path, not the conversation. The size gate below then applies inside it. Where the harness has no subagents, run it inline and say so in the report.

## 1. Recon, kept cheap

1. **Pool.** Build the pool, the set of changes this review covers, by polish's shared [scope rules](../polish/references/scope.md): take Sources A and B by scope keyword, then apply the base rule and the task-ownership filter. That file is the only part of polish this step needs. `branch` is committed changes only. `all` includes pending and untracked task changes. When the caller supplies a base or a diff, use it instead of discovering one. On work committed straight to the default branch, use the recorded task-start commit as the base, not the current branch tip as its own base. `pr` reads the published diff and description. Local verification requires a matching `HEAD` and no dirty changes that affect that verification. Otherwise, report the mismatch and review the published diff without claiming that local results prove it. Read the diff once, and open context where you need it.
2. **Intent.** Know what the change was supposed to do before you judge it. Look at the acceptance checklist when the plan has one, then at the task in this conversation, the PR body, or the commit messages. A review done without the intent finds the wrong things. A checklist item with no code behind it is a finding.
3. **The repo's own rules come first.** Look for a review checklist or guideline: `REVIEW.md` (the file Claude Code's hosted Code Review reads), `CONTRIBUTING.md`, a PR template, a review section in `AGENTS.md`, `CLAUDE.md`, or `docs/`, and any reviewer config the repo already runs (a review bot config, Danger, a `review` or `check` script). If the repo defines what a review checks, that list is the checklist, and the lenses below only fill what it does not cover. If the repo has review tooling that runs locally, run it, read its output, and don't repeat what it already reported. The global preferences are the fallback, and they don't override the repo's rules.
4. **Cheapest bug finder first.** If the repo has a quick typecheck, lint, or test command, run it once on the pool and read the failures before reading the diff. If this exact tree already passed that command this session, such as the run `tdd` just finished, cite that result instead of rerunning it. Don't invent a gate the repo doesn't have. Don't run a slow full suite here either, because `pass` owns the local check and CI runs the whole suite.

## 2. Size the run

- **Small** (one concern, a handful of files). Read the diff once with every lens in mind, and don't fan out.
- **Large** (several concerns or many files). Triage first, then fan out read-only reviewers in parallel, one per lens or one per area. Give each one its diff slice, the intent, the repo's rules, and the finding rule below. Their job is coverage, not filtering, so every finding comes back with a confidence and a severity, and section 4 decides what to drop. Then reconcile their results.
- **Quick** (`quick review`). Read once, with no fan-out and no triage lines, whatever the size. Run the cheapest bug finder only if this tree hasn't had it this session. Cover correctness, security, and missing in full, and cover edge cases and performance only where the diff obviously invites them. Skip section 4's tracing. A finding is confirmed only when the failure is plain in the diff itself. Everything else is likely and marked "traced, not run", and guesses are dropped. Open the report with "Quick review", so nothing counts it as the final task review.
- **Deep** (`deep`, `deeper`). This is the tier for a risky change or a large diff written in one go, and it is expensive by design. Fan out per lens whatever the size, and in the triage, don't put any hand-written code in the skimmed group. Read one hop wider: the callers' callers where a contract changed, the existing tests for the touched behavior to check they still assert the right thing, and the rest of the repo for the same mistake. In section 4, reproduce every high or medium finding with a script or test so it is marked confirmed rather than "traced, not run", since `pass` applies only confirmed findings. Treat earlier reviews of this tree as input, not as results to reuse. Read the code again, and don't re-report what they found unless it changed. Open the report with "Deep review".

**Triage, on a large run only.** Time for close reading is limited, so spend it where a defect would cost something. Read closely anything touching auth or permissions, money, a data migration, a schema or API contract, a server path, newly accepted external input, or concurrency. Also read closely wherever the change's actual purpose lives, and the new or changed tests, since they are the evidence. Skim generated files, lockfiles, mass renames, formatting-only churn, test fixtures, and vendored code. Then **say the split in two lines before the findings**. A triage you don't state hides its own mistakes, and this one can put the thing the user cared about in the skimmed group:

```
Read closely: the session handling, the payments webhook, the migration.
Skimmed: 40 files of regenerated types, the test fixture renames.
```

Read the diff, not the whole repo. Open the callers of a changed function, the types it uses, and its tests, and stop there unless a finding needs more. Don't search the web. If a finding depends on how a vendor API behaves, do one targeted check or hand it to `vet`.

## 3. Lenses

Every finding needs a concrete failure scenario: which input or state, and what goes wrong. If you can't write that sentence, it isn't a finding.

- **Correctness.** Look for a wrong condition, an off-by-one, a wrong coercion, a null path the types don't rule out, an unawaited promise or unhandled rejection, state that can go stale, and a changed function whose other callers weren't updated.
- **Edge cases.** Check the empty, one, huge, unicode, duplicate, concurrent, timed out, partially failed, retried, and out of order cases, time zones and DST, and the boundary value itself.
- **Security.** Look for a missing auth or ownership check on a protected operation, failure to enforce a public endpoint's intended access policy, untrusted input reaching a query, command, path, URL, or HTML, secrets in code, logs, URLs, or the client bundle, data in a response the caller shouldn't get, unsafe CORS or open redirects, and privilege escalation. For a secret, report the location and type, never the value.
- **Performance.** Report only what a user or a bill would notice: N+1, unbounded loops or payloads, missing pagination, work on a hot path or the main thread, and memory that grows without bound. Leave out micro-optimization.
- **Missing.** Look for a case the task implies that the diff never handles, an acceptance criterion with nothing behind it, the empty, loading, or error state of new UI, error handling absent where the user would see it, and the migration, config, env var, feature flag, or docs the change needs. For tests, flag these: no test for new behavior, a test named by a coverage number rather than by the case, one that cannot catch a relevant incorrect behavior, one that duplicates a test that already exists, one that only proves a framework, a mock, or a constant, one that would break on every intended change, or a bug fix that adds no test for the corrected behavior. A test that only forbids the previous behavior, or one left from an earlier version of this change, is not that test. Passing with an empty implementation is not enough to reject a negative assertion such as "no event is sent without consent." An existing test that this diff deleted, skipped, focused, or loosened (a weaker assertion, a wider tolerance, a snapshot rewritten with no behavior change behind it) is a finding, unless the task deliberately replaced the behavior it described.
- **Unasked behavior change.** Look for something that changed without the task asking for it, which the author may not have noticed. Small necessary refactors are allowed by the global Git rules. Flag unrelated or risky restructuring that should have been separated.
- **Unreadable hot path.** Style is normally polish's job. A piece of logic a reviewer can't follow in one read (a dense one-liner, a nested ternary, a clever trick) on a path that matters is still worth one finding here, because nobody can review what they can't read.

## 4. Verify before reporting

For every finding that would be high or medium, trace the scenario through the callers, types, and tests to confirm it is reachable, and run a quick test or script when that is cheap. Mark it confirmed (reproduced or fully traced) or likely (traced, not run). Drop anything that stays a guess. A tradeoff the repo has written down, in an ADR, a decision note, or a comment that gives the reason, is settled and not a finding. When the code has drifted from what that note says, the drift is the finding. If the proposed fix is another guard, default, or catch-all, and no real caller reaches that state, drop the finding too. A missing auth check or a user-visible error path still counts, because those have a caller. A review with three sure findings is better than one with ten maybes. Low-severity findings aren't traced. Keep one when its scenario is concrete and the fix is small, and drop the rest, since that is the cap the fan-out no longer has.

## 5. Report

Remove duplicates, rank the findings worst first by severity and then confidence, and write the report in the global Communication voice. Open with one line: `✅ No blockers.` or `❌ N issues, worst first.` Then write one item per finding: what and where in bold, then the scenario in a sentence, then the fix in a sentence, and "traced, not run" when that is the case. Leave out anything that was fine, style comments, and any "consider". If the repo's own checklist ran, say what it added in one sentence. If the change is clean, say so and stop.

```
❌ 2 issues, worst first.

- **Anyone can delete another user's photo** in the photo delete route. The handler checks that a session exists but never that the photo belongs to that user, so any signed-in user can delete any photo by id. Look the photo up and compare its owner to the session user before deleting.
- **The upload progress bar sticks at 99 % after a retry** in the uploader hook. On retry the byte counter keeps the failed attempt's bytes, so the total passes the file size and the bar is clamped. Reset the counter when a retry starts. Traced, not run.

The repo's PR checklist in CONTRIBUTING.md also asks for a changelog line, and this change has none.
```

With `fix`, or "review and fix", apply the fixes worst first, each with a test for the corrected behavior where testable, then rerun the quick check and report what changed. A fix is the smallest change that removes the failure scenario. Don't add a new abstraction layer, a defensive branch for a case the types already rule out, or a test for something that cannot happen. A reviewer asked to find gaps reports some even when the work is sound, so re-read a finding that needs a big fix before you build around it. Never fix silently during a plain review.

"Review and pass" or "review/pass", with or without "final", means this report comes first (through `pr check` when a PR is open), and then `pass` applies the confirmed findings under this same fix rule. `quick` in front makes both quick.
