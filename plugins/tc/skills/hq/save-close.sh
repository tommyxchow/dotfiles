#!/usr/bin/env bash
# Claude Code Stop hook for hq. Saves a named herdr agent's last message to
# ~/.local/state/hq/closes/<name>.md, so hq reads the whole close instead of a
# screen that cuts long ones off. settings.json runs it; it must stay portable
# to Git Bash on Windows and bash 3.2 on macOS.

dir="$HOME/.local/state/hq"
[ -d "$dir" ] || exit 0 # hq has never run on this machine

input=$(cat)

# A failed lookup (herdr or hc not answering) just means no name.
if [ "$HERDR_ENV" = 1 ] && [ -n "$HERDR_PANE_ID" ]; then
  name=$(herdr agent get "$HERDR_PANE_ID" 2>/dev/null | jq -r '.result.agent.name // empty' 2>/dev/null)
elif [ -n "$HC_TERMINAL_ID" ]; then
  # A worker hq started carries an hc name; a session it picked up only a label.
  # hq clears a stale label to an empty string, which counts as no name.
  name=$(hc get "$HC_TERMINAL_ID" --json 2>/dev/null |
    jq -r '[.name, .labels["tc.agent"]] | map(select(. != null and . != "")) | first // empty' 2>/dev/null)
else
  exit 0
fi

name=$(printf '%s' "$name" | tr -d '\r')
# No dots or slashes, so the name can't point outside closes/.
[[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] || exit 0
[ "$name" = hq ] && exit 0 # hq reads its workers' closes, never its own

# A Stop hook that exits 2 keeps Claude working, and jq can exit 2, so every
# failure from here exits 1, which Claude Code shows as a hook error.
set -o pipefail
mkdir -p "$dir/closes" || exit 1
# The temp file sits in the same folder so the rename below is atomic.
tmp=$(mktemp "$dir/closes/.$name.XXXXXX") || exit 1
trap 'rm -f "$tmp"' EXIT
# jq on Windows writes CRLF line endings; hq wants the text as Claude wrote it.
printf '%s' "$input" | jq -j '.last_assistant_message // empty' | tr -d '\r' >"$tmp" || exit 1
[ -s "$tmp" ] || exit 0 # an empty message would overwrite a real close with nothing
mv -f "$tmp" "$dir/closes/$name.md" || exit 1
