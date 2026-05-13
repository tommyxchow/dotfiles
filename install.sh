#!/usr/bin/env bash
# Dotfiles installer — creates symlinks from this repo to config locations.
# For Windows, use install.ps1 instead (symlinks require Developer Mode).
# Usage: ./install.sh
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd -P)"

case "$(uname -s)" in
  Darwin) VSCODE_USER="$HOME/Library/Application Support/Code/User" ;;
  Linux)  VSCODE_USER="$HOME/.config/Code/User" ;;
  *)
    echo "Unsupported OS: $(uname -s). Use install.ps1 on Windows." >&2
    exit 1
    ;;
esac

link() {
  local rel="$1"
  local target="$2"
  local src="$DOTFILES/$rel"

  if [ ! -e "$src" ]; then
    printf "  SKIP  %s (not in repo)\n" "$rel"
    return
  fi

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
    printf "  OK    %s\n" "$target"
    return
  fi

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak"
    printf "  BAK   %s -> %s\n" "$target" "$target.bak"
  fi

  ln -sfn "$src" "$target"
  printf "  LINK  %s -> %s\n" "$target" "$rel"

  # Cleanup: drop .bak if it's byte-identical to the new symlink target.
  # Keeps .bak only when it actually preserves unique content.
  if [ -e "$target.bak" ]; then
    if [ -d "$src" ] && [ -d "$target.bak" ]; then
      diff -rq "$target.bak" "$src" > /dev/null 2>&1 && { rm -rf "$target.bak"; printf "  CLEAN %s.bak (identical)\n" "$target"; }
    elif [ -f "$src" ] && [ -f "$target.bak" ]; then
      cmp -s "$target.bak" "$src" && { rm -f "$target.bak"; printf "  CLEAN %s.bak (identical)\n" "$target"; }
    fi
  fi
}

link "git/.gitconfig"          "$HOME/.gitconfig"
link "vscode/settings.json"    "$VSCODE_USER/settings.json"
link "vscode/keybindings.json" "$VSCODE_USER/keybindings.json"
link "ghostty/config"          "$HOME/.config/ghostty/config"
link ".claude/settings.json"   "$HOME/.claude/settings.json"
link ".claude/CLAUDE.md"       "$HOME/.claude/CLAUDE.md"
link ".claude/CLAUDE.md"       "$HOME/.codex/AGENTS.md"
link ".claude/notify.sh"       "$HOME/.claude/notify.sh"

# Shared skills: symlink each skill dir individually so future untracked skills
# at ~/.claude/skills/ or ~/.agents/skills/ aren't swept inside the repo.
# statusline-install depends on Claude Code-specific features (subagents,
# statusline JSON schema) — linked only to ~/.claude/skills, never the shared
# ~/.agents/skills picked up by codex/opencode.
if [ -d "$DOTFILES/.claude/skills" ]; then
  for skill in "$DOTFILES/.claude/skills"/*/; do
    [ -d "$skill" ] || continue
    name="${skill%/}"
    name="${name##*/}"
    link ".claude/skills/$name" "$HOME/.claude/skills/$name"
    [ "$name" = "statusline-install" ] || link ".claude/skills/$name" "$HOME/.agents/skills/$name"
  done
fi

upsert_codex_config() {
  local src="$DOTFILES/codex/config.toml"
  local target="$HOME/.codex/config.toml"
  local tmp
  [ -f "$src" ] || return 0

  mkdir -p "$(dirname "$target")"
  touch "$target"
  tmp="$(mktemp)"

  awk '
    FNR == NR {
      if ($0 ~ /^[[:space:]]*[A-Za-z0-9_]+[[:space:]]*=/) {
        key = $0
        sub(/=.*/, "", key)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
        if (!(key in settings)) {
          order[++count] = key
        }
        settings[key] = $0
      }
      next
    }

    function emit_missing() {
      if (emitted) {
        return
      }
      for (i = 1; i <= count; i++) {
        if (!(order[i] in seen)) {
          print settings[order[i]]
          wrote_head = 1
        }
      }
      emitted = 1
    }

    /^[[:space:]]*\[/ && !in_tables {
      emit_missing()
      if (wrote_head) {
        print ""
      }
      in_tables = 1
    }

    !in_tables && $0 ~ /^[[:space:]]*[A-Za-z0-9_]+[[:space:]]*=/ {
      key = $0
      sub(/=.*/, "", key)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      if (key in settings) {
        print settings[key]
        seen[key] = 1
        wrote_head = 1
        next
      }
    }

    {
      print
      if (!in_tables && $0 !~ /^[[:space:]]*$/) {
        wrote_head = 1
      }
    }

    END {
      emit_missing()
    }
  ' "$src" "$target" > "$tmp"
  mv "$tmp" "$target"

  printf "  MERGE %s <- codex/config.toml\n" "$target"
}

upsert_codex_config

echo
echo "Done."
