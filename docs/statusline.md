# Statusline

`.claude/statusline-command.sh` is my Claude Code statusline: location as
`repo:worktree branch`, model with effort, context in tokens over the window,
the 5h and 7d rate-limit windows, and session cost when it is real money. The
installer links it and `settings.json` already runs it (see `README.md`), so a
new machine needs nothing else. This file is the design notes behind the
script.

## Output format

```
healthy   frosty main | Opus 5.5 high | 34% 340K/1M | 5h 24% · 7d 42%
worktree  frosty:my-feature feat/add-auth | Opus 5.5 high | 34% 340K/1M | 5h 24% · 7d 42%
stressed  frosty main | Opus 5.5 high fast | 96% 962K/1M cold | 5h out 1h48m · 7d 88% 4d6h | $1.42
```

**Every number is "used", so bigger is always worse.** An earlier version
showed context as used and the rate-limit windows as remaining, which put two
opposite scales behind the same `NN%` shape: a high number and a low number both meant trouble,
four tokens apart. One direction means one mental model and one color function.

**Structure comes from spacing and tier, color is reserved for attention.** A
healthy line is entirely uncolored: gray marks everything structural (separators,
labels, and secondary values like the branch and the reset countdowns), and what
you actually read sits in the default foreground. Orange or red anywhere means
something wants attention, so it's findable without reading the line.

- **`frosty main`**: where you are, then the branch a tier down in gray. Shows
  the project alone if not in a repo; the whole segment drops if there's no dir.
- Inside a **worktree** it becomes **`frosty:my-feature feat/thing`**: repo bound
  to the worktree by a gray `:`, branch still held off by the space. The dir
  basename in a worktree is the worktree, not the repo, so without the prefix a
  worktree would look like an unrelated project.
- **Two rules keep the three names apart.** The branch is never joined with
  punctuation, because branch names carry their own slashes and a path-style
  joiner (`frosty/my-feature@feat/thing`) puts two kinds of slash in one token so
  neither reads. And the repo binds with `:` rather than `/`, so the only `/`
  left on the segment is the branch's own.
- The repo comes from `workspace.repo.name` (the `origin` remote), falling back
  to the dir basename, then dropping out entirely when there's no origin and the
  basename is already the worktree name. The worktree name is `worktree.name`
  (present only in a Claude Code worktree session) falling back to
  `workspace.git_worktree` (populated for any worktree, Claude's included, so it
  only means "made by hand" once `worktree.name` has come back empty).
- A `--worktree` session names its branch `worktree-<name>`, which would print
  the worktree name twice. That case **drops the branch**, since the place has
  already said it.
- **`Opus 5.5 high`**: model name, then effort in gray, from the live `/effort`
  (`low` / `medium` / `high` / `xhigh` / `max`; Ultracode reports as `xhigh`).
  Effort is session config, so it sits apart from the numbers that move. A
  `fast` follows it in fast mode, which bills at a higher rate. The display
  name's built-in `(… context)` suffix is stripped, since the context segment
  states the window.
- **`34% 340K/1M`**: context used, first as a percentage for the quick read,
  in the same shape as the rate-limit windows, then in gray as tokens from
  `total_input_tokens` over the window from `context_window_size`, the units
  compaction and cost are measured in. It needs no label, since the token count
  is what tells it apart from the labeled `5h` and `7d` windows. Both come from
  the same token count, and only the percentage takes a color: orange at 50% on a window of 1M or more,
  the soft ceiling hq and the herdr sidebar also use, and red under 50K tokens
  of room, which is 75% on a 200K window and 95% on a 1M one (see Color
  thresholds). The window is the model's, not an `--autocompact` one: Claude
  Code doesn't pass that to the statusline, so an hq worker started with
  `--autocompact 500k` still shows `/1M` and compacts at about 470K.
- **`cold`**: the prompt cache has expired (`prompt_cache.warm` is false), so
  the next message re-caches the whole conversation. It shows only from 50K
  tokens, where that re-cache costs enough to matter, and it's the moment a
  `/clear` is worth considering when the history isn't needed.
- **`5h 24% · 7d 42%`**: 5-hour and 7-day rate-limit windows **used**.
  Uncolored below 75, orange at 75, red at 90. Pro/Max only, and only after the
  first API response of a session.
- **Time until reset** (`1h48m` / `4d6h`, gray) appears only on a window at 75
  or above, or spent, and never when missing or already past. The rest of the
  time it's noise: the segment's own labels are already durations, so a
  permanent countdown gives you four duration-shaped tokens to scan past.
- A **spent window reads `5h out 1h48m`** in red rather than a percentage.
  Official docs still say `used_percentage` is 0–100
  ([statusline](https://code.claude.com/docs/en/statusline)). The script clamps
  display at 100 and treats **over** 100 as `out`, so `100%` means full and
  `out` means past the documented range (a payload over 100 has been seen).
  Nothing in the payload exposes credit balance or whether extra usage is even
  enabled, so the statusline can't say more than this.
- **Names are clipped with `…`**: 20 chars for the project and worktree, 24 for
  the branch. A ticket-id branch is easily long enough to wrap the line, and
  wrapping is far worse than losing the tail of a name you already know.
- **`$1.42`**: `cost.total_cost_usd`, the client-side session estimate (not the
  real bill), two decimals, gray. `/clear` resets it to $0; a rate-limit window
  resetting does not. It appears **only when tokens are actually being billed**:
  a window reading `out` (usage drawing on credits) or no `rate_limits` in the
  payload at all (API-key pricing), counted only after the first response,
  since rate limits arrive with it and a fresh session would otherwise show
  `$0.00`. Inside the subscription allowance the figure
  isn't money, so a permanent one would just be a number to ignore. It covers
  the whole session at list rates, so a window that flips to `out` mid-session
  reveals a figure that includes what you spent before credits started.

## Herdr tokens

Inside a herdr pane the script also reports two pane tokens with `herdr pane
report-metadata`: `effort`, and the context as `34% 340K/1M`, the same text as the statusline (an
OpenCode pane leaves off the window, which its footer doesn't state). The model never sees
its own statusline, so this is how an `hq` session reads a worker's context and
effort. The herdr sidebar shows the context next to each Claude Code agent;
effort is left out there, since it is fixed at launch and `hq` picked it.
The agent's `name` token, shown on the same row, comes from the `tc` herdr
plugin rather than from here, so it works for every harness. Pane tokens are
shared across sources, so the script never sends or clears `name`.

Context goes out under one of two names. It is `ctxhigh` once a session on a
window of 1M tokens or more passes a soft ceiling of 50%, and `ctx` otherwise;
the sidebar colors `ctxhigh`. Anthropic documents that quality drops as
context fills but publishes no threshold, so 50% is a judgment call: 500K
tokens is already two and a half full 200K windows of history, every turn re-
sends all of it, and the flag only suggests a `/compact` at the next break, so
an early one costs little. hq watches it for its own pane; its workers compact
on their own at 500K. A smaller window has no soft ceiling and never reports
`ctxhigh`, because auto-compact handles it well enough. The flag marks where a
`/compact` at the next break starts paying off, not where the window runs out.

The report runs in the background with a three-minute TTL. The statusline
never waits on herdr, and the tokens disappear shortly after Claude exits
because nothing refreshes them. OpenCode 2 and Grok Build have no statusline
hook. The `tc` herdr plugin reads OpenCode 2's context off the bottom of its
screen at each change of state instead; Grok panes show only the name.

## Requirements (cross-platform)

Needs `bash`, `jq`, and `git` (plus `date`, always present):

- **macOS/Linux**: native bash (works on stock bash 3.2) + `brew install jq` /
  `apt install jq`. git is already present.
- **Windows**: runs under **Git Bash**, which ships all of these, so no
  PowerShell version is maintained.

The reset times use `date +%s` arithmetic (portable) rather than
`date -d`/`date -r` formatting (which differs between GNU and BSD).

## Wiring

`settings.json` runs the linked script with `bash` on every platform, so no
exec bit is needed:

```json
"statusLine": {
  "type": "command",
  "command": "bash \"$HOME/.claude/statusline-command.sh\"",
  "refreshInterval": 60
}
```

`refreshInterval` re-runs the script on a timer on top of the event triggers
(new assistant message, `/compact`, permission-mode change, vim-mode toggle,
session start). Without it the reset countdowns freeze while the session sits
idle, showing whatever was true at the last message. 60s keeps them honest.

## Color thresholds

Context gives each color one meaning. Orange is the soft ceiling, a
percentage that only windows of 1M or more have, because it tracks how full the conversation is and matches the
herdr token below. Red is auto-compact's deadline, which Claude Code derives
from the window minus reserved output rather than a fixed percentage, so red
trips on the tokens left: 50K of room is the same amount of work on any
window, while 75% used is 50K on a 200K window and 250K on a 1M one.

|        | Context        | Rate-limit window   |
| ------ | -------------- | ------------------- |
| low    | none           | none                |
| orange | 500k+ (1M)     | 75%+ used           |
| red    | under 50K left | 90%+ used, or `out` |

"None" is the terminal's default foreground, not a gray: uncolored values stay
fully legible, they just carry no signal. Green and yellow are gone entirely,
since a healthy value now says nothing rather than saying "green".

**One gray, ANSI bright black (`\033[90m`)**, covers everything structural:
labels, separators, and the secondary annotations (the worktree repo prefix,
the model's effort, the context's token count, the reset times, the cost). An earlier version
split this into two tiers, but in a healthy line the second tier landed on
exactly one token, so it read as a stumble rather than a hierarchy.

It's the terminal's own muted slot rather than a hex, so it resolves through
the active theme rather than assuming one. The tradeoff is that the exact
contrast depends on the palette. It should land near the 3:1 that a glanceable annotation wants,
deliberately below the AA text threshold, but a palette with an unusually dark
bright-black will need `\033[38;2;153;153;153m` (`#999999`) instead.

Claude Code's own equivalent is the `inactive` theme token ("secondary text such
as hints, timestamps, and disabled items"; `subtle` covers faint borders). The
built-in presets don't publish concrete values for it, so bright black is not a
guaranteed match. To make the two provably identical, override the token to the
same slot rather than guessing a hex, in `~/.claude/themes/<name>.json`:

```json
{ "base": "dark", "overrides": { "inactive": "ansi:blackBright" } }
```

An earlier version gave the location an accent color to anchor the line. Spacing
and the gray tier already separate place from branch, so the hue did nothing
the layout didn't, and without it a colored token on this line always means
attention, with no exceptions.

Codes: gray `\033[90m`, orange `\033[38;5;208m`, red `\033[38;2;187;106;122m`.
