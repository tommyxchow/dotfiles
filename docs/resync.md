# Resync — pull, install, then clean leftovers

Make **this machine** match the canonical layout in the dotfiles repo. Also check whether copied skills have drifted from upstream; do not apply that here. Not a docs rewrite. Not a plugin redesign.

This playbook lives in the repo and loads only when you open this workspace and ask to resync. It is not a global skill.

Refreshing packages and framework versions in a **product** repo is the `refresh` skill. Do not run that here.

Primary harnesses: **Claude Code**, **Cursor**, **Grok Build**, **OpenCode 2**. The installer is enough for instructions and first-party skills on all of those. Marketplace plugins (`ek`, `frontend-design`, `typescript-lsp`) need the `claude` CLI; skip that section if it is not installed.

Flow: **find repo → pull or clone → installer → marketplace plugins (if `claude`) → dedupe → leftover sweep → vendored skills → report.**

The installer is the mechanical source of truth (`install.sh`). Do not reimplement its links. This file is the judgment pass around it.

## Find the repo

Prefer the current workspace if it is this repo (root `install.sh` plus `.claude/CLAUDE.md`). Else `~/dev/dotfiles`. If neither exists, clone `https://github.com/tommyxchow/dotfiles.git` to `~/dev/dotfiles` and continue from there. Do not search the whole disk.

Never install from a linked worktree of this repo. You are in one when `git rev-parse --path-format=absolute --git-common-dir` and `--git-dir` differ; don't compare `--git-common-dir` to `.git`, which is already `../.git` one directory down. The installer links absolute paths into whatever checkout it runs from, so a worktree you later delete leaves this machine's config pointing at a folder that is gone. `--git-common-dir` names the main checkout to use instead.

## Pull

From the repo: `git fetch` then `git pull --ff-only`. Skip pull on a brand-new clone.

- Dirty or diverged: show `git status` / `git log` and **stop**. Do not stash, reset, or force unless the user says so.
- After a fast-forward, the repo files are canonical. Ignore stale local copies of `enabledPlugins` from before the pull.

## Installer

`./install.sh` on every platform, from Git Bash on Windows.

It links configs, first-party skills, and the statusline script, prunes links from older layouts, copies Cursor's local `tc` plugin, and links the herdr worktree bootstrap plugin when herdr is on PATH and its server is running. The `gh` and `herdr` skills are not installer links; see Third-party skills below. It also seeds `~/.grok/config.toml` from `grok/config.toml` on new machines and patches only that file's non-default keys on re-runs — Grok writes runtime state into it, so it is never symlinked. Same for `~/.grok/lsp.json` (seed if missing, warn if `typescript-language-server` is not on PATH; never overwrite an existing file). Re-running is safe. This is the step that makes Claude / Cursor / Grok / OpenCode 2 pick up the instructions and every skill under `plugins/tc/skills` on a new machine.

On Windows, symlink creation needs Developer Mode (or an elevated shell). If a link comes out dead, fix the mode and re-run the installer rather than replacing links with copies.

## Marketplace plugins

Only if `claude` is on PATH. Cursor and Grok import these from Claude's plugin cache; OpenCode 2 does not. A Cursor-only or OpenCode 2-only machine still gets first-party skills from the installer.

Read `.claude/settings.json` `enabledPlugins` **after** the pull. That list is what should be installed at **user** scope. `enabledPlugins` does not install; `claude plugin list` is the truth.

For each enabled plugin that is missing at user scope:

```bash
claude plugin install <name> --scope user
```

Then update the ones that do not come from this working tree:

```bash
claude plugin marketplace update chow
claude plugin update ek@chow
```

Skip `tc@chow`. First-party skills are installer links into `~/.claude/skills`. Enabling the plugin loads a second cached copy, and so does installing it on claude.ai, which Claude Code syncs down to `~/.claude/plugins/synced`.

Official plugins (`typescript-lsp`, `frontend-design`) have no `autoUpdate`. Install if missing; do not invent extra official plugins.

Use the CLI. The interactive `/plugin` menu installs to **project** scope.

If `claude` is missing, say so in the report and continue.

## Dedupe

**First-party skills:** every directory under `plugins/tc/skills/` must be a symlink in `~/.claude/skills`. If `tc@chow` is installed or enabled, uninstall it `--scope user` (needs `claude`). Snapshot `enabledPlugins` first; restore any key the uninstall punched (it must not resurrect `tc@chow`). If `~/.claude/plugins/synced/*/tc` exists, the plugin is installed on claude.ai; that cannot be undone from here, so report it and leave the sync settings alone. claude.ai's own skills under `~/.claude/skills/synced` are expected.

**Cursor:** `~/.cursor/plugins/local/tc/rules/global.mdc` must match `.claude/CLAUDE.md` plus `alwaysApply: true` and no `description`. Delete `~/.cursor/plugins/cache/chow/tc` if it exists. Do not paste `CLAUDE.md` into User Rules. Third-party import should stay on so Cursor reads `~/.claude/skills`.

**Grok:** `~/.grok/config.toml` must carry the non-default keys from `grok/config.toml` — the installer patches them; re-run it if drifted. Everything else in that file is Grok-owned runtime state; do not manage it. `~/.grok/lsp.json` should exist (installer seeds from `grok/lsp.json`); warn if `typescript-language-server` is missing from PATH. No extra links: Grok reads `~/.claude/CLAUDE.md` and `~/.claude/skills` through Claude compatibility.

**OpenCode 2:** `~/.config/opencode/AGENTS.md` must be a symlink to `.claude/CLAUDE.md`. In this repo, root `AGENTS.md` must be a symlink to `CLAUDE.md` (installer-created, gitignored). OpenCode 2 does not load `CLAUDE.md`, so this link is what feeds it. It already reads `~/.claude/skills`. Do not also link first-party skills into `~/.config/opencode/skills`. There are no slash-command stubs any more: each first-party skill carries `metadata: opencode/slash: "true"`, which is what makes a typed `/vet` run the skill on OpenCode 2. The installer sweep removes any leftover links in `~/.config/opencode/commands` that point into this repo. `~/.config/opencode/cli.json` is the TUI/keybinds file from `opencode/cli.json`. On Windows, apply the WT sendInput chords from the README; they are not linked. Do not also link `~/.agents/skills`.

**Project-scope leftovers:** only if `claude` exists. `claude plugin list` plus `~/.claude/plugins/installed_plugins.json`. User scope is the only scope that should exist, so uninstall `--scope project` every project-scope record, running each uninstall from its `projectPath`. When that path is this repo, the uninstall edits `.claude/settings.json` here, which is also the user-scope file: restore any `enabledPlugins` key it removed by editing the JSON, not with `git checkout`. Both scopes share one cache directory, so confirm `claude plugin list` still shows the user-scope entry afterwards and reinstall `--scope user` if it vanished.

Candidate repos are the sibling project folders of wherever this repo was found on this machine (the same resolution as "Find the repo" above — e.g. everything next to `~/dev/dotfiles`). Other repos may still **enable** uninstalled plugins in their own `.claude/settings.json`. Remove those leftover `enabledPlugins` keys (or the whole object if it is only leftovers). Leave hooks, permissions, and MCP config. `settings.local.json` Skill() allows for gone plugins can go too. Do not commit those repos unless asked.

## Leftover sweep

Delete only what is clearly leftover from an older layout:

- Dangling symlinks under `~/.claude`, `~/.agents`, `~/.config/opencode` that pointed at this repo
- The leftover `~/.codex/AGENTS.md` symlink (we no longer manage Codex; leave the rest of `~/.codex` alone)
- Any installer target that is a link whose target no longer exists — check every path the installer prints, not only the roots above (Windows can produce dead links when Developer Mode is off)
- Identical `.bak` next to installer targets (the installer already drops those; remove a remaining `.bak` only when it is a pre-link leftover and the live file is the symlink)
- Plugin cache dirs under `~/.claude/plugins/cache` for plugins **not** in `installed_plugins.json` (skip this if there is no Claude plugin cache)
- Empty `~/.agents` / `~/.agents/skills` / `~/.config/opencode/skills` after pruning

Do not delete skills in `~/.claude/skills` that are not from this repo. Do not delete the `ek@chow` cache while that plugin is installed.

## Stale worktrees and branches

Run the `cleanup` skill's read-only survey in each candidate repo (the sibling project folders from "Find the repo"). Show exact candidates and let the user select what to delete before applying anything; resync does not grant deletion approval.

Git GC eventually prunes stale worktree registrations when it runs, but automatic GC is conditional, so an explicit survey is still useful. Claude Code periodically cleans eligible subagent and background-session worktrees, not every ordinary worktree session. Cursor has configurable retention-based periodic cleanup. Grok's own docs disagree on its worktree GC: the website says it runs only when invoked, while the user guide bundled with the installed build says the same pass also runs on a timer. Neither documents whether `worktree.auto_gc` is on by default, so survey rather than assume. Report any Grok cleanup separately; do not run `grok worktree gc --max-age 7d` automatically, since it removes worktree folders by age, without the evidence or the approval the cleanup skill requires.

## OpenCode install and channel

OpenCode 2 is still the beta channel. The regular installer at
`https://opencode.ai/install` serves the v1 line from GitHub releases, so a new
machine that runs the URL everyone shares silently lands on v1. Install v2 with
`curl -fsSL https://opencode.ai/v2/install | bash`, from Git Bash on Windows.

Both channels install a binary named `opencode` now, so the command no longer
tells you which line you are on. `opencode --version` does, and a `1.x` there
means the machine is on the wrong channel. `opencode2` is only a back-compat
shim the v2 installer writes.

Check each resync whether the channels have merged:

```bash
gh api repos/anomalyco/opencode/releases/latest -q .tag_name
```

A `v1.x` means keep using the v2 URL. A `v2.x` or higher means v2 reached the
regular channel: switch installs and any upgrade wrapper to
`https://opencode.ai/install`, after which the `opencode2` shim stops mattering.

The built-in `opencode upgrade` runs bare `bash` on the installer it downloads.
On Windows that resolves to the WSL launcher and updates the Linux copy instead,
so upgrades there have to route through Git Bash. This machine does that with an
`opencode` function in `Microsoft.PowerShell_profile.ps1`, which this repo does
not track.

## Third-party skills

Two skills in `~/.claude/skills` come from other repos through `gh skill`, not
the installer: `gh` from `cli/cli` and `herdr` from `herdrdev/herdr`. Both are
user scope, Claude Code agent only; Cursor, Grok, and OpenCode 2 read that same
folder, so do not install them again for those agents.

If `gh` is on PATH, refresh the pair with `gh skill update`. `gh skill list`
shows what is installed; install a missing one with
`gh skill install cli/cli gh --agent claude-code --scope user` or
`gh skill install herdrdev/herdr herdr --agent claude-code --scope user`. Skip
herdr when the binary is not on PATH.

The herdr skill tracks the latest tag, and the installed binary is the authority
for command syntax, so a version gap between them is fine. A copy that `gh skill
list` shows with no source was written by hand from `herdr --skill`; delete it
and reinstall through gh so updates reach it.

## Herdr pane hook

Skip this section if `herdr` is not on PATH.

Update the binary first: `herdr update`, run outside a herdr session since it
refuses to swap itself from inside one. The channel is preview, because
integration fixes ship in preview builds well before a stable tag; `herdr
channel show` confirms it and `herdr channel set preview` restores it.

A plain `herdr update` swaps the client and leaves the running server on the old
build, which `herdr status` reports as `server_binary_stale: yes`. Leave it: the
server picks up the new build the next time herdr restarts, and a restart ends
whatever the panes are running. Report it and let the user pick the moment.
Never stop the server from inside a session.

The pane hook is the other surface, and it is per agent rather than per machine.
Run `herdr integration status --outdated-only` and reinstall whatever it lists
with `herdr integration install <agent>`. Keep that set to claude, codex, cursor,
grok, and opencode. Two of those write into files this repo tracks: claude into
`.claude/settings.json`, opencode into `opencode/cli.json` through the
`~/.config/opencode/cli.json` link. Read both diffs after installing. The rest
are self-contained in their own config directories and need no cleanup. When a
pane shows the wrong state, `herdr agent explain <pane>` says which rule decided
it.

The opencode integration only works from a build that ships its OpenCode 2
plugin, which installs as `herdr-opencode/tui.js` under the config directory.
Builds through preview 2026-09-08 carry only the OpenCode 1 plugin, which
OpenCode 2 refuses to load while status still reports `current`; on those, skip
it. Pane detection recognizes `opencode.exe` without any integration, so
skipping only loses working/idle/blocked reporting and session restore. Delete
this paragraph once the integration has installed from a newer build.

The worktree bootstrap plugin under `herdr/plugins` is the third herdr surface.
It runs on every worktree herdr creates, copies the gitignored env files from
the main checkout, and runs `pnpm install` only when the repo has pnpm's global
virtual store on; everywhere else dependencies install on first need. The
`tc.pr-badge` plugin sits next to it and fills two sidebar values per git
workspace: the branch's pull request and its count of uncommitted files. It
runs on herdr start, when an agent settles, when a workspace gets focus, and
through `herdr plugin action invoke tc.pr-badge.refresh`. The installer links
every folder under `herdr/plugins` through `herdr plugin link`, which needs the
server up, so a `SKIP` line there means start herdr and re-run the installer.
`herdr plugin list --json` shows them registered and `herdr plugin log list`
shows their last runs with exit codes and output, which is where to look when a
new worktree came up without its env or a badge is missing.

Then check `git diff .claude/settings.json`. Installing the claude integration
writes a hook command with an absolute path into this machine's home directory,
which does not belong in a public repo and is dead on the other platform. Older
builds replaced the committed portable command with it. Current builds leave
the committed entry alone and append a second `SessionStart` entry, so until
that entry is removed the hook also runs twice.

Restore the committed form. When the hook is the only pending change,
`git checkout -- .claude/settings.json` does it. When another settings edit is
pending, delete the added entry by editing the JSON so that edit survives.
Herdr's entry only matches `startup`, `resume`, `clear`, `compact`, and `fork`;
the committed `*` matcher already covers those, so keep `*`. The committed
command already covers both platforms. Herdr writes
`hooks/herdr-agent-state.ps1` and a `powershell -NoProfile -ExecutionPolicy
Bypass -File` command on Windows, and `hooks/herdr-agent-state.sh` with `bash
'<path>' session` everywhere else, which is exactly what the committed dispatch
tests for by name.

Still read the diff rather than restoring blind. If a future version ever writes
another filename, widen the dispatch to match it, because an unmatched name is
the bad case: the command exits 0 and the hook silently never runs.

Reinstalls stay occasional. `herdr integration status` reads the version marker
in the script file and ignores the settings entry, so the portable command
survives and only a real version bump puts claude on the outdated list.

## Herdr config

Skip this section if `herdr` is not on PATH.

Herdr's `config.toml` is machine-local; `herdr --help` prints its path. This
setup expects four settings in it. The global rules have agents send a
notification after a long run, and `system` is the delivery that shows outside
the herdr window. The Claude entry puts each session's title in the sidebar. It
replaces `rows` rather than adding to it, so its first and last rows repeat
whatever `[ui.sidebar.agents] rows` holds on that machine. A fresh session
titles itself "Claude Code", which only repeats the agent row under it, so the
title row hides until the session has a real title; `hide` needs herdr 0.9.1 or
newer. The spaces rows are
herdr's defaults plus the `$pr` and `$dirty` slots the `tc.pr-badge` plugin
fills; a slot shows nothing until a value is reported. The first matching rule
wins, so the failed-check rule comes first, and an inline table has to stay on
one line.

```toml
[ui.toast]
delivery = "system"

[ui]
show_agent_labels_on_pane_borders = true

[ui.sidebar.agents.rows_by_agent]
claude = [
  ["state_icon", "machine", "workspace", "tab"],
  [{ token = "terminal_title_stripped", rules = [{ equals = "Claude Code", hide = true }] }],
  ["agent"],
]

[ui.sidebar.spaces]
rows = [
  ["state_icon", "workspace"],
  ["branch", "git_status", { token = "$pr", rules = [{ contains = "✗", fg = "#f38ba8" }, { contains = "approved", fg = "#a6e3a1" }, { contains = "merged", dim = true }, { contains = "closed", dim = true }] }, { token = "$dirty", fg = "#f9e2af" }],
]
```

After an edit, `herdr config check` validates the file and `herdr server
reload-config` applies it.

## Skill sources

Nothing here is vendored. Every skill in `plugins/tc/skills` is written in this
repo, so there is no upstream file to diff. Credits for borrowed ideas live in
`README.md`. Never copy Emil's files in; `ek@chow` is a marketplace
plugin and its update already ran. Do not install `mattpocock-skills` from the
marketplace either: its `grill-me` would collide with ours.

## Report

What changed, anything still broken, and what the user must do.

- Cursor: **Developer: Reload Window** after the local plugin rewrite.
- Grok / OpenCode 2: links are updated on disk. Reload or start a new session if it has not loaded the revised instructions; link presence alone does not prove that.
- Claude Code: `/reload-plugins` if marketplace plugins changed.

Do not commit. Do not push.
