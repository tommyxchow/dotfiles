#!/usr/bin/env bash
# Dotfiles installer — creates symlinks from this repo to config locations.
# For Windows, use install.ps1 instead (symlinks require Developer Mode).
# Usage: ./install.sh
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd -P)"
LEGACY_OPENCODE_SKILLS="$HOME/.config/opencode/skills"

# Migration from the pre-OpenCode compatibility setup, which linked every tc skill.
if [ -L "$LEGACY_OPENCODE_SKILLS" ] && [ "$(readlink "$LEGACY_OPENCODE_SKILLS")" = "$DOTFILES/plugins/tc/skills" ]; then
  rm "$LEGACY_OPENCODE_SKILLS"
fi

case "$(uname -s)" in
  Darwin)
    VSCODE_USER="$HOME/Library/Application Support/Code/User"
    CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
    ;;
  Linux)
    VSCODE_USER="$HOME/.config/Code/User"
    CURSOR_USER="$HOME/.config/Cursor/User"
    ;;
  *)
    echo "Unsupported OS: $(uname -s). Use install.ps1 on Windows." >&2
    exit 1
    ;;
esac

clean_bak() {
  local src="$1"
  local target="$2"
  if [ ! -e "$target.bak" ]; then
    return 0
  fi
  if [ -d "$src" ] && [ -d "$target.bak" ]; then
    if diff -rq "$target.bak" "$src" > /dev/null 2>&1; then
      rm -rf "$target.bak"
      printf "  CLEAN %s.bak (identical)\n" "$target"
    fi
  elif [ -f "$src" ] && [ -f "$target.bak" ]; then
    if cmp -s "$target.bak" "$src"; then
      rm -f "$target.bak"
      printf "  CLEAN %s.bak (identical)\n" "$target"
    fi
  fi
}

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
    clean_bak "$src" "$target"
    return
  fi

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak"
    printf "  BAK   %s -> %s\n" "$target" "$target.bak"
  fi

  ln -sfn "$src" "$target"
  printf "  LINK  %s -> %s\n" "$target" "$rel"
  clean_bak "$src" "$target"
}

# Drop leftover symlinks from older installer layouts.
prune_stale() {
  local path="$1"
  [ -L "$path" ] || return 0
  local t
  t="$(readlink "$path")"
  if [ ! -e "$path" ] || [ "${t#"$DOTFILES"}" != "$t" ]; then
    rm -f "$path"
    printf "  PRUNE %s\n" "$path"
  fi
}

prune_stale "$HOME/.claude/notify.sh"
prune_stale "$HOME/.claude/skills/understand"
prune_stale "$HOME/.agents/skills/understand"
prune_stale "$HOME/.claude/skills/resync"
prune_stale "$HOME/.agents/skills/resync"
prune_stale "$HOME/.config/opencode/skills/resync"
prune_stale "$HOME/.config/opencode/commands/resync.md"

link "git/.gitconfig"          "$HOME/.gitconfig"
link "vscode/settings.json"    "$VSCODE_USER/settings.json"
link "vscode/keybindings.json" "$VSCODE_USER/keybindings.json"
link "vscode/settings.json"    "$CURSOR_USER/settings.json"
link "vscode/keybindings.json" "$CURSOR_USER/keybindings.json"
link "ghostty/config"          "$HOME/.config/ghostty/config"
link ".claude/settings.json"   "$HOME/.claude/settings.json"
link ".claude/CLAUDE.md"       "$HOME/.claude/CLAUDE.md"
link ".claude/CLAUDE.md"       "$HOME/.codex/AGENTS.md"

for skill_dir in "$DOTFILES"/plugins/tc/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  prune_stale "$HOME/.agents/skills/$name"
  prune_stale "$HOME/.config/opencode/skills/$name"
  link "plugins/tc/skills/$name" "$HOME/.claude/skills/$name"
done
for cmd in "$DOTFILES"/opencode/commands/*.md; do
  [ -f "$cmd" ] || continue
  name="$(basename "$cmd")"
  link "opencode/commands/$name" "$HOME/.config/opencode/commands/$name"
done
rmdir "$HOME/.agents/skills" 2>/dev/null || true
rmdir "$HOME/.agents" 2>/dev/null || true

# Cursor rejects a plugin folder that symlinks to this repo. Write a real
# directory under ~/.cursor/plugins/local and copy CLAUDE.md into an
# alwaysApply rule. Re-run the installer after editing CLAUDE.md, then
# Developer: Reload Window. Do not put a description on the rule; Cursor has
# mapped alwaysApply + description to agent-requestable.
write_cursor_plugin() {
  local src="$DOTFILES/.claude/CLAUDE.md"
  local dest="$HOME/.cursor/plugins/local/tc"
  local manifest="$dest/.cursor-plugin/plugin.json"
  local rule="$dest/rules/global.mdc"
  local tmp

  if [ ! -f "$src" ]; then
    printf "  SKIP  .claude/CLAUDE.md (not in repo)\n"
    return
  fi

  mkdir -p "$dest/.cursor-plugin" "$dest/rules"
  local desired_manifest='{"name":"tc","description":"Personal global instructions from dotfiles"}'
  if [ "$(cat "$manifest" 2>/dev/null | tr -d '\n')" != "$desired_manifest" ]; then
    printf '%s\n' "$desired_manifest" > "$manifest"
  fi

  tmp="$(mktemp)"
  printf '%s\n' '---' 'alwaysApply: true' '---' '' > "$tmp"
  cat "$src" >> "$tmp"
  if [ -f "$rule" ] && cmp -s "$tmp" "$rule"; then
    rm -f "$tmp"
    printf "  OK    %s\n" "$rule"
    return
  fi
  mv "$tmp" "$rule"
  printf "  WRITE %s\n" "$rule"
}

# The skill markdown is the source of truth. settings.json already points here.
write_statusline() {
  local skill="$DOTFILES/plugins/tc/skills/statusline-install/SKILL.md"
  local dest="$HOME/.claude/statusline-command.sh"
  local tmp

  if [ ! -f "$skill" ]; then
    printf "  SKIP  statusline-install skill (not in repo)\n"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  tmp="$(mktemp)"
  awk '
    /^## Script$/ { want = 1; next }
    want && /^```bash$/ { code = 1; next }
    code && /^```$/ { exit }
    code { print }
  ' "$skill" > "$tmp"

  if [ ! -s "$tmp" ]; then
    rm -f "$tmp"
    printf "  SKIP  statusline script missing from skill\n"
    return
  fi
  if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"
    printf "  OK    %s\n" "$dest"
    return
  fi
  mv "$tmp" "$dest"
  printf "  WRITE %s\n" "$dest"
}

write_cursor_plugin
write_statusline

echo
echo "Done."
