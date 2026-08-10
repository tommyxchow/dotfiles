# Shared Agent Config

This directory holds the shared global instructions and Claude Code settings.
The shared instructions also link into Codex and are read by OpenCode's Claude
Code compatibility fallback.
Personal plugins ship from the `chow` marketplace in this same repo
(`tommyxchow/dotfiles`). Third-party plugins are declared as separate marketplaces in
`settings.json`.

Repo-level gotchas for anyone (or any agent) editing this repo live in the root [`CLAUDE.md`](../CLAUDE.md). This file is the reference: what is declared, why, and how to change it.

## Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Shared global instructions (linked into Claude Code and Codex; read by OpenCode, Cursor, and Grok Build) |
| `settings.json` | Claude Code permissions, sandbox, model/effort, plugins, statusline, marketplaces |

OpenCode natively loads the compatible first-party `vet`, `tldr`, and `polish`
skills from `plugins/tc/skills`, linked to `~/.config/opencode/skills` by the
installer. `opencode/commands` adds `/vet`, `/tldr`, and `/polish` wrappers
without duplicating the skill instructions. `statusline-install` remains Claude
Code-only because OpenCode has no custom statusline support. OpenCode does not
load Claude marketplace plugins, so `ek` remains Claude Code-only and
upstream-managed.

Plugin content for `chow` lives outside this directory:

| Path | Purpose |
|------|---------|
| `.claude-plugin/marketplace.json` | Marketplace catalog (`chow`) |
| `plugins/tc/` | Personal plugin skills |
| `ek` (git url source) | [emilkowalski/skills](https://github.com/emilkowalski/skills) - fetched at install time, not vendored here |

## Declared plugins

### `chow` (this repo)

| Plugin | Source | Skills |
|--------|--------|--------|
| `tc@chow` | `./plugins/tc` | `/tc:vet`, `/tc:tldr`, `/tc:polish`, `/tc:statusline-install` |
| `ek@chow` | `emilkowalski/skills` (git url) | `emil-design-eng`, `review-animations`, `improve-animations`, `find-animation-opportunities`, `animation-vocabulary`, `apple-design`, `pick-ui-library` |

Plugin names are owner initials (`tc`, `ek`) because the name prefixes every skill at the call site: `/ek:improve-animations`.

`ek` uses a `url` plugin source with `strict: false` so Claude Code installs Emil's upstream `skills/` tree directly. Upstream has no `plugin.json`, so this catalog entry is the only place the name lives. Do not copy those files into this repo or install them via `skills.sh` / `npx skills`.

**Do not "simplify" this to a `github` source.** `/plugin install` builds an SSH clone URL (`git@github.com:owner/repo.git`) for `source: github` and has no HTTPS fallback, so it dies with `Permission denied (publickey)` on any machine without a GitHub SSH key ([#47088](https://github.com/anthropics/claude-code/issues/47088), among several dupes). `source: url` with an explicit `https://` URL clones anonymously and needs no keys. `/plugin marketplace add` *does* have the HTTPS fallback, which is why the `chow` and `improve` marketplaces resolve fine either way.

Caveat: `strict: false` means the marketplace entry is the *entire* definition. The upstream repo has no `plugin.json` today; if Emil adds one that declares components, that's a conflict and the plugin fails to load. Switch the entry to `strict: true` (or drop the field) if that happens.

### Other marketplaces (`extraKnownMarketplaces`)

| Plugin | Marketplace repo | Notes |
|--------|------------------|-------|
| `improve@improve` | [shadcn/improve](https://github.com/shadcn/improve) | Codebase audit / planning skill |

### Official marketplace (`claude-plugins-official`)

| Plugin | Notes |
|--------|-------|
| `typescript-lsp` | Enables Claude Code's built-in LSP tool for TS/JS. Requires `typescript-language-server` + `typescript` on PATH. |
| `frontend-design` | Distinctive frontend design guidance for new or substantially redesigned UI. |

## Setup

1. Run the dotfiles installer to link the shared instructions into `~/.claude/`
   and `~/.codex/`, plus `settings.json` into `~/.claude/`.
2. Open Claude Code. `extraKnownMarketplaces` / `enabledPlugins` declare the plugins above, but `enabledPlugins` alone does **not** install them. Install each, then `/reload-plugins`:

   ```bash
   claude plugin install tc@chow --scope user
   claude plugin install ek@chow --scope user
   claude plugin install improve@improve --scope user
   claude plugin install typescript-lsp@claude-plugins-official --scope user
   claude plugin install frontend-design@claude-plugins-official --scope user
   ```

   Use the CLI over the interactive `/plugin` menu here: the menu installs to **project** scope, which pins the plugin to one repo, while `enabledPlugins` lives in user-scope `settings.json` and enables it everywhere. That mismatch shows up as "enabled but missing" in every other repo.
3. Run `/tc:statusline-install`. `settings.json` points at `~/.claude/statusline-command.sh`, which is a **generated artifact** - the skill is its source of truth and the script isn't committed. Until you run it, the statusline is broken on a fresh machine.
4. Check the `/plugin` **Errors** tab afterwards. `typescript-lsp` reports `Executable not found in $PATH` until `typescript-language-server` is installed.

### Cursor

Enable **Settings → Rules, Skills, Subagents → Include third-party Plugins, Skills, and other configs**. That picks up `~/.claude/CLAUDE.md`, installed Claude plugins/skills, and related configs. Cursor does **not** run Claude's marketplace install itself: install plugins in Claude Code first.

### Grok Build

Grok Build reads `~/.claude/CLAUDE.md` through its built-in Claude Code compatibility,
so the installer does not create a separate Grok instructions link. Confirm effective
discovery with the inspector inside an active Grok session; the standalone
`grok inspect` command may report a different instruction list.

## Auditing config

Worth doing when a notably better model ships, or on a new machine:

1. `/insights` to generate fresh usage data.
2. `/doctor` for the removal side: unused skills and plugins, `CLAUDE.md` lines a session
   could derive on its own, duplicate memory files, install health.
3. Ask Claude for the addition side, which `/doctor` does not cover: read the `/insights`
   report and the `feedback` memories under `~/.claude/projects/*/memory/`, and propose
   `CLAUDE.md` rules or new skills for mistakes and workflows that keep recurring.

Approved edits land in this working tree directly, so review with `git diff` and commit.
Skill edits under `plugins/tc/skills/` also need a push before they take effect. Both
mechanics are in the root [`CLAUDE.md`](../CLAUDE.md).

## Maintenance

- **Installing and enabling are separate**, and so are their files: `enabledPlugins` here declares what should load, while install records live in `~/.claude/plugins/installed_plugins.json` (runtime state, not committed). A plugin can be enabled and not installed, or installed and not enabled. `claude plugin list` shows the truth.
- Run `/insights` periodically to generate fresh usage data before syncing.
- `/plugin marketplace update` refreshes the catalog only; `/plugin update <plugin>@<marketplace>` is what updates an installed plugin. To refresh Emil's upstream skills: `/plugin update ek@chow`.
- No plugin here pins a `version`, so each resolves to its source's latest commit SHA. Pushing is what publishes; no version bump needed.
- `autoUpdate: true` is set on `chow` only, so pushes to this repo land on their own: Claude Code refreshes the marketplace and updates installed plugins shortly after startup (random delay up to 10 min), then prompts for `/reload-plugins`. The manual sequence in the root [`CLAUDE.md`](../CLAUDE.md) is still the way to pick up a change immediately.
- `improve` deliberately has **no** `autoUpdate`. Third-party marketplaces default to off because a plugin executes arbitrary code with your user privileges - auto-updating a repo you don't control runs new code unreviewed. Update it by hand with `/plugin update improve@improve`.

## Credits

- [emilkowalski/skills](https://github.com/emilkowalski/skills) - © Emil Kowalski, MIT. Referenced by `ek@chow`; not modified in this repo.
