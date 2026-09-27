# dotfiles

Personal config for git, VS Code, Ghostty, Claude Code, OpenCode 2, Cursor, and Grok Build. The
installer symlinks files from this repo into their real locations, so edits update
the linked files immediately. Active sessions may need a reload or restart to use
revised instructions. The exception is Cursor's global instructions, which the
installer copies instead (see below the table).

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
and say **resync**, which follows `docs/resync.md`.

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
| `.claude/references/` | `~/.claude/references` (situational rules the global file tells agents to read) |
| `CLAUDE.md` | `AGENTS.md` in this repo (OpenCode 2 project instructions; installer-only) |
| `plugins/tc/skills/*` | `~/.claude/skills/{name}` (OpenCode 2 reads this path too) |
| `opencode/cli.json` | `~/.config/opencode/cli.json` |
| `bin/wait-for` | `~/.local/bin/wait-for` (agents wait on a URL with a deadline; the installer warns when that folder is not on PATH) |
| `herdr/plugins/worktree-bootstrap` | herdr plugin `tc.worktree-bootstrap`, linked through the running herdr server |
| `herdr/plugins/pr-badge` | herdr plugin `tc.pr-badge`, linked the same way |
| `.claude/statusline-command.sh` | `~/.claude/statusline-command.sh` (design notes in `docs/statusline.md`) |

Cursor's rule file needs `alwaysApply: true` frontmatter that the shared file
doesn't carry, so the installer writes a real plugin at
`~/.cursor/plugins/local/tc` whose `rules/global.mdc` is a copy of
`.claude/CLAUDE.md` with that key added. Re-run the installer after editing
that file, then **Developer: Reload Window**. Don't also paste it into User
Rules, or the same text is injected twice.

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
claude.ai and grok.com. The installer never touches it; paste it by hand. How
to keep it in step is in `CLAUDE.md`.

`~/.grok/config.toml` is seeded from `grok/config.toml` and then patched, never
linked; see Grok Build below. `~/.cursor/mcp.json` stays outside the installer.

## Instructions

`.claude/CLAUDE.md` is the one global instruction file; how each harness
picks it up is under Harnesses below. Rules that only matter in one situation
live in `.claude/references/` (working inside herdr, long-work handoffs, and
editing instruction files), and the global file names each one with the moment
to read it, so every session doesn't carry them. Anything
specific to this repo belongs in the root `CLAUDE.md`, which also carries the
gotchas for editing any of this. `.claude/settings.json` holds Claude Code
permissions, model and advisor, theme, plugins, statusline, and marketplaces.

## Skills

First-party skills are the directories under `plugins/tc/skills`, live links into
`~/.claude/skills` that Claude, Cursor, Grok, and OpenCode 2 all read. Slash any
of them from any repo after the installer has run. Details live in the skill
files.

| Slash | When |
|-------|------|
| `/vet` | A claim, version, known issue, or "is this still true". Not "is this code correct". Reports, then waits. `quick` is a few claims, a page each. |
| `/tdd` | Build new behavior test first: name the cases, red, then the smallest code that passes. |
| `/polish` | Shape of code you already wrote. `quick` is inline and removal-only. |
| `/review` | Real bugs, security, performance, edge cases, and missing pieces in pending changes. Reports; fixes only when told. `quick` is one read; `deep` fans out and reproduces findings. |
| `/pass` | Slice is done: apply this session's confirmed review findings, vet, leftovers, polish if code-shaped, slice-ready, then the commit. `quick` trims vet and polish. |
| **finalize** | The final step, said on demand: the full review in a fresh context, then `pass` applies what it confirmed and commits. With a PR open and pushed, the review goes through `pr check`. "review/pass" in either order means the same. |
| `/pr` | Prepare the task, review its complete final diff, publish a draft with acceptance evidence, then watch its CI to green. Again later to address feedback and update the body. `pr check` reports readiness; `pr ready` checks and flips the draft; an explicit `pr rebase` restacks. Never merges. |
| `/refresh` | Occasional package/framework catch-up in a **product** repo. |
| `/grill-me` | Stress-test a plan through the harness's question tool. Ends in the acceptance checklist `tdd` and `pr` work from. |
| `/hq` | Manual only. Run this herdr session as a coordinator: dispatch tasks to workers in their own worktrees, wait on them, relay their questions, report status. Picks each worker's effort at launch, runs Claude models in Claude Code, and shares one board with any other HQ. Never builds or approves for you, and merges only a PR you name. |
| `/cleanup` | Repo hygiene: finished and dead worktrees, merged branches, stale refs. Shows the exact list and asks what to delete. |
| **resync** (this repo) | This **machine**. Follow `docs/resync.md`. |
| **audit** (this repo) | This **setup**. Follow `docs/audit.md`: re-examine the instructions and skills against current harnesses and recent pain, then propose. |

`/tldr` summarizes.

How the skills chain during a task, including `ship it` and how each step is
sized to the change, is the "How a task runs" section of `.claude/CLAUDE.md`.
Slash commands are shortcuts into it.

The official `gh` skill and the `herdr` skill sit in the same folder but come
from their own tools, not this repo. Resync installs and refreshes them, and
`CLAUDE.md` lists what must never be installed twice.

## Harnesses

### Claude Code

The installer links instructions, skills, and the statusline. Marketplace
plugins still need `claude plugin install`, since `settings.json` only declares
them (see Maintenance below). Install each, then `/reload-plugins`. Skip
`tc@chow` on a machine that ran the installer, since those skills are already
linked:

```bash
claude plugin install ek@chow --scope user
claude plugin install typescript-lsp@claude-plugins-official --scope user
claude plugin install frontend-design@claude-plugins-official --scope user
```

Use the CLI over the interactive `/plugin` menu: the menu installs to
**project** scope, which pins the plugin to one repo while user-scope
`enabledPlugins` enables it everywhere, so it shows up as "enabled but
missing" in every other repo. Check the `/plugin`
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
`grok/config.toml` here, non-default keys only. Grok writes runtime state back
into `~/.grok/config.toml`, which is why the installer seeds and patches that
file instead of linking it. It also seeds `~/.grok/lsp.json` from
`grok/lsp.json` when missing, rewriting the Windows `.cmd` shim on that
platform.

### OpenCode 2

This setup is OpenCode 2 ([V2 docs](https://opencode.ai/v2/docs/)). The binary
is `opencode`, with `opencode2` left as a back-compat shim.
It reads user-global instructions from `~/.config/opencode/AGENTS.md` and
project `AGENTS.md` walking up from the working directory; the installer links
those to the shared `.claude/CLAUDE.md` and this repo's `CLAUDE.md`. Skills
come from `~/.claude/skills`. OpenCode 2 does not load Claude marketplace
plugins, so `ek` is Claude Code-only.

### Herdr

Worktrees start from herdr, not from a harness. New worktree on a repo's
sidebar row makes a real git worktree under `~/.herdr/worktrees/<repo>/<branch>`
and opens it as a child workspace, so the agent, a shell, and a dev server all
sit in the same checkout and show their git state together. The
`tc.worktree-bootstrap` plugin the installer links runs on that event: it copies
the gitignored `.env*` files from the main checkout and posts a notification.
It installs dependencies only in a pnpm repo that sets `virtualStoreType: global`
in `pnpm-workspace.yaml`, pnpm's own recipe for worktrees: with that on, the
worktree's `node_modules` is symlinks into one shared store and the install
takes seconds even in a monorepo. Everywhere else the agent installs on first
need. Launch the harness in that workspace once the notification lands.

The global store is opt-in per repo and pnpm calls it experimental. Measured on
tommychow.com (Next.js 16): a plain worktree install takes about 16 seconds, the
first install with the store on about 20 seconds, and every worktree after that
about 3 seconds through the plugin. The catch is Turbopack, which refuses to
compile files outside the project root, and with the store on `node_modules`
resolves into the pnpm store under the user's profile. `next dev` needs
`turbopack.root` set to a folder above both the worktrees and the store, in
practice the home folder. Without that, the home page 500s. `tsc` is
unaffected. Repos that pin pnpm below 11.23 spell the setting
`enableGlobalVirtualStore: true`. When the branch is merged, `cleanup` lists
the worktree and, once approved, removes it through herdr, which closes the
child row too. Delete worktree checkout on that row does the same by hand.

The plugin only knows env files, not projects. A repo that needs other secrets
copied, a database seeded, a port picked, or dependencies installed before
anything else says so in its own agent instructions, and the agent does that
part.

Inside herdr, agents name their tabs and label the panes they split (like
`dev :3001` for a port), start fresh sessions and helpers through
`herdr agent start`, and send a herdr notification after a long run. The rules
are in `.claude/references/herdr.md`, which `.claude/CLAUDE.md` tells an agent
to read on its first turn inside a herdr pane.

The `tc.pr-badge` plugin fills two sidebar values for every git workspace: the
branch's pull request with its CI, like `#12 draft ◌` while checks run, `✓` once
they pass, or `✗` when one failed; `CI ✓` and the like on the default branch,
which has no pull request; and the count of uncommitted files, like `±3`. The
pull request comes from `gh`, so without `gh` signed in only the file count
shows. When it refreshes and how to debug it are in `docs/resync.md`.

Herdr's `config.toml` stays machine-local, since it names the shell for that
OS. `docs/resync.md` lists the settings this setup expects in it.

Per herdr's docs, Claude panes reopen after a server restart: the Claude
integration reports each session's id and herdr resumes it with
`claude --resume`. Anything else a pane was running, like a dev server, does
not survive a restart. A plain `herdr update` leaves a compatible server
running, so panes keep going; a release that changes the protocol needs a
restart, and herdr's status says which.

## Plugins

Personal plugins ship from the `chow` marketplace in this same repo, declared in
`.claude/settings.json` under `extraKnownMarketplaces`. Official plugins come
from `claude-plugins-official`, which needs no declaration.

| Path | Purpose |
|------|---------|
| `.claude-plugin/marketplace.json` | Marketplace catalog (`chow`) |
| `plugins/tc/` | Personal plugin skills |
| `ek` (git url source) | [emilkowalski/skills](https://github.com/emilkowalski/skills), fetched at install time, not vendored here |

### `chow` (this repo)

| Plugin | Source | Skills |
|--------|--------|--------|
| `tc@chow` | `./plugins/tc` | The same skill directories. Marketplace packaging for machines that never ran the installer. Not installed on claude.ai, since Claude Code would sync that copy back down next to the links. |
| `ek@chow` | `emilkowalski/skills` (git url) | Whatever is in upstream `skills/` (not vendored here) |

Plugin names are owner initials (`tc`, `ek`) because the name prefixes every skill at the call site: `/ek:improve-animations`.

`ek` uses a `url` plugin source with `strict: false` so Claude Code installs Emil's upstream `skills/` tree directly. Upstream has no `plugin.json`, so this catalog entry is the only place the name lives. Do not copy those files into this repo or install them via `skills.sh` / `npx skills`.

**Do not "simplify" this to a `github` source.** `/plugin install` builds an SSH clone URL (`git@github.com:owner/repo.git`) for `source: github` and has no HTTPS fallback, so it dies with `Permission denied (publickey)` on any machine without a GitHub SSH key ([#47088](https://github.com/anthropics/claude-code/issues/47088), among several dupes). `source: url` with an explicit `https://` URL clones anonymously and needs no keys. `/plugin marketplace add` *does* have the HTTPS fallback, which is why the `chow` marketplace resolves fine either way.

Caveat: `strict: false` means the marketplace entry is the *entire* definition. The upstream repo has no `plugin.json` today; if Emil adds one that declares components, that's a conflict and the plugin fails to load. Switch the entry to `strict: true` (or drop the field) if that happens.

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

## Credits

- [emilkowalski/skills](https://github.com/emilkowalski/skills) - © Emil Kowalski, MIT. Referenced by `ek@chow`; not modified in this repo.
- [mattpocock/skills](https://github.com/mattpocock/skills) - © 2026 Matt Pocock, MIT. Nothing here is a copy of his files. `grill-me` is written from scratch and keeps his design-tree and frontier framing. `tdd` is also from scratch, with its seam idea and its anti-patterns adapted from that repo's `tdd`, plus the red-before-green gates from [obra/superpowers](https://github.com/obra/superpowers) and the find-the-repo's-test-command rule from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills).
