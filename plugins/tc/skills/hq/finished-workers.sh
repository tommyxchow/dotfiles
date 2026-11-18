#!/usr/bin/env bash
# For hq: lists its done or idle workers, one line each, with a hint on whether
# the worker can end. It only reads: it never ends a worker, deletes a file, or
# fetches. It must stay portable to Git Bash on Windows and bash 3.2 on macOS.
#
#   end    every PR it found is merged, and nothing in its checkout is unsaved
#   keep   one of its PRs is still open
#   check  uncommitted or unpushed work, a PR closed without merging, a failed
#          lookup, or no PR at all, so hq judges from the close and the board
#
# A worker's PRs are the ones on its checkout's branch plus any PR link in its
# close file, when hq hasn't deleted that file yet.

if [ -z "$HC_TERMINAL_ID" ]; then
  echo "finished-workers: HC_TERMINAL_ID is not set, so there is no hq to list workers for" >&2
  exit 1
fi

# Without this, a failed gh lookup would hide behind the jq that reads it.
set -o pipefail

closes="$HOME/.local/state/hq/closes"
pr_fields='.[] | "\(.state) \(.number) \(.headRefOid) \(.url)"'

# A worker is a child of this terminal that runs an agent, which leaves out the
# dev servers a worker or hq started.
workers=$(hc ls --json | jq -r --arg me "$HC_TERMINAL_ID" '
  .terminals[]
  | select(.parent == $me and .agent != null and (.status == "done" or .status == "idle"))
  | "\(.address)\t\(.name // .address)\t\(.cwd)"') || exit 1
workers=$(printf '%s' "$workers" | tr -d '\r' | tr '\\' '/')

if [ -z "$workers" ]; then
  echo "No done or idle workers."
  exit 0
fi

# The numbers of this worker's PRs in one state, like "#41, #44".
numbers() { printf '%s\n' "$prs" | awk -v state="$1" '$1 == state { printf "%s#%s", sep, $2; sep = ", " }'; }

# The list comes in on its own descriptor so no command in the loop can read it.
while IFS=$'\t' read -r address name cwd <&3; do
  close="$closes/$name.md"
  prs=""
  lookup_failed=""

  # The default branch is skipped, since a fork's PR can also come from a
  # branch called main and would be counted as this worker's.
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  default=$(git -C "$cwd" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
  if [ -n "$branch" ] && [ "origin/$branch" != "$default" ]; then
    found=$(cd "$cwd" && gh pr list --head "$branch" --state all \
      --json number,state,headRefOid,url | jq -r "$pr_fields") || lookup_failed=1
    prs="$found"
  fi

  paths="$cwd"
  if [ -f "$close" ]; then
    for url in $(grep -oE 'https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/[0-9]+' "$close" | sort -u); do
      found=$(gh pr view "$url" --json number,state,headRefOid,url | jq -r "[.] | $pr_fields") || lookup_failed=1
      prs=$(printf '%s\n%s' "$prs" "$found")
    done
    named=$(grep -oE "[^[:space:]\`'\"()]*\.herdr/worktrees/[^[:space:]\`'\"(),]*" "$close" | sed "s|^~|$HOME|" | tr '\\' '/')
    paths=$(printf '%s\n%s' "$paths" "$named")
  fi
  prs=$(printf '%s\n' "$prs" | tr -d '\r' | grep . | sort -u)
  paths=$(printf '%s\n' "$paths" | sed 's|[./]*$||' | grep . | sort -u)

  unsaved=""
  while IFS= read -r path; do
    git -C "$path" rev-parse --git-dir >/dev/null 2>&1 || continue
    if [ -n "$(git -C "$path" status --porcelain 2>/dev/null | head -n 1)" ]; then
      unsaved="uncommitted changes in $path"
      break
    fi
    # A squash merge with its remote branch deleted leaves the local commits on
    # no remote, so a head that matches one of the PRs counts as pushed.
    head=$(git -C "$path" rev-parse HEAD 2>/dev/null)
    case "$prs" in *" $head "*) continue ;; esac
    ahead=$(git -C "$path" rev-list --count HEAD --not --remotes 2>/dev/null)
    if [ "${ahead:-0}" -gt 0 ]; then
      unsaved="unpushed commits in $path"
      break
    fi
  done <<EOF
$paths
EOF

  open=$(numbers OPEN)
  closed=$(numbers CLOSED)
  merged=$(numbers MERGED)

  if [ -n "$open" ]; then
    hint=keep why="PR $open is still open"
  elif [ -n "$lookup_failed" ]; then
    hint=check why="a PR lookup failed, so its PRs are unknown"
  elif [ -n "$unsaved" ]; then
    hint=check why="$unsaved"
  elif [ -n "$closed" ]; then
    hint=check why="PR $closed was closed without merging"
  elif [ -z "$merged" ]; then
    if [ -f "$close" ]; then
      hint=check why="no PR found, so read its close for where the result went"
    else
      hint=check why="no PR and no close file"
    fi
  else
    hint=end why="PR $merged merged, and nothing is unsaved"
  fi

  printf '%-5s %s (%s): %s\n' "$hint" "$name" "$address" "$why"
done 3<<EOF
$workers
EOF
