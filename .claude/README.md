# Shared Agent Config

This directory holds global Claude Code instructions and settings. Skills and output styles ship as the `tc` plugin from the `chow` marketplace in this same repo.

## Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Global instructions (installer-linked to `~/.claude/CLAUDE.md`) |
| `settings.json` | Claude Code permissions, sandbox, plugins, statusline, marketplace |

Plugin content lives outside this directory:

| Path | Purpose |
|------|---------|
| `.claude-plugin/marketplace.json` | Marketplace catalog (`chow`) |
| `plugins/tc/` | Personal plugin: skills + `structured` output style |

## Setup

1. Run the dotfiles installer to symlink `CLAUDE.md` and `settings.json` into `~/.claude/`.
2. Open Claude Code. `extraKnownMarketplaces` / `enabledPlugins` in settings declare `tc@chow` from `tommyxchow/dotfiles`. Install/enable when prompted, or run `/plugin` and install `tc@chow`.
3. Skills are namespaced: `/tc:vet`, `/tc:tldr`, `/tc:polish`, `/tc:statusline-install`, `/tc:codex-advisor`. Claude Code gets Codex MCP from the plugin `.mcp.json`; Cursor needs global Codex MCP (already in `~/.cursor/mcp.json`) plus third-party plugin import for the skill.

### Cursor

Enable **Settings → Rules, Skills, Subagents → Include third-party Plugins, Skills, and other configs**. Cursor imports installed Claude plugins from `~/.claude/` after Claude Code has installed them. It does **not** run Claude's marketplace install itself.

Cursor does **not** read `~/.claude/CLAUDE.md` for rules. Sync global instructions into Cursor User Rules (or per-project `AGENTS.md`) manually when `CLAUDE.md` changes.

## Syncing Config Across Machines

After using Claude Code on a machine for a while, run `/insights` to generate fresh usage data, then run this prompt to audit the local config. The dotfiles should already be installed on the machine — this prompt updates `~/.claude/` in place, no git operations needed:

```
Audit my global Claude Code config (CLAUDE.md + skills) using local usage data and propose improvements.

## Phase 1: Gather data

1. Read ~/.claude/usage-data/report.html (the /insights report) and extract: friction patterns, suggested additions, recurring mistakes, and repeated workflows.
2. Read all auto memory files across all projects: find every MEMORY.md under ~/.claude/projects/*/memory/ and read each referenced memory file. Focus on "feedback" type memories (corrections I've given Claude) that may apply globally.
3. Read my current global CLAUDE.md at ~/.claude/CLAUDE.md.
4. Read every SKILL.md under the installed tc@chow plugin (and any remaining ~/.claude/skills/).
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

For changes I approve, apply them to ~/.claude/CLAUDE.md and to the tc plugin skills under the dotfiles repo (plugins/tc/skills/).

Be conservative — only propose rules that correct real mistakes and skills that capture real workflows. Don't add noise.
```

After the audit, if `CLAUDE.md` is symlinked, changes are already in the dotfiles repo — just review and commit. Skill edits belong in `plugins/tc/skills/` in this repo. If files were copied (not symlinked), sync them back first:

```bash
cp ~/.claude/CLAUDE.md <dotfiles-path>/.claude/CLAUDE.md
cd <dotfiles-path> && git diff
```

## Maintenance

- **Pruning test**: For each line in `CLAUDE.md`, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.
- **Target size**: Under 200 lines. Longer files reduce adherence.
- **Emphasis**: Use `IMPORTANT` / `YOU MUST` on critical rules that must not be ignored.
- **Don't duplicate**: Rules already enforced by `settings.json` deny rules or hooks don't need prose unless the "why" adds context.
- Run `/insights` periodically to generate fresh usage data before syncing.
- After changing plugin skills, push the repo and refresh in Claude Code (`/plugin marketplace update` / `/reload-plugins`) so the cache picks up the new commit.
