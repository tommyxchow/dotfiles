#!/usr/bin/env bash
# Dotfiles installer — links files from this repo into their real locations.
# One script for macOS, Linux, and Windows under Git Bash. Windows needs
# Developer Mode (Settings > System > For developers) so an unelevated shell
# can create symlinks; the installer stops with that hint when it cannot.
# Usage: ./install.sh
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd -P)"
WINDOWS=0

case "$(uname -s)" in
  Darwin)
    VSCODE_USER="$HOME/Library/Application Support/Code/User"
    CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
    ;;
  Linux)
    VSCODE_USER="$HOME/.config/Code/User"
    CURSOR_USER="$HOME/.config/Cursor/User"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    WINDOWS=1
    # Git Bash copies the file when asked for a symlink unless told otherwise.
    # nativestrict makes ln -s create a real NTFS symlink, and fail rather
    # than copy when Windows refuses.
    export MSYS=winsymlinks:nativestrict
    appdata="$(cygpath -u "$APPDATA")"
    VSCODE_USER="$appdata/Code/User"
    CURSOR_USER="$appdata/Cursor/User"
    ;;
  *)
    echo "Unsupported OS: $(uname -s)." >&2
    exit 1
    ;;
esac

if [ "$WINDOWS" = 1 ]; then
  probe="$(mktemp -d)"
  if ! ln -s "$DOTFILES/install.sh" "$probe/link" 2>/dev/null; then
    rm -rf "$probe"
    echo "Cannot create symlinks. Turn on Developer Mode (Settings > System > For developers) and re-run." >&2
    exit 1
  fi
  rm -rf "$probe"
fi

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

# Every target this run links, so the sweep below knows what is current.
LINKED="|"

link() {
  local rel="$1"
  local target="$2"
  local src="$DOTFILES/$rel"

  if [ ! -e "$src" ]; then
    printf "  SKIP  %s (not in repo)\n" "$rel"
    return
  fi

  LINKED="$LINKED$target|"
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

link "git/.gitconfig"          "$HOME/.gitconfig"
link "git/ignore"              "$HOME/.config/git/ignore"
link "vscode/settings.json"    "$VSCODE_USER/settings.json"
link "vscode/keybindings.json" "$VSCODE_USER/keybindings.json"
link "vscode/settings.json"    "$CURSOR_USER/settings.json"
link "vscode/keybindings.json" "$CURSOR_USER/keybindings.json"
if [ "$WINDOWS" = 1 ]; then
  printf "  SKIP  ghostty/config (macOS and Linux only)\n"
else
  link "ghostty/config"        "$HOME/.config/ghostty/config"
fi
link ".claude/settings.json"   "$HOME/.claude/settings.json"
link ".claude/CLAUDE.md"       "$HOME/.claude/CLAUDE.md"
link ".claude/CLAUDE.md"       "$HOME/.config/opencode/AGENTS.md"
link ".claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
link "CLAUDE.md"               "$DOTFILES/AGENTS.md"
link "opencode/cli.json"       "$HOME/.config/opencode/cli.json"

for skill_dir in "$DOTFILES"/plugins/tc/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  link "plugins/tc/skills/$name" "$HOME/.claude/skills/$name"
done

# Herdr runs a linked plugin from the repo path, so this is a link too, only
# registered through the running herdr server instead of the filesystem.
link_herdr_plugin() {
  local id="tc.worktree-bootstrap"
  local path="$DOTFILES/herdr/plugins/worktree-bootstrap"
  if ! command -v herdr >/dev/null 2>&1; then
    printf "  SKIP  herdr plugin %s (herdr not on PATH)
" "$id"
    return
  fi
  [ "$WINDOWS" = 1 ] && path="$(cygpath -w "$path")"
  if herdr plugin list --json 2>/dev/null | grep -q "\"plugin_id\":\"$id\""; then
    printf "  OK    herdr plugin %s
" "$id"
  elif herdr plugin link "$path" >/dev/null 2>&1; then
    printf "  LINK  herdr plugin %s -> herdr/plugins/worktree-bootstrap
" "$id"
  else
    printf "  SKIP  herdr plugin %s (start herdr, then re-run or: herdr plugin link %s)
" "$id" "$path"
  fi
}
link_herdr_plugin

# Links from older layouts: in the folders this installer manages, anything
# that points into this repo but was not linked above, plus dangling links
# left by a deleted dotfiles checkout. Links to anything else are not ours.
sweep() {
  local path t
  for path in "$@"; do
    [ -L "$path" ] || continue
    case "$LINKED" in *"|$path|"*) continue ;; esac
    t="$(readlink "$path")"
    if [ "${t#"$DOTFILES"}" != "$t" ] || { [ ! -e "$path" ] && [ "${t#*dotfiles}" != "$t" ]; }; then
      rm -f "$path"
      printf "  PRUNE %s\n" "$path"
    fi
  done
}
sweep "$HOME"/.claude/* "$HOME"/.claude/skills/* "$HOME"/.agents/skills/* \
  "$HOME"/.config/opencode/* "$HOME"/.config/opencode/skills/* "$HOME"/.config/opencode/commands/* \
  "$HOME"/.codex/*
for dir in "$HOME/.agents/skills" "$HOME/.agents" "$HOME/.config/opencode/skills" "$HOME/.config/opencode/commands"; do
  rmdir "$dir" 2>/dev/null || true
done

# Cursor can load a symlinked local plugin, but the rule file needs
# alwaysApply frontmatter that .claude/CLAUDE.md does not carry. Write a real
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
write_cursor_plugin

# Grok Build reads ~/.grok/config.toml and writes runtime state back into it
# (marketplace bookkeeping, pinned sessions), so it is never symlinked. Seed a
# missing config from grok/config.toml; otherwise patch only our non-default
# keys in place, leaving everything Grok wrote untouched.
grok_toml_set() { # file section key value
  local file="$1" sec="$2" key="$3" val="$4"
  local tmp
  tmp="$(mktemp)"
  awk -v want="[$sec]" -v key="$key" -v val="$val" \
      -v pat="^[[:space:]]*${key}[[:space:]]*=" '
    BEGIN { insec = 0; seen = 0; done = 0; last = "x" }
    function emit(s) { print s; last = s }
    insec && /^\[/ && !done { emit(key " = " val); done = 1 }
    {
      if (!seen && $0 == want) { seen = 1; insec = 1; emit($0); next }
      if (insec && !done && $0 ~ pat) {
        cur = $0
        sub(/^[^=]*=[[:space:]]*/, "", cur)
        gsub(/[[:space:]]/, "", cur)
        wnt = val
        gsub(/[[:space:]]/, "", wnt)
        if (cur == wnt) emit($0)
        else emit(key " = " val)
        done = 1
        next
      }
      emit($0)
    }
    END {
      if (!seen) {
        if (last != "") print ""
        print want
        print key " = " val
      } else if (!done) {
        print key " = " val
      }
    }
  ' "$file" > "$tmp"
  if cmp -s "$tmp" "$file"; then
    rm -f "$tmp"
    return 1
  fi
  mv "$tmp" "$file"
  return 0
}

write_grok_config() {
  local seed="$DOTFILES/grok/config.toml"
  local dest="$HOME/.grok/config.toml"

  if [ ! -f "$seed" ]; then
    printf "  SKIP  grok/config.toml (not in repo)\n"
    return
  fi
  if [ ! -d "$HOME/.grok" ]; then
    printf "  SKIP  %s (no ~/.grok)\n" "$dest"
    return
  fi
  if [ ! -f "$dest" ]; then
    cp "$seed" "$dest"
    printf "  SEED  %s\n" "$dest"
    return
  fi

  local changed=0
  grok_toml_set "$dest" memory enabled true && changed=1
  grok_toml_set "$dest" features lsp_tools true && changed=1
  grok_toml_set "$dest" features two_pass_compaction true && changed=1
  grok_toml_set "$dest" ui theme '"auto"' && changed=1
  grok_toml_set "$dest" ui auto_dark_theme '"oscura-midnight"' && changed=1
  grok_toml_set "$dest" models default_reasoning_effort '"high"' && changed=1
  if [ "$changed" = 1 ]; then
    printf "  PATCH %s\n" "$dest"
  else
    printf "  OK    %s\n" "$dest"
  fi
}
write_grok_config

# Seed user-scoped LSP definitions once and leave an existing file alone. The
# repo file names the bare binary; a Windows npm-style install exposes a .cmd
# shim instead, so that one field is rewritten on seed there.
write_grok_lsp() {
  local seed="$DOTFILES/grok/lsp.json"
  local dest="$HOME/.grok/lsp.json"

  if [ ! -f "$seed" ]; then
    printf "  SKIP  grok/lsp.json (not in repo)\n"
    return
  fi
  if [ ! -d "$HOME/.grok" ]; then
    printf "  SKIP  %s (no ~/.grok)\n" "$dest"
    return
  fi
  if [ ! -f "$dest" ]; then
    if [ "$WINDOWS" = 1 ]; then
      sed 's/"typescript-language-server"/"typescript-language-server.cmd"/' "$seed" > "$dest"
    else
      cp "$seed" "$dest"
    fi
    printf "  SEED  %s\n" "$dest"
  else
    printf "  OK    %s\n" "$dest"
  fi
  if command -v typescript-language-server >/dev/null 2>&1; then
    printf "  OK    typescript-language-server on PATH\n"
  else
    printf "  WARN  typescript-language-server not on PATH — pnpm add -g typescript-language-server typescript\n"
  fi
}
write_grok_lsp

# The Agent Skills spec caps description at 1024 characters and Claude Code
# allows more, so an over-cap description passes here and only misbehaves in
# the other harnesses reading the same files.
check_skill_descriptions() {
  local over=0
  local skill name desc len
  for skill in "$DOTFILES"/plugins/tc/skills/*/SKILL.md; do
    [ -f "$skill" ] || continue
    name="$(basename "$(dirname "$skill")")"
    desc="$(awk '/^description:/ { sub(/^description:[[:space:]]*/, ""); printf "%s", $0; exit }' "$skill")"
    # A folded or literal block would measure as its marker, so the cap would
    # never fire. Say so instead of reporting a passing two-byte description.
    case "$desc" in
      '' | '>'* | '|'*)
        printf "  WARN  %s description is empty or a YAML block; this check reads one line only\n" "$name"
        over=1
        continue
        ;;
    esac
    len="$(printf '%s' "$desc" | wc -c | tr -d ' ')"
    if [ "$len" -gt 1024 ]; then
      printf "  WARN  %s description is %s bytes, over the 1024 spec cap\n" "$name" "$len"
      over=1
    fi
  done
  if [ "$over" = 0 ]; then
    printf "  OK    skill descriptions within the 1024-char spec cap\n"
  fi
  return 0
}
check_skill_descriptions

# grok.com's Customize Grok box holds 4000 characters and truncates silently
# past that. Nothing loads this file, so an over-length paste is only found by
# pasting it. Both counts here are bytes, not characters: `wc -m` counts
# characters only under a UTF-8 locale and silently falls back to bytes
# otherwise, so it would answer differently on each machine. Bytes are never
# fewer than characters, so this warns slightly early and never too late.
check_web_instructions() {
  local src="$DOTFILES/.claude/CLAUDE.web.md"
  local len
  [ -f "$src" ] || return 0
  len="$(wc -c < "$src" | tr -d ' ')"
  if [ "$len" -gt 4000 ]; then
    printf "  WARN  CLAUDE.web.md is %s chars, over grok.com's 4000 limit\n" "$len"
  else
    printf "  OK    CLAUDE.web.md fits grok.com's 4000-char limit (%s)\n" "$len"
  fi
}
check_web_instructions

echo
echo "Done."
