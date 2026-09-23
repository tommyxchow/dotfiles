---
name: cleanup
metadata:
  opencode/slash: "true"
description: 'Repo hygiene for finished worktrees, dead worktree registrations, merged branches, stale remote-tracking refs, and a bloated object store. Surveys read-only, shows exact deletion candidates and their evidence, and asks the user to select what to remove before any deletion. Even apply requires approval of the list. Use when the user says clean up branches, stale branches, old or finished worktrees, remove this worktree, prune, tidy this repo, delete merged branches, or asks what is safe to delete here. Never drops a stash, and touches working files only by removing an approved, clean worktree folder whole. Not the closer that commits pending changes (that is pass), code shaping (polish), or package catch-up (refresh).'
argument-hint: "[<repo path>] [apply]"
---

# Cleanup

Clean up a repo that has collected months of dead refs and finished worktrees.

`$ARGUMENTS` holds an optional repo path, which defaults to the current repo, and the word `apply` to request cleanup. With `apply` or without it, the run starts with a read-only survey and uses the approval flow in section 5.

## 1. Survey first

Identify the repository, the remote, the default branch, and the matching local and remote-tracking refs separately. Use the remote's advertised HEAD (`git ls-remote --symref <remote> HEAD`) when it is available. A cached remote HEAD is only provisional. When the default or the remote is ambiguous, ask rather than guess `main` or `master`. When there is no remote, use an explicitly established local default and report only local ancestry evidence.

Count the following without changing anything: worktrees and their registrations (`git worktree list --porcelain` and `git worktree prune --dry-run --verbose`), each linked worktree's branch, lock, and `git -C <path> status --porcelain`, branches merged into the identified default ref, missing upstreams, stashes, and loose objects (`git count-objects -v`). Record the candidate refs and their full tip SHAs. Cached refs may be stale. A missing tracking ref alone does not prove the branch was deleted on the remote. Read remote refs and forge metadata where they are available, but don't fetch or prune during the survey.

Report the counts and evidence before proposing any deletions. For a clean repo, one sentence is enough.

## 2. Worktrees

**Finished worktree folders.** A linked worktree is a candidate for removal, folder included, only when all of this holds: its branch meets the section 3 evidence for deletion, `git -C <path> status --porcelain` prints nothing, it is not locked, and nothing is running in it. Never propose the main checkout or the worktree this session runs in. A detached worktree qualifies only when its commit is reachable from the default ref.

Inside a herdr pane (`HERDR_ENV` is set), `herdr pane list` gives every pane's working directory. When a pane inside the folder hosts an agent, the worktree is in use, so keep it and say which pane. A pane whose foreground process, as reported by `herdr pane process-info`, is a dev server or watcher for that checkout doesn't block removal. List closing that pane together with the worktree as one item, and after approval, close the pane first and then remove the folder. An idle shell doesn't count, and every herdr worktree has one. When comparing paths, ignore slash direction, and on Windows ignore case as well. Outside herdr, say that occupancy could not be checked.

When a worktree's branch has landed but its tree is dirty, keep the worktree and report it with the file names, never their contents.

List the folder and its branch as one item, to be removed in that order. State the side effect: ignored files such as env copies, dependencies, and build output go with the folder. Name any ignored env file that differs from the main checkout's copy, since that edit exists nowhere else.

After approval, run `git worktree remove <path>` without `--force`. Inside a herdr pane, check `herdr worktree list --cwd <repo>` first. Pass `--cwd`, because without it herdr lists the workspace the user has open, which may be another repo. When the list shows the folder open as a workspace, run `herdr worktree remove --workspace <id>` instead, which runs the same git command and closes that workspace. Leave the primary workspace open. Closing it while linked worktrees are still open needs `herdr workspace close <id> --group`, and that is the user's decision, not this skill's. If git refuses, which it does for modified files, untracked files, or submodules, keep the worktree and report why.

**Dead registrations.** Propose removing only the registrations of worktrees that were actually deleted. A missing path can mean a moved folder, or network or removable storage that is currently unavailable. Keep uncertain or locked entries, and explain `repair` or `lock` where appropriate.

Pruning removes administrative files, not just a display entry. It is also a batch operation, so immediately before running it, repeat the dry run with the same expiry options. Run it only if every entry it would remove was approved and is still eligible. If the user selected a subset that prune can't isolate, skip pruning and explain why. Never delete `.git/worktrees` entries by hand to work around that.

## 3. Branches, where the care goes

Never propose deleting the default branch, the current branch, a branch checked out in a worktree that is staying, or a branch the user asked to keep. Classify a branch whose worktree is a section 2 candidate the same way, and list it with that worktree as one item. Classify each branch by its evidence:

- **Ancestor of the default ref.** Establish this explicitly with `git merge-base --is-ancestor <tip> <default-ref>`. Use `git branch -d` only after approval. Its own check uses the branch's upstream, or HEAD when there is no upstream, which is not necessarily the default. If it refuses, keep the branch and report why. Don't escalate to `-D` automatically.
- **Upstream gone, but not an ancestor.** A squash merge is one possible explanation, not proof. Use the repo's forge tool to verify the source repository and branch, the merged state, a PR head SHA equal to the current local tip, and a merge-result commit reachable from the intended default ref. A merged PR with the same name is not enough, because the branch may have new commits or its name may have been reused. Only exact, complete evidence makes the branch a candidate for `-D`, and only with explicit approval.
- **Missing or mismatched evidence.** Keep the branch. A closed, unmerged PR, unavailable historical head evidence, no PR tool, or a failed network lookup does not justify force-deletion.

## 4. Objects and remote refs

List the exact stale remote-tracking refs by comparing the selected remote's advertised branches with its fetch mappings. Inspect refspecs and prune settings. Tags, mirror mappings, and custom namespaces are not ordinary branch cleanup. Keep ambiguous mappings. Never delete remote branches or tags.

Don't use an unrestricted `git fetch --prune`, because it can prune more than the approved list. Exclude symbolic refs, including remote HEAD aliases. After approval, recheck each stale ref against a successful remote lookup, and confirm it is still a direct ref in the verified remote-tracking namespace. Delete only that ref, with `git update-ref --no-deref -d <ref> <approved-old-sha>`. The old-SHA guard rejects a changed value, and `--no-deref` keeps git from following a symbolic pointer. If the SHA changed or the lookup failed, skip that ref.

Report loose objects and offer `git gc` when it would help, but let the user run it. Don't run GC, expire reflogs, or prune objects as part of this skill.

## 5. Ask, then recheck and apply

Show the exact names, worktree paths, branch tip SHAs, evidence, and proposed operation. Group them as finished worktrees with their branches, other local branches, worktree registrations, and stale remote-tracking refs. Explain which branch deletions need force, that each deleted branch's reflog goes with it, and what goes with each worktree folder. Ask following the global Session flow rules for question tools and the text fallback. Let the user choose individual items or explicitly listed groups, and include an option to keep everything. Wait for the user's selection. Neither `apply`, nor a general cleanup request, nor showing the list counts as approval to delete.

Before deleting approved branches, refresh only the selected remote's default-branch ref. For ordinary mappings, use `git fetch --no-all --no-tags --no-prune --no-prune-tags --no-recurse-submodules --no-auto-maintenance --refmap= <remote> refs/heads/<default>:refs/remotes/<remote>/<default>`. The empty refmap keeps configured mappings from widening the fetch. Maintenance is disabled to avoid incidental pruning. Recompute ancestry and forge evidence against that refreshed ref. If the refresh fails, don't make deletions that rely on remote evidence. A local-only repo uses its established local default instead.

Immediately before deleting, recheck each approved tip, the default ref, which worktrees hold which branches, each approved worktree's status and running panes, and protection. Remove an approved worktree before its branch, and keep the branch when the worktree could not be removed. If the evidence changed, new commits appeared, new items became eligible, or the operation would be broader, show a new preview and get approval again. Run only the selected items that are still valid. If something fails unexpectedly, stop and report the operations that completed. Don't retry with force or widen the selection.

Never drop stashes, explicitly expire or delete reflogs, or touch working files, ignored files, build output, or dependencies outside an approved worktree folder. An approved worktree folder is removed whole. Deleting an approved branch removes that branch's reflog as an unavoidable side effect.

## 6. Report

Follow the global Communication and Session flow rules. After the approved operations run, say what actually ran, what was removed, and what was kept or failed.

```
One finished worktree and one branch are candidates. The worktree at `~/.herdr/worktrees/app/new-nav` is clean and no pane is running in it, and its branch `new-nav` at <sha> matches the head of merged PR #12, whose merge commit is in `origin/main`. Removing it deletes the folder with its env copies and `node_modules`, closes its herdr workspace, then force-deletes the branch. `fix/login` at <sha> is an ancestor of `origin/main`. Both branch deletions remove their reflogs. Nothing has been deleted. Which would you like to remove?
```
