# dotfiles

Personal config for git, VS Code, Ghostty, and Claude Code. The installer symlinks files
from this repo into their real locations, so editing a file here changes the live config
immediately, with no copy step.

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
| `.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |

Ghostty is macOS/Linux only, so `install.ps1` skips it.

## What does not get linked

`plugins/tc/` and `.claude-plugin/marketplace.json` ship through the `chow` plugin
marketplace instead, which resolves from GitHub rather than from this working tree. A
push publishes them; nothing local reads them directly.

See [`.claude/README.md`](.claude/README.md) for the Claude Code setup: declared plugins,
marketplace mechanics, and the config-sync workflow.
