---
name: pr
description: 'Owns the pull request from near-ready to ready for review. Verifies each acceptance criterion with evidence, runs the whole-branch review in a fresh subagent, runs pass, pushes, and opens the draft with the standard body (summary, what-to-review table with sizes, AC ledger, test plan, screenshots, risk, stack). Then keeps that body current and addresses open review threads in one batch. `ready` flips the draft after the readiness check; `rebase` restacks when a parent moves or merges. Use when the user says pr, open a pr, draft pr, ship it, take this to a pr, update the pr, address the reviews, fix the review comments, mark pr as ready, is this ready, final review, close out the pr, rebase the stack, sync the stack, sync this down to another pr, or pastes UAT feedback. Also runs on its own when a build reaches near-ready. Not the slice closer (that''s pass), not a report-only review (that''s review), not a summary (that''s tldr pr). Never merges.'
argument-hint: "[ready | rebase | reviews | <focus or pasted feedback>]"
---

# PR

Takes a branch from "the build is near ready" to "ready for review" and keeps it honest in between. The PR body is the one durable record of what the change does and how it was proven, so this skill owns it from the first draft on. It reads the repo's own rules first: a PR template, `AGENTS.md`, `CONTRIBUTING.md`, and any review bot config win over the defaults here.

`$ARGUMENTS`: an optional mode first (`ready`, `rebase`, `reviews`), then focus text or pasted feedback. Bare `pr` decides by state.

It calls `review` and `pass` and does not rewrite them. It never merges, and it never marks ready except in `ready` mode.

In the user's own repos, work that never needed a plan never needs this skill either: `pass` commits the small fix and that is the end. A team repo gives every change a PR however small, so a small fix still comes here, with a short ledger from section 1. Work that did have a plan and arrives without its checklist has lost it, not outgrown it, and section 1 rebuilds that too.

## Decide by state

Look before acting: `gh pr view --json number,isDraft,baseRefName,headRefOid,url,mergeStateStatus,reviewDecision`, then `git status` and whether the plan's acceptance checklist has items without evidence. Only "no pull requests found" means there is no PR; any other failure is a failed lookup, so say so and stop rather than opening a second PR over the top of one you couldn't see.

- **No PR yet** → Open (section 2).
- **`ready`, or "mark as ready", "is this ready", "final review", "close out the pr"** → Ready (section 4).
- **`rebase`, "restack", "sync the stack", or a branch below this one moved or merged** → Restack (section 5), then Update.
- **PR exists, anything else** → Update (section 3): refresh the body, then work the open ledger items and unresolved review threads. Nothing open in either: say so and stop.
- **Pasted UAT feedback or a scope change**, in any mode → fold it into the ledger first (section 1), then continue.

## 1. The ledger

The acceptance checklist comes from the plan. If there is none (a described idea, a GitHub issue, a session that lost it), derive three to five criteria from the conversation and the issue, state them, and confirm before spending effort proving them. Keep the ledger in the harness plan file where one exists until the PR body holds it.

Each criterion ends in exactly one state, and the word "unverified" is allowed:

- **Proven by a test**: the test name and its last result on this head.
- **Exercised**: what was driven and where (preview URL, localhost, browser tool, `curl`), with a screenshot for anything visual.
- **Unverified**: why, and what the reviewer has to do instead.

Things that count as criteria even when the ticket never wrote them down: the empty, loading, error, and success states of any new UI, the keyboard path through it, and the failure path of any new mutation. A PM finds these on the first click, so the ledger finds them first.

**Feedback and scope changes.** A pasted PM or reviewer note becomes numbered items tagged "UAT feedback," one per distinct point, screenshots read for the points the text left out. Each ends fixed with evidence, declined with a one-line reason to relay, or one question back with a recommended reading when a screenshot is ambiguous. A criterion the user drops mid-build stays in the ledger marked dropped, so nothing disappears silently.

**Browser UAT is opt-in.** If the user opted in at plan time, drive the preview or localhost with the browser tool for every visual criterion. If they did not, don't start a browser; mark those items "covered by tests, not driven in a browser" where a test really covers the criterion and "unverified" where none does, and put the click path in the test plan either way. If they opted in and the tool errors or is missing, stop and say so rather than falling back to "should work." Prefer the preview over localhost when the PR has one, and only after the deployment's commit matches the current head (`gh api repos/{owner}/{repo}/deployments?sha=<head>` and its statuses, or the deploy bot's comment on this head); a preview of the previous push is not evidence for this one.

## 2. Open

In order, and say each step in one line as it happens:

1. **Ledger.** Section 1 on the whole checklist. Anything unverified that a test or a run could settle cheaply gets settled now.
2. **Review.** `review branch fix` on the branch against its intended base, with the ledger and summary as the intent, in a fresh-context subagent when the harness can spawn one, inline when it can't. Confirmed findings get fixed with the smallest change that removes the scenario, plus a regression test where the behavior is testable; "likely" findings go in the report. Say which mode ran.
3. **Pass.** Follow `pass`. It vets, removes leftovers, polishes, runs the repo's full check, and commits. If review or pass changed files, re-run whatever the ledger's evidence depended on.
4. **Push.** `git push -u origin <branch>`. Taking a task to a draft PR carries the permission to push that branch. Stacked: the base is the parent branch, not the default branch.
5. **Create.** `gh pr create --draft --base <base> --title "<type(scope): subject>" --body-file <tmp>` with the body in section 6. Title follows Conventional Commits; add the ticket key where the repo's recent PR titles do. Solo repos still get a draft, because the body is where the evidence lives.

Work bots review drafts on every push, so this runs once, near the end, not per slice.

## 3. Update

1. **Head check.** Be on the PR's head branch, with the `headRefOid` from `gh pr view` an ancestor of `HEAD` (`git merge-base --is-ancestor <headRefOid> HEAD`). Local commits ahead of it are normal, since this section ends in a push. Stop only for the wrong branch or a diverged history, and then say which branch is where; with several worktrees open that is the mistake that costs an hour.
2. **Body.** Rebuild section 6 from the current diff and ledger. Every commit that changed what the PR does or its evidence should already have refreshed it; if the body is stale, that is a finding about the last session, fix it now.
3. **Threads.** Read them with GraphQL, because REST comments carry no thread ids and `gh` has no resolve command:

   ```
   gh api graphql -F owner=<o> -F repo=<r> -F pr=<n> -f query='
     query($owner:String!,$repo:String!,$pr:Int!){ repository(owner:$owner,name:$repo){
       pullRequest(number:$pr){ reviewThreads(first:100){ nodes{
         id isResolved isOutdated viewerCanResolve path line
         comments(first:20){ nodes{ author{login} body url } } } } } } }'
   ```

   Keep only unresolved threads. Bot and human authors get the same treatment. Drop any thread whose last comment is your own decline: those stay open by design, and answering again posts a duplicate. A reviewer who replied after that decline puts the thread back in play.
4. **Triage before touching code.** Work the open ledger items and the threads as one list, and dedupe anything describing the same root cause. For each: trace or reproduce the scenario the way `review` does. Then one of **fix** (real, in scope), **decline** (wrong, already handled, or out of the ticket's scope, with the evidence), or **ask** (the fix would change agreed scope or the reviewers want conflicting things). Ask items go to the user as one consolidated question, not one by one.
5. **Fix in one batch.** Root cause, not the line the bot pointed at; regression test where testable; check related in-scope paths for the same mistake. Run the repo's full check. One commit, `fix(<scope>): address review` with the threads' subjects in the body. One push. Every push is a bot round at work, so never push per comment.
6. **Close the loop on GitHub.** Resolve every thread you fixed: `resolveReviewThread(input:{threadId:$id})`, several per mutation with aliases. Say up front which ones `viewerCanResolve` rules out rather than finding out mid-batch. Reply on every thread you declined with the reason, under the user's account, and leave it open so the reviewer sees it. Never resolve a declined thread. If GraphQL or permissions fail partway, report which threads actually resolved: aliased mutations apply in order, so the ones before the failure already landed and cannot be taken back.
7. **Learn.** If a thread class recurred, or a bot found something `review` should have caught, propose one line for that repo's `AGENTS.md` review section in the report. Propose, don't apply: that file is team-shared and outside the ticket.

Don't kick bots to re-review, don't wait on them, don't detect which bot posted. If a review arrives later, the user says `pr` again.

## 4. Ready

The readiness check runs on the current head, then flips the draft when everything holds:

- Head check as in section 3, and the body reflects this head.
- Every ledger item is proven, exercised, or unverified with a reason the user has accepted.
- No unresolved actionable threads. Declined threads with a reply are fine.
- The repo's full check is green on this head; `gh pr checks` shows required checks passing or pending, none failing. A repo with no check of its own says so and counts as unverified, never as a pass.
- `review pr <number>` has run once as a whole on this head. If it hasn't, run it now, since per-push reviews never saw the commits together. Confirmed findings get fixed, which sends this back to step one.
- The PR is stacked only on parents that are merged or themselves ready, and says so.

All of that holds: `gh pr ready <number>`, then report. Anything fails: report what, leave it draft, don't flip. Mention whether the repo has auto-merge available and whether the user might want it on, once.

## 5. Restack

Two jobs share this section, and the easy one comes up far more often.

**The parent moved and is still open.** New commits on it, review fixes, or work pulled down from a child. Every branch above it runs `git rebase <parent branch>`, bottom-up, and that is all: the fork point is still reachable, and git drops by patch-id anything already on the parent. Moving work down the stack is a cherry-pick onto the lower branch followed by this same catch-up above it, and the cherry-picked commit deduplicates itself.

**The parent merged.** A squash merge rewrites its commits into one new commit, so the child still carries originals git can no longer match and the base branch may be gone. That is the recipe below. An unstacked branch never gets here; it is `git fetch` and `git rebase origin/<default>`.

Each rebase needs the commit its branch was forked from, and that commit loses its name as soon as the branch below it moves. `<parent branch>@{1}` is that previous tip, and branch reflogs are shared, so a session holding only its own worktree reads it without asking the session that did the rebase. Recording every tip up front (`git rev-parse <each branch>`) is the safer route on the rarer occasion that one session owns the whole stack.

1. Find the parent's last head before merge (`gh pr view <parent> --json headRefOid,mergeCommit,baseRefName`) and the new base (the parent's `baseRefName`), then `git fetch`.
2. Rebase bottom-up, one branch at a time: `git rebase --onto <parent's new tip> <parent's recorded old tip> <branch>`. The lowest branch rebases onto `origin/<newbase>`.
3. Run each rebase from the worktree that has that branch checked out, since git refuses to touch a branch another worktree holds.
4. Conflicts you can resolve mechanically (the parent's own hunks reappearing), resolve. Anything that needs a judgment call: stop with the conflicting files named and wait.
5. Run the repo's full check, then `git push --force-with-lease` every branch that moved, to your own branches only and never to one someone else pushes to.
6. Say which branches moved and onto what, and name any you could not move.

`rebase.updateRefs` is on in this setup, so every rebase already moves the refs inside the range it replays. That is harmless per branch and is not a way to move a whole stack: it never reaches a branch sitting above the range, and it skips a branch another worktree holds without a word, still exiting 0.

Asking for a restack carries the permission to force-push the branches it moves, so don't stop to ask again mid-stack. GitHub usually retargets a child PR when its base branch is deleted; confirm with `gh pr view --json baseRefName` and `gh pr edit --base <newbase>` only if it didn't.

"Stack this PR" sets the PR's `--base` to the named parent; the global git rules cover reparenting the branch. If the parent is named after the PR exists, that reparenting is this section plus `gh pr edit --base`.

## 6. Body

One screen, fixed order, in the global External writing voice. A repo PR template wins on order and headings; fill its sections with the content below and keep the table and ledger somewhere in it. Sections with nothing to say are omitted, not filled with "N/A." Anything long goes inside `<details>`.

1. **Summary.** Two or three sentences in app terms, plus `Closes #N` or the ticket link.
2. **What to review.** Grouped by concern, not per file, worst risk first, at most about eight rows even on a big PR. Sizes come from `git diff --stat <base>...HEAD`; a total line at the bottom. The read/skim/skip call is the same split `review` makes when it triages.

   | Area | What changed | Size | Review |
   |---|---|---|---|
   | Invoice permissions (`src/lib/invoices/*`) | Viewer role blocked at the action and the data layer | 3 files, +120 / −14 | Read closely |
   | Invoice edit page | Edit control hidden for viewers, error state added | 2 files, +48 / −6 | Read, quick |
   | Tests | 6 new cases for the permission matrix | 2 files, +140 | Skim |
   | Generated types, lockfile | Regenerated after the schema change | 2 files, +410 / −380 | Skip |

3. **Acceptance criteria.** The ledger from section 1, one line per item with its evidence or its "unverified" reason. UAT-feedback items keep their tag. Dropped items say dropped.
4. **Test plan.** What ran (the check, the test counts) and the numbered click path for UAT, starting from the preview URL when there is one, otherwise `pnpm dev` and a route.
5. **Screenshots.** Before and after for anything visual; folded past two.
6. **Risk and rollback.** Only when the change is shared: a schema, an API, auth, money, a deploy others depend on. One sentence each for what could go wrong and how to back it out.
7. **Out of scope / follow-ups.** What the ticket implied and this PR deliberately leaves, with an issue link when one exists.
8. **Stack.** `Stacked on #N` and `Depends on #M` when they apply.

Numbers go in whenever they are cheap and change how the reader reads: sizes, test counts, before-and-after timings on a performance PR. Bundle deltas and Lighthouse scores only when the repo already measures them. Never invent a metric.

## Report

Write it in the global Communication voice: answer first, full sentences, app terms. Open with what state the PR is in now and its URL. Then what this run did: how many ledger items are proven, exercised, and unverified; what review found and fixed; what pass changed; which threads were fixed, declined, or need the user; whether the browser ran and against what. Then anything unverified and anything the user has to do, worst first. Skip empty parts. Don't walk the diff.

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
