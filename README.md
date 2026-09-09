# dotfiles

Personal config for git, VS Code, Ghostty, Claude Code, OpenCode 2, Cursor, and Grok Build. The
installer symlinks files from this repo into their real locations, so editing a file
here changes the live config immediately. Cursor global instructions are the exception:
the installer copies `.claude/CLAUDE.md` into a local plugin and adds Cursor's
`alwaysApply: true` frontmatter.

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

On a fresh machine you can also clone, open this repo in Cursor / Grok / OpenCode 2,
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
| `.claude/CLAUDE.md` | `~/.config/opencode/AGENTS.md` (OpenCode 2 user-global instructions) |
| `CLAUDE.md` | `AGENTS.md` in this repo (OpenCode 2 project instructions; installer-only) |
| `plugins/tc/skills/*` | `~/.claude/skills/{name}` (OpenCode 2 reads this path too) |
| `opencode/commands/*.md` | `~/.config/opencode/commands/{name}` |
| `opencode/cli.json` | `~/.config/opencode/cli.json` |

Cursor supports symlinked local plugins, but its rule file needs frontmatter
that the shared `CLAUDE.md` does not carry. The installer writes a real plugin at
`~/.cursor/plugins/local/tc` whose `rules/global.mdc` is a copy of
`.claude/CLAUDE.md` with `alwaysApply: true`. Re-run the installer after editing
that file, then **Developer: Reload Window**. Do not also paste it into User
Rules or the same text is injected twice.

Ghostty is macOS/Linux only, so `install.ps1` skips it.

Windows Terminal settings are not linked (profiles and GUIDs are machine-local).
OpenCode 2 still has no Windows keybind section. Use the same WT `sendInput`
CSI-u pattern as [V1's Shift+Enter note](https://opencode.ai/docs/keybinds/#windows-terminal).
`unbound` is not enough. OpenCode does not publish these strings; they use
that same encoding (`\u001b[13;2u` for Shift+Enter). Leave Ctrl+Shift+Tab
on WT. Store path:
`%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`.

| Chord | Sequence | Why |
| --- | --- | --- |
| Ctrl+Tab | `\u001b[9;5u` | WT next-tab; Tab has no Ctrl byte |
| Ctrl+Backspace | `\u001b[127;5u` | WT sends plain Backspace |
| Ctrl+Shift+Z | `\u001b[122;6u` | same `0x1a` as Ctrl+Z |
| Ctrl+M | `\u001b[109;5u` | same Enter as ASCII CR; Move session / new worktree |
| Ctrl+Shift+T | `\u001b[116;6u` | WT new tab; reopen session tab |

Grok Build reads `~/.claude/CLAUDE.md` through its built-in Claude Code compatibility,
so it does not need a separate instructions link. Its own settings live in
`grok/config.toml` here — non-default keys only. Because Grok writes runtime state
back into `~/.grok/config.toml`, that file is never symlinked: the installer seeds it
from the repo copy on new machines and patches just those keys afterwards.
The installer also seeds `~/.grok/lsp.json` from `grok/lsp.json` when missing (rewriting
the Windows `.cmd` shim on that platform) and warns if `typescript-language-server`
is not on PATH.

This setup is OpenCode 2 (`opencode2`, [V2 docs](https://opencode.ai/v2/docs/)).
It reads user-global instructions from `~/.config/opencode/AGENTS.md` and
project `AGENTS.md` walking up from the working directory. It does not load
`CLAUDE.md`. The installer links those `AGENTS.md` paths to the shared
`.claude/CLAUDE.md` and this repo's `CLAUDE.md`. Skills still come from
`~/.claude/skills`. Do not also copy first-party skills into
`~/.config/opencode/skills`.

Slash from any repo after the installer has run. Details live in the skill
files.

| Slash | When |
|-------|------|
| `/vet` | A claim, version, known issue, or "is this still true". Not "is this code correct". Reports, then waits. |
| `/tdd` | Build new behavior test first: name the cases, red, then the smallest code that passes. |
| `/polish` | Shape of code you already wrote. |
| `/review` | Real bugs, security, performance, edge cases, and missing pieces in pending changes. Reports; fixes only when told. |
| `/pass` | Slice is done: vet, leftovers, polish if code-shaped, slice-ready, then the commit. |
| `/pr` | Branch is near ready: prove the acceptance checklist, review in a fresh subagent, pass, push, open the draft with the standard body. Again later to refresh the body and address review threads in one batch. `pr ready` flips the draft; `pr rebase` restacks after a parent merges. Never merges. |
| `/refresh` | Occasional package/framework catch-up in a **product** repo. |
| `/grill-me` | Stress-test a plan through the harness's question tool. Ends in the acceptance checklist `tdd` and `pr` work from. |
| `/cleanup` | Repo hygiene: dead worktrees, merged branches, stale refs. Surveys before it deletes. |
| **resync** (this repo) | This **machine**. Follow `docs/resync.md`. |
| **audit** (this repo) | This **setup**. Follow `docs/audit.md`: re-examine the instructions and skills against current harnesses and recent pain, then propose. |

`/tldr` summarizes. `statusline-install` is Claude-only setup.

The skills chain on their own during a task (plan ends in a checklist, build runs `tdd` where it fits, slices close with `pass`, planned work ends with `pr`), so the slash commands are shortcuts, not the only way in. The global `.claude/CLAUDE.md` "How a task runs" section is where that chain is written down.

The installer also writes `~/.claude/statusline-command.sh` from
`plugins/tc/skills/statusline-install`, so a new machine does not need
`/tc:statusline-install`. Re-run the installer after editing that skill.

First-party skills are live links into `~/.claude/skills`. The official `gh`
skill is installed there by resync (`gh skill install`), not linked from this
repo. Do not also enable
`tc@chow` on a machine that ran the installer, or Claude and Cursor load the
same skills twice. Keep `tc@chow` in the marketplace catalog for machines that
only install the plugin. Do not also install `mattpocock-skills` from the official
marketplace, or `grill-me` loads twice. `ek`, `improve`,
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
when Claude Code is on the machine. Cursor, Grok, and OpenCode 2 get first-party
skills from the installer alone. Saying **resync** in this repo does both. See
[`.claude/README.md`](.claude/README.md) for the declared plugins.
