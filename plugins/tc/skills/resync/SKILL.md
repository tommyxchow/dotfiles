---
name: resync
description: Bring this machine's agent harnesses in line with the dotfiles repo — clone or pull, run the installer, then prune dupes and leftovers. Works on a fresh machine after cloning this repo. Use when the user says "resync", "resync dotfiles", "sync this machine", "update harnesses", "catch this machine up", or boots another computer and wants Cursor / Grok / OpenCode (and Claude Code / Codex when present) matched to origin without leftover copies.
argument-hint: "[machine]"
---

# Resync — pull, install, then clean leftovers

Make **this machine** match the canonical layout in the dotfiles repo. Not a docs rewrite. Not a plugin redesign.

Primary harnesses: **Cursor**, **Grok Build**, **OpenCode**. Claude Code and Codex when they exist. The installer is enough for instructions and first-party skills on all of those. Marketplace plugins (`ek`, `improve`, `frontend-design`, `typescript-lsp`) need the `claude` CLI; skip that section if it is not installed.

Flow: **find repo → pull or clone → installer → marketplace plugins (if `claude`) → dedupe → leftover sweep → report.**

The installer is the mechanical source of truth (`install.sh` / `install.ps1`). Do not reimplement its links. This skill is the judgment pass around it.

## Find the repo

Prefer the current workspace if it is this repo (root `install.sh` plus `.claude/CLAUDE.md`). Else `~/dev/dotfiles`. If neither exists, clone `https://github.com/tommyxchow/dotfiles.git` to `~/dev/dotfiles` and continue from there. Do not search the whole disk.

On a fresh clone, this skill lives at `.claude/skills/resync` in the repo, so Cursor, Grok, and OpenCode can run `/resync` before the installer has linked `~/.claude/skills`. After the installer, the user-level link is the same files.

## Pull

From the repo: `git fetch` then `git pull --ff-only`. Skip pull on a brand-new clone.

- Dirty or diverged: show `git status` / `git log` and **stop**. Do not stash, reset, or force unless the user says so.
- After a fast-forward, the repo files are canonical. Ignore stale local copies of `enabledPlugins` from before the pull.

## Installer

macOS/Linux: `./install.sh`. Windows: `pwsh -File install.ps1`.

It links configs and first-party skills, prunes known stale paths, writes `~/.claude/statusline-command.sh`, and copies Cursor's local `tc` plugin. Re-running is safe. This is the step that makes Cursor / Grok / OpenCode / Codex pick up instructions and `vet` / `tldr` / `polish` / `resync` on a new machine.

## Marketplace plugins

Only if `claude` is on PATH. Cursor and Grok import these from Claude's plugin cache; OpenCode does not. A Cursor-only or OpenCode-only machine still gets first-party skills from the installer.

Read `.claude/settings.json` `enabledPlugins` **after** the pull. That list is what should be installed at **user** scope. `enabledPlugins` does not install; `claude plugin list` is the truth.

For each enabled plugin that is missing at user scope:

```bash
claude plugin install <name> --scope user
```

Then update the ones that do not come from this working tree:

```bash
claude plugin marketplace update chow
claude plugin update ek@chow
claude plugin update improve@improve
```

Skip `tc@chow`. First-party skills are installer links into `~/.claude/skills`. Enabling the plugin loads a second cached copy.

Official plugins (`typescript-lsp`, `frontend-design`) have no `autoUpdate`. Install if missing; do not invent extra official plugins.

Use the CLI. The interactive `/plugin` menu installs to **project** scope.

If `claude` is missing, say so in the report and continue.

## Dedupe

**First-party skills:** every directory under `plugins/tc/skills/` must be a symlink in `~/.claude/skills`. If `tc@chow` is installed or enabled, uninstall it `--scope user` (needs `claude`). Snapshot `enabledPlugins` first; restore any key the uninstall punched (it must not resurrect `tc@chow`).

**Cursor:** `~/.cursor/plugins/local/tc/rules/global.mdc` must match `.claude/CLAUDE.md` plus `alwaysApply: true` and no `description`. Delete `~/.cursor/plugins/cache/chow/tc` if it exists. Do not paste `CLAUDE.md` into User Rules. Third-party import should stay on so Cursor reads `~/.claude/skills`.

**Grok:** no extra links. It reads `~/.claude/CLAUDE.md` and `~/.claude/skills` through Claude compatibility.

**OpenCode:** native links in `~/.config/opencode/skills` are the same files as `~/.claude/skills`. Leave both. Do not also link `~/.agents/skills`.

**Codex:** installer already points `~/.codex/AGENTS.md` at `.claude/CLAUDE.md`. Do not recreate `~/.agents/skills`.

**Project-scope leftovers:** only if `claude` exists. `claude plugin list` plus `~/.claude/plugins/installed_plugins.json`. Uninstall `--scope project` any plugin that is not a user-scope install of an enabled plugin. Run the uninstall from that `projectPath`. Snapshot and restore user `enabledPlugins` after, same as above.

Other repos may still **enable** uninstalled plugins in their own `.claude/settings.json`. Remove those leftover `enabledPlugins` keys (or the whole object if it is only leftovers). Leave hooks, permissions, and MCP config. `settings.local.json` Skill() allows for gone plugins can go too. Do not commit those repos unless asked.

## Leftover sweep

Delete only what is clearly leftover from an older layout:

- Dangling symlinks under `~/.claude`, `~/.agents`, `~/.config/opencode` that pointed at this repo
- Identical `.bak` next to installer targets (the installer already drops those; remove a remaining `.bak` only when it is a pre-link leftover and the live file is the symlink)
- Plugin cache dirs under `~/.claude/plugins/cache` for plugins **not** in `installed_plugins.json` (skip this if there is no Claude plugin cache)
- Empty `~/.agents` / `~/.agents/skills` after pruning

Do not delete skills in `~/.claude/skills` that are not from this repo. Do not delete `ek@chow` or `improve@improve` caches while those plugins are installed.

## Report

What changed, anything still broken, what the user must do.

- Cursor: **Developer: Reload Window** after the local plugin rewrite.
- Grok / OpenCode: new `~/.claude` links are live; no extra reload if the session already sees them.
- Claude Code: `/reload-plugins` if marketplace plugins changed.

Do not commit. Do not push.
