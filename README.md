# dotfiles

Personal config for git, VS Code, Ghostty, Claude Code, OpenCode 2, Cursor, and Grok Build. The
installer symlinks files from this repo into their real locations, so edits update
the linked files immediately. Active sessions may need a reload or restart to use
revised instructions. Cursor global instructions are copied instead:
the installer copies `.claude/CLAUDE.md` into a local plugin and adds Cursor's
`alwaysApply: true` frontmatter.

## Install

```bash
git clone https://github.com/tommyxchow/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh
```

Same command everywhere. On Windows run it from Git Bash with **Developer
Mode** on (Settings > System > For developers); the installer stops with that
hint when it cannot create symlinks.

On a fresh machine you can also clone, open this repo in Cursor / Grok / OpenCode 2,
and say **resync**. The repo `CLAUDE.md` points at `docs/resync.md`. That playbook
is repo-local, not a global skill.

The installer is idempotent. An existing real file at a target gets moved to `.bak`
first, and the backup is deleted again if it turns out to be byte-identical to the repo
copy. `*.bak` is gitignored. Links from older layouts are swept on every run: in
the folders the installer manages, a link that points into this repo but was
not made on this run is removed, and so is a dangling link left by a deleted
dotfiles checkout.

## What gets linked

| Repo path | Target |
|-----------|--------|
| `git/.gitconfig` | `~/.gitconfig` |
| `git/ignore` | `~/.config/git/ignore` |
| `vscode/settings.json` | VS Code and Cursor user settings |
| `vscode/keybindings.json` | VS Code and Cursor user keybindings |
| `ghostty/config` | `~/.config/ghostty/config` |
| `.claude/settings.json` | `~/.claude/settings.json` |
| `.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `.claude/CLAUDE.md` | `~/.config/opencode/AGENTS.md` (OpenCode 2 user-global instructions) |
| `CLAUDE.md` | `AGENTS.md` in this repo (OpenCode 2 project instructions; installer-only) |
| `plugins/tc/skills/*` | `~/.claude/skills/{name}` (OpenCode 2 reads this path too) |
| `opencode/cli.json` | `~/.config/opencode/cli.json` |
| `.claude/statusline-command.sh` | `~/.claude/statusline-command.sh` (design notes in `docs/statusline.md`) |

Cursor supports symlinked local plugins, but its rule file needs frontmatter
that the shared `CLAUDE.md` does not carry. The installer writes a real plugin at
`~/.cursor/plugins/local/tc` whose `rules/global.mdc` is a copy of
`.claude/CLAUDE.md` with `alwaysApply: true`. Re-run the installer after editing
that file, then **Developer: Reload Window**. Do not also paste it into User
Rules or the same text is injected twice.

Ghostty is macOS/Linux only, so the installer skips it on Windows.

Windows Terminal settings are not linked (profiles and GUIDs are machine-local).
OpenCode 2 still has no Windows keybind section. Use the same WT `sendInput`
CSI-u pattern as [V1's Shift+Enter note](https://opencode.ai/docs/keybinds/#windows-terminal).
`unbound` is not enough. OpenCode does not publish these strings; they use
that same encoding (`[13;2u` for Shift+Enter). Leave Ctrl+Shift+Tab
on WT. Store path:
`%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`.

| Chord | Sequence | Why |
| --- | --- | --- |
| Ctrl+Tab | `[9;5u` | WT next-tab; Tab has no Ctrl byte |
| Ctrl+Backspace | `[127;5u` | WT sends plain Backspace |
| Ctrl+Shift+Z | `[122;6u` | same `0x1a` as Ctrl+Z |
| Ctrl+M | `[109;5u` | same Enter as ASCII CR; Move session / new worktree |
| Ctrl+Shift+T | `[116;6u` | WT new tab; reopen session tab |

## What does not get linked

`.claude-plugin/marketplace.json` is catalog-only. `plugins/tc/` is the source
for the skill links above and for `tc@chow` on machines that only install the
plugin. Nothing else reads the marketplace file locally.

`.claude/CLAUDE.web.md` is the web-chat version of the global instructions for
claude.ai and grok.com. The installer never touches it; paste it by hand.
Mirror Communication and External writing changes there when they apply to chat.

`~/.grok/config.toml` is seeded from `grok/config.toml` and then patched, never
linked; see Grok Build below. `~/.cursor/mcp.json` stays outside the installer.

## Instructions

`.claude/CLAUDE.md` is the one global instruction file. Claude Code links it,
OpenCode 2 reads it through the `AGENTS.md` link, Grok Build reads it through
its Claude Code compatibility, and Cursor gets the installer's copy. Anything
specific to this repo belongs in the root `CLAUDE.md`, which also carries the
gotchas for editing any of this. `.claude/settings.json` holds Claude Code
permissions, sandbox, model and effort, plugins, statusline, and marketplaces.

## Skills

First-party skills are the directories under `plugins/tc/skills`, live links into
`~/.claude/skills` that Claude, Cursor, Grok, and OpenCode 2 all read. Slash any
of them from any repo after the installer has run. Details live in the skill
files. In OpenCode 2 the slash works because each skill sets
`metadata: opencode/slash: "true"`; without it a skill is only reachable
through `/skills` there.

| Slash | When |
|-------|------|
| `/vet` | A claim, version, known issue, or "is this still true". Not "is this code correct". Reports, then waits. |
| `/tdd` | Build new behavior test first: name the cases, red, then the smallest code that passes. |
| `/polish` | Shape of code you already wrote. `quick` is inline and removal-only. |
| `/review` | Real bugs, security, performance, edge cases, and missing pieces in pending changes. Reports; fixes only when told. `quick` is one read; `deep` fans out and reproduces findings. |
| `/pass` | Slice is done: apply this session's confirmed review findings, vet, leftovers, polish if code-shaped, slice-ready, then the commit. `quick` trims vet and polish. |
| `/pr` | Prepare the task, review its complete final diff, and publish a draft with acceptance evidence. Again later to address feedback and update the body. `pr check` reports readiness; `pr ready` checks and flips the draft; an explicit `pr rebase` restacks. Never merges. |
| `/refresh` | Occasional package/framework catch-up in a **product** repo. |
| `/grill-me` | Stress-test a plan through the harness's question tool. Ends in the acceptance checklist `tdd` and `pr` work from. |
| `/cleanup` | Repo hygiene: dead worktrees, merged branches, stale refs. Shows the exact list and asks what to delete. |
| **resync** (this repo) | This **machine**. Follow `docs/resync.md`. |
| **audit** (this repo) | This **setup**. Follow `docs/audit.md`: re-examine the instructions and skills against current harnesses and recent pain, then propose. |

`/tldr` summarizes.

The skills chain during a task: plan where needed, build with `tdd` where it fits,
and close slices with `pass`. Both direct commits and PRs use the same final
acceptance, verification, and review requirements. `pr` publishes the evidence
when a PR is warranted; having a plan does not require one. The same model can
plan and build. Switching models or sessions carries the approved plan forward
without another approval round. The global `.claude/CLAUDE.md` "How a task runs"
section owns those rules; slash commands are shortcuts.

The official `gh` and `herdr` skills are installed into the same folder by
resync through `gh skill install` and refreshed with `gh skill update`, not
linked from this repo. Herdr's pane hook comes from
`herdr integration install claude`. What must never be installed twice is
listed in `CLAUDE.md`.

The installer also links the Claude Code statusline script, so a new machine
needs nothing else for it and edits to the script are live. The design behind
it is in `docs/statusline.md`.

## Harnesses

### Claude Code

The installer links instructions, skills, and the statusline. Marketplace
plugins still need `claude plugin install` when Claude Code is on the machine;
`extraKnownMarketplaces` and `enabledPlugins` in `settings.json` declare them,
but `enabledPlugins` alone does not install anything. Install each, then
`/reload-plugins`. Skip `tc@chow` on a machine that ran the installer, since
those skills are already linked:

```bash
claude plugin install ek@chow --scope user
claude plugin install improve@improve --scope user
claude plugin install typescript-lsp@claude-plugins-official --scope user
claude plugin install frontend-design@claude-plugins-official --scope user
```

Use the CLI over the interactive `/plugin` menu here: the menu installs to
**project** scope, which pins the plugin to one repo, while `enabledPlugins`
lives in user-scope `settings.json` and enables it everywhere. That mismatch
shows up as "enabled but missing" in every other repo. Check the `/plugin`
**Errors** tab afterwards; `typescript-lsp` reports `Executable not found in
$PATH` until `typescript-language-server` is installed. Saying **resync** in
this repo does all of this.

### Cursor

The installer links editor settings and writes the local `tc` plugin above.
Enable **Rules, Skills, Subagents → Include third-party Plugins, Skills, and
other configs** so Cursor also loads installed Claude plugins and skills. Cursor
does not run Claude's marketplace install, so install those plugins in Claude
Code first.

### Grok Build

Grok Build reads `~/.claude/CLAUDE.md` through its built-in Claude Code compatibility,
so it does not need a separate instructions link. Confirm effective discovery
with the inspector inside an active Grok session; the standalone `grok inspect`
command may report a different instruction list. Its own settings live in
`grok/config.toml` here, non-default keys only. Because Grok writes runtime state
back into `~/.grok/config.toml`, that file is never symlinked: the installer seeds it
from the repo copy on new machines and patches just those keys afterwards.
The installer also seeds `~/.grok/lsp.json` from `grok/lsp.json` when missing (rewriting
the Windows `.cmd` shim on that platform) and warns if `typescript-language-server`
is not on PATH.

### OpenCode 2

This setup is OpenCode 2 ([V2 docs](https://opencode.ai/v2/docs/)). The binary
is `opencode`, with `opencode2` left as a back-compat shim.
It reads user-global instructions from `~/.config/opencode/AGENTS.md` and
project `AGENTS.md` walking up from the working directory. It does not load
`CLAUDE.md`. The installer links those `AGENTS.md` paths to the shared
`.claude/CLAUDE.md` and this repo's `CLAUDE.md`. Skills still come from
`~/.claude/skills`. OpenCode 2 does not load Claude marketplace plugins, so
`ek` is Claude Code-only.

## Plugins

Personal plugins ship from the `chow` marketplace in this same repo. Third-party
plugins are declared as separate marketplaces in `.claude/settings.json`.

| Path | Purpose |
|------|---------|
| `.claude-plugin/marketplace.json` | Marketplace catalog (`chow`) |
| `plugins/tc/` | Personal plugin skills |
| `ek` (git url source) | [emilkowalski/skills](https://github.com/emilkowalski/skills), fetched at install time, not vendored here |

### `chow` (this repo)

| Plugin | Source | Skills |
|--------|--------|--------|
| `tc@chow` | `./plugins/tc` | The same skill directories. Marketplace packaging for machines that never ran the installer, including claude.ai. |
| `ek@chow` | `emilkowalski/skills` (git url) | Whatever is in upstream `skills/` (not vendored here) |

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

### Maintenance

- **Installing and enabling are separate**, and so are their files: `enabledPlugins` here declares what should load, while install records live in `~/.claude/plugins/installed_plugins.json` (runtime state, not committed). A plugin can be enabled and not installed, or installed and not enabled. `claude plugin list` shows the truth.
- `/plugin marketplace update` refreshes the catalog only; `/plugin update <plugin>@<marketplace>` is what updates an installed plugin. To refresh Emil's upstream skills: `/plugin update ek@chow`.
- No plugin here pins a `version`, so each resolves to its source's latest commit SHA. Pushing is what publishes; no version bump needed.
- `autoUpdate: true` is set on `chow` only, so `ek@chow` refreshes after a push
  (random delay up to 10 min), then Claude prompts for `/reload-plugins`. First-party
  skills on this machine do not wait on that: they are installer links.
- `improve` deliberately has **no** `autoUpdate`. Third-party marketplaces default to off because a plugin executes arbitrary code with your user privileges; auto-updating a repo you don't control runs new code unreviewed. Update it by hand with `/plugin update improve@improve`.

## Credits

- [emilkowalski/skills](https://github.com/emilkowalski/skills) - © Emil Kowalski, MIT. Referenced by `ek@chow`; not modified in this repo.
- [mattpocock/skills](https://github.com/mattpocock/skills) - © 2026 Matt Pocock, MIT. Nothing here is a copy of his files. `grill-me` is written from scratch and keeps his design-tree and frontier framing. `tdd` is also from scratch, with its seam idea and its anti-patterns adapted from that repo's `tdd`, plus the red-before-green gates from [obra/superpowers](https://github.com/obra/superpowers) and the find-the-repo's-test-command rule from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills).
