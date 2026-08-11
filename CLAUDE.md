# dotfiles

Config repo. `install.sh` / `install.ps1` symlink files from here into their real
locations. See `README.md` for the full mapping.

## Gotchas

- **`~/.claude/settings.json` points to `.claude/settings.json`;
  `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` both point to `.claude/CLAUDE.md`.**
  The repo files are canonical: editing them updates the live machine config
  immediately, in every project, with no apply step. Cursor does not use the global
  file as a User Rule: copy it into **Customize → Rules → User Rules** once per
  machine and update that rule manually whenever this file changes. Cursor's
  third-party config setting still imports installed Claude plugins and skills.
  Grok Build reads `~/.claude/CLAUDE.md` through Claude Code compatibility, so
  there is no separate Grok instructions link.
  OpenCode reads the same Claude file through its compatibility fallback, so it
  has no separate instructions link either.
  `.claude/CLAUDE.md` contains global instructions, so anything specific to this
  repo belongs in this file instead.

- **OpenCode links the compatible `vet`, `tldr`, and `polish` skills from
  `plugins/tc/skills` into `~/.config/opencode/skills`.**
  `opencode/commands` provides their `/vet`, `/tldr`, and `/polish` wrappers.
  `statusline-install` remains Claude Code-only because OpenCode has no custom
  statusline support. Keep shared skills portable Agent Skills (`name` and
  `description` frontmatter). Do not mirror Claude marketplace plugin caches:
  OpenCode has no compatible marketplace loader.

- **The `chow` marketplace resolves from GitHub's default branch, not this working
  tree.** Unpushed edits
  to `.claude-plugin/marketplace.json` or `plugins/tc/` have no local effect at all.
  After changing either: push, then `/plugin marketplace update chow`,
  `/plugin update tc@chow`, `/reload-plugins`.

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
