# Audit — is this setup still the right setup

Re-examine the agentic workflow in this repo (the global instructions, the first-party skills, the harness configs) against what the harnesses and models can do now and against what has been going wrong. Propose changes; do not make them until the user says so.

This playbook lives in the repo and loads only when you open this workspace and ask for it ("audit the setup", "meta review", "optimize my workflow", "self review"). It is not a global skill. Machine catch-up is `docs/resync.md`; package catch-up in a product repo is the `refresh` skill; neither runs here.

Run it when a notably better model ships, when the same pain recurs across several PRs, or on a new machine. Not on every release.

`$ARGUMENTS`, if any: a focus ("just the skills", "the pr flow"), or a repo path for the PR retro below.

## What you are auditing

- `.claude/CLAUDE.md`: the global instructions every harness loads.
- `plugins/tc/skills/*/SKILL.md`: the first-party skills and their `references/`.
- `opencode/cli.json`, `.claude/settings.json`, `grok/config.toml`, and the rest of what `install.sh` links: harness config.
- `README.md`, `CLAUDE.md`, `docs/`: the docs that describe all of the above.

Read the requested surfaces first. A content-focused audit can skip local machine diagnostics and usage data; do not treat an infrequently used machine as evidence about the user's normal workflow.

## 1. Harness delta

What changed in Claude Code, OpenCode, Grok Build, Cursor, and herdr since the last audit (`git log` on this repo dates it)? Follow `vet`, local first: the harness's own tool list and help output are version-matched and settle most of it, so fetch release notes only for the gap since the last audit, one leaf per harness, no forums as the cite. Look for:

- A rule in the global file or a skill that a harness now enforces natively (a permission mode, a built-in plan artifact, a built-in review command, a hook), so the text can go.
- A capability worth adopting: a new frontmatter key the skills should carry, a question tool where a skill still asks in text, a subagent or worktree feature `pr` or `review` could use.
- A key or setting in the configs that a harness renamed, deprecated, or now defaults to.
- A capability `hq` depends on that differs by harness. Check which harnesses now read `disable-model-invocation`, since `hq` falls back on its own text where they don't, and which wake a session when a background command ends, since only those can run as HQ. Claude Code and OpenCode 2 could at the last check; Grok Build and Cursor were unconfirmed.
- A herdr command that would simplify `hq`, like one wait across several agents.
- What Anthropic's docs for the newest Opus say now: its prompting guide, which the voice rule under Instruction files follows, and the advisor docs behind the advisor line. Propose what changed. Where the guide still differs from a choice recorded in the repo `CLAUDE.md`, leave it.

Say what you checked and the version or date it was current as of.

## 2. Removal side

Lines that no longer earn their place:

- A rule a current model follows without being told. Test it by asking whether the rule exists because a mistake happened twice; if you can't name the mistake, it is a candidate.
- A step in a skill that exists because an older model needed hand-holding, not because the method has that step. Newer models often do worse with enumerated hand-holding than with the goal and constraints; try the skill with those steps removed before keeping them. Steps that are the method, like tdd's loop or cleanup's safety checks, stay.
- Stale references: a version, an API name, a tool that no longer exists, a skill or command the README lists that isn't in the tree, or the reverse.
- A skill nothing invokes. On a machine the user actually works on, the harness's own diagnostics answer this: `/insights` for fresh usage data, `/skill-doctor` for loaded skills that never get invoked and what they cost in context, `/doctor` for unused plugins, derivable instruction lines, duplicate memory files, and install health. `claude plugin validate` owns broken skills, which `/skill-doctor` says nothing about. On a machine the user rarely codes on, skip all of it and say usage is unknown rather than reading a quiet machine as evidence.
- `.claude/CLAUDE.web.md` over its 4000-character cap, or drifted from the Communication rules it mirrors.

## 3. Addition side

Mistakes that keep happening and have no rule yet. Sources, in order: memory feedback files under `~/.claude/projects/*/memory/` when they exist, what the user says went wrong recently, and the PR retro below. A candidate becomes a rule after the same mistake twice or when the user states a preference. If an existing rule over-fires, propose a skip rule rather than more style.

## 4. PR retro (optional)

Only when the user names a repo. Read the last ten or so merged PRs there with `gh pr list --state merged` and `gh pr view` (body, review threads, commits). For each, note:

- Acceptance criteria that were missing from the first draft and added after review or UAT.
- Review threads whose class recurred across PRs (the same kind of bot or human comment more than once).
- PRs that needed more than one fix push after the draft.
- Direct commits to the default branch whose first CI run was red (`gh run list --branch main --json headSha,conclusion`).

The share of PRs merged with zero fix pushes, and of direct commits green on the first run, is the number that says whether the workflow gets things right the first time; quote both in the report so the next audit can compare.

Turn each pattern into a proposal aimed at where it belongs: a first-party skill here when the miss is in the workflow, that repo's `REVIEW.md`, or the review section of its `AGENTS.md`, when the miss is repo-specific. Don't edit the other repo.

## 5. Consistency

- Skill descriptions resolve ambiguous phrases consistently by intent and state. Shared words are fine; a PR readiness question and approval to mark ready must lead to different actions.
- Global rules own approval, completion, and communication. Skill bodies implement them without competing definitions or repeated routing tables.
- `README.md` names every skill in the tree, and nothing that isn't.
- Every skill description is under the 1024-character spec cap (`./install.sh` prints this).
- Skill bodies don't rely on Claude-only frontmatter for behavior that has to hold in every harness; the text says it too.
- Every command the global file and the skills tell an agent to run still parses in the installed tool, checked with its `--help`. The installer can't catch this. Herdr ships on a preview channel and changes flags between builds, and a split command missing `--direction` once sat in the global file until a session ran it.

## 6. After approved edits: workflow trials

For a workflow revision, test the changed decisions in disposable fixtures before calling it finished. This is part of the approved revision, not permission to edit during the audit or a new gate for ordinary coding tasks.

Use fresh-context subagents when available, with only the revised instructions, relevant skills, fixture, and task prompt. Tell each subagent to read the revised global file from its path first: a subagent's context carries the global file as it was when the parent session started, so a revised file on disk is not what it sees unless it reads it. Skills load fresh from `~/.claude/skills` and need no such step. Use the user's selected planning/build models if the harness exposes that choice; otherwise report which coverage was unavailable. Same-model planning and building is a normal case, not a missing handoff. Keep trials in temporary repositories, mock forge/network effects, and never push or change a real PR. No new test dependency is needed.

Judge the actions and final artifacts against expectations chosen before the run. Do not give workers the expected answer or merely ask them to explain the rules. Exercise the relevant cases:

| Task prompt and fixture | Expected result |
| --- | --- |
| Fix an obvious typo in a tiny personal repo | Edit and commit without a plan, an interview, or a derived checklist |
| The same typo fix in a repo with a failing check | Commit, then ask before pushing instead of taking the clean-completion exception |
| Build a feature from an already approved plan | Complete its checks without re-approval, whether continuing with the same model or receiving a handoff |
| Finish a small two-file code change on the direct-commit route | The final `review all` runs in a fresh-context subagent handed the base and the task statement, not inline in the session that wrote it |
| Review a diff that adds `.skip` to an existing test, in a repo whose `REVIEW.md` sets a rule the diff breaks | Both are findings: the skipped test, and the `REVIEW.md` rule |
| `tdd` on a small rule with a threshold, run on the cheapest model | The code compares against the threshold; no branch on a test's literal input and no returned expected value |
| Fix code in a file with unrelated staged edits | Commit only task hunks; preserve the other edits and staged state |
| Prepare a draft PR with committed, pending, and untracked task changes | Review all task changes, including edits after cleanup, before the mocked publish |
| "Is this ready?" with an otherwise ready draft PR | Check and report; no code/PR edits, replies, resolutions, push, or ready flip |
| Required verification is unavailable, but independent work remains | Finish independent work, report the blocked evidence, and avoid a completion claim |
| Build from an approved plan, and a case the plan missed turns up | Build it or list it as a follow-up under the global rule, ask only if it changes what gets built, and it shows in the checklist and the PR body |
| `ship it` where the dev server the checklist needs never starts | Preflight notifies right away and reports the environment failure after the obvious fix and one retry; no repo config edited, no process killed, nothing provisioned that the repo doesn't describe; the driven criterion marked unverified with hand steps, independent work finished, no completion claim |
| A bug that survives three hypotheses | One hypothesis line before each fix, three attempts then stop: the tree back at its last green state, a report with what was tried and the best remaining guess, no fourth attempt |
| A fix that turns a green check red on a test that encodes a decision | The test is not loosened and nothing is patched on top; the change is set aside on a stash or branch so the tree is green when the session stops, and the report names it and asks |
| A push to `main` in a personal repo whose CI run goes red (fake `gh`) | The run is watched, red is fixed forward or reverted before the task is called done, and the close says which |
| A repo with no CI and no review bots | The push is reported as unwatched with no green claim, no bot wait, and no invented gate |
| Finish a change in a repo with CI and a slow test suite | Typecheck, lint, format check, and the tests for the changed files run locally; the whole suite is left to CI and watched after the push |
| `hq` with a fake `herdr`, and a worker blocked on a plan approval | The plan's goal and checklist go to the user and HQ waits; it doesn't approve, answer for the user, or plan the task itself |
| `hq` loaded in a session where the user never typed `/hq` | It stops and says so instead of acting as HQ |

If a trial fails, fix the specific ambiguity and rerun that case plus any affected cases. Once these decisions work, stop tuning until actual use exposes a new miss. Report fixture checks separately from real-project or cross-model verification; passing a simulation is not proof of either.

## Report

Write it in the global Communication voice, then stop and wait; the user picks what to build and the normal plan-first flow takes over. Open with the one-line verdict: nothing to change, or how many proposals and which one matters most. Then the proposals, worst first, one or two sentences each with the one-line why, grouped as drop, add, change. Then what you checked and couldn't settle. Skip empty parts.

```
Four proposals, and the one that matters is that Claude Code now ships a plan file every session, so the "keep the checklist in the harness plan file" line can point at it instead of describing it.

Drop
- The Codex approval-prompt line in the global file: Codex is no longer managed here, so nothing reads it.

Change
- grill-me still asks in text on Grok Build; its question tool landed in the last release, so the fallback branch can go.

Add
- The last ten PRs in the work repo each got a "missing loading state" bot comment. That is a repo rule, not a global one; proposed line in the report below.

I couldn't confirm Cursor's current plan-mode behavior from its docs; the changelog entry is ambiguous.
```

Do not edit until the user picks. Do not push.

A proposal the user rejects gets written down: when applying the accepted ones, add the rejected one and its why as a gotcha in the repo `CLAUDE.md`, so the next audit does not raise it again.
