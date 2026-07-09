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

echo
echo "Done."
