# Audit — is this setup still the right setup

Re-examine the agentic workflow in this repo (the global instructions, the first-party skills, the harness configs) against what the harnesses and models can do now and against what has been going wrong. Propose changes; do not make them until the user says so.

This playbook lives in the repo and loads only when you open this workspace and ask for it ("audit the setup", "meta review", "optimize my workflow", "self review"). It is not a global skill. Machine catch-up is `docs/resync.md`; package catch-up in a product repo is the `refresh` skill; neither runs here.

Run it when a notably better model ships, when the same pain recurs across several PRs, or on a new machine. Not on every release.

`$ARGUMENTS`, if any: a focus ("just the skills", "the pr flow"), or a repo path for the PR retro below.

## What you are auditing

- `.claude/CLAUDE.md`: the global instructions every harness loads.
- `plugins/tc/skills/*/SKILL.md`: the first-party skills and their `references/`.
- `opencode/commands/*.md`, `opencode/cli.json`, `.claude/settings.json`, `grok/config.toml`: harness config.
- `README.md`, `.claude/README.md`, `CLAUDE.md`, `docs/`: the docs that describe all of the above.

Read them first. Then work through the sections below in order.

## 1. Harness delta

What changed in Claude Code, OpenCode, Grok Build, and Cursor since the last audit (`git log` on this repo dates it)? Follow `vet`: release notes and official docs, one leaf per harness, no forums as the cite. Look for:

- A rule in the global file or a skill that a harness now enforces natively (a permission mode, a built-in plan artifact, a built-in review command, a hook), so the text can go.
- A capability worth adopting: a new frontmatter key the skills should carry, a question tool where a skill still asks in text, a subagent or worktree feature `pr` or `review` could use.
- A key or setting in the configs that a harness renamed, deprecated, or now defaults to.

Say what you checked and the version or date it was current as of.

## 2. Removal side

Lines that no longer earn their place:

- A rule a current model follows without being told. Test it by asking whether the rule exists because a mistake happened twice; if you can't name the mistake, it is a candidate.
- Stale references: a version, an API name, a tool that no longer exists, a skill or command the README lists that isn't in the tree, or the reverse.
- A skill nothing invokes. Where the harness has `/insights` or `/doctor`, run them and read the result; otherwise say usage is unknown.
- `.claude/CLAUDE.web.md` over its 4000-byte cap, or drifted from the Communication rules it mirrors.

## 3. Addition side

Mistakes that keep happening and have no rule yet. Sources, in order: memory feedback files under `~/.claude/projects/*/memory/` when they exist, what the user says went wrong recently, and the PR retro below. A candidate becomes a rule after the same mistake twice or when the user states a preference. If an existing rule over-fires, propose a skip rule rather than more style.

## 4. PR retro (optional)

Only when the user names a repo. Read the last ten or so merged PRs there with `gh pr list --state merged` and `gh pr view` (body, review threads, commits). For each, note:

- Acceptance criteria that were missing from the first draft and added after review or UAT.
- Review threads whose class recurred across PRs (the same kind of bot or human comment more than once).
- PRs that needed more than one fix push after the draft.

Turn each pattern into a proposal aimed at where it belongs: a first-party skill here when the miss is in the workflow, that repo's `AGENTS.md` review section when the miss is repo-specific. Don't edit the other repo.

## 5. Consistency

- Every skill description routes without overlapping another's trigger words; read them side by side.
- The "Distinct from" tables agree with each other in both directions.
- `README.md`, `.claude/README.md`, and `docs/resync.md` name every skill and command in the tree, and nothing that isn't.
- Every skill description is under the 1024-byte spec cap (`./install.sh` prints this).
- Skill bodies don't rely on Claude-only frontmatter for behavior that has to hold in every harness; the text says it too.

## Report

Write it in the global Communication voice, then stop and wait; the user picks what to build and the normal plan-first flow takes over. Open with the one-line verdict: nothing to change, or how many proposals and which one matters most. Then the proposals, worst first, one or two sentences each with the one-line why, grouped as drop, add, change. Then what you checked and couldn't settle. Skip empty parts.

```
Four proposals, and the one that matters is that Claude Code now ships a plan file every session, so the "keep the checklist in the harness plan file" line can point at it instead of describing it.

Drop
- The Next.js `error.tsx` line in the global file: the repo template's AGENTS.md already carries it and it went stale once.

Change
- grill-me still asks in text on Grok Build; its question tool landed in the last release, so the fallback branch can go.

Add
- The last ten PRs in the work repo each got a "missing loading state" bot comment. That is a repo rule, not a global one; proposed line in the report below.

I couldn't confirm Cursor's current plan-mode behavior from its docs; the changelog entry is ambiguous.
```

Do not edit until the user picks. Do not push.
