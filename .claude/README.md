# Claude Code Global Config

This directory contains the global Claude Code configuration, managed as dotfiles and symlinked to `~/.claude/`.

## Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Global instructions loaded every session across all projects |
| `settings.json` | Permissions, hooks, MCP servers, sandbox, plugins |
| `notify.sh` | Desktop notification script used by hooks |
| `skills/` | Custom skills (statusline installer, etc.) |

## Setup

Run the dotfiles installer to symlink these files to `~/.claude/`. The global `CLAUDE.md` is the source of truth — don't edit `~/.claude/CLAUDE.md` directly.

## Syncing CLAUDE.md Across Machines

After using Claude Code on a machine for a while, run this prompt to analyze local usage patterns and propose additions to the global `CLAUDE.md`:

```
Analyze my local Claude Code usage data and propose improvements to my global CLAUDE.md.

1. Read ~/.claude/usage-data/report.html (the /insights report) and extract: friction patterns, suggested CLAUDE.md additions, and recurring mistakes.
2. Read all auto memory files across all projects: find every MEMORY.md under ~/.claude/projects/*/memory/ and read each referenced memory file. Focus on "feedback" type memories — these are corrections I've given Claude that may apply globally.
3. Read my current global CLAUDE.md at ~/.claude/CLAUDE.md.
4. Cross-reference findings against the existing CLAUDE.md. For each potential addition, assess:
   - Is this a cross-project pattern (not specific to one repo)?
   - Would removing this cause Claude to make the same mistake again?
   - Is it already covered by an existing rule?
   - Is it already default Claude Code behavior?
5. Present a table: suggestion | source (insights/memory/project) | verdict (add/skip) | reasoning.
6. For additions I approve, apply them to the CLAUDE.md. If the dotfiles repo is cloned locally, sync the copy there too.

Be conservative — only propose rules that correct real, recurring mistakes. Don't add noise.
```

## Maintenance

- **Pruning test**: For each line in `CLAUDE.md`, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.
- **Target size**: Under 200 lines (currently ~85). Longer files reduce adherence.
- **Emphasis**: Use `IMPORTANT` / `YOU MUST` on critical rules that must not be ignored.
- **Don't duplicate**: Rules already enforced by `settings.json` deny rules or hooks don't need prose unless the "why" adds context.
- Run `/insights` periodically to generate fresh usage data before syncing.
