# Resync: pull, install, then clean leftovers

Make **this machine** match the canonical layout in the dotfiles repo. Also
check whether copied skills have drifted from upstream, but do not apply that
here. This is not a docs rewrite or a plugin redesign, and it never runs the
`refresh` skill, which is for packages in a product repo.

Harnesses: **Claude Code** and **OpenCode 2** are the daily CLIs, **Grok Build**
is occasional, and **Cursor** is the desktop editor, which never runs inside
herdr. The installer is enough for instructions and first-party skills on all of
those. Marketplace plugins (`ek`, `frontend-design`, `typescript-lsp`) need the
`claude` CLI; skip that section if it is not installed.

The installer is the mechanical source of truth (`install.sh`). Do not
reimplement its links. This file is the judgment pass around it.

## Find the repo

Prefer the current workspace if it is this repo (root `install.sh` plus
`.claude/CLAUDE.md`). Else `~/dev/dotfiles`. If neither exists, clone
`https://github.com/tommyxchow/dotfiles.git` to `~/dev/dotfiles` and continue
from there. Do not search the whole disk.

Never install from a linked worktree of this repo. You are in one when
`git rev-parse --path-format=absolute --git-common-dir` and `--git-dir` differ;
don't compare `--git-common-dir` to `.git`, which is already `../.git` one
directory down. The installer links absolute paths into whatever checkout it
runs from, so deleting that worktree later leaves this machine's config pointing
at a missing folder. `--git-common-dir` names the main checkout to use instead.

## Pull

From the repo: `git fetch` then `git pull --ff-only`. Skip pull on a brand-new
clone.

- Dirty or diverged: show `git status` / `git log` and **stop**. Do not stash,
  reset, or force unless the user says so.
- After a fast-forward, the repo files are canonical. Ignore stale local copies
  of `enabledPlugins` from before the pull.

## Installer

`./install.sh` on every platform, from Git Bash on Windows.

It links configs, first-party skills, the statusline script, and `bin/wait-for`
into `~/.local/bin`, prunes links from older layouts, copies Cursor's local `tc`
plugin, and links the herdr plugins (worktree bootstrap and PR badge) when herdr
is on PATH and its server is running. The `gh` and `herdr` skills are not
installer links; see Third-party skills below. It also seeds
`~/.grok/config.toml` from `grok/config.toml` on new machines and on re-runs
patches only that file's non-default keys, because Grok writes runtime state
into it, so it is never symlinked. It seeds `~/.grok/lsp.json` the same way but
never overwrites an existing one, and warns if `typescript-language-server` is
not on PATH. Re-running is safe. This is the step that makes Claude Code,
Cursor, Grok Build, and OpenCode 2 pick up the instructions and every skill
under `plugins/tc/skills` on a new machine.

On Windows, symlink creation needs Developer Mode (or an elevated shell). If a
link comes out dead, fix the mode and re-run the installer rather than replacing
links with copies.

## Marketplace plugins

Only if `claude` is on PATH. Cursor and Grok Build import these from Claude
Code's plugin cache; OpenCode 2 does not. A Cursor-only or OpenCode 2-only
machine still gets first-party skills from the installer.

Read `.claude/settings.json` `enabledPlugins` **after** the pull. That list is
what should be installed at **user** scope. `enabledPlugins` does not install;
`claude plugin list` is the truth.

For each plugin in `enabledPlugins` that is missing at user scope, including
`ek@chow`, which is listed as `false`:

```bash
claude plugin install <name> --scope user
```

Installing enables a plugin, so after installing `ek@chow` run
`claude plugin disable ek@chow --scope user` and check that
`git diff .claude/settings.json` is clean. It stays installed and current, off
until UI work turns it on.

Then update the ones that do not come from this working tree:

```bash
claude plugin marketplace update chow
claude plugin update ek@chow
```

Skip `tc@chow`. First-party skills are installer links into `~/.claude/skills`.
Enabling the plugin loads a second cached copy, and so does installing it on
claude.ai, which Claude Code syncs down to `~/.claude/plugins/synced`.

Official plugins (`typescript-lsp`, `frontend-design`) have no `autoUpdate`.
Install if missing; do not invent extra official plugins.

Use the CLI, since the interactive `/plugin` menu installs to **project** scope.

If `claude` is missing, say so in the report and continue.

## Dedupe

**First-party skills:** every directory under `plugins/tc/skills/` must be a
symlink in `~/.claude/skills`. If `tc@chow` is installed or enabled, uninstall
it `--scope user` (needs `claude`). Snapshot `enabledPlugins` first; restore any
key the uninstall punched (it must not resurrect `tc@chow`). If
`~/.claude/plugins/synced/*/tc` exists, the plugin is installed on claude.ai;
that cannot be undone from here, so report it and leave the sync settings alone.
claude.ai's own skills under `~/.claude/skills/synced` are expected.

**Cursor:** `~/.cursor/plugins/local/tc/rules/global.mdc` must match
`.claude/CLAUDE.md` plus `alwaysApply: true` and no `description`. Delete
`~/.cursor/plugins/cache/chow/tc` if it exists. Do not paste `CLAUDE.md` into
User Rules. Third-party import should stay on so Cursor reads
`~/.claude/skills`.

**Grok Build:** `~/.grok/config.toml` must carry the non-default keys from
`grok/config.toml`; re-run the installer if they drifted. Everything else in
that file is Grok-owned runtime state, so do not manage it. `~/.grok/lsp.json`
should exist; warn if `typescript-language-server` is missing from PATH. No
extra links: Grok reads `~/.claude/CLAUDE.md` and `~/.claude/skills` through
Claude Code compatibility.

**OpenCode 2:** `~/.config/opencode/AGENTS.md` must be a symlink to
`.claude/CLAUDE.md`. In this repo, root `AGENTS.md` must be a symlink to
`CLAUDE.md` (installer-created, gitignored), since OpenCode 2 reads only
`AGENTS.md` and never `CLAUDE.md`. It already reads `~/.claude/skills`, so do
not also link first-party skills into `~/.config/opencode/skills` or link
`~/.agents/skills`. Skills are reached through its `/skills` picker; v2.0.18
ignores the skills' `opencode/slash` key, so on a newer build, check whether a
typed `/vet` reaches the skill. There are no command stubs; the installer sweep
removes any leftover links in `~/.config/opencode/commands` that point into this
repo. `~/.config/opencode/cli.json` is the TUI/keybinds file from
`opencode/cli.json`. On Windows, apply the WT sendInput chords from the README;
they are not linked.

**Project-scope leftovers:** only if `claude` exists. `claude plugin list` plus
`~/.claude/plugins/installed_plugins.json`. User scope is the only scope that
should exist, so uninstall `--scope project` every project-scope record, running
each uninstall from its `projectPath`. When that path is this repo, the
uninstall edits `.claude/settings.json` here, which is also the user-scope file:
restore any `enabledPlugins` key it removed by editing the JSON, not with
`git checkout`. Both scopes share one cache directory, so confirm
`claude plugin list` still shows the user-scope entry afterwards and reinstall
`--scope user` if it vanished.

Candidate repos are the sibling project folders of wherever "Find the repo"
found this repo, for example everything next to `~/dev/dotfiles`. Other repos
may still **enable** uninstalled plugins in their own `.claude/settings.json`.
Remove those leftover `enabledPlugins` keys (or the whole object if it is only
leftovers). Leave hooks, permissions, and MCP config. `settings.local.json`
Skill() allows for gone plugins can go too. Do not commit those repos unless
asked.

## Leftover sweep

Delete only what is clearly leftover from an older layout:

- Dangling symlinks under `~/.claude`, `~/.agents`, `~/.config/opencode` that
  pointed at this repo
- The leftover `~/.codex/AGENTS.md` symlink (we no longer manage Codex; leave
  the rest of `~/.codex` alone)
- Any installer target that is a link whose target no longer exists. Check every
  path the installer prints, not only the roots above (Windows can produce dead
  links when Developer Mode is off)
- Identical `.bak` next to installer targets (the installer already drops those;
  remove a remaining `.bak` only when it is a pre-link leftover and the live
  file is the symlink). `~/.config/opencode/cli.json.bak` is the exception: it
  holds settings OpenCode saved, so copy them into `opencode/cli.json` first
- Plugin cache dirs under `~/.claude/plugins/cache` for plugins **not** in
  `installed_plugins.json` (skip this if there is no Claude plugin cache)
- Empty `~/.agents` / `~/.agents/skills` / `~/.config/opencode/skills` after
  pruning

Do not delete skills in `~/.claude/skills` that are not from this repo. Do not
delete the `ek@chow` cache while that plugin is installed.

## Stale worktrees and branches

Run the `cleanup` skill's read-only survey in each candidate repo (the sibling
project folders from "Find the repo"). Show exact candidates and let the user
select what to delete before applying anything; resync does not grant deletion
approval.

No tool cleans everything on its own, so survey rather than assume. Git GC
prunes stale worktree registrations only when its conditional automatic run
happens. Claude Code periodically cleans eligible subagent and
background-session worktrees, not every ordinary worktree session. Cursor has
configurable retention-based periodic cleanup. Grok Build's docs disagree on its
worktree GC: the website says it runs only when invoked, while the user guide
bundled with the installed build says it also runs on a timer, and neither says
whether `worktree.auto_gc` is on by default. Report any Grok cleanup separately;
do not run `grok worktree gc --max-age 7d` automatically, since it removes
worktree folders by age, without the evidence or the approval the cleanup skill
requires.

## OpenCode install and channel

OpenCode 2 is still the beta channel. The regular installer at
`https://opencode.ai/install` serves the v1 line from GitHub releases, so a new
machine that runs the URL everyone shares silently lands on v1. Install v2 with
`curl -fsSL https://opencode.ai/v2/install | bash`, from Git Bash on Windows.

Both channels install a binary named `opencode`, so only `opencode --version`
tells you the line, and a `1.x` there means the machine is on the wrong
channel. `opencode2` is only a back-compat shim the v2 installer writes.

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

Two skills in `~/.claude/skills` come from somewhere other than the installer:
`gh` from `cli/cli` through `gh skill`, and `herdr` from the herdr binary. Both
are user scope, Claude Code agent only; Cursor, Grok Build, and OpenCode 2 read
that same folder, so do not install them again for those agents.

If `gh` is on PATH, refresh its skill with `gh skill update`. `gh skill list`
shows what is installed; install it when missing with
`gh skill install cli/cli gh --agent claude-code --scope user`.

The herdr skill is the copy bundled with the installed binary, which herdr's
docs say to reinstall after every upgrade, so write it after the `herdr update`
in the next section:

```bash
mkdir -p ~/.claude/skills/herdr && herdr --skill > ~/.claude/skills/herdr/SKILL.md
```

Skip it when the binary is not on PATH. An older copy that `gh skill list`
shows as installed from `herdrdev/herdr` tracks the latest tag rather than the
binary; delete `~/.claude/skills/herdr` and write the bundled one. `gh skill`
has no remove command, and `gh skill list` reads the folders themselves, so the
bundled copy then lists with no source repo.

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
with `herdr integration install <agent>`. Keep that set to claude, opencode,
and grok, the CLIs that run in herdr panes; Codex is never used, and Cursor is
used only as its desktop app, outside herdr. If a codex or cursor integration is
still installed, report it and leave its removal to the user. Two of those write
into files this repo tracks: claude into `.claude/settings.json`, opencode into
`opencode/cli.json` through the `~/.config/opencode/cli.json` link. Read both
diffs after installing. Grok's is self-contained in its own config directory and
needs no cleanup. When a pane shows the wrong state, `herdr agent explain
<pane>` says which rule decided it.

Keep the `"plugins": ["./herdr-opencode"]` entry the opencode install adds to
`opencode/cli.json`; it is relative to the config directory, so it works on
every machine, and it is the only way OpenCode 2 loads herdr's plugin. Without
it herdr gets no working, idle, or blocked state from OpenCode 2 and no session
to restore, and `herdr integration status` reports opencode as `needs repair`.

The `tc` herdr plugin under `herdr/plugins/tc` (worktree env files, PR badges,
and agent names, described in the README's Herdr section) is the third surface.
The installer links it through `herdr plugin link`, which needs the server up,
so a `SKIP` line there means start herdr and re-run the installer. It also
unlinks `tc.pr-badge` and `tc.worktree-bootstrap`, the two plugins `tc`
replaced, and prints an `UNLINK` line for each. `herdr plugin list --json`
shows it registered and `herdr plugin log list` shows its last runs with exit
codes and output, which is where to look when a new worktree came up without
its env, or a badge or name is missing. The badge refreshes when herdr starts,
when an agent settles, when a workspace gets focus, when a new worktree opens,
and by hand through `herdr plugin action invoke tc.refresh`. The name refreshes
when herdr starts and on every agent status change, since herdr has no rename
event, so a freshly renamed agent shows its name at its next status change, or
at once through `herdr plugin action invoke tc.names`, which `hq` runs after
adopting workers.

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
setup expects five settings in it:

- **Theme** follows the terminal's light or dark mode, like Claude Code's
  `theme: auto`. Herdr's default theme is catppuccin, so the file sets only
  `auto_switch`, which swaps in its `catppuccin-latte` sibling on a light
  terminal. Picking a theme by hand in herdr's Settings writes a `name` and
  turns `auto_switch` back off.
- **Toast delivery** is `system`, the one that shows outside the herdr window,
  since the global rules have agents send a notification after a long run.
- **Pane border labels** are on, so each pane's border names the harness
  running in it. Herdr's source labels the border with the harness, not the
  agent's name.
- **Agent rows** give Claude Code, OpenCode 2, and Grok Build the same shape:
  where the agent is, what it is doing, and who it is. No row names the
  harness. Claude is the default and carries no mark, OpenCode 2's own title
  already starts with `OC |`, and Grok's reads `grok` or ends in `- grok`, marks
  no herdr rule can strip, so an `agent` row would only repeat them. A
  fresh Claude session titles itself "Claude Code", so that title row hides
  until the session has a real title; `hide` needs herdr 0.9.1 or newer. The
  last row is the agent's herdr name in bold, which the `tc` plugin publishes
  for every harness, so an `hq` worker named `vega` is easy to find; an agent
  with no name shows no such row. Claude's adds the context the statusline
  publishes (see `docs/statusline.md`), and OpenCode's adds the context the
  `tc` plugin reads off its screen. The context turns orange as `$ctxhigh` past
  the soft ceiling. Effort and model stay out: both are fixed at launch, and
  `hq`, which picks them, reads the `effort` token from `herdr agent list`. Any
  other harness uses `rows`, herdr's default with the name added after the
  harness, like `codex · vega`. An entry replaces `rows` rather than adding to
  it.
- **Spaces rows** are herdr's defaults plus the `$pr` and `$dirty` slots the
  `tc` plugin fills: the PR or default-branch CI state, and the
  uncommitted file count. A slot shows nothing until a value is reported. The
  first matching rule wins, so the red rules for a failed check and for
  requested changes come first, then orange for running checks (yellow is the
  file count's color). An inline table has to stay on one line.

The colors are mid-tones rather than catppuccin's pastels, because a rule takes
only a fixed hex and the pastels vanish on the light theme.

```toml
[theme]
auto_switch = true

[ui.toast]
delivery = "system"

[ui]
show_agent_labels_on_pane_borders = true

[ui.sidebar.agents]
rows = [
  ["state_icon", "machine", "workspace", "tab"],
  ["agent", { token = "$name", bold = true }],
]

[ui.sidebar.agents.rows_by_agent]
claude = [
  ["state_icon", "machine", "workspace", "tab"],
  [{ token = "terminal_title_stripped", rules = [{ equals = "Claude Code", hide = true }] }],
  [{ token = "$name", bold = true }, "$ctx", { token = "$ctxhigh", fg = "#e8762c" }],
]
opencode = [
  ["state_icon", "machine", "workspace", "tab"],
  ["terminal_title_stripped"],
  [{ token = "$name", bold = true }, "$ctx", { token = "$ctxhigh", fg = "#e8762c" }],
]
grok = [
  ["state_icon", "machine", "workspace", "tab"],
  ["terminal_title_stripped"],
  [{ token = "$name", bold = true }],
]

[ui.sidebar.spaces]
rows = [
  ["state_icon", "workspace"],
  ["branch", "git_status", { token = "$pr", rules = [{ contains = "✗", fg = "#e5484d" }, { contains = "changes", fg = "#e5484d" }, { contains = "◌", fg = "#e8762c" }, { contains = "approved", fg = "#3fa34d" }, { contains = "merged", dim = true }, { contains = "closed", dim = true }] }, { token = "$dirty", fg = "#d99a1a" }],
]
```

After an edit, `herdr config check` validates the file and `herdr server
reload-config` applies it.

## Skill sources

Nothing here is vendored. Every skill in `plugins/tc/skills` is written in this
repo, so there is no upstream file to diff; credits for borrowed ideas live in
`README.md`. Never copy Emil's files in, since `ek@chow` is a marketplace plugin
and its update already ran, and do not install `mattpocock-skills` from the
marketplace, whose `grill-me` would collide with ours.

## Report

What changed, anything still broken, and what the user must do.

- Cursor: **Developer: Reload Window** after the local plugin rewrite.
- Grok Build / OpenCode 2: links are updated on disk. Reload or start a new session if it has not loaded the revised instructions; link presence alone does not prove that.
- Claude Code: `/reload-plugins` if marketplace plugins changed.
- If the installer warned that `~/.local/bin` is not on PATH, add the export line it prints to your shell profile; `wait-for` doesn't resolve until then.

Do not commit. Do not push.
