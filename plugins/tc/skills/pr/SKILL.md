---
name: pr
metadata:
  opencode/slash: "true"
description: 'Owns draft PR creation, updates, review feedback, and restacking. Use for PR requests and PR readiness: "is this ready?", "final review", and "close out the PR" check and report only; `pr ready` or "mark it ready" checks and flips the draft. `rebase` restacks an identified stack. Without a PR, use the global Git rules to choose a direct commit or PR. Not a summary (tldr pr), standalone code review (review), or slice cleanup (pass). Never merges.'
argument-hint: "[check | ready | rebase | <focus or pasted feedback>]"
---

# PR

This skill publishes and maintains the task's acceptance evidence in a PR. Read the repo's PR template, `AGENTS.md`, `CONTRIBUTING.md`, and review config first, because their requirements win over the defaults here.

`$ARGUMENTS` holds an optional mode first (`check`, `ready`, `rebase`), then focus text or pasted feedback. A bare `pr` decides what to do by state.

Follow the global completion and Git rules. `check` only reports. It makes no code fixes, commits, pushes, PR edits, thread replies or resolutions, and it doesn't flip the draft to ready. Only explicit `ready` approval permits the flip. This skill never merges.

## Decide by state

Look before acting. Run `gh pr view --json number,isDraft,baseRefName,headRefOid,url,mergeStateStatus,reviewDecision`, then `git status`, and check whether the plan's acceptance checklist has items without evidence. Only "no pull requests found" means there is no PR. Any other failure is a failed lookup, so say so and stop rather than opening a second PR on top of one you couldn't see.

- **`check`, "is this ready", "final review", or "close out the PR"**: check readiness (section 4) and report only. When there is no PR, report that rather than opening one.
- **`ready` or "mark it ready"**: check readiness and mark ready (section 4). When there is no PR, report that rather than opening one.
- **Explicit `rebase`, "restack", or "sync the stack"**: run Restack (section 5), then Update when a PR exists. Identify the stack branches before acting, and ask if the intended stack is unclear.
- **No PR yet, an open/create request or bare `pr`**: run Open (section 2).
- **PR exists, anything else**: run Update (section 3). Refresh the body, then work through the open ledger items and unresolved review threads. When neither has anything open, say so and stop.
- **A parent moved or merged without a restack request**: report the dependency and ask before rewriting pushed history. Noticing the move is not permission to restack.
- **Pasted UAT feedback or a scope change**: account for it in the ledger (section 1). In `check`, report the needed update without changing the PR.

## 1. The ledger

The ledger is the task's list of acceptance criteria, each with its evidence. Use the approved plan's acceptance checklist. Without one, derive the criteria from the agreed task. A small, clear change may have only one criterion, the requested outcome. Ask only if deriving them exposes an unresolved scope or design decision. Keep the ledger in the existing plan artifact until the PR body holds it.

Each criterion ends in exactly one state, and the word "unverified" is allowed:

- **Proven by a test**: record the test name and its last result on this head.
- **Exercised**: record what was driven and where (preview URL, localhost, browser tool, `curl`), with a screenshot for anything visual.
- **Unverified**: record why, and what the reviewer has to do instead.

Include the relevant UI states, keyboard path, and mutation failure paths from the global rules. Shared handling counts, so a state that is already covered needs no separate implementation.

**Feedback and scope changes.** Turn a pasted PM or reviewer note into numbered items tagged "UAT feedback," one per distinct point, and read its screenshots for the points the text left out. Each item ends fixed with evidence, declined with a one-line reason to relay, or as one question back with a recommended reading when a screenshot is ambiguous. A criterion the user drops mid-build stays in the ledger marked dropped, so nothing disappears silently. A case the plan missed enters the ledger tagged "discovered," with its evidence when built or as a follow-up when deferred under the global rule.

**Browser and device UAT follows the global rule.** It stays off until `uat`. Then drive the change in the browser or on the device, including a phone or the web target, and cite that drive. When a ledger exists, that is the browser and device criteria still marked not driven. Re-drive only what a slice couldn't reach or what a matching preview now shows. Otherwise mark each as "covered by tests, not driven" or "unverified," according to the evidence, and include its click path. A missing or failed browser or device blocks that evidence, but it doesn't block independent checks or fixes. Prefer a PR preview only after its deployed commit matches the current head (`gh api repos/{owner}/{repo}/deployments?sha=<head>` and its statuses, or the deploy bot's comment on this head). A preview of the previous push is not evidence for this one.

## 2. Open

In order:

1. **Ledger.** Run section 1 on the whole checklist. Settle now anything unverified that a process-local test or run could settle cheaply. A browser or device check waits for `uat`.
2. **Pass.** Follow `pass` on this task's changes, reusing valid work already done. Skip it when the last slice already closed through `pass` on this exact tree. `pass` prepares and commits the slice, but it does not replace the final correctness review.
3. **Review the final task.** Run `review all` against the intended base, including committed, pending, and untracked task changes, with the ledger as the statement of intent. Use a fresh-context subagent when `review`'s own size gate says so, and run it inline otherwise. Reuse an equivalent review of this final diff if one already ran. Apply the global mechanical/docs/config/instruction-only skip. The review only reports, so likely findings stay reported. Say which mode ran.
4. **Finish.** Close through `pass`, which applies the confirmed findings with a test for the corrected behavior where testable. Any substantive edits made since that review get reviewed too. Rerun affected evidence and the full check if invalidated, then commit the fixes. Don't restart polish on unchanged files. Inspect the task's complete final diff and staged ownership before publishing. Squash unpushed fix-and-follow-up commits under the global Git rules.
5. **Push.** Run `git push -u origin <branch>` under the global task-scoped permission. For a stacked PR, the base is the parent branch, not the default branch.
6. **Create.** Run `gh pr create --draft --base <base> --title "<type(scope): subject>" --body-file <tmp>` with the body described in section 6. The title follows Conventional Commits. Add the ticket key where the repo's recent PR titles do. Solo repos still get a draft, because the body is where the evidence lives.
7. **Watch CI.** Run `gh pr checks <number> --watch --fail-fast` in the background with a deadline, since a run can outlast a tool call, and act as soon as it returns. The deadline is the repo's usual CI time from its AGENTS.md, otherwise twenty minutes. Exit 0 means green. Under `--watch` the command returns only once nothing is pending, so a deadline that fires first means the checks are still pending, which is not green. In that case, report it with the checks link and stop the watch. On a failure, read the failed job's log with `gh run view <run-id> --log-failed`, reproduce it locally, fix it through the normal loop, and push once. A second red on the same check is the global debugging budget's same-failure-twice stop. It is reached after one push because each CI round costs minutes. At that stop, the pushed head stays, the ledger carries the red check with its checks link, and the global notification rule fires. The text `no checks reported on the '<branch>' branch` means the repo has no CI, and the report says so instead of claiming green. Then check for review bots: a repo has them when its review config names one or a recent PR carries a bot review. In such a repo, poll `gh pr view <number> --json reviews,comments` in the background under a ten-minute deadline until the first bot review lands, then run Update once and notify. With no bots there is no wait, and a bot that has not posted by the deadline is noted in the report. The bot wait happens once per `pr` run.

Run this section once near the end, not per slice. In repos with push-triggered review bots, each push also starts another review round.

## 3. Update

1. **Head check.** Make sure you are on the PR's head branch and that the `headRefOid` from `gh pr view` is an ancestor of `HEAD` (`git merge-base --is-ancestor <headRefOid> HEAD`). Local commits ahead of it are normal, since this section ends in a push. Stop only for the wrong branch or a diverged history, and then say which branch is where. With several worktrees open, that is the mistake that costs an hour.
2. **Body.** Reconcile the current diff and ledger with section 6. Publish the refreshed body after the batch's push, so its claims describe the remote head rather than unpublished local changes. If no push is needed, repair stale text directly.
3. **Threads.** Read every page with GraphQL, because REST comments carry no thread ids and `gh` has no resolve command. First fetch the threads:

   ```bash
   gh api graphql --paginate --slurp -F owner=<o> -F repo=<r> -F pr=<n> -f query='
     query($owner:String!,$repo:String!,$pr:Int!,$endCursor:String){
       repository(owner:$owner,name:$repo){
         pullRequest(number:$pr){
           reviewThreads(first:100,after:$endCursor){
             nodes{ id isResolved isOutdated viewerCanResolve path line }
             pageInfo{ hasNextPage endCursor }
           }
         }
       }
     }'
   ```

   Collect the threads from every returned page and keep only the unresolved ones. For each of those thread ids, fetch all its comments separately so each connection has its own cursor:

   ```bash
   gh api graphql --paginate --slurp -f thread=<thread-id> -f query='
     query($thread:ID!,$endCursor:String){
       node(id:$thread){
         ... on PullRequestReviewThread{
           comments(first:100,after:$endCursor){
             nodes{ author{login} body url }
             pageInfo{ hasNextPage endCursor }
           }
         }
       }
     }'
   ```

   Join each thread's comment pages in returned order before deciding what its last comment says. If any page fails, returns GraphQL errors, or lacks the expected connection, report the incomplete lookup and stop before triage or marking ready. Partial results never mean there is nothing left to address.

   Resolve bot threads you fixed or declined. Resolve a human thread when the fix is mechanical or you are sure it is done. Leave it open when the reply is pushback or a judgment call, so the reviewer sees it. Threads waiting for the user's decision stay open. A new reviewer reply puts the thread back in play.
4. **Triage before touching code.** Work the open ledger items and the threads as one list, and dedupe anything describing the same root cause. For each item, trace or reproduce the scenario the way `review` does. Then choose one of **fix** (real, in scope), **decline** (wrong, already handled, or out of the ticket's scope, with the evidence), or **ask** (the fix would change agreed scope or the reviewers want conflicting things). Send the ask items to the user as one consolidated question, not one by one.
5. **Fix in one batch.** Fix the root cause, not the line the bot pointed at. Add a test for the corrected behavior where testable, and check related in-scope paths for the same mistake. Close the batch through `pass`, then follow the global completion rule on the changed code, reusing unaffected evidence. Make one commit, `fix(<scope>): address review`, with the threads' subjects in the body. Push once and then refresh the body against that head, rather than pushing once per comment. Then watch CI as Open step 7 says, with no second bot wait.
6. **Close the loop on GitHub.** Say up front which threads `viewerCanResolve` rules out. Reply under the user's account on every thread you fixed or declined, explaining the outcome and why. Skip a duplicate reply only when the last comment is your own reply and already explains the current outcome. Confirm that the reply exists before resolving the thread. If posting fails, leave the thread open and report the failure. Then resolve the threads that step 3 says to resolve, using `resolveReviewThread(input:{threadId:$id})`, several per mutation with aliases. If GraphQL or permissions fail partway, report which threads actually resolved. Aliased mutations apply in order, so the ones before the failure have already taken effect and cannot be undone.
7. **Learn.** If a thread class recurred, or a bot found something `review` should have caught, propose one line for that repo's `AGENTS.md` review section in the report. Propose it rather than applying it, because that file is team-shared and outside the ticket.

Don't trigger bots to re-review, and don't try to detect which bot posted. The only bot wait is the one in Open step 7, once per `pr` run. A review that arrives later is handled the next time the user says `pr`.

## 4. Check readiness or mark ready

Both modes use the same evidence. `check` reports findings without applying fixes or changing GitHub. Explicit `ready` approval permits in-scope fixes through Update, and then you recheck the resulting head before flipping the draft.

- Local `HEAD` matches the remote PR head, no pending task edits remain, and the body reflects that head. A local check with dirty task files does not prove the published PR. In `check`, report the mismatch. In `ready`, finish and push the task through Update first.
- Every ledger item is proven, exercised, or unverified with a reason the user has accepted.
- No actionable threads are unresolved, checked with the complete thread and comment lookup in section 3. Apply that section's resolution policy: human pushback or judgment threads with an outcome reply may stay open when no implementation work or user decision remains outstanding.
- The repo's full check is green on this head, and `gh pr checks` shows the required checks passing. Pending is not green. When a repo has no check of its own, say so and count it as unverified, never as a pass.
- The whole PR diff has been reviewed on this head. Reuse an equivalent complete review from Open or Update, and otherwise run `review pr <number>`. Apply the global mechanical/docs/config/instruction-only skip. In `check`, report the findings. In `ready`, send confirmed findings through Update, then restart this check. Per-push reviews of separate pieces do not replace a whole-diff review.
- The PR is stacked only on parents that are merged or themselves ready, and it says so.

In `check`, report whether the criteria hold and stop. In `ready`, run `gh pr ready <number>` only when all of them hold. Otherwise report the blocker and leave the PR as a draft. Never merge or enable auto-merge as part of either mode.

## 5. Restack

Read [references/restack.md](references/restack.md) only when this mode runs, which means an explicit `rebase`, "restack", or "sync the stack", or a parent named after the PR exists. It carries the parent-moved and parent-merged recipes, the boundary rules for the old parent tip, and the push step. The global restack permission boundary applies either way. An explicit request covers the identified user-owned stack, but noticing that a parent moved does not authorize a rewrite or force-push.

## 6. Body

Write the body in the global External writing voice, sized to the change. When the repo has a PR template, its order and headings win, and you fill its sections with the content below. A small PR gets a summary plus a test plan that carries the evidence. The review table and the criteria list are worth including on a PR with a multi-item ledger or several areas to read. Omit empty sections rather than writing "N/A," and fold long details inside `<details>`.

1. **Summary.** Give a short explanation in app terms, plus `Closes #N` or a ticket link when applicable. For a change with a mechanism worth knowing, follow it with how it works: the pieces and the flow between them in three to five sentences, a small diagram when the flow has more than two steps, and the one snippet that carries the idea, so the reader has the model before the diff.
2. **What to review, for substantial changes.** Group the rows by concern, not per file, with the worst risk first, and keep to about eight rows at most, even on a big PR. Take the sizes from `git diff --stat <base>...HEAD`, and put a total line at the bottom. The read/skim/skip call is the same split `review` makes when it triages.

   | Area | What changed | Size | Review |
   |---|---|---|---|
   | Invoice permissions (`src/lib/invoices/*`) | Viewer role blocked at the action and the data layer | 3 files, +120 / −14 | Read closely |
   | Invoice edit page | Edit control hidden for viewers, error state added | 2 files, +48 / −6 | Read, quick |
   | Tests | 6 new cases for the permission matrix | 2 files, +140 | Read |
   | Generated types, lockfile | Regenerated after the schema change | 2 files, +410 / −380 | Skip |

3. **Acceptance criteria, when the ledger has more than one item.** List the ledger from section 1, one line per item with its evidence or its "unverified" reason. UAT-feedback and discovered items keep their tags. Dropped items say dropped.
4. **Test plan.** Say what ran (the check, the test counts), and give the numbered click path for UAT, starting from the preview URL when there is one and otherwise from `pnpm dev` and a route.
5. **Screenshots.** Show before and after for anything visual. Fold them past two.
6. **Risk and rollback.** Include this only when the change is risky: a migration, a backfill, auth, money, or a shape another client or deploy still reads. Write one sentence each for what could go wrong and how to back it out.
7. **Decisions and follow-ups.** Cover the cases the plan missed. First give what was built beyond the ticket, with a one-line why, then what the ticket implied that this PR deliberately leaves out, with an issue link when one exists.
8. **Stack.** Add `Stacked on #N` and `Depends on #M` when they apply.

Include numbers whenever they are cheap to get and change how the reader reads the PR: sizes, test counts, before-and-after timings on a performance PR. Include bundle deltas and Lighthouse scores only when the repo already measures them. Never invent a metric.

## Report

Follow the global Communication and Session flow rules. Open with the PR's state and URL. When a check is red or still pending, put the checks tab link, `<pr url>/checks`, next to its name so the user lands on the failing job in one click. A green run needs no link. Summarize meaningful fixes and verification evidence, then anything unverified or needing the user's decision. Use ledger counts when they help explain a substantial checklist, and leave out routine narration of each step. Under `ship it`, this report is the finish the global notification rule names.

```
Draft PR opened: https://github.com/org/app/pull/412. Viewers can no longer edit invoices, at the button and at the server.

All six criteria are proven by tests; the two visual ones are covered by tests and not driven, until `uat`. Review in a fresh subagent found a missing ownership check on the duplicate route, fixed with a test for that ownership check. The final diff is reviewed and the full check passes.

Nothing else outstanding. Say `pr ready` when your UAT is done.
```
