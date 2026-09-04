# dotfiles

Personal config for git, VS Code, Ghostty, Claude Code, OpenCode, Cursor, and Grok Build. The
installer symlinks files from this repo into their real locations, so editing a file
here changes the live config immediately. Cursor global instructions are the exception:
the installer copies `.claude/CLAUDE.md` into a local plugin (Cursor rejects a symlink
to this repo).

## Install

```bash
git clone https://github.com/tommyxchow/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh
```

Same command everywhere. On Windows it hands off to `install.ps1`, which does the
real work there, so run it from Git Bash or run `pwsh -File install.ps1` directly.
Windows also needs **Developer Mode** on (Settings > System > For developers) or
symlink creation fails.

On a fresh machine you can also clone, open this repo in Cursor / Grok / OpenCode,
and say **resync**. The repo `CLAUDE.md` points at `docs/resync.md`. That playbook
is repo-local, not a global skill.

The installer is idempotent. An existing real file at a target gets moved to `.bak`
first, and the backup is deleted again if it turns out to be byte-identical to the repo
copy. `*.bak` is gitignored.

## What gets linked

| Repo path | Target |
|-----------|--------|
| `git/.gitconfig` | `~/.gitconfig` |
| `vscode/settings.json` | VS Code and Cursor user settings |
| `vscode/keybindings.json` | VS Code and Cursor user keybindings |
| `ghostty/config` | `~/.config/ghostty/config` |
| `.claude/settings.json` | `~/.claude/settings.json` |
| `.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `plugins/tc/skills/*` | `~/.claude/skills/{name}` (OpenCode reads this path too) |
| `opencode/commands/*.md` | `~/.config/opencode/commands/{name}` |

Cursor cannot symlink a local plugin at this repo (the loader rejects targets
outside `~/.cursor/plugins/local`). The installer writes a real plugin at
`~/.cursor/plugins/local/tc` whose `rules/global.mdc` is a copy of
`.claude/CLAUDE.md` with `alwaysApply: true`. Re-run the installer after editing
that file, then **Developer: Reload Window**. Do not also paste it into User
Rules or the same text is injected twice.

Ghostty is macOS/Linux only, so `install.ps1` skips it.

Grok Build reads `~/.claude/CLAUDE.md` through its built-in Claude Code compatibility,
so it does not need a separate instructions link. Its own settings live in
`grok/config.toml` here — non-default keys only. Because Grok writes runtime state
back into `~/.grok/config.toml`, that file is never symlinked: the installer seeds it
from the repo copy on new machines and patches just those keys afterwards.
The installer also seeds `~/.grok/lsp.json` from `grok/lsp.json` when missing (rewriting
the Windows `.cmd` shim on that platform) and warns if `typescript-language-server`
is not on PATH.

OpenCode uses its Claude Code compatibility fallback to read the shared
`~/.claude/CLAUDE.md` instructions, plus project `AGENTS.md` or `CLAUDE.md`
files and `~/.claude/skills`. Do not also copy first-party skills into
`~/.config/opencode/skills`.

Slash from any repo after the installer has run. Details live in the skill
files.

| Slash | When |
|-------|------|
| `/vet` | A claim, version, known issue, or "is this still true". Not "is this code correct". Reports, then waits. |
| `/polish` | Shape of code you already wrote. |
| `/review` | Real bugs, security, performance, edge cases, and missing pieces in pending changes. Reports; fixes only when told. |
| `/pass` | Slice is done: vet, leftovers, polish if code-shaped, ship-ready. Not a commit. |
| `/refresh` | Occasional package/framework catch-up in a **product** repo. |
| `/grill-me` | Stress-test a plan. |
| **resync** (this repo) | This **machine**. Follow `docs/resync.md`. |

`/tldr` summarizes. `statusline-install` is Claude-only setup.

The installer also writes `~/.claude/statusline-command.sh` from
`plugins/tc/skills/statusline-install`, so a new machine does not need
`/tc:statusline-install`. Re-run the installer after editing that skill.

First-party skills are live links into `~/.claude/skills`. Do not also enable
`tc@chow` on a machine that ran the installer, or Claude and Cursor load the
same skills twice. Keep `tc@chow` in the marketplace catalog for machines that
only install the plugin. Do not also install `mattpocock-skills` from the official
marketplace, or `grill-me` / `grilling` load twice. `ek`, `improve`,
`typescript-lsp`, and `frontend-design` stay marketplace plugins.

## Cursor

The installer links editor settings and writes the local `tc` plugin above.
Enable **Rules, Skills, Subagents → Include third-party Plugins, Skills, and
other configs** so Cursor also loads installed Claude plugins and skills. Cursor
does not run Claude's marketplace install, so install those plugins in Claude
Code first. `~/.cursor/mcp.json` stays outside the installer.

## What does not get linked

`.claude-plugin/marketplace.json` is catalog-only. `plugins/tc/` is the source
for the skill links above and for `tc@chow` on machines that only install the
plugin. Nothing else reads the marketplace file locally.

`.claude/CLAUDE.web.md` is the web-chat version of the global instructions for
claude.ai and grok.com. The installer never touches it; paste it by hand.

## Claude Code still needs the marketplace step

The installer links skills and writes the statusline. Marketplace plugins (`ek`,
`improve`, `typescript-lsp`, `frontend-design`) still need `claude plugin install`
when Claude Code is on the machine. Cursor, Grok, and OpenCode get first-party
skills from the installer alone. Saying **resync** in this repo does both. See
[`.claude/README.md`](.claude/README.md) for the declared plugins.
