# Restack

`pr` section 5 loads this file only when a restack was explicitly requested. The global restack permission boundary applies. An explicit request covers the identified user-owned stack, but noticing that a parent moved does not authorize a rewrite or force-push. This file covers two jobs.

**The parent moved forward and is still open.** This means new commits on it, review fixes, or work pulled down from a child, with its old tip still an ancestor of the new one (`git merge-base --is-ancestor <old tip> <parent branch>`). Every branch above it runs `git rebase <parent branch>`, bottom-up, and that is all. The fork point is still reachable, and git drops by patch-id anything already on the parent. To move work down the stack, cherry-pick it onto the lower branch and then run this same catch-up above it, and the cherry-picked commit deduplicates itself. If the parent was amended, squashed, or had a commit dropped while open, that ancestor check fails. Treat it like the merged case below, because a plain rebase would replay the parent's stale commits or bring back the one it deliberately removed.

**The parent merged.** A squash merge rewrites its commits into one new commit, so the child still carries originals that git can no longer match, and the base branch may be gone. The recipe below handles that case. An unstacked branch never gets here. For one of those, run `git fetch` and `git rebase origin/<default>`.

Each rebase needs the old parent tip that bounds the child's own commits. Use a recorded SHA when one is available. Otherwise inspect `git reflog show <parent branch>` and identify the value immediately before the relevant rebase or rewrite. Branch reflogs are shared across worktrees, so another session can read that history. `<parent branch>@{1}` is only the immediately previous value. A commit after the rebase makes it the wrong boundary. Verify the candidate against the child's history, and inspect `<old tip>..<child>` to make sure it contains only the work to replay. If the boundary cannot be established, stop and name what is missing rather than guessing. When one session owns the whole stack, record every tip before moving any branch (`git rev-parse <each branch>`).

1. Read the parent's metadata (`gh pr view <parent> --json headRefOid,mergeCommit,baseRefName`) and new base, then run `git fetch`. Treat `headRefOid` as a candidate old tip, not as guaranteed merge-time history. Establish the boundary from recorded history and the child-range check above before rebasing. If it cannot be verified, stop.
2. Rebase bottom-up, one branch at a time: `git rebase --onto <parent's new tip> <parent's recorded old tip> <branch>`. The lowest branch rebases onto `origin/<newbase>`.
3. Run each rebase from the worktree that has that branch checked out, since git refuses to touch a branch another worktree holds.
4. Resolve the conflicts you can resolve mechanically (the parent's own hunks reappearing). For anything that needs a judgment call, stop with the conflicting files named and wait.
5. Run the repo's full check, then `git push --force-with-lease` every branch that moved. Push only to your own branches, and never to one someone else pushes to. Then watch CI on each moved PR as Open step 7 of `pr` says.
6. Say which branches moved and onto what, and name any you could not move.

`rebase.updateRefs` is on in this setup, so every rebase already moves the refs inside the range it replays. That is harmless per branch, but it is not a way to move a whole stack. It never reaches a branch sitting above the range, and it silently skips a branch another worktree holds, still exiting 0.

GitHub usually retargets a child PR when its base branch is deleted. Confirm with `gh pr view --json baseRefName`, and run `gh pr edit --base <newbase>` only if it didn't.

"Stack this PR" sets the PR's `--base` to the named parent. The global git rules cover reparenting the branch. If the parent is named after the PR exists, that reparenting is this file plus `gh pr edit --base`.
