#!/usr/bin/env bash
# For hq: lists its done or idle workers, one line each, with a hint on whether
# the worker can end. It only reads: it never ends a worker, deletes a file, or
# fetches. It must stay portable to Git Bash on Windows and bash 3.2 on macOS.
#
#   end    every PR it found is merged, a checkout of its sits on a merged PR's
#          head, and nothing in its checkouts is unsaved
#   keep   one of its PRs is still open
#   check  uncommitted work, commits no merged PR holds, a PR closed without
#          merging, a failed lookup, a path it couldn't read, or no PR at all,
#          so hq judges from the close and the board
#
# hq ends a worker marked end without asking, so every doubt comes out as check.
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

# A checkout's remote default branch, like origin/main, or nothing when it
# can't be told.
default_ref() {
  local ref
  ref=$(git -C "$1" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
  if [ -n "$ref" ]; then
    printf '%s' "$ref"
  elif git -C "$1" rev-parse --verify --quiet origin/main >/dev/null 2>&1; then
    printf 'origin/main'
  elif git -C "$1" rev-parse --verify --quiet origin/master >/dev/null 2>&1; then
    printf 'origin/master'
  fi
}

# Sets $unsaved when the checkout at $1 holds work that isn't safely merged.
# $2 is set for a path that only the close names.
unsaved_in() {
  local path="$1" head base ahead
  if ! git -C "$path" rev-parse --git-dir >/dev/null 2>&1; then
    # Nothing was inspected, so it can't pass as clean: a path from the close
    # may be a real worktree that was parsed wrong, and a worker whose own
    # folder isn't a checkout did its work somewhere this script can't see.
    if [ -n "$2" ]; then
      unsaved="its close names $path, which can't be read as a checkout"
    else
      unsaved="its folder $path isn't a checkout, so unsaved work can't be ruled out"
    fi
    return
  fi
  # --no-optional-locks keeps status from taking the index lock, which could
  # fail a commit another session is making in the same checkout.
  if [ -n "$(git --no-optional-locks -C "$path" status --porcelain 2>/dev/null | head -n 1)" ]; then
    unsaved="uncommitted changes in $path"
    return
  fi
  # A head that one of its PRs holds is saved, which also covers a squash merge
  # whose branch was deleted. Any other commit has to be on the default branch.
  # Being on some remote branch isn't enough: a commit pushed after the merge,
  # or to a branch name an earlier PR used, is in no merged PR.
  head=$(git -C "$path" rev-parse HEAD 2>/dev/null)
  if printf '%s\n' "$prs" | awk -v head="$head" '$1 == "MERGED" && $3 == head { found = 1 } END { exit !found }'; then
    merged_head=1
    return
  fi
  case "$prs" in *" $head "*) return ;; esac
  base=$(default_ref "$path")
  if [ -z "$base" ]; then
    unsaved="the default branch of $path can't be told, so its commits can't be checked"
    return
  fi
  ahead=$(git -C "$path" rev-list --count HEAD --not "$base" 2>/dev/null)
  if [ "${ahead:-1}" -gt 0 ]; then
    unsaved="commits in $path that no merged PR or the default branch holds"
  fi
}

# The list comes in on its own descriptor so no command in the loop can read it.
while IFS=$'\t' read -r address name cwd <&3; do
  close="$closes/$name.md"
  prs=""
  named=""
  lookup_failed=""

  # The default branch is skipped, since a fork's PR can also come from a
  # branch called main and would be counted as this worker's.
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  if [ -n "$branch" ] && [ "origin/$branch" != "$(default_ref "$cwd")" ]; then
    found=$(cd "$cwd" && gh pr list --head "$branch" --state all \
      --json number,state,headRefOid,url | jq -r "$pr_fields") || lookup_failed=1
    prs="$found"
  fi

  if [ -f "$close" ]; then
    for url in $(grep -oE 'https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/[0-9]+' "$close" | sort -u); do
      found=$(gh pr view "$url" --json number,state,headRefOid,url | jq -r "[.] | $pr_fields") || lookup_failed=1
      prs=$(printf '%s\n%s' "$prs" "$found")
    done
    # Worktree paths the close names, in either slash style, with the markup
    # and punctuation around them trimmed off.
    named=$(tr '\\' '/' <"$close" |
      grep -oE "[^[:space:]\`'\"()]*\.herdr/worktrees/[^[:space:]\`'\"()/]+/[^[:space:]\`'\"()/]+" |
      sed -e 's|^[^A-Za-z~/]*||' -e "s|^~|$HOME|" -e 's|[^A-Za-z0-9_-]*$||' | grep . | sort -u)
  fi
  prs=$(printf '%s\n' "$prs" | tr -d '\r' | grep . | sort -u)

  unsaved=""
  merged_head=""
  unsaved_in "$cwd"
  while IFS= read -r path; do
    [ -z "$unsaved" ] || break
    [ -z "$path" ] || unsaved_in "$path" named
  done <<EOF
$named
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
  elif [ -z "$merged_head" ]; then
    # A merged PR that a close only cites, or one an earlier task opened from
    # the same branch name, says nothing about this worker's own work.
    hint=check why="PR $merged merged, but no checkout of its sits on that PR's head"
  else
    hint=end why="PR $merged merged, and nothing is unsaved"
  fi

  printf '%-5s %s (%s): %s\n' "$hint" "$name" "$address" "$why"
done 3<<EOF
$workers
EOF
