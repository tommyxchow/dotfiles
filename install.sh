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
    printf "  BAK   %s -> %s.bak\n" "$target" "$target"
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

stale_opencode_agents="$HOME/.config/opencode/AGENTS.md"
if [ -L "$stale_opencode_agents" ] && [ "$(readlink "$stale_opencode_agents")" = "$DOTFILES/.claude/CLAUDE.md" ]; then
  rm -f "$stale_opencode_agents"
  printf "  CLEAN %s (opencode uses ~/.claude fallback)\n" "$stale_opencode_agents"
fi

# Skills that depend on Claude Code-specific features (subagents, statusline
# JSON schema, etc.) — linked only to ~/.claude/skills, never the shared
# ~/.agents/skills picked up by codex/opencode.
CLAUDE_ONLY_SKILLS=(statusline-install)

is_claude_only() {
  local name="$1"
  for s in "${CLAUDE_ONLY_SKILLS[@]}"; do
    [ "$s" = "$name" ] && return 0
  done
  return 1
}

# Shared skills: symlink each skill dir individually so future untracked skills
# at ~/.claude/skills/ or ~/.agents/skills/ aren't swept inside the repo.
if [ -d "$DOTFILES/.claude/skills" ]; then
  for skill in "$DOTFILES/.claude/skills"/*/; do
    [ -d "$skill" ] || continue
    name="${skill%/}"
    name="${name##*/}"
    link ".claude/skills/$name" "$HOME/.claude/skills/$name"
    is_claude_only "$name" || link ".claude/skills/$name" "$HOME/.agents/skills/$name"
  done
fi

echo
echo "Done."
