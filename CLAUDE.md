# dotfiles

Config repo. `install.sh` / `install.ps1` symlink files from here into their real
locations. See `README.md` for the full mapping.

## Resync

When I say resync, update, sync this machine, or catch this machine up: read
`docs/resync.md` and follow it. That playbook is repo-local, not a global skill.

## Gotchas

- **`~/.claude/settings.json` points to `.claude/settings.json`;
  `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` both point to `.claude/CLAUDE.md`.**
  The repo files are canonical: editing them updates Claude, Codex, OpenCode, and
  Grok immediately. Cursor cannot symlink a local plugin at this repo, so the
  installer copies `.claude/CLAUDE.md` into
  `~/.cursor/plugins/local/tc/rules/global.mdc`. Re-run `./install.sh` (or
  `install.ps1`) after editing that file, then **Developer: Reload Window**. Do
  not also keep a User Rule with the same text. Cursor's third-party config
  setting still imports installed Claude plugins and skills.
  `.claude/CLAUDE.md` contains global instructions, so anything specific to this
  repo belongs in this file instead.

- **OpenCode links the compatible `vet`, `tldr`, and `polish` skills from
  `plugins/tc/skills` into `~/.config/opencode/skills`.**
  The installer also links those skills, plus `statusline-install`, into
  `~/.claude/skills` so Claude, Cursor, and Grok read this working tree.
  `opencode/commands` provides `/vet`, `/tldr`, and `/polish` wrappers.
  Keep shared skills portable Agent Skills (`name` and `description` frontmatter).
  Do not enable `tc@chow` on a machine that ran the installer: that plugin is
  the same files via the marketplace cache, so both would load.

- **The `chow` marketplace resolves from GitHub's default branch, not this working
  tree.** That matters for `ek@chow` and for machines that install `tc@chow`
  instead of running the installer. After changing `.claude-plugin/marketplace.json`
  or `plugins/tc/`: push, then `/plugin marketplace update chow`,
  `/plugin update ek@chow`, `/reload-plugins`. Local `vet` / `tldr` / `polish`
  edits are live through `~/.claude/skills` with no push.

- **Catalog entries for plugins in other repos need `source: url` with an `https://`
  URL, never `source: github`.** This does not apply to `extraKnownMarketplaces`, where
  `source: github` is correct and must stay. See `.claude/README.md` for why.

- **`ek@chow` is upstream-only.** Never vendor, copy, or edit its skill files here.
  Refresh it with `/plugin update ek@chow`.

- **Install and uninstall plugins with `--scope user`.** `claude plugin uninstall
  --scope project` also deletes the key from user-scope `enabledPlugins`, and the
  interactive `/plugin` menu installs to project scope. Either way, check
  `git diff .claude/settings.json` afterwards and restore any key that disappeared, or
  the plugin silently stops loading everywhere.
