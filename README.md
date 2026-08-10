# dotfiles

Personal config for git, VS Code, Ghostty, Claude Code, Codex, OpenCode, and Grok Build. The
installer symlinks files from this repo into their real locations, so editing a file
here changes the live config immediately, with no copy step.

## Install

```bash
./install.sh          # macOS / Linux
```

```powershell
pwsh -File install.ps1    # Windows
```

Windows needs **Developer Mode** on (Settings > System > For developers) or symlink
creation fails.

The installer is idempotent. An existing real file at a target gets moved to `.bak`
first, and the backup is deleted again if it turns out to be byte-identical to the repo
copy. `*.bak` is gitignored.

## What gets linked

| Repo path | Target |
|-----------|--------|
| `git/.gitconfig` | `~/.gitconfig` |
| `vscode/settings.json` | VS Code user settings |
| `vscode/keybindings.json` | VS Code user keybindings |
| `ghostty/config` | `~/.config/ghostty/config` |
| `.claude/settings.json` | `~/.claude/settings.json` |
| `.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` |
| `plugins/tc/skills/{vet,tldr,polish}` | `~/.config/opencode/skills/{vet,tldr,polish}` |
| `opencode/commands/{vet,tldr,polish}.md` | `~/.config/opencode/commands/{vet,tldr,polish}.md` |

Ghostty is macOS/Linux only, so `install.ps1` skips it.

Grok Build reads `~/.claude/CLAUDE.md` through its built-in Claude Code compatibility,
so it does not need a separate instructions link.

Codex is configured with `project_doc_fallback_filenames = ["CLAUDE.md"]` in
`~/.codex/config.toml` so it also recognizes repo-level `CLAUDE.md` files. The
installer does not manage that existing config file, so add the setting once on a new
machine.

OpenCode uses its Claude Code compatibility fallback to read the shared
`~/.claude/CLAUDE.md` instructions, plus project `AGENTS.md` or `CLAUDE.md`
files and external Claude skills. The compatible first-party `vet`, `tldr`, and
`polish` skills are also linked into OpenCode's native global skill directory.
`statusline-install` remains Claude Code-only. Claude Code marketplace plugins
are not mirrored from Claude's plugin cache.

OpenCode command wrappers expose these skills through `/vet`, `/tldr`, and
`/polish` autocomplete without duplicating their instructions.

## What does not get linked

`plugins/tc/` and `.claude-plugin/marketplace.json` ship through the `chow` plugin
marketplace instead of through symlinks. Nothing local reads them directly.

## Claude Code needs a second pass

The installer is not enough on its own. Plugins still have to be installed, and the
statusline script is generated rather than committed, so it stays broken until you run
`/tc:statusline-install`. See [`.claude/README.md`](.claude/README.md) for those steps,
the declared plugins, and the config-sync workflow.
