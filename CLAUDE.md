# dotfiles

Config repo. `./install.sh` symlinks files from here into their real locations, and
hands off to `install.ps1` on Windows. See `README.md` for the full mapping.

## Resync

When I say resync, update, sync this machine, or catch this machine up: read
`docs/resync.md` and follow it. That playbook is repo-local, not a global skill.

Refreshing a **product** repo (packages, framework migrations, shadcn) is the
`refresh` skill, including when I say resync in that repo.

## Gotchas

- **`~/.claude/settings.json` points to `.claude/settings.json`;
  `~/.claude/CLAUDE.md` points to `.claude/CLAUDE.md`.**
  The repo files are canonical: editing them updates Claude, OpenCode, and
  Grok immediately. Cursor cannot symlink a local plugin at this repo, so the
  installer copies `.claude/CLAUDE.md` into
  `~/.cursor/plugins/local/tc/rules/global.mdc`. That copy is stale until you
  re-run `./install.sh` after editing that file, whichever agent or editor made
  the edit, and then **Developer: Reload Window**. Do
  not also keep a User Rule with the same text. Cursor's third-party config
  setting still imports installed Claude plugins and skills.
  `.claude/CLAUDE.md` contains global instructions, so anything specific to this
  repo belongs in this file instead.

- **`.claude/CLAUDE.web.md` is the web-chat twin of `.claude/CLAUDE.md`.** Nothing
  loads it: paste it by hand into claude.ai (Settings > Instructions for Claude)
  and grok.com (Customize Grok). When a Communication or External writing rule changes in
  `.claude/CLAUDE.md`, mirror it there if it applies to chat. Keep the file
  paste-clean: no header, no comments. **Hard cap 4000 characters**, which is
  grok.com's limit and the tighter of the two; it truncates silently past that,
  so cut a whole rule rather than compressing sentences. The installer warns
  when the file goes over.

- **The installer links first-party skills into `~/.claude/skills`.** Claude,
  Cursor, Grok, and OpenCode all read that path. `opencode/commands` provides
  `/vet`, `/tldr`, `/polish`, `/review`, `/tdd`, `/grill-me`, `/refresh`, and
  `/pass` wrappers. Do not also copy those skills into `~/.config/opencode/skills`.
  Keep shared skills portable Agent Skills (`name` and `description` required).
  Claude-only `context` / `agent` / `background` / `disable-model-invocation` are
  fine where a skill should fork or stay user-started; other harnesses ignore
  them, so whatever such a key enforces has to be written into the skill's own
  text as well or it only holds in Claude Code. Don't put `allowed-tools` on a
  shared skill.
  Do not enable `tc@chow` on a machine that ran the installer: that plugin is
  the same files via the marketplace cache, so both would load. Do not install
  `mattpocock-skills` from the official marketplace either: it ships its own
  `grill-me`, which would collide with the one in `plugins/tc/skills`.

- **The `chow` marketplace resolves from GitHub's default branch, not this working
  tree.** That matters for `ek@chow` and for machines that install `tc@chow`
  instead of running the installer. After changing `.claude-plugin/marketplace.json`
  or `plugins/tc/`: push, then `/plugin marketplace update chow`,
  `/plugin update ek@chow`, `/reload-plugins`. Local `vet` / `tldr` / `polish` /
  `review` / `tdd` / `grill-me` / `refresh` / `pass` edits are live through
  `~/.claude/skills` with no push.

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
