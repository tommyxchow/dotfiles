# Restack

Loaded by `pr` section 5 only when a restack was explicitly requested. The global restack permission boundary applies: an explicit request covers the identified user-owned stack; noticing that a parent moved does not authorize a rewrite or force-push. Two jobs share this file.

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

GitHub usually retargets a child PR when its base branch is deleted; confirm with `gh pr view --json baseRefName` and `gh pr edit --base <newbase>` only if it didn't.

"Stack this PR" sets the PR's `--base` to the named parent; the global git rules cover reparenting the branch. If the parent is named after the PR exists, that reparenting is this file plus `gh pr edit --base`.
