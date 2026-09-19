---
name: cleanup
metadata:
  opencode/slash: "true"
description: 'Repo hygiene for finished worktrees, dead worktree registrations, merged branches, stale remote-tracking refs, and a bloated object store. Surveys read-only, shows exact deletion candidates and their evidence, and asks the user to select what to remove before any deletion. Even apply requires approval of the list. Use when the user says clean up branches, stale branches, old or finished worktrees, remove this worktree, prune, tidy this repo, delete merged branches, or asks what is safe to delete here. Never drops a stash, and touches working files only by removing an approved, clean worktree folder whole. Not the closer that commits pending changes (that is pass), code shaping (polish), or package catch-up (refresh).'
argument-hint: "[<repo path>] [apply]"
---

# Cleanup

Reclaim a repo that has collected months of dead refs and finished worktrees.

`$ARGUMENTS`: an optional repo path, defaulting to the current repo, and `apply` to request cleanup. Both start with a read-only survey and use the approval flow in section 5.

## 1. Survey first

Identify the repository, remote, default branch, and matching local and remote-tracking refs separately. Use the remote's advertised HEAD (`git ls-remote --symref <remote> HEAD`) when available; a cached remote HEAD is provisional. Do not guess `main` or `master` when the default or remote is ambiguous: ask. With no remote, use an explicitly established local default and report only local ancestry evidence.

Count, read-only: worktrees and their registrations (`git worktree list --porcelain` and `git worktree prune --dry-run --verbose`), each linked worktree's branch, lock, and `git -C <path> status --porcelain`, branches merged into the identified default ref, missing upstreams, stashes, and loose objects (`git count-objects -v`). Record candidate refs and their full tip SHAs. Cached refs may be stale; a missing tracking ref alone does not prove the branch was deleted remotely. Read remote refs and forge metadata where available, without fetching or pruning during survey.

Report counts and evidence before proposing deletions. A clean repo needs only one sentence.

## 2. Worktrees

**Finished worktree folders.** A linked worktree is a candidate for removal, folder included, only when all of this holds: its branch meets the section 3 evidence for deletion, `git -C <path> status --porcelain` prints nothing, it is not locked, and nothing is running in it. Never the main checkout or the worktree this session runs in. A detached worktree qualifies only when its commit is reachable from the default ref. Inside a herdr pane (`HERDR_ENV` is set), `herdr pane list` gives every pane's working directory. A pane inside the folder is in use when it hosts an agent, or when `herdr pane process-info` shows a foreground process other than the pane's own shell; then keep the worktree and say which pane. An idle shell does not count, and every herdr worktree has one. Compare paths without regard to slash direction, or to case on Windows. Outside herdr, say that occupancy could not be checked. A worktree whose branch has landed but whose tree is dirty is kept and reported with the file names, never their contents.

List the folder and its branch as one item, removed in that order. State the side effect: ignored files go with the folder, such as env copies, dependencies, and build output. Name any ignored env file that differs from the main checkout's copy, since that edit exists nowhere else.

After approval, run `git worktree remove <path>` without `--force`. Inside a herdr pane, check `herdr worktree list --cwd <repo>` first; without `--cwd` herdr lists the workspace the user has open, which may be another repo. When it shows the folder open as a workspace, run `herdr worktree remove --workspace <id>` instead, which runs the same git command and closes that workspace. A refusal, which git gives for modified files, untracked files, or submodules, means keep the worktree and report why.

**Dead registrations.** Propose only registrations for genuinely deleted worktrees. A missing path can be a moved folder or unavailable network/removable storage; keep uncertain or locked entries and explain `repair` or `lock` where appropriate.

Pruning removes administrative files, not just a display entry. It is a batch operation: immediately before running it, repeat the dry run with the same expiry options. Run only if every entry it would remove was approved and remains eligible. If the user selected a subset that prune cannot isolate, skip pruning and explain; never delete `.git/worktrees` entries by hand to work around that.

## 3. Branches, where the care goes

Never propose deleting the default branch, current branch, a branch checked out in a worktree that is staying, or one the user asked to keep. A branch whose worktree is a section 2 candidate is classified the same way and listed with that worktree as one item. Classify by evidence:

- **Ancestor of the default ref.** Establish this explicitly with `git merge-base --is-ancestor <tip> <default-ref>`. Use `git branch -d` only after approval. Its own check uses the branch's upstream, or HEAD without one, not necessarily the default. A refusal means keep it and report why; do not automatically escalate to `-D`.
- **Upstream gone, but not an ancestor.** A squash merge is one possible explanation, not proof. Use the repo's forge tool to verify the source repository and branch, merged state, PR head SHA equal to the current local tip, and a merge-result commit reachable from the intended default ref. A merged PR with the same name is insufficient: the branch may have new commits or a reused name. Only exact, complete evidence makes it a candidate for explicitly approved `-D`.
- **Missing or mismatched evidence.** Keep it. Closed-unmerged PRs, unavailable historical head evidence, no PR tool, and failed network lookups do not justify force-deletion.

## 4. Objects and remote refs

List exact stale remote-tracking refs by comparing the selected remote's advertised branches with its fetch mappings. Inspect refspecs and prune settings; tags, mirror mappings, and custom namespaces are not ordinary branch cleanup. Keep ambiguous mappings. Never delete remote branches or tags.

Do not use an unrestricted `git fetch --prune`: it can prune more than the approved list. Exclude symbolic refs, including remote HEAD aliases. After approval, recheck each stale ref against a successful remote lookup and confirm it is still a direct ref in the verified remote-tracking namespace. Delete only that ref with `git update-ref --no-deref -d <ref> <approved-old-sha>`: the old-SHA guard rejects changed values and `--no-deref` prevents following a symbolic pointer. A changed SHA or lookup failure means skip it.

Report loose objects and offer `git gc` when useful, but let the user run it. Do not run GC, expire reflogs, or prune objects as part of this skill.

## 5. Ask, then recheck and apply

Show the exact names, worktree paths, branch tip SHAs, evidence, and proposed operation, grouped as finished worktrees with their branches, other local branches, worktree registrations, and stale remote-tracking refs. Explain which branch deletions require force, that branch reflogs go too, and what goes with each worktree folder. Follow the global Session flow rules for question tools and the text fallback, letting the user choose individual items or explicitly listed groups, with a keep-everything option. Wait for the selection: neither `apply`, a general cleanup request, nor showing the list approves deletion.

Before deleting approved branches, refresh only the selected remote's default-branch ref. For ordinary mappings, use `git fetch --no-all --no-tags --no-prune --no-prune-tags --no-recurse-submodules --no-auto-maintenance --refmap= <remote> refs/heads/<default>:refs/remotes/<remote>/<default>`. The empty refmap prevents configured mappings from widening the fetch; maintenance is disabled to avoid incidental pruning. Recompute ancestry and forge evidence against that refreshed ref. A failed refresh blocks deletions that rely on remote evidence; local-only repos use their established local default instead.

Recheck each approved tip, default ref, which worktrees hold which branches, each approved worktree's status and running panes, and protection immediately before deleting. Remove an approved worktree before its branch, and keep the branch when the worktree would not go. Changed evidence, new commits, newly eligible items, or a broader operation need a new preview and approval. Execute only the still-valid selected items. Stop on an unexpected failure and report completed operations; do not retry with force or widen the selection.

Never drop stashes, explicitly expire or delete reflogs, or touch working files, ignored files, build output, or dependencies outside an approved worktree folder, which goes whole. Approved branch deletion removes that branch's reflog as an inherent side effect.

## 6. Report

Follow the global Communication and Session flow rules. After execution, say what actually ran, what was removed, and what was kept or failed.

```
One finished worktree and one branch are candidates. The worktree at `~/.herdr/worktrees/app/tc-new-nav` is clean and no pane is running in it, and its branch `tc/new-nav` at <sha> matches the head of merged PR #12, whose merge commit is in `origin/main`. Removing it deletes the folder with its env copies and `node_modules`, closes its herdr workspace, then force-deletes the branch. `fix/login` at <sha> is an ancestor of `origin/main`. Both branch deletions remove their reflogs. Nothing has been deleted. Which would you like to remove?
```
