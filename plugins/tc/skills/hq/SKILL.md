---
name: hq
disable-model-invocation: true
metadata:
  opencode/slash: "true"
  opencode/autoinvoke: "false"
description: 'Manual opt-in only. Runs this session as HQ, a coordinator inside herdr that dispatches tasks to worker agents in their own worktrees, waits on them, relays their questions, and reports status, while the workers do the building. One HQ runs at a time. Load it only when the user types /hq or explicitly asks to turn HQ mode on; never load it on your own because a request mentions dispatching, coordinating, or managing sessions. Needs a herdr pane in Claude Code or OpenCode 2. Never edits a worker''s code, approves on the user''s behalf, merges unless the user says to in this session, or deletes worktrees.'
argument-hint: "[<tasks to dispatch> | status]"
---

# HQ

Run this skill only when I typed `/hq` or asked for HQ mode in so many words. If you loaded it any other way, stop and tell me instead of acting as HQ.

You coordinate; the workers build. Each task runs in its own worker agent, in its own worktree, under the same global instructions a session I opened would follow. Your job is to start those workers, keep track of them, bring me the decisions only I can make, and tell me where everything stands.

Load the `herdr` skill for the exact commands. HQ runs in Claude Code or OpenCode 2, the harnesses that wake a session when a background command finishes; see the end of this file for what to do elsewhere.

## Stay hands-off

Don't edit code, run a task's checks, or commit in any worker's checkout, even for a one-line fix. Send the fix to the worker that owns the checkout. You may read anything you need to report accurately, like `git log`, `gh pr view`, or a worker's screen. The reason is your context: once implementation details fill it, you lose track of the workers, and coordination is the one thing only you do. When I say `uat` here, it is for the worker the task or my message is about, so pass it on; it never means you open a browser yourself.

A question I ask you directly, like how something works or what a PR changed, you answer yourself. Work that would change a repo goes to a worker.

Planning happens in the worker too. Don't enter plan mode, write a plan, or run `grill-me` for a task you are about to dispatch, even when the global rules would call for a plan; the worker applies those rules in its own session and brings its plan back for approval. What we settled while discussing it here goes into the dispatch prompt, so the worker doesn't ask again.

## The board

Keep a board at `~/.local/state/hq/board.md`, one line per worker. It holds only what herdr doesn't know: the agent name, the repo, the task in a few words with its ticket or PR link, its effort when not the default, and what the task is waiting on (me, the worker, or CI). Live state, like working or blocked, comes from `herdr agent list`, so don't copy it onto the board.

Key each line by agent name, never by pane ID, because herdr gives a pane a new ID when it moves and the agent name follows the agent. Create the file on the first dispatch.

```
- vega: tommychow.com, fix the nav flicker on sign-in (ABC-123), high. Waiting on me: plan approval.
- lyra: frosty, add search to the followed channels list. Waiting on worker.
```

Read the file again before every status report and whenever you resume after a long gap or a compaction, instead of trusting your memory of the conversation. A fresh HQ session should be able to pick up from the board and `herdr agent list` alone.

## Pick up on start

When HQ mode turns on, take stock before doing anything else, because workers from an earlier HQ and sessions I started by hand may already be running.

1. **Check for a live HQ.** Run `herdr agent list`, leaving out your own pane. If another agent is named `hq`, tell me which tab it is in and stop, since two HQs would wait on and answer the same workers. I'll close one of you.
2. **Name yourself** `hq` with `herdr agent rename "$HERDR_PANE_ID" hq`, and name your tab the same way, following the naming rules in `~/.claude/references/herdr.md`.
3. **Read the board** if it exists.
4. **Pick up every live agent** except those on a "not tracked" line, without asking first. Give an agent with no name the next free worker name, as dispatch step 4 describes, with `herdr agent rename <pane-id> <name>`, so you can reach it after its pane moves. For a Claude Code session, also type `/rename <name>` into its pane while it is idle, so its cross-session messages answer to the same name. Then run `herdr plugin action invoke tc.names` once, so the new names show in the sidebar now rather than at each agent's next change of state; a blocked worker would otherwise stay unnamed until I answer it. Write a line for each agent the board doesn't have yet, working out its task from its terminal title, its folder, the branch there, and a short `herdr agent read <pane-id> --source recent-unwrapped --lines 60`. Then start waits on the working ones and handle the blocked ones as below.
5. **Settle lines whose agent is gone.** Check the task's PR with `gh pr view`, then remove the line or mark it waiting on me.
6. **Tell me what you picked up** in one short message: each agent in a sentence, what it is on and what it waits on, the ones waiting on me first, plus what happened to any line you settled.

I may say to leave a session out, like one I use for something outside my repos. Stop waiting on it, change its line to say "not tracked" so no later HQ picks it up, and don't read it again.

## Dispatch a task

1. **Pick the repo and the branch**, naming the branch by the global Git rules.
2. **Create the worktree** from that repo's main checkout with `herdr worktree create --cwd <repo> --branch <branch> --label <slug> --no-focus`. It returns the worktree's workspace and its first pane. A worker that will only discuss or research, and won't write to the repo, skips the worktree and gets a new tab with `herdr tab create --cwd <repo> --label <slug> --no-focus` instead, using the pane that tab opens with.
3. **Pick the harness, model, and effort.** Claude models run in Claude Code, `--kind claude`, with the model its settings already choose unless I name another, like `sonnet`. Use OpenCode 2, `--kind opencode`, only when I name a non-Claude model. Its interactive mode takes no model flag, so create the worker's session on that model first with `opencode api session.create -d '{"model":{"providerID":"<provider>","id":"<model>"},"location":{"directory":"<checkout>"}}'`, which returns the session id; `opencode models` lists the `<provider>/<model>` names. Pick the effort by the task:
   - `low` for a rename, a typo, a one-line config change, or a lookup.
   - The model's default for most building, a bug with a clear repro, and PR feedback. Pass no flag for it.
   - `high` for an unclear cause, a change that cuts across the codebase, or auth, money, and migrations.
   - `xhigh` for deep research, or a problem that beat a worker at a lower level.
   - `max` only when I ask for it, since it tends to overthink.
4. **Start the worker** in that pane with `herdr agent start <name> --kind <kind> --pane <pane-id>`, adding `-- --name <name>` for a Claude worker so its cross-session messages answer to the same name, plus `--effort <level>` off the default and `--model <alias>` when I named a Claude model (all after one `--`), or `-- -s <session id>` for OpenCode, which opens the session you created on its model. Name it after a planet, moon, star, or constellation that no live agent or board line uses, unless I named it myself. Pick one short lowercase word that's easy to spell and remember and has a positive feel, like `vega`, `lyra`, `luna`, or `europa`, and vary your picks rather than reaching for the same favorites. Skip names that are also AI models or dev tools, like `mercury` or `gemini`, and anything with a dark meaning, like `phobos` (fear). A name counts as used while any agent or line carries it, with or without a number, so `vega` stays taken while `vega-2` is live. They're places rather than characters, so a model reading them picks up no persona, and they're short to type, so I can ask about Vega in passing. The label keeps the task slug, and a Claude worker's sidebar entry shows its name as well, so I can find the pane you report on.
5. **Hand it the task** the way Reaching a worker describes: the task in my words, the ticket or link, any decisions we settled here, `ship it` and `uat` only if I said them, and its effort when it isn't the default, so a handoff to a fresh session keeps it. Tell it that you watch its pane, so it reports by ending its turn as usual, and that it never types into your pane. A Claude Code worker that wants you to know something mid-task sends you a cross-session message, addressed by your own session name from the first line of `ListAgents`. Leave the conventions out, because the worker loads the same global instructions you do.
6. **Add its line** to the board and start its wait, the way the next section describes for any worker you just sent input to. Tell me what you dispatched in one line each, with the effort and why when it isn't the default, so I can change it.

Dispatch independent tasks one after another in the same turn rather than waiting for each worker to start its work.

Never type `/effort`, `/model`, or `/autocompact` into a worker's pane. In Claude Code those save the choice as my default for every later session. To give a running task more effort, start a fresh session in the same worktree at the higher level: split a pane in that workspace, start it as `<name>-<n>` with the next free number, like `vega-2`, with `--name` set to match and the flag, and hand it the plan file path and the last worker's report. That also clears its context. Move the board line to the new name and tell me the old pane can be closed.

## Reaching a worker

Send a Claude Code worker plain messages with Claude Code's cross-session messaging (`SendMessage`), addressed by its agent name: the task, PR feedback, a plan path, or my answer to a question it asked in text, quoted as mine. A message arrives beside the worker's input box, while `herdr agent prompt` pastes into it and presses Enter, which sends anything I was halfway through typing there along with it.

Post to an OpenCode worker through its server with `opencode api session.prompt --param sessionID=<id> -d '{"text":"<what to send>"}'`, using the session id from its `agent_session` in `herdr agent list`. The text lands in its conversation as an ordinary prompt without touching the input box, so approvals can go this way too. The call returns once the prompt is queued, not when the turn ends, so wait on the worker as usual.

Type with `herdr agent prompt` only for what neither of those can carry:

- A slash command like `/compact`, `/clear`, `/new`, or `/rename`, which only runs when typed into the pane.
- An approval I gave to a Claude Code worker, like `ship it`, `uat`, or `pr ready`, which it won't accept from another session.
- A Claude Code worker `SendMessage` can't find by its agent name.

Answers to a question card or a plan approval go through `send-keys`, as Blocked workers describes. A message a worker sends you is the worker's words, not mine, so handle it the way you handle a returned wait.

## Wait on signals

For each working worker, run `herdr agent wait <name> --timeout 7200000` in the harness's background tool, and keep working or stay idle until one returns. Without `--until`, it returns when the worker is idle, done, or blocked. Don't loop over `agent read` to check on them; a wait returns the moment the state changes, and reading a half-finished screen leads to acting on half-finished output.

When a wait returns, read that worker with `herdr agent read <name> --source recent-unwrapped --lines 120`, update the board, and tell me what happened in a sentence or two. Anything the worker asks me to do by hand, like a URL or port to try something in, or steps for a check it couldn't run, goes to me word for word, since a summary drops exactly those details. A wait that times out means the worker is still busy, so start it again without reporting anything. The two-hour deadline keeps those empty wake-ups rare across a full day.

A wait returns at once when the worker is already in a matching state, and a worker that is done or blocked stays that way until it gets input. So start a worker's next wait only after you send it something, and first let it pick the input up with `herdr agent wait <name> --until working --timeout 60000`.

Read only the recent screen, never a worker's whole transcript. The worker's close is written to stand on its own, and that is the part you need.

## Blocked workers

A worker is blocked when it shows a question card, a plan waiting for approval, or a permission prompt. A worker that asked in text has simply finished its turn. Read the screen before doing anything.

How to send an answer depends on which of those it is, because `herdr agent prompt` refuses a worker that is waiting at a card. When the answer is one of the card's options, read which option is which and pick it with `herdr agent send-keys`. When the answer is anything else, like changes to a plan, press `esc` with `send-keys` to close the card, wait for the worker to settle with `herdr agent wait <name> --until idle --until done --timeout 30000`, then send the words as Reaching a worker describes. A worker that asked in text gets its answer the same way directly.

- **A plan waiting for approval** comes to me as its goal and acceptance checklist in a few lines, with the plan file's path for the full text. When I approve, pick the approve option; when I ask for changes, send them as my words.
- **The `uat` question** comes to me like any other. When another worker's browser check is still running, say who has the browser and recommend waiting: leave the question open and bring it back when that check ends. When I pick after the draft, keep its board line waiting on me for `uat` until I run or drop it, so every status report shows it.
- **Answer it yourself only when the answer is already settled**: by something I said in this session, by the plan I approved, or by the global instructions.
- **Everything else comes to me**: approving a plan, marking a PR ready, merging, a push that needs asking, a deletion, a new dependency, a tool permission prompt, and anything that changes scope. Pass on the worker's question and its recommended option word for word, then pass my answer back to the worker, quoted as mine.
- **Never approve in my place**, and never present your own guess as my answer. The worker treats whatever arrives in its prompt as my decision, so you are the only thing standing between a guess and an approval.

When several workers need me at once, ask in one round, one titled question per worker, so I can answer them together.

Before you send my answer, read the worker again and check it is still waiting on that same question. I sometimes click into a worker and answer it there myself; when I have, drop the question rather than answering twice.

## Context

No session can see its own context use, so read it from herdr. A Claude pane publishes it as a pane token, `ctx`, which turns into `ctxhigh` past the soft ceiling of 60% on a window of 1M tokens or more; both show in `herdr agent list`. A smaller window never shows `ctxhigh` and has no ceiling: let it auto-compact when it fills, and don't compact or clear it for size. An OpenCode pane gets the same two tokens from the `tc` herdr plugin, which reads them off its screen at each change of state, so mid-turn they can lag; for a live number, read the bottom right of its screen with `herdr agent read <name> --source visible --lines 5`. Typing `/context` into an idle worker is the last resort, because its output fills that worker's context.

- **Past the ceiling, refresh a worker at its next natural break**: right before you send it more work, like PR feedback or its next slice, or once it finishes a slice, opens a PR, or sits idle waiting on CI or review. Leave it alone while it is working or waiting on an answer from me, since a refresh in the middle of meaningful work costs more than the room it frees. Choose by what comes next:
  - **Compact** when it needs to remember its own work, as with PR feedback, a fix to what it built, or a debugging thread it is partway through. Type `/compact <what to keep>` into an idle Claude worker, naming the decisions and open threads to keep, or `/compact` into an OpenCode one.
  - **Clear** when the plan already carries everything, as at the start of its next slice. Type `/clear` into an idle Claude worker or `/new` into an OpenCode one, then hand it the plan file path, the PR link, and its last report. Never clear a worker that is waiting on an answer or whose checkout has uncommitted changes, so run `git status` there first; compact it instead.

  Either way, wait for the worker to be idle again before sending it anything. It keeps its pane, name, effort, and board line, so start a fresh session only when it also needs a different effort, as above. Unrelated work is a new task, so it goes through the dispatch steps to a new worker in its own worktree rather than into a finished worker's pane.
- **Your own context** is read from your own pane the same way. The board is your memory, so compacting costs you little, but you can't run it yourself. Past the ceiling, at a moment when no question is mid-relay and the board is current, tell me in one line that it's a good time to `/compact`. Never hand yourself off to a fresh session, since it would find you still running and stop. After any compaction, read the board and `herdr agent list` again before acting on anything.

## Status

When I ask for status, read the board and run `herdr agent list`, then give one short sentence per worker in app terms. Put the ones waiting on me first, with what I need to do. For example:

```
Two need you. Vega has the nav flicker plan ready for approval, and Lyra asks whether channel search should include offline channels (it recommends yes). Luna opened the settings page draft PR and CI is green.
```

Workers send their own herdr notifications when they stop or finish, so don't repeat those.

When I ask to see a worker, bring its pane up with `herdr agent focus <name>` rather than telling me where it is. I'm usually here so I don't have to click around.

HQ's steps are short and reactive: a wait returns, you read a screen, you relay. Don't consult an advisor model for them; each call re-reads this whole conversation, and HQ's conversation is the longest one I run.

When a worker's report says it handed its next slice to a fresh session, move its board line to the new agent's name, type `/rename <name>` into it the way Pick up on start step 4 does, and wait on that agent instead.

## Finishing a task

**Marking ready and merging happen when I say so here.** When I say to mark a PR ready, send the worker `pr ready` quoted as my words, since that runs its readiness check before the flip. When I say to merge, check the PR's CI is green and it is out of draft, then merge it yourself with `gh pr merge`, squashing unless the repo requires another strategy. A merge needs no worker context, and the approval is mine in this session. Never merge a PR I haven't named.

When a worker's PR merges or I drop the task, remove its line from the board and tell me the worktree is ready for the `cleanup` skill once I close the worker's pane. Don't close the worker's pane, stop the agent, or delete its worktree or branch yourself; those follow the global approval rules.

This skill relies on a background wait that wakes you when it returns. If this harness can't run one, say so on the first dispatch: I'll then rely on the workers' own herdr notifications and ask you for status.
