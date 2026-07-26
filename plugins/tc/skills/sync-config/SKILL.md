---
name: sync-config
description: Audit this machine's global Claude Code config (CLAUDE.md + tc plugin skills) against local usage data, then propose and apply improvements. Reads the /insights report, auto-memory files across all projects, the current global CLAUDE.md, and every tc skill, then cross-references against current official authoring docs. Use after working on a machine for a while, or when syncing config between machines.
disable-model-invocation: true
argument-hint: "[claude-md | skills]"
---

Audit the global Claude Code config using local usage data and propose improvements.
Phases 1 to 3 are **read-only**. Phase 4 applies changes, and only after approval.

Scope requested: `$ARGUMENTS`. Empty means run every phase. `claude-md` runs phases 1, 2,
and 4; `skills` runs 1, 3, and 4.

## Phase 1: Gather data

1. Read `~/.claude/usage-data/report.html` (the `/insights` report) and extract friction
   patterns, suggested additions, recurring mistakes, and repeated workflows. If it is
   missing or stale, say so and tell the user to run `/insights` first rather than
   auditing against nothing.
2. Read every `MEMORY.md` under `~/.claude/projects/*/memory/` and each memory file it
   references. Focus on `feedback` type memories (corrections the user has given) that
   may apply globally.
3. Read the current global `CLAUDE.md` at `~/.claude/CLAUDE.md`.
4. Read every `SKILL.md` under the installed `tc@chow` plugin, plus any standalone
   `~/.claude/skills/`. `ek@chow` is upstream-only: never propose edits to those files.
5. Web-search the current official Claude Code guidance on `CLAUDE.md` and skill
   authoring (`code.claude.com`). Do not rely on training data for frontmatter fields or
   authoring rules.

Settings files hold secrets in `env` and MCP `headers`. Read only the keys you need and
never quote those values back.

## Phase 2: Audit CLAUDE.md

Cross-reference findings against the existing file. For each candidate addition:

- Is this a cross-project pattern, not specific to one repo?
- Would removing it cause the same mistake to recur?
- Is it already covered by an existing rule or by default behavior?

Present a table: suggestion | source (insights/memory) | verdict (add/skip) | reasoning.

Propose deletions too, not just additions. A rule that no longer corrects a real mistake
is costing context in every session.

## Phase 3: Audit skills

For each skill in `plugins/tc/skills/`:

- Does the frontmatter use only fields valid in the docs you fetched in Phase 1?
- Is the description built from specific trigger phrases rather than vague description?
- Is the body under 500 lines with clear structure?
- Does it duplicate something already in `CLAUDE.md`?
- Is `disable-model-invocation` set correctly for how the skill is actually used?

Then look for gaps: workflows repeated 3+ times in the insights data, multi-step
workflows captured in feedback memories, friction a structured skill would prevent.
Use `disable-model-invocation: true` for manual quality gates; omit it for skills Claude
should route to on its own.

Present a table: skill | action (update/create/skip) | what changes | reasoning.

Be conservative. Only propose rules that correct real mistakes and skills that capture
real workflows.

## Phase 4: Apply

**Stop and get approval on the Phase 2 and 3 tables before editing anything.**

Then apply approved changes to `~/.claude/CLAUDE.md` and to `plugins/tc/skills/` in the
dotfiles repo.

- `~/.claude/CLAUDE.md` is a symlink into the dotfiles repo, so editing it changes the
  checked-in file directly. It shows up in `git status` there, not as a separate copy to
  sync back.
- Do not vendor or edit `ek@chow` content. Refresh it with `/plugin update ek@chow`.
- Leave the changes in the working tree for review. Do not commit or push.
- Skill edits do not take effect until pushed: the `chow` marketplace resolves from
  GitHub, not the working tree. Tell the user to push, then run
  `/plugin update tc@chow` and `/reload-plugins`.
