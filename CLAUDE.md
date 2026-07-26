# dotfiles

Config repo. `install.sh` / `install.ps1` symlink files from here into their real
locations. See `README.md` for the full mapping.

## Gotchas

- **`.claude/settings.json` and `.claude/CLAUDE.md` are symlinks to `~/.claude/`.**
  Editing them changes the live machine config immediately, in every project, with no
  apply step. `.claude/CLAUDE.md` in particular is the global instruction file, so
  anything specific to this repo belongs in this file instead.

- **The `chow` marketplace resolves from GitHub's default branch, not this working
  tree.** Unpushed edits to `.claude-plugin/marketplace.json` or `plugins/tc/` have no
  local effect at all. After changing either: push, then `/plugin marketplace update
  chow`, `/plugin update tc@chow`, `/reload-plugins`.

- **Catalog entries for plugins in other repos need `source: url` with an `https://`
  URL.** `/plugin install` builds an SSH clone URL for `source: github` and has no HTTPS
  fallback, so it fails with `Permission denied (publickey)` without a GitHub SSH key.
  This does not apply to `extraKnownMarketplaces`, where `source: github` is correct.

- **`claude plugin uninstall --scope project` also deletes the key from user-scope
  `enabledPlugins`.** Check `git diff .claude/settings.json` after any uninstall and
  restore the line, or the plugin silently stops loading everywhere.

- **Plugin names are owner initials** (`tc`, `ek`) because the name prefixes every skill
  at the call site: `/ek:improve-animations`.
