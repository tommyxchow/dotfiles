---
name: cleanup
description: 'Repo hygiene for dead worktree registrations, merged branches, stale remote-tracking refs, and a bloated object store. Surveys read-only, shows exact deletion candidates and their evidence, and asks the user to select what to remove before any deletion. Even apply requires approval of the list. Use when the user says clean up branches, stale branches, old worktrees, prune, tidy this repo, delete merged branches, or asks what is safe to delete here. Never drops a stash or touches working files, build output, or dependencies. Not the end-of-slice closer for pending changes (that is pass), code shaping (polish), or package catch-up (refresh).'
argument-hint: "[<repo path>] [apply]"
---

# Cleanup

Reclaim a repo that has collected months of dead refs. Working files, ignored files, build output, and dependencies are out of scope. Branch deletion also removes that branch's reflog, so it still needs an explicit decision.

`$ARGUMENTS`: an optional repo path, defaulting to the current repo, and `apply` to request cleanup. Both start with a read-only survey. Neither `apply` nor a general request to clean up approves unseen deletions. Show the exact list and ask first; only the user's selection authorizes execution.

## 1. Survey first

Identify the repository, remote, default branch, and matching local and remote-tracking refs separately. Use the remote's advertised HEAD (`git ls-remote --symref <remote> HEAD`) when available; a cached remote HEAD is provisional. Do not guess `main` or `master` when the default or remote is ambiguous: ask. With no remote, use an explicitly established local default and report only local ancestry evidence.

Count, read-only: worktree registrations (`git worktree list --porcelain` and `git worktree prune --dry-run --verbose`), branches merged into the identified default ref, missing upstreams, stashes, and loose objects (`git count-objects -v`). Record candidate refs and their full tip SHAs. Cached refs may be stale; a missing tracking ref alone does not prove the branch was deleted remotely. Read remote refs and forge metadata where available, without fetching or pruning during survey.

Report counts and evidence before proposing deletions. A clean repo needs only one sentence.

## 2. Worktrees

Propose only registrations for genuinely deleted worktrees. A missing path can be a moved folder or unavailable network/removable storage; keep uncertain or locked entries and explain `repair` or `lock` where appropriate. Existing worktree folders are never removed here.

Pruning removes administrative files, not just a display entry. It is a batch operation: immediately before running it, repeat the dry run with the same expiry options. Run only if every entry it would remove was approved and remains eligible. If the user selected a subset that prune cannot isolate, skip pruning and explain; never delete `.git/worktrees` entries by hand to work around that.

## 3. Branches, where the care goes

Never propose deleting the default branch, current branch, a branch checked out in any worktree, or one the user asked to keep. Classify the rest by evidence:

- **Ancestor of the default ref.** Establish this explicitly with `git merge-base --is-ancestor <tip> <default-ref>`. Use `git branch -d` only after approval. Its own check uses the branch's upstream, or HEAD without one, not necessarily the default. A refusal means keep it and report why; do not automatically escalate to `-D`.
- **Upstream gone, but not an ancestor.** A squash merge is one possible explanation, not proof. Use the repo's forge tool to verify the source repository and branch, merged state, PR head SHA equal to the current local tip, and a merge-result commit reachable from the intended default ref. A merged PR with the same name is insufficient: the branch may have new commits or a reused name. Only exact, complete evidence makes it a candidate for explicitly approved `-D`.
- **Missing or mismatched evidence.** Keep it. Closed-unmerged PRs, unavailable historical head evidence, no PR tool, and failed network lookups do not justify force-deletion.

## 4. Objects and remote refs

List exact stale remote-tracking refs by comparing the selected remote's advertised branches with its fetch mappings. Inspect refspecs and prune settings; tags, mirror mappings, and custom namespaces are not ordinary branch cleanup. Keep ambiguous mappings. Never delete remote branches or tags.

Do not use an unrestricted `git fetch --prune`: it can prune more than the approved list. Exclude symbolic refs, including remote HEAD aliases. After approval, recheck each stale ref against a successful remote lookup and confirm it is still a direct ref in the verified remote-tracking namespace. Delete only that ref with `git update-ref --no-deref -d <ref> <approved-old-sha>`: the old-SHA guard rejects changed values and `--no-deref` prevents following a symbolic pointer. A changed SHA or lookup failure means skip it.

Report loose objects and offer `git gc` when useful, but let the user run it. Do not run GC, expire reflogs, or prune objects as part of this skill.

## 5. Ask, then recheck and apply

Show the exact names, worktree paths, branch tip SHAs, evidence, and proposed operation, grouped as local branches, worktree registrations, and stale remote-tracking refs. Explain which branch deletions require force and that branch reflogs go too. Follow the global Session flow rules for question tools and the text fallback, letting the user choose individual items or explicitly listed groups, with a keep-everything option. Wait for the answer; do not treat showing the list as approval.

Before deleting approved branches, refresh only the selected remote's default-branch ref. For ordinary mappings, use `git fetch --no-all --no-tags --no-prune --no-prune-tags --no-recurse-submodules --no-auto-maintenance --refmap= <remote> refs/heads/<default>:refs/remotes/<remote>/<default>`. The empty refmap prevents configured mappings from widening the fetch; maintenance is disabled to avoid incidental pruning. Recompute ancestry and forge evidence against that refreshed ref. A failed refresh blocks deletions that rely on remote evidence; local-only repos use their established local default instead.

Recheck each approved tip, default ref, worktree occupancy, and protection immediately before deleting. Changed evidence, new commits, newly eligible items, or a broader operation need a new preview and approval. Execute only the still-valid selected items. Stop on an unexpected failure and report completed operations; do not retry with force or widen the selection.

Never drop stashes, explicitly expire or delete reflogs, or touch working files, ignored files, build output, or dependencies. Approved branch deletion removes that branch's reflog as an inherent side effect.

## 6. Report

Follow the global Communication and Session flow rules. Before approval, report the candidates and ask for the selection. After execution, say what actually ran, what was removed, and what was kept or failed. Do not describe a proposed deletion as completed.

```
Two branches are candidates: `fix/login` at <sha> is an ancestor of `origin/main`; `fix/menu` at <sha> matches the head of merged PR #12, whose merge commit is in `origin/main`, and needs force-deletion. Both deletions remove their branch reflogs. Nothing has been deleted. Which would you like to remove?
```

## Distinct from

| Skill     | This skill                                                                  |
| --------- | --------------------------------------------------------------------------- |
| `pass`    | Closes the slice you just built. Cleanup is the repo around it, and ignores pending changes. |
| `polish`  | Shape of working code. Cleanup never opens a source file.                    |
| `refresh` | Packages and framework versions. Cleanup touches no dependency.               |
| `pr`      | Ships a branch. Cleanup removes the branches that already shipped.            |
