# Shared Agent Config

This directory holds global Claude Code instructions and settings. Personal plugins ship from the `chow` marketplace in this same repo (`tommyxchow/dotfiles`). Third-party plugins are declared as separate marketplaces in `settings.json`.

## Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Global instructions (installer-linked to `~/.claude/CLAUDE.md`) |
| `settings.json` | Claude Code permissions, sandbox, model/effort, plugins, statusline, marketplaces |

Plugin content for `chow` lives outside this directory:

| Path | Purpose |
|------|---------|
| `.claude-plugin/marketplace.json` | Marketplace catalog (`chow`) |
| `plugins/tc/` | Personal plugin: skills + `structured` output style |
| `emil` (git url source) | [emilkowalski/skills](https://github.com/emilkowalski/skills) - fetched at install time, not vendored here |

## Declared plugins

### `chow` (this repo)

| Plugin | Source | Skills |
|--------|--------|--------|
| `tc@chow` | `./plugins/tc` | `/tc:vet`, `/tc:tldr`, `/tc:polish`, `/tc:statusline-install` |
| `emil@chow` | `emilkowalski/skills` (git url) | `emil-design-eng`, `review-animations`, `improve-animations`, `find-animation-opportunities`, `animation-vocabulary`, `apple-design`, `pick-ui-library` |

`emil` uses a `url` plugin source with `strict: false` so Claude Code installs Emil's upstream `skills/` tree directly. The short name is deliberate - it prefixes every skill at the call site (`/emil:improve-animations`), and upstream has no `plugin.json`, so this catalog entry is the only place the name lives. Do not copy those files into this repo or install them via `skills.sh` / `npx skills`.

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

## Setup

1. Run the dotfiles installer to symlink `CLAUDE.md` and `settings.json` into `~/.claude/`.
2. Open Claude Code. `extraKnownMarketplaces` / `enabledPlugins` declare the plugins above, but `enabledPlugins` alone does **not** install them. Install each, then `/reload-plugins`:

   ```bash
   claude plugin install tc@chow --scope user
   claude plugin install emil@chow --scope user
   claude plugin install improve@improve --scope user
   claude plugin install typescript-lsp@claude-plugins-official --scope user
   ```

   Use the CLI over the interactive `/plugin` menu here: the menu installs to **project** scope, which pins the plugin to one repo, while `enabledPlugins` lives in user-scope `settings.json` and enables it everywhere. That mismatch shows up as "enabled but missing" in every other repo.
3. Run `/tc:statusline-install`. `settings.json` points at `~/.claude/statusline-command.sh`, which is a **generated artifact** - the skill is its source of truth and the script isn't committed. Until you run it, the statusline is broken on a fresh machine.
4. Check the `/plugin` **Errors** tab afterwards. `typescript-lsp` reports `Executable not found in $PATH` until `typescript-language-server` is installed.

### Cursor

Enable **Settings → Rules, Skills, Subagents → Include third-party Plugins, Skills, and other configs**. That picks up `~/.claude/CLAUDE.md`, installed Claude plugins/skills, and related configs. Cursor does **not** run Claude's marketplace install itself — install plugins in Claude Code first (or rely on github-sourced plugins after `chow` is updated).

## Syncing Config Across Machines

After using Claude Code on a machine for a while, run `/insights` to generate fresh usage data, then run this prompt to audit the local config. The dotfiles should already be installed on the machine — this prompt updates `~/.claude/` in place, no git operations needed:

```
Audit my global Claude Code config (CLAUDE.md + skills) using local usage data and propose improvements.

## Phase 1: Gather data

1. Read ~/.claude/usage-data/report.html (the /insights report) and extract: friction patterns, suggested additions, recurring mistakes, and repeated workflows.
2. Read all auto memory files across all projects: find every MEMORY.md under ~/.claude/projects/*/memory/ and read each referenced memory file. Focus on "feedback" type memories (corrections I've given Claude) that may apply globally.
3. Read my current global CLAUDE.md at ~/.claude/CLAUDE.md.
4. Read every SKILL.md under the installed tc@chow plugin (and any remaining ~/.claude/skills/). Note emil@chow is upstream-only — do not propose edits to those skill files in this repo.
5. Web search for the latest Claude Code CLAUDE.md and skill authoring best practices (official docs at code.claude.com).

## Phase 2: Audit CLAUDE.md

Cross-reference findings against the existing CLAUDE.md. For each potential addition, assess:
- Is this a cross-project pattern (not specific to one repo)?
- Would removing this cause Claude to make the same mistake again?
- Is it already covered by an existing rule or default Claude Code behavior?

Present a table: suggestion | source (insights/memory) | verdict (add/skip) | reasoning.

## Phase 3: Audit skills

For each existing skill in plugins/tc/skills/, assess:
- Does the frontmatter use only valid fields per [official docs](https://code.claude.com/docs/en/skills#frontmatter-reference) (name, description, when_to_use, argument-hint, arguments, disable-model-invocation, user-invocable, allowed-tools, disallowed-tools, model, effort, context, agent, hooks, paths, shell)?
- Is the description optimized for triggering (specific trigger phrases, not vague)?
- Is the skill body under 500 lines with clear structure?
- Are there instructions that duplicate what's already in CLAUDE.md?
- Does disable-model-invocation make sense for this skill's use case?

Then look for gaps — recurring workflows that no existing skill covers. Good candidates:
- Patterns repeated 3+ times across projects in the insights data
- Multi-step workflows captured in feedback memories
- Friction patterns from insights where a structured skill would prevent the mistake
- Workflows the user does manually that could be a `/slash-command`

Create new skills when the pattern is clear. Use disable-model-invocation: true for manual quality gates, omit it for skills Claude should auto-invoke.

Present a table: skill | action (update/create/skip) | what changes | reasoning.

## Phase 4: Apply

For changes I approve, apply them to ~/.claude/CLAUDE.md and to the tc plugin skills under the dotfiles repo (plugins/tc/skills/). Do not vendor or edit emil@chow content here — update that plugin via /plugin marketplace update chow after upstream changes.

Be conservative — only propose rules that correct real mistakes and skills that capture real workflows. Don't add noise.
```

After the audit, if `CLAUDE.md` is symlinked, changes are already in the dotfiles repo — just review and commit. Skill edits belong in `plugins/tc/skills/` in this repo. If files were copied (not symlinked), sync them back first:

```bash
cp ~/.claude/CLAUDE.md <dotfiles-path>/.claude/CLAUDE.md
cd <dotfiles-path> && git diff
```

## Maintenance

- **Installing and enabling are separate**, and so are their files: `enabledPlugins` here declares what should load, while install records live in `~/.claude/plugins/installed_plugins.json` (runtime state, not committed). A plugin can be enabled and not installed, or installed and not enabled. `claude plugin list` shows the truth.
- **`claude plugin uninstall --scope project` also deletes the key from user-scope `enabledPlugins`**, even though you only asked it to drop a project install. Re-add the line to `settings.json` afterwards or the plugin silently stops loading everywhere.
- **Renaming a plugin resets its usage counter.** `pluginUsage` in `~/.claude.json` is keyed `<plugin>@<marketplace>`, so a rename orphans the old key and the new one starts at zero. `emil@chow` was renamed from `emil-design-skills@chow` on 2026-07-25, and the plugin was first installed the same day - so a low count there is thin data, not evidence either way.
- **Pruning test**: For each line in `CLAUDE.md`, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.
- **Target size**: Under 200 lines. Longer files reduce adherence.
- **Emphasis**: Use `IMPORTANT` / `YOU MUST` on critical rules that must not be ignored.
- **Don't duplicate**: Rules already enforced by `settings.json` deny rules or hooks don't need prose unless the "why" adds context.
- Run `/insights` periodically to generate fresh usage data before syncing.
- The `chow` marketplace resolves from GitHub, not from this working tree - **unpushed edits to `marketplace.json` or `plugins/tc/` have no effect locally**. After changing either: push, then `/plugin marketplace update chow` (refreshes the catalog), `/plugin update tc@chow` (pulls the new plugin commit), `/reload-plugins`.
- `/plugin marketplace update` refreshes the catalog only; `/plugin update <plugin>@<marketplace>` is what updates an installed plugin. To refresh Emil's upstream skills: `/plugin update emil@chow`.
- No plugin here pins a `version`, so each resolves to its source's latest commit SHA - a push is enough to publish, no version bump needed.
- `autoUpdate: true` is set on `chow` only, so pushes to this repo land on their own: Claude Code refreshes the marketplace and updates installed plugins shortly after startup (random delay up to 10 min), then prompts for `/reload-plugins`. The manual sequence above is still the way to pick up a change immediately.
- `improve` deliberately has **no** `autoUpdate`. Third-party marketplaces default to off because a plugin executes arbitrary code with your user privileges - auto-updating a repo you don't control runs new code unreviewed. Update it by hand with `/plugin update improve@improve`.

## Credits

- [emilkowalski/skills](https://github.com/emilkowalski/skills) - © Emil Kowalski, MIT. Referenced by `emil@chow`; not modified in this repo.
