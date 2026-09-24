# dotfiles

Config repo. `./install.sh` symlinks files from here into their real locations on
every platform. See `README.md` for the full mapping.

## The check

**`./install.sh` is this repo's own check.** Run it from the permanent checkout
before calling a change here verified, and read its output: it validates every
skill description against the 1024-character spec cap and `.claude/CLAUDE.web.md`
against grok.com's 4000-character limit, reports every link target, and rewrites
Cursor's copy of the global file. A `WARN` line is a failing check.

It is a gate with side effects, since it repoints the machine's live links. That
is why it runs from the permanent checkout and never from a worktree.

It checks mechanics, not judgment. It cannot tell whether a rule is right or
whether two files now contradict each other, so it never substitutes for the
review step in `.claude/CLAUDE.md`.

## Personal first, work compatible

This is my personal setup. Everything in it has to work when I am alone in a
repo with no ticket, no PR template, and no review bots, and still hold up in a
team repo that has all three. A rule or skill that assumes a ticket exists, that
bots review every push, or that someone else reads the PR needs a solo path too.
This repo is public, so nothing here names an employer, an internal repo, or a
work-only tool.

## Resync

When I say resync, update this machine, sync this machine, or catch this machine up: read
`docs/resync.md` and follow it. That playbook is repo-local, not a global skill.

Refreshing a **product** repo (packages, framework migrations, shadcn) is the
`refresh` skill. There, resync means only a `git pull`.

## Audit

When I say audit the setup, meta review, optimize my workflow, or self review:
read `docs/audit.md` and follow it. It re-examines the global instructions,
skills, and harness configs against what the harnesses can do now and what has
been going wrong, then proposes changes and waits. Also repo-local.

## Gotchas

- **Don't add `permissions.deny` or `autoMode` rules for destructive commands.**
  Auto mode already ships a long list of soft blocks, and they are better than anything
  written here: one rule names `rm -rf`, `git reset --hard`, `git clean -fd[x]`,
  `git restore .` and `git stash drop` plus the PowerShell, Python and Node
  spellings, another names force pushing and remote-history rewrites. Run
  `claude auto-mode defaults` and check before concluding something is missing.
  A `deny` rule matches a literal command prefix, so it covers one spelling and
  nothing else, and `Bash(git push --force*)` would also match
  `--force-with-lease` that restacking needs.

- **`~/.claude/settings.json` points to `.claude/settings.json`;
  `~/.claude/CLAUDE.md` points to `.claude/CLAUDE.md`.**
  The repo files are canonical: editing them updates the linked files on disk.
  Already-running sessions may need a reload or restart to load revised
  instructions. OpenCode 2 reads the global text through
  `~/.config/opencode/AGENTS.md` (installer link to `.claude/CLAUDE.md`); it
  does not load `~/.claude/CLAUDE.md`, so the link is what actually feeds it.
  In this repo the installer also links
  `AGENTS.md` to this file so OpenCode 2 sees these gotchas. Cursor does support
  symlinked local plugins, but `rules/global.mdc` needs `alwaysApply: true`
  frontmatter that `.claude/CLAUDE.md` doesn't carry, so the installer still
  copies it into `~/.cursor/plugins/local/tc/rules/global.mdc`. That
  copy is stale until you re-run `./install.sh` after editing that file,
  whichever agent or editor made the edit, and then **Developer: Reload
  Window**. Do not also keep a User Rule with the same text. Cursor's
  third-party config setting still imports installed Claude plugins and skills.
  `.claude/CLAUDE.md` contains global instructions, so anything specific to this
  repo belongs in this file instead.

- **Slash commands write into the repo through that link.** `/model`, `/effort`,
  and anything else Claude Code saves as a default lands in
  `.claude/settings.json`, so a dirty settings file after a session is usually a
  preference a command saved, not an edit someone meant to keep. Read the diff
  and decide whether that default belongs in the repo. Discarding it with
  `git checkout` also undoes the live setting, since the two are one file.

- **Don't `git switch` the linked checkout under a running session.** A branch
  swap there rewrites the live config and skill files. Offer a worktree the
  global way instead.

- **Run the installer from the permanent checkout.** When working in a worktree,
  wait until the changes reach the permanent checkout, then install there.
  Installing from a worktree redirects the machine's live links into it.

- **Harness response-style defaults conflict, so `.claude/CLAUDE.md` overrides
  them rather than assuming them.** Claude Code's Default is not the short
  style, Concise is opt-in, other harnesses still push brevity, and Grok Build
  asks for complete sentences over identifiers. The `IMPORTANT: readable beats
  brief` line exists so a terse default does not win; don't prune it because
  the harness you are testing in already reads fine. Don't move the shared
  Communication rules into a Claude Code output style either: styles are
  Claude-only, so Cursor and Grok Build would lose them, and
  `keep-coding-instructions` defaults to false, so a style that forgets the
  flag strips coding instructions. `outputStyle` stays unset in
  `.claude/settings.json`.

- **`.claude/CLAUDE.web.md` is the web-chat twin of `.claude/CLAUDE.md`.** Nothing
  loads it: paste it by hand into claude.ai (Settings > Instructions for Claude)
  and grok.com (Customize Grok). When a Communication or External writing rule changes in
  `.claude/CLAUDE.md`, mirror it there if it applies to chat. Keep the file
  paste-clean: no header, no comments. **Hard cap 4000 characters**, which is
  grok.com's limit and the tighter of the two; it truncates silently past that,
  so cut a whole rule rather than compressing sentences. The installer warns
  when the file goes over. It leaves out the literal-phrase rule on purpose and
  sets no persona anywhere, because I use chat to see each model's default
  style; an audit that finds those gaps is looking at a decision, not drift.

- **The installer links first-party skills into `~/.claude/skills`.** Claude,
  Cursor, Grok, and OpenCode 2 all read that path. OpenCode 2 only treats a
  typed `/vet` as that skill when its frontmatter carries
  `metadata: opencode/slash: "true"`, so every first-party skill sets it; a
  new skill without it is reachable there only through `/skills`. Do not copy
  those skills into `~/.config/opencode/skills`, do not enable `tc@chow` on a machine
  that ran the installer or install it on claude.ai (account sync brings that
  copy down too, so both would load), and do not install `mattpocock-skills`
  from the official marketplace (its `grill-me` collides with ours).

- **Keep shared skills portable Agent Skills** (`name` and `description`
  required). Claude-only `context` / `agent` / `background` are fine where a
  skill should fork, and `disable-model-invocation` is read by Claude and Cursor
  but not by every harness. Whatever such a key enforces has to be written into
  the skill's own text as well or it only holds where the key is read. Don't put
  `allowed-tools` on a shared skill.

- **Don't list harness-shipped review, cleanup, or audit skills** here or in a
  skill body; they arrive and get renamed release to release. Two cases cover
  it. A **name collision**, like the built-in `review` in Cursor and OpenCode 2:
  Cursor's precedence is undocumented and OpenCode 2 runs its own command
  before a same-named skill, so asking in words still reaches ours while
  typing `/review` there is theirs or ambiguous. A **different name for stronger
  tooling**, like a paid cloud review: `.claude/CLAUDE.md` says ours run unless
  I name the built-in or it does something ours can't, and the `review` skill
  defers to tooling the repo itself configures. Ours stay because they are the
  only copies that work in all four harnesses and read a repo's own rules
  first. The cloud review can be started from a script, but it bills per run,
  so no session starts it unasked.

- **`tc` stays in the marketplace catalog; do not install it on claude.ai.**
  The catalog entry serves machines that install the plugin instead of running
  the installer, so keep it. On claude.ai the plugin only surfaces in chat, it
  does not update itself from GitHub (a snapshot there still served a retired
  skill two days after the pushes), and Claude Code syncs every claude.ai
  plugin down to `~/.claude/plugins/synced`, so every terminal session loads a
  second, stale copy of the skills as `tc:` entries. If `tc:`-prefixed skills
  or `tc@synced` show up, the plugin is installed on claude.ai; uninstall it
  there rather than adding a local override. claude.ai's own skills (docx,
  pptx, xlsx, and the rest) sync the same way and stay on purpose.

- **The `chow` marketplace resolves from GitHub's default branch, not this working
  tree.** That matters for `ek@chow` and for machines that install `tc@chow`
  instead of running the installer. After changing `.claude-plugin/marketplace.json`
  or `plugins/tc/`: push, then `/plugin marketplace update chow`,
  `/plugin update ek@chow`, `/reload-plugins`. Local edits to any skill under
  `plugins/tc/skills` are live through `~/.claude/skills` with no push.

- **Catalog entries for plugins in other repos need `source: url` with an `https://`
  URL, never `source: github`.** This does not apply to `extraKnownMarketplaces`, where
  `source: github` is correct and must stay. See the Plugins section of `README.md` for why.

- **`ek@chow` is upstream-only.** Never vendor, copy, or edit its skill files here.
  Refresh it with `/plugin update ek@chow`.

- **The `gh` and `herdr` skills live in `~/.claude/skills`, not in this
  repo.** `gh` comes from `gh skill install` and `herdr` from `herdr --skill`,
  the copy bundled with the installed binary, which resync rewrites after each
  `herdr update`. Do not vendor either into `plugins/tc/skills`. One copy in
  `~/.claude/skills`; do not also install them for cursor, opencode, or grok.

- **Herdr owns its pane hook; never vendor it here either.**
  `herdr integration install claude` writes an absolute machine path into the
  `hooks` section of `.claude/settings.json`, replacing the committed entry on
  older builds and appending a second one on current builds. The committed
  entry is a portable `$HOME` form that already covers both platforms, so
  restore it after any reinstall or that path ships to every machine. The
  opencode integration writes into `opencode/cli.json` too, but its
  `"plugins": ["./herdr-opencode"]` entry is relative and stays committed;
  without it OpenCode 2 never loads herdr's plugin. How the two surfaces
  refresh is in `docs/resync.md`.

- **OpenCode 2 replaces the `cli.json` link when it saves a setting.** A
  toggle in its UI, like turning tabs on, writes a regular file over the
  installer's link. The installer's `BAK` line for that path is the sign:
  copy the backup's new settings into `opencode/cli.json` and rerun it.

- **Inside this checkout, user scope and project scope are the same file.**
  Claude Code reads `<project>/.claude/settings.json` as project settings, and
  here that is the file `~/.claude/settings.json` links to. So a session run in
  this repo also sees `enabledPlugins` at project scope, and the interactive
  `/plugin` menu records project-scope installs with this repo as `projectPath`.
  Install and uninstall plugins with `--scope user`. A `claude plugin uninstall
  --scope project` run here edits this same file and so deletes the user-scope
  key too; afterwards check `git diff .claude/settings.json` and put the key
  back by editing the JSON, never with `git checkout`, which would also discard
  any other pending settings change.

- **The two Next.js lines stay in `.claude/CLAUDE.md`.** An audit proposed
  moving them to next-template's AGENTS.md, since a stack rule in a
  global file looks out of place. Rejected: three of the product repos are
  Next.js, globals are the source of truth, and the security line guards a bug
  class weaker models still write. Don't propose the move again.

- **Models are set by alias, and effort stays at each model's default.**
  `model` is `opus` and `advisorModel` is `fable`. Aliases follow the newest
  release of each family, so a new model needs no edit here. Pin a version or
  add a suffix like `[1m]` only when the model docs say the bare alias falls
  short. A `modelSettings` block or a top-level `effortLevel` that reappears is
  a `/effort` or `/model` write-back; discard it unless I say to keep that
  level. A stray top-level `effortLevel` does more harm here than elsewhere:
  inside this checkout this file is also project settings, and a
  project-level `effortLevel` overrides every model's own default.

- **Rejected, don't propose again.** Loading the herdr rules
  only inside herdr through a hook: hooks are Claude-only, so Cursor, Grok,
  and OpenCode 2 would lose them, and a rule only fires from an always-loaded
  file. A `gh`-based scoreboard script: the audit's PR retro asks the same
  question in words, and a script here goes stale. A plan-time check of open
  branches for file overlap: one branch and worktree per ticket, phases
  stacked on top, so overlap is rare and resolved at merge by hand. The `tc/`
  branch prefix stays dropped. It was a sidebar grouping trick; the global Git
  section uses the ticket id in the tracker's own case, or
  `<github-login>/kebab-phrase` with no ticket. A rule naming a model's
  early-stop habits, like the list in Anthropic's prompting guides (a summary
  that announces the next step, an offer to continue, and the rest), globally
  or under `ship it`, and any rule setting how often to post progress updates:
  how often a model reports and where it ends a turn is left to each model's
  default. A watcher like herd-orchestrator-cli on top of `hq`: HQ already
  collects the decisions that need me, so revisit it only if HQ misses them.
  Two `review` lens lines from the 2026-09-23 audit: a new-dependency check
  (the package is the intended one, not a hallucinated or typosquatted name)
  and prompt injection into a model that can call tools. Neither mistake has
  happened, and none of my repos gives a model tools. Revisit the first if an
  agent ever adds a wrong package, the second once an app calls a model with
  tools.

- **Where the global file differs from Anthropic's prompting advice, it does so on purpose.**
  Anthropic leans toward prose with little bold, calm emphasis, and saying what
  to do rather than what not to do. The file keeps bold-led lists for three or
  more parallel items that each need a sentence, because I skim down the left
  edge, keeps its one `IMPORTANT` for the reason in the response-style gotcha
  above, and keeps its "don't" lines next to the "looks like this / not like
  this" examples that show the positive shape. An audit that finds these is
  looking at a decision, not drift.

- **The Claude Code sandbox stays off.** It doesn't run on native Windows, where
  I use this setup. On macOS or Linux it would be real OS-level containment
  that auto mode's classifier doesn't replace, so turn it back on if one of
  those becomes a daily machine.

- **Three lines in `.claude/CLAUDE.md` look like duplicates and are not.**
  The Communication hatch ("Break any of these rules...") is not a copy of
  the preamble: the preamble asks for a why, and for a wording deviation that
  why is the meta commentary the start-with-the-substance line bans. "Never
  write that the UI works without having driven it" is not a copy of "Never
  claim something works without having checked it": with the screen check not
  requested and tests green, a model would otherwise argue tests are evidence.
  And the subagents line stays even though Claude Code's Agent tool says not
  to spawn unless asked; that note is about cost on the plan, and the file
  overrides harness defaults.
