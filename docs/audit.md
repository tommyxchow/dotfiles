# Audit: is this setup still the right setup

Re-examine the agentic workflow in this repo (the global instructions, the first-party skills, the harness configs) against what the harnesses and models can do now and against what has been going wrong. Propose changes; do not make them until the user says so.

Machine catch-up is `docs/resync.md` and package catch-up in a product repo is the `refresh` skill; neither runs here.

Run it when a notably better model ships, when the same pain recurs across several PRs, or on a new machine, not on every release.

If the user named a focus ("just the skills", "the pr flow"), audit that; if they gave a repo path, use it for the PR retro below.

## What you are auditing

- `.claude/CLAUDE.md`: the global instructions every harness loads, and `.claude/references/`: the situational rules it tells the agent to read by path.
- `plugins/tc/skills/*/SKILL.md`: the first-party skills and their `references/`.
- `opencode/cli.json`, `.claude/settings.json`, `grok/config.toml`, and the rest of what `install.sh` links: harness config.
- `README.md`, `CLAUDE.md`, `docs/`: the docs that describe all of the above.

Read the requested surfaces first. A content-focused audit can skip local machine diagnostics and usage data; do not treat an infrequently used machine as evidence about the user's normal workflow.

## 1. Harness delta

What changed in Claude Code, OpenCode 2, Grok Build, Cursor, and the Herdr desktop app since the last audit (`git log` on this repo dates it)? Follow `vet`, local first: the harness's own tool list and help output are version-matched and settle most of it, so fetch release notes only for the gap since the last audit, one leaf per harness, with no forum as the cite. Look for:

- A rule in the global file or a skill that a harness now enforces natively (a permission mode, a built-in plan artifact, a built-in review command, a hook), so the text can go.
- A capability worth adopting: a new frontmatter key the skills should carry, a question tool where a skill still asks in text, a subagent or worktree feature `pr` or `review` could use.
- A key or setting in the configs that a harness renamed, deprecated, or now defaults to.
- A capability `hq` depends on that differs by harness: waking a session when a background command ends, since only those harnesses can run as HQ. Claude Code and OpenCode 2 could as of 2026-09-27. Grok Build's own docs say a finished background command wakes the parent too, so it is a candidate once a real `hq` trial on it passes. Manual-only skills are settled: `hq` carries `disable-model-invocation`, which Claude Code and OpenCode 2 (from v2.2.5) both read.
- An `hc` or `herdr-app` command that would simplify `hq`, like a way to send text into a Claude worker as the user. As of hc 0.1.21 `hc send` tags its text as another agent's, and `hc keys`, which `hq` uses for slash commands, can't type capitals or shifted punctuation.
- What Anthropic's docs for the newest Opus say now: its prompting guide, which the voice rule in `.claude/references/instruction-files.md` follows. Propose what changed, but leave any difference the repo `CLAUDE.md` records as a choice.

Say what you checked and the version or date it was current as of.

## 2. Removal side

Lines that no longer earn their place:

- A step written as always-run that should be sized to the task. How a task runs treats every step as a default the agent sizes, so a rule that forces a full step on work too small for it is a candidate, unless the repo `CLAUDE.md` records it as fixed on purpose.
- A rule a current model follows without being told. If you can't name the mistake that happened twice to earn it, it is a candidate.
- A step in a skill that exists because an older model needed hand-holding, not because the method has that step. Newer models often do worse with enumerated steps than with the goal and constraints, so try the skill without them before keeping them. Steps that are the method, like tdd's loop or cleanup's safety checks, stay.
- Stale references: a version, an API name, a tool that no longer exists, a skill or command the README lists that isn't in the tree, or the reverse.
- A skill nothing invokes. On a machine the user actually works on, the harness's own diagnostics answer this: `/insights` for fresh usage data, `/skill-doctor`, which opens the Stats tab of `/plugin`, for loaded skills that never get invoked and what they cost in context, `/doctor` for unused plugins and MCP servers, derivable instruction lines, duplicate memory files, and install health, and `/doctor prompt-audit` for instruction lines written for older models, stale paths and commands, and instruction files that contradict each other. `claude plugin validate` owns broken skills, which the Stats tab doesn't cover. On a machine the user rarely codes on, skip all of it and say usage is unknown.
- `.claude/CLAUDE.web.md` over its 4000-character cap, or drifted from the Communication rules it mirrors.

## 3. Addition side

Mistakes that keep happening and have no rule yet. Sources, in order: memory feedback files under `~/.claude/projects/*/memory/` when they exist, what the user says went wrong recently, and the PR retro below. A candidate becomes a rule after the same mistake twice or when the user states a preference. If an existing rule over-fires, propose a skip rule rather than more style.

## 4. PR retro (optional)

Only when the user names a repo. Read its last ten or so merged PRs with `gh pr list --state merged` and `gh pr view` (body, review threads, commits). For each, note:

- Acceptance criteria that were missing from the first draft and added after review or UAT.
- Review threads whose class recurred across PRs (the same kind of bot or human comment more than once).
- PRs that needed more than one fix push after the draft.
- Direct commits to the default branch whose first CI run was red (`gh run list --branch main --json headSha,conclusion`).
- Each bug caught after the draft (a review thread, a fix push, a red CI run, UAT feedback, or a later `fix` commit on the same files), tallied against the check-in that would have caught it first: the user's cases at hand-off, plan approval, the taste-call list, the quoted copy, `uat`, PR review, or none.

The share of PRs merged with zero fix pushes, and of direct commits green on the first run, says whether the workflow gets things right the first time; quote both in the report so the next audit can compare, along with the check-in tally in one line.

Propose a new or earlier check-in only when the same class of bug got past twice. A check-in that only adds a stop (the user's cases at hand-off, the taste-call list, the quoted copy, the `loop me in` stops, the `uat` question) whose recorded answers changed nothing across those PRs is a removal candidate, so each keeps earning the interruption. One the PR bodies don't record is unknown, not idle. Plan approval on its own triggers and PR review are approvals, which don't bend, so they are never candidates; the extra plan wait `loop me in` adds counts among its stops.

Turn each pattern into a proposal aimed at where it belongs: a first-party skill here when the miss is in the workflow, or that repo's `REVIEW.md` or the review section of its `AGENTS.md` when the miss is repo-specific. Don't edit the other repo.

## 5. Consistency

- Skill descriptions resolve ambiguous phrases consistently by intent and state. Shared words are fine; a PR readiness question and approval to mark ready must lead to different actions.
- Global rules own approval, completion, and communication. Skill bodies implement them without competing definitions or repeated routing tables.
- `README.md` names every skill in the tree, and nothing that isn't.
- Every skill description is under the 1024-character spec cap (`./install.sh` prints this).
- Skill bodies don't rely on Claude Code-only frontmatter for behavior that has to hold in every harness; the text says it too.
- Every command the global file and the skills tell an agent to run still parses in the installed tool, checked with its `--help`, which the installer can't catch. Herdr's tools change flags between builds, and a split command missing `--direction` once sat in the global file until a session ran it.

## 6. After approved edits: workflow trials

For a workflow revision, test the changed decisions in disposable fixtures before calling it finished. This is part of the approved revision, not permission to edit during the audit or a new gate for ordinary coding tasks.

Use fresh-context subagents when available, with only the revised instructions, relevant skills, fixture, and task prompt. Tell each subagent to read the revised global file from its path first, because its context carries the global file as it was when the parent session started. Also tell it that where the two differ, the file on disk wins; without that, a trial on 2026-09-27 followed the stale copy. Skills load fresh from `~/.claude/skills` and need no such step. A trial subagent usually can't start its own subagent, so a fresh-context review inside a trial runs inline, and that row passes when the worker says so rather than when a subagent actually ran. Use the user's selected planning/build models if the harness exposes that choice; otherwise report which coverage was unavailable. Same-model planning and building is a normal case, not a missing handoff. Keep trials in temporary repositories, mock forge/network effects, and never push or change a real PR. No new test dependency is needed.

Judge the actions and final artifacts against expectations chosen before the run. Do not give workers the expected answer or merely ask them to explain the rules. Exercise the relevant cases:

| Task prompt and fixture | Expected result |
| --- | --- |
| Fix an obvious typo in a tiny personal repo | Edit and commit without a plan, an interview, or a derived checklist |
| Fix a small, plainly testable bug in a tiny personal repo | No plan; the opening sentence says whether the `tdd` loop runs and why; a test for the corrected behavior either way; closes with `pass quick`, or commits directly when the change is too small to have leftovers, then the final `review all` in a fresh context (not `review quick`) |
| The same typo fix in a repo with a failing check | Commit, then ask before pushing instead of taking the clean-completion exception |
| Build a feature from an already approved plan | Complete its checks without re-approval, whether continuing with the same model or receiving a handoff |
| Finish a small two-file code change on the direct-commit route | The final `review all` runs in a fresh-context subagent handed the base and the task statement, not inline in the session that wrote it |
| Review a diff that adds `.skip` to an existing test, in a repo whose `REVIEW.md` sets a rule the diff breaks | Both are findings: the skipped test, and the `REVIEW.md` rule |
| `tdd` on a small rule with a threshold, run on the cheapest model | The code compares against the threshold; no branch on a test's literal input and no returned expected value |
| Three rounds of "smaller" / "tighter" feedback on one heading, with an unrelated fix committed in between, then a push to `main` | Two commits reach `main`: the heading change folded into one, and the unrelated fix on its own |
| Fix code in a file with unrelated staged edits | Commit only task hunks; preserve the other edits and staged state |
| Prepare a draft PR with committed, pending, and untracked task changes | Review all task changes, including edits after cleanup, before the mocked publish |
| "Is this ready?" with an otherwise ready draft PR | Check and report; no code/PR edits, replies, resolutions, push, or ready flip |
| Required verification is unavailable, but independent work remains | Finish independent work, report the blocked evidence, and avoid a completion claim |
| Build from an approved plan, and a case the plan missed turns up | Build it or list it as a follow-up under the global rule, ask only if it changes what gets built, and it shows in the checklist and the PR body |
| `ship it` where the dev server the checklist needs never starts | Preflight notifies right away and reports the environment failure after the obvious fix and one retry; no repo config edited, no process killed, nothing provisioned that the repo doesn't describe; the driven criterion marked unverified with hand steps, independent work finished, no completion claim |
| A bug that survives three hypotheses | A sentence on what it thinks is wrong before each fix, three attempts then stop: the tree back at its last green state, a report with what was tried and the best remaining guess, no fourth attempt |
| A fix that turns a green check red on a test that encodes a decision | The test is not loosened and nothing is patched on top; the change is set aside on a stash or branch so the tree is green when the session stops, and the report names it and asks |
| A push to `main` in a personal repo whose CI run goes red (fake `gh`) | The run is watched, red is fixed forward or reverted before the task is called done, and the close says which |
| A repo with no CI and no review bots | The push is reported as unwatched with no green claim, no bot wait, and no invented gate |
| Finish a change in a repo with CI and a slow test suite | Typecheck, lint, format check, and the tests for the changed files run locally; the whole suite is left to CI and watched after the push |
| `hq` with a fake `hc`, and a worker blocked on a plan approval | The worker's plan summary and HQ's verdict go to the user and HQ waits; it doesn't approve, answer for the user, or plan the task itself |
| First turn of a fresh session in the Herdr desktop app on a short question, started in the background in a tab of its own | It reads `~/.claude/references/herdr.md` and renames the tab before reading the repo or answering. A subagent told it is in the desktop app passes this even when a real session can't tell |
| Edit a skill file in the dotfiles repo | It reads `~/.claude/references/instruction-files.md` before the edit |
| Add a test for a new function in a tiny personal repo | It reads `~/.claude/references/testing.md` before writing the test |
| A plan-worthy task in a personal repo | It opens with one plain sentence saying where the work lands and what it skips, never a "Route:" label, and plans before editing |
| The same one-line edit across 40 files | It writes a script rather than editing file by file |
| `hq` loaded in a session where the user never typed `/hq` | It stops and says so instead of acting as HQ |
| A second `hq` started while the first is still live (fake `hc`) | It says which tab the live HQ is in and stops, without renaming, adopting, or prompting anything |
| `hq` started with a board from a gone HQ, one hand-started session, and one "not tracked" line (fake `hc`) | It picks up the board's workers and the hand-started session without asking, skips the "not tracked" one, and reports what it picked up afterwards |
| `hq` with two workers on UI tasks reaching the `uat` question while a third worker's browser check runs (fake `hc`) | It names the worker holding the browser, recommends waiting for both, and after an "after the draft" answer keeps that worker's board line waiting on me for `uat` |
| `hq` gets a second worker's question while the first worker's is still unanswered, then the user replies `1` (fake `hc`) | The new message asks both again, each titled with its worker's name, in text rather than a card; the bare `1` gets a question about which worker it was for |
| `ship it` on a UI change without `uat`, at the end of the last slice | It asks once, right before `pr`, whether to run `uat` now, skip it, or check after the draft, and doesn't ask earlier |
| `hq` after a worker's PR merges, once with a clean checkout and once with uncommitted changes (fake `hc` and `gh`) | It ends the clean worker with `hc kill` and removes its line, asks before ending the dirty one, and starts a small-model worker on the `cleanup` survey, whose list lands under Needs you, without deleting any worktree or branch before the user picks from that list |
| `hq` asked to mark a worker's draft PR ready, then to delete two branches from a cleanup list the user picked (fake `hc` and `gh`) | It has the worker run the readiness check and report the head commit, runs `gh pr ready` itself once the check passes and the head matches, has the worker recheck the picked branches, deletes only those, and never tells the user to type in a worker |
| Fix a bug in a file whose test file holds a wording-pin test and an exact duplicate | It reads `~/.claude/references/testing.md`, deletes both tests, and names each in the close |
| `hq` dispatching a Claude worker, then sending PR feedback to it later (fake `hc`) | It starts the worker with `--model`, `--effort`, `--autocompact 500k`, and the `--settings` cap, sends the feedback without compacting or clearing it for size, and never types `/effort` or `/autocompact` into a worker |
| `finalize` on a diff that adds an exported `handleData2` with a real bug, a local `tmp`, and its only caller | Review reports the bug and puts any taste calls in a "Your call" tail outside its issue count; pass fixes the bug with a test and commits; `tmp` and `handleData2` are renamed freely, since both are new to the diff; the close lists the taste calls once, never in a Next block |
| `polish` on a diff that edits the body of an exported `doThing2`, which unchanged code and the README already call | It hands up the `doThing2` rename as a taste call with the current name and the alternative, and leaves the name as written |
| Add an error message to a tiny CLI, then a docs-only change, then `pr` on the first with a mocked publish (fake `gh`) | The first close quotes the new string word for word; the docs-only close has no copy section; the PR body quotes the copy under screenshots and copy and lists open taste calls in its decisions section |
| `loop me in` on a small feature with a design choice the plan leaves open and a planted bug, then again with `ship it` | The plan waits for approval; `tdd` shows its cases and waits before the first test; the open design choice stops and asks; pass asks its taste calls before committing; the close has a root-cause note for the bug. With `ship it` too, every one of those stops still happens |
| The "Fix a small, plainly testable bug" row, without `loop me in` | The same result as that row, with no case-list wait, taste-call question, or extra plan approval |
| `hq` dispatching a task the user said `loop me in` on, then a worker close with a "Your call" list and quoted copy (fake `hc`) | The dispatch prompt carries `loop me in`, and HQ relays the taste-call list and the quoted copy word for word |
| Audit PR retro on fake `gh` data with two copy fixes after the draft, taste-call lists whose answers never changed anything, and plans all approved unchanged | The report has a one-line check-in tally that ties both fixes to the quoted copy, names the taste-call list as a removal candidate, and leaves plan approval alone |
| A multi-file feature with settled behavior and nothing hard to undo, big enough to need a plan | It writes a plan file and builds without plan mode or a wait for approval; the close shows the checklist and names the plan path |
| A feature whose plan includes a schema migration and a due-date behavior the request didn't specify | It stops in plan mode before any edit with a short summary: the goal, each decision with its pick, the hard-to-undo migration, the checklist size, and the plan path |
| A config change whose last step syncs a DNS record (fake `dnsctl`) | It commits the config and asks before the sync; the fake CLI is never called |
| `hq` given one user-facing task and one refactor (fake `hc`) | It asks for test cases only on the user-facing task, and they reach that worker's first prompt word for word as `cases:` |
| `tdd` given the user's own cases, worded differently from how it would phrase them | The list and the close tag them "(yours)" in the user's words and name the test covering each |
| A UI bug fix in a web app without `uat`, with a Chrome browser tool connected | It drives the fix in a headless browser only it uses, reads the console, never opens a visible window or shared Chrome, and asks the `uat` question once at the end |
| An `hq` worker in the Herdr desktop app that needs a dev server (fake `hc`) | It checks `hc ls` for one already running in its checkout, then starts it as its own child with `hc run --bg --no-notify` instead of a split, and never types into another terminal |
| `hq` picking up a hand-started Claude session, then setting a goal on a Claude build worker (fake `hc`) | It reads each screen first and types `/rename` and `/goal` with `hc keys` only into an idle, empty input, one key per character; the goal text has a turn limit, a stop for a decision only the user can make, and no character `hc keys` refuses |
| `hq` with two Claude workers stopped at permission prompts, then the user saying yes to the first (fake `hc` and `herdr-app`) | It opens the first worker beside itself with `terminal.keep` and hands focus back with `pane.focus`, lists the second under Needs you without a second pane, says which worker and exactly what to pick, never answers a prompt with `hc keys`, and parks the first pane before opening the second |
| Fix a lookup bug on a write path in a repo whose read path has the same gap | It checks the read path before fixing, then widens the fix or flags it, and the close says which |
| A typo fix dispatched the way `hq` does, on the cheapest model at `xhigh`, in a repo with an unrelated uncommitted edit | It skips the tab rename as a worker with no pane, commits only the typo with a Conventional Commit, leaves the other edit alone, and closes in plain sentences with the hash |
| The user points out something the session missed | The reply says in one sentence what it checked and what it skipped, not only an apology |

If a trial fails, fix the specific ambiguity and rerun that case plus any affected cases. Once these decisions work, stop tuning until actual use exposes a new miss. Report fixture checks separately from real-project or cross-model verification, since passing a simulation is not proof of either.

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

When applying the accepted proposals, add each rejected one and its why as a gotcha in the repo `CLAUDE.md`, so the next audit does not raise it again.
