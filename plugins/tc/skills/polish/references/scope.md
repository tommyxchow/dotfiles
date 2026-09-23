# Pool scope

Shared by `polish` and `review`. The calling skill parses its own scope keyword (`staged`, `unstaged`, `branch`, `all`, and review's `pr`); this file says what each one means and how the pool is built.

Build the pool from two sources:

- **Source A — git changes** in the CWD repo, as the table defines them.
- **Source B — session-edited files**, meaning files changed with Edit/Write in this conversation in any repo, **except when scope is `branch`**. Use their absolute paths, and don't `git diff` them.

| Scope | Source A | Source B | Untracked |
|---|---|---|---|
| *(default)* | dirty vs HEAD (`git diff HEAD` if staged exists, else `git diff`) | include | include via `git status` |
| `unstaged` | `git diff` | include | include |
| `staged` | `git diff --cached` | include | no |
| `branch` | committed range only: `<base>...HEAD`, with the base established below | **exclude** | **exclude** |
| `all` | same range as `branch` **+** dirty vs HEAD (`git diff HEAD` so staged+unstaged are included) | include | include |

**Base.** Honor a caller-supplied task base. Otherwise use the PR's intended base, or the established default branch for an unstacked feature branch. On the default branch itself, use the recorded task-start commit. If that is missing, establish it from the task's commits or ask. Never compare a branch with itself and call the empty diff a review. Never use `@{upstream}...HEAD` for a feature branch: it drops pushed work, and the default branch would include a stacked parent's changes.

If both sources are empty after applying the table, fall back to files the user named. If there are none, ask.

**Caller-supplied pool.** When another skill (`pass`) or the user hands over an explicit file list, that list is the whole pool and replaces Sources A and B. Session-wide discovery is for a bare run. `all` still widens to the branch.

**Post-commit / clean tree.** An empty Source A with a non-empty Source B is still a pool. A bare run means "what we worked on this session," not "only uncommitted hunks," so read those files from disk and size any gate from the pool file set rather than from `git diff`. Don't stop at "nothing to do" because `git status` is clean or autofix changed nothing. "Already clean" is what the read says after it has run, or the result for a truly trivial pool under the calling skill's size gate.

**Ownership.** Filter every pool by task ownership before editing. Dirty or session-edited files can contain unrelated hunks. Preserve those hunks and any staged state under the global Git rule. Skip whole-file autofix on mixed files when it would change unrelated work. Ask once, and only if ownership cannot be established.
