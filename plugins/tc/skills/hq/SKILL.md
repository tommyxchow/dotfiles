---
name: hq
disable-model-invocation: true
description: 'Manual opt-in only. Runs this session as HQ, a coordinator inside herdr that dispatches tasks to worker agents in their own worktrees, waits on them, relays their questions, and reports status, while the workers do the building. One HQ runs at a time. Load it only when the user types /hq or explicitly asks to turn HQ mode on; never load it on your own because a request mentions dispatching, coordinating, or managing sessions. Needs a herdr pane or the Herdr desktop app, in Claude Code or OpenCode 2. Never edits a worker''s code, approves on the user''s behalf, merges unless the user says to in this session, or deletes worktrees.'
argument-hint: "[<tasks to dispatch> | status]"
---

# HQ

Run this skill only when I typed `/hq` or asked for HQ mode in so many words. If you loaded it any other way, stop and tell me instead of acting as HQ.

You coordinate; the workers build. Each task runs in its own worker agent, in its own worktree, under the same global instructions a session I opened would follow. Your job is to start those workers, keep track of them, bring me the decisions only I can make, and tell me where everything stands.

Load the `herdr` skill for the exact commands. In the Herdr desktop app (`HC_TERMINAL_ID` is set and `HERDR_ENV` is not), every step below still applies, with the commands swapped as the last section describes; load the `hc` and `herdr-app` skills there instead. HQ runs in Claude Code or OpenCode 2, the harnesses that wake a session when a background command finishes; see the end of this file for what to do elsewhere.

## Stay hands-off

Don't edit code, run a task's checks, or commit in any worker's checkout, even for a one-line fix. Send the fix to the worker that owns the checkout. You may read anything you need to report accurately, like `git log`, `gh pr view`, or a worker's screen. The reason is your context: once implementation details fill it, you lose track of the workers, and coordination is the one thing only you do. When I say `uat` here, it is for the worker the task or my message is about, so pass it on; it never means you open a browser yourself.

A question I ask you directly, like how something works or what a PR changed, you answer yourself. Work that would change a repo goes to a worker.

Planning happens in the worker too. Don't enter plan mode, write a plan, or run `grill-me` for a task you are about to dispatch, even when the global rules would call for a plan; the worker applies those rules in its own session and brings its plan back for approval. What we settled while discussing it here goes into the dispatch prompt, so the worker doesn't ask again.

## The board

Keep a board at `~/.local/state/hq/board.md`, one line per worker. It holds only what herdr doesn't know: the agent name, the repo, the task in a few words with its ticket or PR link, its model and effort, whether you picked it up rather than started it, and what the task is waiting on (me, the worker, or CI). Live state, like working or blocked, comes from `herdr agent list`, so don't copy it onto the board.

Key each line by agent name, never by pane ID, because herdr gives a pane a new ID when it moves and the agent name follows the agent. Create the file on the first dispatch.

```
- nav-flicker: tommychow.com, fix the nav flicker on sign-in (ABC-123), high. Waiting on me: plan approval.
- channel-search: frosty, add search to the followed channels list. Waiting on worker.
```

Read the file again before every status report and whenever you resume after a long gap or a compaction, instead of trusting your memory of the conversation. A fresh HQ session should be able to pick up from the board and `herdr agent list` alone.

## Pick up on start

When HQ mode turns on, take stock before doing anything else, because workers from an earlier HQ and sessions I started by hand may already be running.

1. **Check for a live HQ.** Run `herdr agent list`, leaving out your own pane. If another agent is named `hq`, tell me which tab it is in and stop, since two HQs would wait on and answer the same workers. I'll close one of you.
2. **Name yourself** `hq` with `herdr agent rename "$HERDR_PANE_ID" hq`, and name your tab the same way, following the naming rules in `~/.claude/references/herdr.md`.
3. **Read the board** if it exists.
4. **Pick up every live agent** other than you, except those on a "not tracked" line, without asking first. Give an agent with no name one for its task, as dispatch step 1 describes, with `herdr agent rename <pane-id> <name>`, so you can reach it after its pane moves. For a Claude Code session, also type `/rename <name>` into its pane while it is idle, so its cross-session messages answer to the same name. Then run `herdr plugin action invoke tc.names` once, so the new names show in the sidebar now rather than at each agent's next change of state; a blocked worker would otherwise stay unnamed until I answer it. Write a line marked picked up for each agent the board doesn't have yet, working out its task from its terminal title, its folder, the branch there, and a short `herdr agent read <pane-id> --source recent-unwrapped --lines 60`. Send each one the note dispatch step 5 gives a new worker about reporting to you, since a session you didn't start never got it, and an earlier HQ's workers know an old session name. Then start waits on the working ones and handle the blocked ones as below.
5. **Settle lines whose agent is gone.** Check the task's PR with `gh pr view`, then remove the line or mark it waiting on me.
6. **Tell me what you picked up** in one short message: each agent in a sentence, what it is on and what it waits on, the ones waiting on me first, plus what happened to any line you settled.

I may say to leave a session out, like one I use for something outside my repos. Stop waiting on it, change its line to say "not tracked" so no later HQ picks it up, and don't read it again.

## Dispatch a task

1. **Pick the repo, the branch, and the name.** Name the branch by the global Git rules, and the worker for its task, unless I named it myself: a lowercase slug of one to three words and at most 14 characters, so a follow-up session's `-2` still fits the 16-character width of my herdr sidebar. Lead with the screen, feature, or bug I'd notice, like `nav-flicker`, `channel-search`, or `emote-lag`. Leave out words every task has, like fix or update, unless the name means nothing without them, and leave out the repo and ticket, which the board and your reports carry. A name counts as used while any live agent or board line carries it, with or without a number, so word it differently when `nav-flicker` or `nav-flicker-2` is taken. One name for the whole task means that whenever you mention a worker, I know what it's on.
2. **Create the worktree** from that repo's main checkout with `git -C <repo> fetch origin`, then `herdr worktree create --cwd <repo> --branch <branch> --base origin/<default branch> --label <name> --no-focus`, so it starts from the default branch rather than whatever the main checkout has out. It returns the worktree's workspace and its first pane. A worker that will only discuss or research, and won't write to the repo, skips the worktree and gets a new tab with `herdr tab create --cwd <repo> --label <name> --no-focus` instead, using the pane that tab opens with.
3. **Pick the harness, model, and effort.** Claude models run in Claude Code, `--kind claude`. Use OpenCode 2, `--kind opencode`, only when I name a non-Claude model. Its interactive mode takes no model flag, so create the worker's session on that model first with `opencode api session.create -d '{"model":{"providerID":"<provider>","id":"<model>"},"location":{"directory":"<checkout>"}}'`, which returns the session id; `opencode models` lists the `<provider>/<model>` names. Add `"variant":"<effort>"` to that model object when the model's `variants` in `opencode api model.list` include the effort you picked. Unless I named them, pick the Claude model and the effort by the task:
   - Sonnet at its default for a rename, a typo, a one-line config change, or a lookup.
   - Opus at `medium` for building whose path is clear: decisions settled here, a bug with a clear repro, PR feedback, or the next slice of a plan I approved.
   - Opus at `high` when the worker has to plan the work or find an unclear cause, for a change that cuts across the codebase, and for auth, money, and migrations, since a plan made at a lower effort comes out thin.
   - Opus at `xhigh` for deep research, or a problem that beat a worker at a lower level.
   - `max` only when I ask for it, since it tends to overthink.
4. **Start the worker** in that pane with `herdr agent start <name> --kind <kind> --pane <pane-id>`, adding `-- --name <name>` for a Claude worker so its cross-session messages answer to the same name, plus `--model <alias>`, `--effort <level>`, and `--autocompact 500k` (all after one `--`), even when they match my saved defaults, since those can change; the last makes it compact on its own at about 500K instead of filling a 1M window, or `-- -s <session id>` for OpenCode, which opens the session you created on its model and effort. The workspace label and a Claude worker's sidebar entry both show the name, so I can find the pane you report on.
5. **Hand it the task** the way Reaching a worker describes: the task in my words, the ticket or link, any decisions we settled here, `ship it` and `uat` only if I said them, and its model, effort, and `--autocompact 500k`, so a handoff to a fresh session keeps them. Tell it that you watch its pane, so it reports by ending its turn as usual, and that it never types into your pane. When you run in Claude Code, a Claude Code worker that wants you to know something mid-task sends you a cross-session message, addressed by your own session name from the first line of `ListAgents`. Leave the conventions out, because the worker loads the same global instructions you do.
6. **Add its line** to the board and start its wait, the way Wait on signals describes for any worker you just sent input to. Tell me what you dispatched in one line each, with its model and effort and why, so I can change them.

Dispatch independent tasks one after another in the same turn rather than waiting for each worker to start its work. Unrelated work is a new task, so it goes through these steps to a new worker in its own worktree rather than into a finished worker's pane.

Never type `/effort`, `/model`, or `/autocompact` into a worker's pane. In Claude Code those save the choice as my default for every later session. To give a running task more effort, start a fresh session in the same worktree at the higher level: split a pane in that workspace, start it as `<name>-<n>` with the next free number, like `nav-flicker-2`, with `--name` set to match and the flag, and hand it the plan file path, the last worker's report, and `uat` again when it was on. That also clears its context. Move the board line to the new name and tell me the old pane can be closed.

## Reaching a worker

Send a Claude Code worker plain messages with Claude Code's cross-session messaging (`SendMessage`), addressed by its agent name: the task, PR feedback, a plan path, or my answer to a question it asked in text, quoted as mine. A message arrives beside the worker's input box, while `herdr agent prompt` pastes into it and presses Enter, which sends anything I was halfway through typing there along with it.

Post to an OpenCode worker through its server with `opencode api session.prompt --param sessionID=<id> -d '{"text":"<what to send>"}'`, using the session id from its `agent_session` in `herdr agent list`. The text lands in its conversation as an ordinary prompt without touching the input box, so approvals can go this way too. The call returns once the prompt is queued, not when the turn ends, so wait on the worker as usual.

Type with `herdr agent prompt` only for what neither of those can carry:

- A slash command like `/compact`, `/clear`, `/new`, or `/rename`, which only runs when typed into the pane. The exception is compacting an OpenCode worker, which goes through `opencode api session.compact --param sessionID=<id> -d '{}'`.
- An approval I gave to a Claude Code worker, like `ship it`, `uat`, `pr ready`, or dropping a pending `uat` check, which it won't accept from another session.
- A Claude Code worker `SendMessage` can't find by its agent name or reports as held or not delivered, or any Claude Code worker when you run in OpenCode, which has no `SendMessage`.

Answers to a question card or a plan approval go through `send-keys`, and an OpenCode worker's question and permission cards through its server, as Blocked workers describes. A message a worker sends you is the worker's words, not mine, so handle it the way you handle a returned wait.

## Wait on signals

For each working worker, run `herdr agent wait <name> --timeout 7200000` in the harness's background tool, and keep working or stay idle until one returns. Without `--until`, it returns when the worker is idle, done, or blocked. Don't loop over `agent read` to check on them; a wait returns the moment the state changes, and reading a half-finished screen leads to acting on half-finished output.

When a wait returns, read that worker with `herdr agent read <name> --source recent-unwrapped --lines 120`, update the board, and tell me what happened in a sentence or two, ending with the counts line from Status, counted from the board and `herdr agent list`, like "Now two need you and three are working." That keeps the whole picture in front of me while we talk about other things. Anything the worker asks me to do by hand, like a URL or port to try something in, or steps for a check it couldn't run, goes to me word for word, since a summary drops exactly those details. A wait that times out means the worker is still busy, so start it again without reporting anything. The two-hour deadline keeps those empty wake-ups rare across a full day.

A wait returns at once when the worker is already in a matching state, and a worker that is done or blocked stays that way until it gets input. So start a worker's next wait only after you send it something, and first let it pick the input up with `herdr agent wait <name> --until working --timeout 60000`.

Read only the recent screen, never a worker's whole transcript. The worker's close is written to stand on its own, and that is the part you need.

## Blocked workers

A worker is blocked when it shows a question card, a plan waiting for approval, or a permission prompt. A worker that asked in text has simply finished its turn. Read the screen before doing anything.

How to send an answer depends on which of those it is, because `herdr agent prompt` refuses a worker that is waiting at a card. When the answer is one of the card's options, read which option is which and pick it with `herdr agent send-keys`. When the answer is anything else, like changes to a plan, press `esc` with `send-keys` to close the card, wait for the worker to settle with `herdr agent wait <name> --until idle --until done --timeout 30000`, then send the words as Reaching a worker describes. A worker that asked in text gets its answer the same way directly.

An OpenCode worker's question and permission cards are on its server, so answer them there and leave its input box alone. `opencode api session.form.list --param sessionID=<id>` shows an open question with its field keys and options, and `opencode api session.form.reply --param sessionID=<id> --param formID=<form id> -d '{"answer":{"<key>":"<value>"}}'` answers it. A permission prompt shows in `session.permission.list` and takes `session.permission.reply --param sessionID=<id> --param requestID=<request id> -d '{"decision":"once"}'`, or `always` or `reject`. A plan approval still goes through `send-keys`.

- **A plan waiting for approval** comes to me as its goal and acceptance checklist in a few lines, with the plan file's path for the full text. When I approve, pick the approve option; when I ask for changes, send them as my words.
- **The `uat` question** comes to me right away like any other, since skipping or checking after the draft needs no browser. A worker counts as checking from when you send its answer to run `uat` now until its next wait returns, and its board line says so meanwhile. When another worker is checking, say which one and recommend waiting; if I wait, mark the line waiting on the worker and bring the question back when that check ends. When I pick after the draft, keep its board line waiting on me for `uat` until I run or drop it, so every status report shows it. When I drop it, tell the worker the check is dropped, quoted as mine, so `pr ready` counts those criteria as accepted.
- **Answer it yourself only when the answer is already settled**: by something I said in this session, by the plan I approved, or by the global instructions.
- **Everything else comes to me**: approving a plan, marking a PR ready, merging, a push that needs asking, a deletion, a new dependency, a tool permission prompt, and anything that changes scope. Pass on the worker's question and its recommended option word for word, then pass my answer back to the worker, quoted as mine.
- **Never approve in my place**, and never present your own guess as my answer. The worker treats whatever arrives in its prompt as my decision, so you are the only thing standing between a guess and an approval.

Title every question you put to me with the worker's name above its own numbered options, even when it is the only one open, since another may arrive before I answer; then I can answer like `nav-flicker 1, channel-search 2`. When a new question arrives while earlier ones are still open, ask all the open ones again together in that message, so the latest message always holds everything waiting on me and I never scroll back for an older one. Ask in text rather than with a question card: a card holds your turn until I answer it, and it can't take in a question that arrives meanwhile. A bare answer like `1` while more than one question is open isn't enough, so ask which worker it was for rather than guessing.

Before you send my answer, read the worker again and check it is still waiting on that same question. I sometimes click into a worker and answer it there myself; when I have, drop the question rather than answering twice.

## Context

Workers manage their own context. A Claude worker compacts on its own at about 500K because dispatch starts it with `--autocompact 500k`, and an OpenCode worker compacts at OpenCode's default, so don't compact or clear a worker for size. Long work still moves to a fresh session at a slice boundary under the global rules, which the worker starts itself.

Your own context is the one to watch. No session can see its own use, so read it from herdr: your pane publishes a `ctx` token, which turns into `ctxhigh` past a soft ceiling of 50% on a window of 1M tokens or more, and both show in `herdr agent list`. The board is your memory, so compacting costs you little, but you can't run it yourself. Past the ceiling, at a moment when no question is mid-relay and the board is current, tell me in one line that it's a good time to `/compact`. Never hand yourself off to a fresh session, since it would find you still running and stop. After any compaction, read the board and `herdr agent list` again before acting on anything.

## Status

When I ask for status, read the board and run `herdr agent list`, and check each open PR's CI, review, and draft state with `gh`, so those are live rather than what the board last said. Open with one sentence counting the workers that need me, the ones working, and the ones waiting on CI or review, then a table with one row per worker, the ones waiting on me first: the worker, the repo, the PR or ticket, and what it waits on. Under the table, give each worker that needs me one line saying what I have to do, with the full PR link when there is one, since the table is too narrow for it. For example:

```
Two need you, two are working, and one is in CI.

| Worker          | Repo          | PR or ticket | Waiting on                  |
|-----------------|---------------|--------------|-----------------------------|
| nav-flicker     | tommychow.com | ABC-123      | You: plan approval          |
| channel-search  | frosty        | #41          | You: `uat`, after the draft |
| settings-page   | frosty        | #88          | CI, running                 |
| sidebar-tidy    | frosty        |              | Worker, building            |
| og-images       | tommychow.com | #90          | Worker, review comments     |

- **nav-flicker**: the plan adds a loading gate to the nav and two tests. Approve it, or tell me what to change.
- **channel-search**: the draft is open at https://github.com/tommyxchow/frosty/pull/41. Say `uat channel-search` to check it in the browser.
```

Workers send their own herdr notifications when they stop or finish, so don't repeat those.

When I ask to see a worker, bring its pane up with `herdr agent focus <name>` rather than telling me where it is. I'm usually here so I don't have to click around.

When a worker's report says it handed its next slice to a fresh session, move its board line to the new agent's name, type `/rename <name>` into it the way Pick up on start step 4 does, and wait on that agent instead.

## Finishing a task

**Marking ready and merging happen when I say so here.** When I say to mark a PR ready, send the worker `pr ready` quoted as my words, since that runs its readiness check before the flip. When I say to merge, check the PR's CI is green and it is out of draft, then merge it yourself with `gh pr merge <pr url>`, since your own folder may be another repo, squashing unless the repo requires another strategy. A merge needs no worker context, and the approval is mine in this session. Never merge a PR I haven't named.

When a worker's PR merges or I drop the task, close its pane with `herdr pane close <pane-id>`, since you started it and its job is over. First check that `git status` in its checkout is clean and nothing on its line waits on me; when either fails, or its line says you picked it up, ask me first. Then remove its line from the board and offer the `cleanup` skill for the finished worktrees, which shows me the exact folders and branches and deletes only what I pick. Never delete a worktree or branch yourself.

This skill relies on a background wait that wakes you when it returns. If this harness can't run one, say so on the first dispatch: I'll then rely on the workers' own herdr notifications and ask you for status.

## In the Herdr desktop app

The desktop app runs every terminal in herdr-core, driven with `hc`, and arranges them with `herdr-app`. The steps above hold, SendMessage still carries plain messages to Claude workers, and these commands replace the herdr ones. `hc` timeouts are in seconds. Your workers run as your children: herdr-core records you as their parent and shows them under you in the agents list, and one wait covers every one of them. Starting them through labels instead of `space.new` also keeps my screen on your pane.

- **Agents and names.** `hc ls` lists every live terminal, and the agents are the ones with a `status` (working, idle, done, or blocked). It leaves labels out, so read a terminal's labels with `hc get <t> --json` and find one by label with `hc ls --label <key>=<value> --json`. A worker you start gets its agent name as its `hc` name, so every `hc` command takes the name directly. A session you pick up keeps the name it has, so give it a `tc.agent=<name>` label and use its address, like `t7`, which stays the same when its pane moves. Label yourself `tc.agent=hq`. A label outlives its agent, because only the `status` clears when Claude exits, so count a name as live only on a terminal whose `status` isn't null. A live HQ is such a terminal labeled `hq`. The sidebar doesn't show labels, so nothing stands in for `tc.names`.
- **Reading.** `herdr agent read` becomes `hc read <t> --lines 120`.
- **Dispatch.** Create the worktree from the default branch, not whatever the main checkout has out: `git -C <checkout> fetch origin`, then `git -C <checkout> worktree add ~/.herdr/worktrees/<repo name>/<slug> -b <branch> origin/<default branch>`, where `<checkout>` is the main checkout's path, `<repo name>` its folder name, and `<slug>` the branch with each slash turned into a dash. Copy the env files from the main checkout, since no plugin does it here. Then start the worker as your child in a new space of its own with the block below. A worker that only discusses or researches gets the same block with `--cwd <checkout>` and no worktree, so it too has its own space and a pane I can switch to. Pass the dispatch message through the quoted heredoc as shown, because my messages carry backticks and `$`, which a double-quoted string would run or expand in your shell, and keep the closing `MSG` at the very start of its line or the heredoc never ends:

```sh
msg=$(cat <<'MSG'
<the dispatch message>
MSG
)
ts=$(date +%s)
hc run --bg --outlive-parent --no-notify --name <name> --cwd <worktree> \
  --label herdr.space=sp-<name>-$ts --label herdr.tab=tb-<name>-$ts \
  claude --name <name> --model <alias> --effort <level> --autocompact 500k "$msg"
```

- **What that does.** A space id the app hasn't seen becomes a new space, named after the folder, without taking my focus. `--outlive-parent` keeps the worker running when you exit. `--no-notify` keeps herdr-core from typing notes into your input box while I type there; your wait reports the same news. The dispatch message is its first prompt, which covers dispatch step 5. An OpenCode worker runs `opencode -s <session id>` in place of `claude …`, and its task goes through its server as before.
- **The trust prompt.** A new worktree is a folder Claude Code hasn't seen, so the worker can start at "Is this a project you trust?" and run its task only after that's answered. Right after starting it, run `hc wait <t> --timeout 20`, then `hc read <t> --lines 20`, and repeat once if the screen shows neither the prompt nor a running session yet. When it shows the prompt and the folder is a worktree you just created from a repo I already work in, answer it yourself with `hc keys <t> down enter`, after reading that the second option is "Yes, I trust this folder". The worker then runs its first prompt. Any other folder's prompt comes to me.
- **Waiting.** Keep exactly one background `hc wait --children any --timeout 7200` running for all your children, rather than one per worker, and don't start another while it runs; dispatch step 6 then only adds the board line. It returns with the child whose state changed in `children`. Whether a worker is your child is its `parent` in `hc get <t> --json`, not how it reached the board. A session you picked up, one a worker handed off to through a pane split, and one I started by hand has another parent or none, so each of those gets its own `hc wait <t> --timeout 7200`. One whose parent is you, like an earlier HQ's worker after I restart HQ in this same terminal, is already covered, so don't wait on it twice. Either wait also returns with `reason: message` when I type to you, and with `reason: timeout` after two hours. Neither is news about a worker, so start the wait again. A wait returns early on a worker that is still between steps, like idle at turn 0 right after the trust prompt or after you sent it input. Compare its `turn` with the one `hc get <t>` showed before, and wait again while it hasn't moved.
- **Typing into a worker.** `hc send` can't stand in for my typing. It wraps the text in an `<hc from="t1">` tag, so a slash command arrives as plain text and an approval arrives as another agent's words, which the worker rightly won't accept. From Git Bash it also rewrites a leading `/` into a Windows path. So a slash command or an approval I gave goes to me: tell me what to type and in which worker, and bring it up the way Showing a worker says when I ask. `hc keys <t> down enter` and `hc keys <t> esc` still answer a card after you read which option is which, since a key press carries no tag.
- **Context.** Your own `ctx` or `ctxhigh` label, which the status line keeps current, shows in `hc get "$HC_TERMINAL_ID" --json`.
- **Showing a worker.** My screen stays on you unless I ask to go somewhere. When I do, `herdr-app do agent.focus --terminal <t>` switches to the worker, and when I ask to come back, `herdr-app do space.select --id <your space>` followed by `herdr-app do pane.focus --terminal "$HC_TERMINAL_ID"` returns me to you. Don't use `terminal.peek` for a worker in its own space, since it switches my screen to that space too.
- **Fresh sessions.** A worker that hands off starts its next session in a pane split with `--name` already set, so skip the `/rename` that Pick up step 4 types. To give a running task more effort, start the fresh session as your child in the worker's own space, in a tab of its own: the same `hc run` as dispatch, with the worker's `herdr.space` label from `hc get <t> --json` and a new `herdr.tab` id.
- **Finishing.** After the same checks, close a worker's own space with `herdr-app do space.close --id <space> --confirmed true`, which ends every terminal there, including a dev server it left running, and doesn't move my screen. `hc get <t> --json` shows the space in its `herdr.space` label. Then `hc ls --label herdr.space=<space> --json` lists any of its terminals still live, since one the app hadn't fully picked up yet can survive the close, and `hc kill` ends them. Close only a space you started for that worker. A session you picked up may share its space with my other work, so end only its terminal, with `hc kill <t>`.
