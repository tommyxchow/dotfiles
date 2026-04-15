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
}

link "git/.gitconfig"          "$HOME/.gitconfig"
link "vscode/settings.json"    "$VSCODE_USER/settings.json"
link "vscode/keybindings.json" "$VSCODE_USER/keybindings.json"
link ".claude/settings.json"   "$HOME/.claude/settings.json"
link ".claude/CLAUDE.md"       "$HOME/.claude/CLAUDE.md"
link ".claude/notify.sh"       "$HOME/.claude/notify.sh"

# Claude skills: symlink each skill dir individually so future untracked skills
# at ~/.claude/skills/ aren't swept inside the repo.
if [ -d "$DOTFILES/.claude/skills" ]; then
  for skill in "$DOTFILES/.claude/skills"/*/; do
    [ -d "$skill" ] || continue
    name="${skill%/}"
    name="${name##*/}"
    link ".claude/skills/$name" "$HOME/.claude/skills/$name"
  done
fi

echo
echo "Done."
