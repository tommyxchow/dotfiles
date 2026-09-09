---
name: cleanup
description: 'Repo hygiene for a checkout that has been worked in for months: dead worktree registrations, branches whose remote is gone, stale remote-tracking refs, and a bloated object store. Surveys and reports first, deletes only what git itself confirms is merged, and checks the forge before touching anything a squash merge left looking unmerged. Use when the user says clean up branches, stale branches, old worktrees, prune, tidy this repo, delete merged branches, or asks what is safe to delete here. Never drops a stash, never force-deletes without showing the list first, and never touches untracked files, build output, or dependencies. Not the end-of-slice closer for pending changes (that is pass), not the shape of code (that is polish), not package catch-up (that is refresh).'
argument-hint: "[<repo path>] [apply]"
---

# Cleanup

Reclaim a repo that has collected months of dead refs. This is bookkeeping only: nothing here removes a file you can see, so the working tree, ignored files, build output, and dependencies are all out of scope.

`$ARGUMENTS`: an optional repo path, defaulting to the current repo, and `apply` to carry out what the survey proposes. Bare `cleanup` surveys and reports without changing anything.

## 1. Survey first

Find the default branch from `git symbolic-ref --quiet --short refs/remotes/origin/HEAD`, falling back to `main` then `master`. Then count, read-only: worktree entries marked `prunable`, branches merged into the default, branches whose upstream is gone (`git branch -vv`, look for `: gone]`), stashes, and loose objects from `git count-objects -v`.

Report the counts before proposing a single deletion. Most repos come back clean, and one line saying so is the whole answer.

## 2. Worktrees

`git worktree prune` clears registrations whose directory is already gone and touches nothing else, so run it without asking. A worktree whose directory still exists is never removed here: report it with its branch and whether it holds uncommitted work.

## 3. Branches, where the care goes

Three groups, and they are not equally safe.

- **Merged into the default branch.** `git branch -d` refuses anything unmerged, so it guards itself. Delete them.
- **Upstream gone and merged.** Same thing, same command.
- **Upstream gone but not merged.** The trap. A squash merge lands one new commit on the default branch, so the original branch is never an ancestor and `-d` refuses it even though the work shipped. Most of a long-lived repo's dead branches land here.

For that third group, ask the forge rather than git, since git cannot tell a squash-merged branch from an abandoned one. The repo's PR tool knows: a merged PR for that branch makes it safe to force-delete, a closed-unmerged PR or no PR at all means keep it and say which. With no PR tool, no remote, or no network, report the group and delete none of it.

Never delete the default branch, the current branch, a branch checked out in any worktree, or one the user asked to keep.

## 4. Objects and remote refs

`git fetch --prune` drops remote-tracking refs for branches deleted upstream, and is safe. Report the loose object count and offer `git gc` when it is high, but let the user run it: it can take minutes on a large repo and is never urgent.

## 5. Never

Stashes, reflogs, untracked and ignored files, build output, dependencies. A stash can be the only copy of something, so report how many there are and leave them alone.

## 6. Report

Answer first, in the global Communication voice. Nothing to do is one line. Otherwise the counts, then what you propose to delete grouped by why it is safe, then what you left and why. On `apply`, say what ran and what it actually removed.

```
22 branches here have no remote left, but only 2 are merged into main. The other 20 look unmerged because the PRs were squash merged, so I checked each on the forge: 17 have a merged PR and are safe, 2 were closed without merging, and 1 never had a PR.

I pruned 3 dead worktree registrations. The 30 stashes are untouched.
```

## Distinct from

| Skill     | This skill                                                                  |
| --------- | --------------------------------------------------------------------------- |
| `pass`    | Closes the slice you just built. Cleanup is the repo around it, and ignores pending changes. |
| `polish`  | Shape of working code. Cleanup never opens a source file.                    |
| `refresh` | Packages and framework versions. Cleanup touches no dependency.               |
| `pr`      | Ships a branch. Cleanup removes the branches that already shipped.            |
