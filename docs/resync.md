# Resync: pull, install, then clean leftovers

Make **this machine** match the canonical layout in the dotfiles repo. Also
check whether copied skills have drifted from upstream, but do not apply that
here. This is not a docs rewrite or a plugin redesign, and it never runs the
`refresh` skill, which is for packages in a product repo.

Harnesses: **Claude Code** and **OpenCode 2** are the daily CLIs, **Grok Build**
is occasional, and **Cursor** is the desktop editor, which never runs inside
the Herdr desktop app. The installer is enough for instructions and first-party skills on all of
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
plugin, and copies the Herdr desktop app's mods with the badge script linked
beside them. The `gh`, `hc`, and `herdr-app` skills are not installer links; see Third-party skills below. It also seeds
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
`~/.agents/skills`. Skills are reached through its `/skills` picker. There are
no command stubs; the installer sweep
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
- What the retired herdr CLI left behind: `~/.claude/skills/herdr`,
  `~/.claude/hooks/herdr-agent-state.*`, `~/.config/opencode/herdr-opencode/`,
  `~/.config/opencode/herdr-tui-session.js`,
  `~/.config/opencode/plugins/herdr-agent-state.js`,
  `~/.config/opencode/tui.jsonc` when it lists only herdr's plugin, and
  `~/.grok/hooks/herdr-agent-state.*` and `~/.grok/hooks/herdr.json`. Never
  touch `~/.herdr/worktrees`, where the desktop app's worktrees live. The herdr
  binary itself is the user's to uninstall, so report it rather than removing it

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

Update it each resync by rerunning that v2 install line, which replaces the
binary in place with the newest v2 build, then confirm with `opencode --version`.
Nothing else flags a stale build, and one once sat weeks behind.

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

## Grok Build update

If `grok` is on PATH, run `grok update`, which installs the newest stable
build. A running Grok session keeps the old build until it restarts, so say so
in the report.

## Third-party skills

Three skills in `~/.claude/skills` come from somewhere other than the
installer: `gh` from `cli/cli` through `gh skill`, and `hc` and `herdr-app`
from the Herdr desktop app's own binaries. All are user scope, Claude Code
agent only; Cursor, Grok Build, and OpenCode 2 read that same folder, so do not
install them again for those agents.

If `gh` is on PATH, refresh its skill with `gh skill update`. `gh skill list`
shows what is installed; install it when missing with
`gh skill install cli/cli gh --agent claude-code --scope user`.

The desktop app bundles its two: `hc --skill` for herdr-core and
`herdr-app --skill` for the window. Neither carries frontmatter, so add it
while writing them. Write each one after its binary updates, and skip either
one when its binary is not on PATH:

```bash
mkdir -p ~/.claude/skills/hc && {
  printf -- '---\nname: hc\ndescription: "%s"\n---\n\n' "Control herdr-core with hc, the runtime behind the Herdr desktop app: start, read, wait on, message, and close terminals and agents. Use only inside the Herdr desktop app (HC_TERMINAL_ID is set), when the herdr rules or hq need a command beyond the tab rename."
  hc --skill
} > ~/.claude/skills/hc/SKILL.md

mkdir -p ~/.claude/skills/herdr-app && {
  printf -- '---\nname: herdr-app\ndescription: "%s"\n---\n\n' "Drive the Herdr desktop app window with herdr-app: spaces, tabs, panes, layouts, keys, themes, and mods. Use only inside the Herdr desktop app (HC_TERMINAL_ID is set), when the herdr rules or hq need a window command or the user asks to change what Herdr shows."
  herdr-app --skill
} > ~/.claude/skills/herdr-app/SKILL.md
```

## Herdr desktop app

Skip this section if `herdr-app` is not on PATH or its window isn't open,
since these commands talk to the running app.

The installer copies the `tc-agents` and `tc-spaces` mods from `herdr-app/mods`
into `~/.config/herdr-app/mods` and links `herdr-app/badge.mjs` into each, so
the app's sidebar shows each space's branch, PR or CI badge, and uncommitted
lines; each agent's name, with its context at the end of the name line; a line
saying what an agent is doing, from Claude Code's own status report; and the
branch and badge on a paneless `hq` worker, which has no space row of its own.
The spaces mod reruns the badge when a checkout changes, at most every 10
seconds, and the agents mod every 90 seconds and when a worker ends a turn.
When a badge or count looks wrong, run `node herdr-app/badge.mjs <folder>` by
hand: it prints the same JSON the mods read, with the reason in `error` when
the PR lookup failed.
The installer copies rather than links because the app reloads a mod only
when a file in its own folder changes, so rerun it after editing a mod.

The layout that shows them is regenerated here rather than committed, so it
follows Herdr's own `main` after an update. `layout.clone` won't overwrite, so
the old copy goes first. Sizes and other clicks live in `layouts/.state/` and
stay:

```sh
h="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
herdr-app do layout.switch --name main
rm -f "$h/layouts/tc.json"
herdr-app do layout.clone --name main --as tc   # also switches to it
# Through a temp file, since macOS sed has no plain -i.
t="$(mktemp)" && sed -e 's/"mod": "agents"/"mod": "tc-agents"/' -e 's/"mod": "spaces"/"mod": "tc-spaces"/' "$h/layouts/tc.json" > "$t" && mv "$t" "$h/layouts/tc.json"
grep -c '"mod": "tc-' "$h/layouts/tc.json"      # 2; anything else means main's blocks changed
```

The two mods are frozen copies of Herdr's own, so an app update doesn't reach
them. When `herdr-app --version` is newer than `cloned_from.version` in a mod's
`mod.json`, diff the repo copy against Herdr's shipped `mods/agents/main.js` or
`mods/spaces/main.js`. Each copy's header lists what tc changed, so anything
else that differs is Herdr's update: port it into the repo copy, bump the
version, and rerun the installer. `herdr-app check` on both
folders and `herdr-app status` with no errors confirm they load. Switching to
`main` shows Herdr's own lists again.

## Skill sources

Nothing here is vendored. Every skill in `plugins/tc/skills` is written in this
repo, so there is no upstream file to diff; credits for borrowed ideas live in
`README.md`. Never copy Emil's files in, since `ek@chow` is a marketplace plugin
and its update already ran, and do not install `mattpocock-skills` from the
marketplace, whose `grill-me` would collide with ours.

## Opus effort

`.claude/settings.json` keeps Opus at `high` through a `modelSettings` entry
keyed by the canonical model id, like `claude-opus-5-5`. Claude Code matches
that model's alias to the entry, but the entry doesn't follow the `opus` alias
to a newer model, so a new Opus would quietly run at its own default. Find the
id `opus` resolves to now in Claude Code's
[model config docs](https://code.claude.com/docs/en/model-config). When
`modelSettings` has no entry for it, or only an `/effort` write-back that the
models gotcha in `CLAUDE.md` says to discard, give the new id the old Opus
entry's level and remove the old key, unless Anthropic's
[effort docs](https://platform.claude.com/docs/en/build-with-claude/effort)
recommend a different starting level for that model in coding or agentic work,
which wins. Update the date and model name in the models gotcha in `CLAUDE.md`
to match, and name the change in the report.

## Memory

Review Claude Code's memory folders under `~/.claude/projects/*/memory`. Delete
a follow-up that's done, a note whose file, plan, or issue is gone, and one a
newer note or a repo file now covers. Merge notes that say the same thing, and
fix index lines that point at missing files. Check only what's quick to check,
like whether a path exists or an issue is still open, and never add memories
here. Report each removal in one line, and never drop a feedback note without
naming it, since those record how the user wants to work.

## Report

What changed, anything still broken, and what the user must do.

- Cursor: **Developer: Reload Window** after the local plugin rewrite.
- Grok Build / OpenCode 2: links are updated on disk. Reload or start a new session if it has not loaded the revised instructions; link presence alone does not prove that.
- Claude Code: `/reload-plugins` if marketplace plugins changed, and a new session to pick up an Opus effort entry the step above moved.
- If the installer warned that `~/.local/bin` is not on PATH, add the export line it prints to your shell profile; `wait-for` doesn't resolve until then.

Do not commit. Do not push.
