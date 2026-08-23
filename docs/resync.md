# Resync — pull, install, then clean leftovers

Make **this machine** match the canonical layout in the dotfiles repo. Also check whether copied skills have drifted from upstream; do not apply that here. Not a docs rewrite. Not a plugin redesign.

This playbook lives in the repo and loads only when you open this workspace and ask to resync. It is not a global skill.

Refreshing packages and framework versions in a **product** repo is the `refresh` skill. Do not run that here.

Primary harnesses: **Cursor**, **Grok Build**, **OpenCode**. Claude Code and Codex when they exist. The installer is enough for instructions and first-party skills on all of those. Marketplace plugins (`ek`, `improve`, `frontend-design`, `typescript-lsp`) need the `claude` CLI; skip that section if it is not installed.

Flow: **find repo → pull or clone → installer → marketplace plugins (if `claude`) → dedupe → leftover sweep → vendored skills → report.**

The installer is the mechanical source of truth (`install.sh` / `install.ps1`). Do not reimplement its links. This file is the judgment pass around it.

## Find the repo

Prefer the current workspace if it is this repo (root `install.sh` plus `.claude/CLAUDE.md`). Else `~/dev/dotfiles`. If neither exists, clone `https://github.com/tommyxchow/dotfiles.git` to `~/dev/dotfiles` and continue from there. Do not search the whole disk.

## Pull

From the repo: `git fetch` then `git pull --ff-only`. Skip pull on a brand-new clone.

- Dirty or diverged: show `git status` / `git log` and **stop**. Do not stash, reset, or force unless the user says so.
- After a fast-forward, the repo files are canonical. Ignore stale local copies of `enabledPlugins` from before the pull.

## Installer

macOS/Linux: `./install.sh`. Windows: `pwsh -File install.ps1`.

It links configs and first-party skills, prunes known stale paths, writes `~/.claude/statusline-command.sh`, and copies Cursor's local `tc` plugin. It also seeds `~/.grok/config.toml` from `grok/config.toml` on new machines and patches only that file's non-default keys on re-runs — Grok writes runtime state into it, so it is never symlinked. Same for `~/.grok/lsp.json` (seed if missing, warn if `typescript-language-server` is not on PATH; never overwrite an existing file). Re-running is safe. This is the step that makes Cursor / Grok / OpenCode / Codex pick up instructions and `vet` / `tldr` / `polish` / `grill-me` / `refresh` / `pass` on a new machine.

On Windows, symlink creation needs Developer Mode (or an elevated shell). If a link comes out dead, fix the mode and re-run the installer rather than replacing links with copies.

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

**Grok:** `~/.grok/config.toml` must carry the non-default keys from `grok/config.toml` — the installer patches them; re-run it if drifted. Everything else in that file is Grok-owned runtime state; do not manage it. `~/.grok/lsp.json` should exist (installer seeds from `grok/lsp.json`); warn if `typescript-language-server` is missing from PATH. No extra links: Grok reads `~/.claude/CLAUDE.md` and `~/.claude/skills` through Claude compatibility.

**OpenCode:** it already reads `~/.claude/skills`. Do not also link first-party skills into `~/.config/opencode/skills`. Slash-command stubs in `~/.config/opencode/commands` stay. Do not also link `~/.agents/skills`.

**Codex:** installer already points `~/.codex/AGENTS.md` at `.claude/CLAUDE.md`. Do not recreate `~/.agents/skills`. If `~/.codex/config.toml` exists, it must list `CLAUDE.md` in `project_doc_fallback_filenames`. Add only that name; don't rewrite the rest. Skip if Codex isn't on the machine.

**Project-scope leftovers:** only if `claude` exists. `claude plugin list` plus `~/.claude/plugins/installed_plugins.json`. Uninstall `--scope project` any plugin that is not a user-scope install of an enabled plugin. Run the uninstall from that `projectPath`. Snapshot and restore user `enabledPlugins` after, same as above.

Candidate repos are the sibling project folders of wherever this repo was found on this machine (the same resolution as "Find the repo" above — e.g. everything next to `~/dev/dotfiles`). Other repos may still **enable** uninstalled plugins in their own `.claude/settings.json`. Remove those leftover `enabledPlugins` keys (or the whole object if it is only leftovers). Leave hooks, permissions, and MCP config. `settings.local.json` Skill() allows for gone plugins can go too. Do not commit those repos unless asked.

## Leftover sweep

Delete only what is clearly leftover from an older layout:

- Dangling symlinks under `~/.claude`, `~/.agents`, `~/.config/opencode` that pointed at this repo
- Any installer target that is a link whose target no longer exists — check every path the installer prints, not only the roots above (Windows can produce dead links when Developer Mode is off)
- Identical `.bak` next to installer targets (the installer already drops those; remove a remaining `.bak` only when it is a pre-link leftover and the live file is the symlink)
- Plugin cache dirs under `~/.claude/plugins/cache` for plugins **not** in `installed_plugins.json` (skip this if there is no Claude plugin cache)
- Empty `~/.agents` / `~/.agents/skills` / `~/.config/opencode/skills` after pruning

Do not delete skills in `~/.claude/skills` that are not from this repo. Do not delete `ek@chow` or `improve@improve` caches while those plugins are installed.

## Vendored skills

`ek@chow` is not this. Marketplace update already ran. Never copy Emil's files into this repo.

The copies are `plugins/tc/skills/grill-me` and `plugins/tc/skills/grilling`, from [mattpocock/skills](https://github.com/mattpocock/skills) `skills/productivity/<name>/SKILL.md` on `main`. Credits live in `.claude/README.md`.

For each, fetch current upstream `SKILL.md` and diff against the repo file.

- Match: say so.
- Drift: say whether to take it (behavior vs example/format) and wait. Do not apply. Do not commit.
- 404: find the new path from that repo's README. Do not invent a third skill to copy.

Do not install `mattpocock-skills` from the marketplace. That loads a second copy.

## Report

What changed, anything still broken, what the user must do, and whether a vendored skill drifted.

- Cursor: **Developer: Reload Window** after the local plugin rewrite.
- Grok / OpenCode: new `~/.claude` links are live; no extra reload if the session already sees them.
- Claude Code: `/reload-plugins` if marketplace plugins changed.

Do not commit. Do not push.
