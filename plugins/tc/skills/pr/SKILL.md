---
name: pr
description: 'Owns a pull request from near-ready to ready for review: verifies acceptance criteria, runs review and pass, opens a draft, maintains its evidence, and addresses review threads. Use for explicit PR requests, existing PR reviews and readiness, or restacking. Without a PR, apply the global Git rules to choose a direct commit or PR. `ready` flips the draft after verification; `rebase` restacks it. Not the slice closer (pass), a report-only review (review), or a summary (tldr pr). Never merges.'
argument-hint: "[ready | rebase | reviews | <focus or pasted feedback>]"
---

# PR

Takes a branch from "the build is near ready" to "ready for review" and keeps it honest in between. The PR body is the one durable record of what the change does and how it was proven, so this skill owns it from the first draft on. It reads the repo's own rules first: a PR template, `AGENTS.md`, `CONTRIBUTING.md`, and any review bot config win over the defaults here.

`$ARGUMENTS`: an optional mode first (`ready`, `rebase`, `reviews`), then focus text or pasted feedback. Bare `pr` decides by state.

It calls `review` and `pass` and does not rewrite them. It never merges, and it never marks ready except in `ready` mode.

Apply the global Git rules before entering this workflow. Keep the plan's acceptance checklist when one exists; section 1 handles missing criteria.

## Decide by state

Look before acting: `gh pr view --json number,isDraft,baseRefName,headRefOid,url,mergeStateStatus,reviewDecision`, then `git status` and whether the plan's acceptance checklist has items without evidence. Only "no pull requests found" means there is no PR; any other failure is a failed lookup, so say so and stop rather than opening a second PR over the top of one you couldn't see.

- **No PR yet** → Open (section 2).
- **`ready`, or "mark as ready", "is this ready", "final review", "close out the pr"** → Ready (section 4).
- **`rebase`, "restack", "sync the stack", or a branch below this one moved or merged** → Restack (section 5), then Update.
- **PR exists, anything else** → Update (section 3): refresh the body, then work the open ledger items and unresolved review threads. Nothing open in either: say so and stop.
- **Pasted UAT feedback or a scope change**, in any mode → fold it into the ledger first (section 1), then continue.

## 1. The ledger

The acceptance checklist comes from the plan. Without one, derive three to five criteria from the conversation and any issue, state them, and confirm before spending effort proving them; a small, clear change can have a single criterion, the requested outcome. Keep the ledger in the harness plan file where one exists until the PR body holds it.

Each criterion ends in exactly one state, and the word "unverified" is allowed:

- **Proven by a test**: the test name and its last result on this head.
- **Exercised**: what was driven and where (preview URL, localhost, browser tool, `curl`), with a screenshot for anything visual.
- **Unverified**: why, and what the reviewer has to do instead.

Things that count as criteria even when the ticket never wrote them down: the empty, loading, error, and success states of any new UI, the keyboard path through it, and the failure path of any new mutation. A PM finds these on the first click, so the ledger finds them first.

**Feedback and scope changes.** A pasted PM or reviewer note becomes numbered items tagged "UAT feedback," one per distinct point, screenshots read for the points the text left out. Each ends fixed with evidence, declined with a one-line reason to relay, or one question back with a recommended reading when a screenshot is ambiguous. A criterion the user drops mid-build stays in the ledger marked dropped, so nothing disappears silently.

**Browser UAT is opt-in.** If the user opted in at plan time, drive the preview or localhost with the browser tool for every visual criterion. If they did not, don't start a browser; mark those items "covered by tests, not driven in a browser" where a test really covers the criterion and "unverified" where none does, and put the click path in the test plan either way. If they opted in and the tool errors or is missing, stop and say so rather than falling back to "should work." Prefer the preview over localhost when the PR has one, and only after the deployment's commit matches the current head (`gh api repos/{owner}/{repo}/deployments?sha=<head>` and its statuses, or the deploy bot's comment on this head); a preview of the previous push is not evidence for this one.

## 2. Open

In order:

1. **Ledger.** Section 1 on the whole checklist. Anything unverified that a test or a run could settle cheaply gets settled now.
2. **Review.** `review branch fix` on the branch against its intended base, with the ledger and summary as the intent, in a fresh-context subagent when the harness can spawn one, inline when it can't. Confirmed findings get fixed with the smallest change that removes the scenario, plus a regression test where the behavior is testable; "likely" findings go in the report. Say which mode ran.
3. **Pass.** Follow `pass`. It vets, removes leftovers, polishes, runs the repo's full check, and commits. If review or pass changed files, re-run whatever the ledger's evidence depended on.
4. **Push.** `git push -u origin <branch>`. Taking a task to a draft PR carries the permission to push that branch. Stacked: the base is the parent branch, not the default branch.
5. **Create.** `gh pr create --draft --base <base> --title "<type(scope): subject>" --body-file <tmp>` with the body in section 6. Title follows Conventional Commits; add the ticket key where the repo's recent PR titles do. Solo repos still get a draft, because the body is where the evidence lives.

Run this once near the end, not per slice; in repos with push-triggered review bots, each push also starts another review round.

## 3. Update

1. **Head check.** Be on the PR's head branch, with the `headRefOid` from `gh pr view` an ancestor of `HEAD` (`git merge-base --is-ancestor <headRefOid> HEAD`). Local commits ahead of it are normal, since this section ends in a push. Stop only for the wrong branch or a diverged history, and then say which branch is where; with several worktrees open that is the mistake that costs an hour.
2. **Body.** Rebuild section 6 from the current diff and ledger. Every commit that changed what the PR does or its evidence should already have refreshed it; if the body is stale, that is a finding about the last session, fix it now.
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

   Collect the threads from every returned page and keep only unresolved ones. For each of those thread ids, fetch all its comments separately so each connection has its own cursor:

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

   Resolve bot threads you fixed or declined. Resolve a human thread when the fix is mechanical or you are sure it is done; leave it open when the reply is pushback or a judgment call so they see it. Threads waiting for the user's decision stay open. A new reviewer reply puts the thread back in play.
4. **Triage before touching code.** Work the open ledger items and the threads as one list, and dedupe anything describing the same root cause. For each: trace or reproduce the scenario the way `review` does. Then one of **fix** (real, in scope), **decline** (wrong, already handled, or out of the ticket's scope, with the evidence), or **ask** (the fix would change agreed scope or the reviewers want conflicting things). Ask items go to the user as one consolidated question, not one by one.
5. **Fix in one batch.** Root cause, not the line the bot pointed at; regression test where testable; check related in-scope paths for the same mistake. Run the repo's full check. One commit, `fix(<scope>): address review` with the threads' subjects in the body. One push, not one per comment.
6. **Close the loop on GitHub.** Say up front which threads `viewerCanResolve` rules out. Reply under the user's account on every thread you fixed or declined, explaining the outcome and why. Skip a duplicate only when the last comment is your own reply and already explains the current outcome. Confirm that reply exists before resolving the thread; if posting fails, leave it open and report the failure. Then resolve threads that meet the bar in step 3: `resolveReviewThread(input:{threadId:$id})`, several per mutation with aliases. If GraphQL or permissions fail partway, report which threads actually resolved: aliased mutations apply in order, so the ones before the failure already landed and cannot be taken back.
7. **Learn.** If a thread class recurred, or a bot found something `review` should have caught, propose one line for that repo's `AGENTS.md` review section in the report. Propose, don't apply: that file is team-shared and outside the ticket.

Don't kick bots to re-review, don't wait on them, don't detect which bot posted. If a review arrives later, the user says `pr` again.

## 4. Ready

The readiness check runs on the current head, then flips the draft when everything holds:

- Head check as in section 3, and the body reflects this head.
- Every ledger item is proven, exercised, or unverified with a reason the user has accepted.
- No unresolved actionable threads, checked with the complete thread and comment lookup in section 3. Apply that section's resolution policy: human pushback or judgment threads with an outcome reply may stay open when no implementation work or user decision remains outstanding.
- The repo's full check is green on this head; `gh pr checks` shows required checks passing or pending, none failing. A repo with no check of its own says so and counts as unverified, never as a pass.
- `review pr <number>` has run once as a whole on this head. If it hasn't, run it now, since per-push reviews never saw the commits together. Confirmed findings get fixed, which sends this back to step one.
- The PR is stacked only on parents that are merged or themselves ready, and says so.

All of that holds: `gh pr ready <number>`, then report. Anything fails: report what, leave it draft, don't flip. Mention whether the repo has auto-merge available and whether the user might want it on, once.

## 5. Restack

Two jobs share this section, and the easy one comes up far more often.

**The parent moved forward and is still open.** New commits on it, review fixes, or work pulled down from a child, with its old tip still an ancestor of the new one (`git merge-base --is-ancestor <old tip> <parent branch>`). Every branch above it runs `git rebase <parent branch>`, bottom-up, and that is all: the fork point is still reachable, and git drops by patch-id anything already on the parent. Moving work down the stack is a cherry-pick onto the lower branch followed by this same catch-up above it, and the cherry-picked commit deduplicates itself. If the parent was amended, squashed, or had a commit dropped while open, that ancestor check fails; treat it like the merged case below, because a plain rebase would replay the parent's stale commits or resurrect the one it deliberately removed.

**The parent merged.** A squash merge rewrites its commits into one new commit, so the child still carries originals git can no longer match and the base branch may be gone. That is the recipe below. An unstacked branch never gets here; it is `git fetch` and `git rebase origin/<default>`.

Each rebase needs the old parent tip that bounds the child's own commits. Use a recorded SHA when available. Otherwise inspect `git reflog show <parent branch>` and identify the value immediately before the relevant rebase or rewrite. Branch reflogs are shared across worktrees, so another session can read that history. `<parent branch>@{1}` is only the immediately previous value; a commit after the rebase makes it the wrong boundary. Verify the candidate against the child's history and inspect `<old tip>..<child>` to ensure it contains only the work to replay. If the boundary cannot be established, stop and name what is missing rather than guessing. When one session owns the whole stack, record every tip before moving any branch (`git rev-parse <each branch>`).

1. Read the parent's metadata (`gh pr view <parent> --json headRefOid,mergeCommit,baseRefName`) and new base, then `git fetch`. Treat `headRefOid` as a candidate old tip, not guaranteed merge-time history. Establish the boundary from recorded history and the child-range check above before rebasing; if it cannot be verified, stop.
2. Rebase bottom-up, one branch at a time: `git rebase --onto <parent's new tip> <parent's recorded old tip> <branch>`. The lowest branch rebases onto `origin/<newbase>`.
3. Run each rebase from the worktree that has that branch checked out, since git refuses to touch a branch another worktree holds.
4. Conflicts you can resolve mechanically (the parent's own hunks reappearing), resolve. Anything that needs a judgment call: stop with the conflicting files named and wait.
5. Run the repo's full check, then `git push --force-with-lease` every branch that moved, to your own branches only and never to one someone else pushes to.
6. Say which branches moved and onto what, and name any you could not move.

`rebase.updateRefs` is on in this setup, so every rebase already moves the refs inside the range it replays. That is harmless per branch and is not a way to move a whole stack: it never reaches a branch sitting above the range, and it skips a branch another worktree holds without a word, still exiting 0.

Asking for a restack carries the permission to force-push the branches it moves, so don't stop to ask again mid-stack. GitHub usually retargets a child PR when its base branch is deleted; confirm with `gh pr view --json baseRefName` and `gh pr edit --base <newbase>` only if it didn't.

"Stack this PR" sets the PR's `--base` to the named parent; the global git rules cover reparenting the branch. If the parent is named after the PR exists, that reparenting is this section plus `gh pr edit --base`.

## 6. Body

Global External writing voice, sized to the change. A repo PR template wins on order and headings; fill its sections with the content below. A small PR is a summary plus a test plan that carries the evidence; the review table and the criteria list earn their place on a PR with a multi-item ledger or several areas to read. Omit empty sections rather than writing "N/A," and fold long details inside `<details>`.

1. **Summary.** A short explanation in app terms, plus `Closes #N` or a ticket link when applicable.
2. **What to review, for substantial changes.** Grouped by concern, not per file, worst risk first, at most about eight rows even on a big PR. Sizes come from `git diff --stat <base>...HEAD`; a total line at the bottom. The read/skim/skip call is the same split `review` makes when it triages.

   | Area | What changed | Size | Review |
   |---|---|---|---|
   | Invoice permissions (`src/lib/invoices/*`) | Viewer role blocked at the action and the data layer | 3 files, +120 / −14 | Read closely |
   | Invoice edit page | Edit control hidden for viewers, error state added | 2 files, +48 / −6 | Read, quick |
   | Tests | 6 new cases for the permission matrix | 2 files, +140 | Skim |
   | Generated types, lockfile | Regenerated after the schema change | 2 files, +410 / −380 | Skip |

3. **Acceptance criteria, when the ledger has more than one item.** The ledger from section 1, one line per item with its evidence or its "unverified" reason. UAT-feedback items keep their tag. Dropped items say dropped.
4. **Test plan.** What ran (the check, the test counts) and the numbered click path for UAT, starting from the preview URL when there is one, otherwise `pnpm dev` and a route.
5. **Screenshots.** Before and after for anything visual; folded past two.
6. **Risk and rollback.** Only when the change is shared: a schema, an API, auth, money, a deploy others depend on. One sentence each for what could go wrong and how to back it out.
7. **Out of scope / follow-ups.** What the ticket implied and this PR deliberately leaves, with an issue link when one exists.
8. **Stack.** `Stacked on #N` and `Depends on #M` when they apply.

Numbers go in whenever they are cheap and change how the reader reads: sizes, test counts, before-and-after timings on a performance PR. Bundle deltas and Lighthouse scores only when the repo already measures them. Never invent a metric.

## Report

Follow the global Communication and Session flow rules. Open with the PR's state and URL. Summarize meaningful fixes and verification evidence, then anything unverified or needing the user's decision. Use ledger counts when they help explain a substantial checklist; omit routine step narration.

```
Draft PR opened: https://github.com/org/app/pull/412. Viewers can no longer edit invoices, at the button and at the server.

All six criteria are proven by tests; the two visual ones were also driven against the preview at this head, screenshots in the body. Review in a fresh subagent found one confirmed issue, a missing ownership check on the duplicate route, fixed with a regression test. Pass removed a leftover console.log and the check passes. I didn't drive the browser for the settings page since you didn't opt in; its click path is in the test plan.

Nothing else outstanding. Say `pr ready` when your UAT is done.
```

## Distinct from

| Skill    | This skill                                                                       |
| -------- | -------------------------------------------------------------------------------- |
| `pass`   | Closes and commits one slice. PR closes the branch and owns the pull request.    |
| `review` | Finds defects and reports. PR runs it, applies confirmed fixes, then ships.      |
| `polish` | Shape of code. PR only reaches it through pass.                                  |
| `tldr`   | `tldr pr` summarizes a PR. PR writes and maintains one.                          |
| `vet`    | Checks a claim. PR checks the preview matches the head, and leaves docs to vet.  |
