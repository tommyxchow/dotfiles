# dotfiles

Config repo. `./install.sh` symlinks files from here into their real locations, and
hands off to `install.ps1` on Windows. See `README.md` for the full mapping.

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

When I say resync, update, sync this machine, or catch this machine up: read
`docs/resync.md` and follow it. That playbook is repo-local, not a global skill.

Refreshing a **product** repo (packages, framework migrations, shadcn) is the
`refresh` skill, including when I say resync in that repo.

## Audit

When I say audit the setup, meta review, optimize my workflow, or self review:
read `docs/audit.md` and follow it. It re-examines the global instructions,
skills, and harness configs against what the harnesses can do now and what has
been going wrong, then proposes changes and waits. Also repo-local.

## Gotchas

- **Don't add `permissions.deny` or `autoMode` rules for destructive commands.**
  Auto mode already ships ~70 soft blocks, and they are better than anything
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
  symlinked local plugins now, but `rules/global.mdc` needs `alwaysApply: true`
  frontmatter that `.claude/CLAUDE.md` doesn't carry, so the installer still
  copies it into `~/.cursor/plugins/local/tc/rules/global.mdc`. That
  copy is stale until you re-run `./install.sh` after editing that file,
  whichever agent or editor made the edit, and then **Developer: Reload
  Window**. Do not also keep a User Rule with the same text. Cursor's
  third-party config setting still imports installed Claude plugins and skills.
  `.claude/CLAUDE.md` contains global instructions, so anything specific to this
  repo belongs in this file instead.

- **Don't `git switch` the linked checkout under a running session.** A branch
  swap there rewrites the live config and skill files. Offer a worktree the
  global way instead.

- **Run the installer from the permanent checkout.** When working in a worktree,
  wait until the changes reach the permanent checkout, then install there.
  Installing from a worktree redirects the machine's live links into it.

- **`.claude/CLAUDE.web.md` is the web-chat twin of `.claude/CLAUDE.md`.** Nothing
  loads it: paste it by hand into claude.ai (Settings > Instructions for Claude)
  and grok.com (Customize Grok). When a Communication or External writing rule changes in
  `.claude/CLAUDE.md`, mirror it there if it applies to chat. Keep the file
  paste-clean: no header, no comments. **Hard cap 4000 characters**, which is
  grok.com's limit and the tighter of the two; it truncates silently past that,
  so cut a whole rule rather than compressing sentences. The installer warns
  when the file goes over.

- **The installer links first-party skills into `~/.claude/skills`.** Claude,
  Cursor, Grok, and OpenCode 2 all read that path. `opencode/commands` provides
  `/vet`, `/tldr`, `/polish`, `/review`, `/tdd`, `/grill-me`, `/refresh`, `/pass`,
  `/pr`, and `/cleanup` wrappers. Do not also copy those skills into `~/.config/opencode/skills`.
  Keep shared skills portable Agent Skills (`name` and `description` required).
  Claude-only `context` / `agent` / `background` are fine where a skill should
  fork, and `disable-model-invocation` is read by Claude and Cursor but not by
  every harness. Whatever such a key enforces has to be written into the skill's
  own text as well or it only holds where the key is read. Don't put
  `allowed-tools` on a shared skill.
  Do not enable `tc@chow` on a machine that ran the installer: that plugin is
  the same files via the marketplace cache, so both would load. Do not install
  `mattpocock-skills` from the official marketplace either: it ships its own
  `grill-me`, which would collide with the one in `plugins/tc/skills`.
  Harnesses also ship review, cleanup, and audit skills of their own, and they
  arrive and get renamed release to release, so don't list them here or in a
  skill body. Two cases cover it. A **name collision**, like Cursor's built-in
  `review`: precedence is undocumented and theirs is slash-only, so asking in
  words still reaches ours while typing `/review` there is ambiguous. A
  **different name for stronger tooling**, like a deeper cloud review only I
  can start: `.claude/CLAUDE.md` already says to point at it, and the
  `review` skill already defers to tooling the repo runs itself. Ours stay
  because they are the only copies that work in all four harnesses and read a
  repo's own rules first.

- **The `chow` marketplace resolves from GitHub's default branch, not this working
  tree.** That matters for `ek@chow` and for machines that install `tc@chow`
  instead of running the installer. After changing `.claude-plugin/marketplace.json`
  or `plugins/tc/`: push, then `/plugin marketplace update chow`,
  `/plugin update ek@chow`, `/reload-plugins`. Local `vet` / `tldr` / `polish` /
  `review` / `tdd` / `grill-me` / `refresh` / `pass` / `pr` / `cleanup` edits are live
  through
  `~/.claude/skills` with no push.

- **Catalog entries for plugins in other repos need `source: url` with an `https://`
  URL, never `source: github`.** This does not apply to `extraKnownMarketplaces`, where
  `source: github` is correct and must stay. See `.claude/README.md` for why.

- **`ek@chow` is upstream-only.** Never vendor, copy, or edit its skill files here.
  Refresh it with `/plugin update ek@chow`.

- **The official `gh` skill lives in `~/.claude/skills/gh` via `gh skill
  install`, not in this repo.** Do not vendor it into `plugins/tc/skills`.
  Resync installs or updates it. One copy in `~/.claude/skills`; do not also
  install it for cursor, opencode, or grok.

- **Herdr owns both of its agent surfaces; never vendor either into
  `plugins/tc/skills`.** The skill is whatever `herdr --skill` prints, and the
  pane hook is `herdr integration install claude`. Installing the integration
  does not touch the skill, so the two refresh separately and resync does both.
  Claude is also the only integration that writes into a file this repo tracks:
  it rewrites the `hooks` entry in `.claude/settings.json` to an absolute machine
  path. The committed entry is a portable `$HOME` form that dispatches on the
  script name and already covers both platforms, so restore it after any
  reinstall or that Windows path ships to every machine. Which integrations are
  worth installing is a resync question; `docs/resync.md` has the current set and
  the ones to skip.

- **Install and uninstall plugins with `--scope user`.** `claude plugin uninstall
  --scope project` also deletes the key from user-scope `enabledPlugins`, and the
  interactive `/plugin` menu installs to project scope. Either way, check
  `git diff .claude/settings.json` afterwards and restore any key that disappeared, or
  the plugin silently stops loading everywhere.
