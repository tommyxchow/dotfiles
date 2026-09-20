# Statusline

`.claude/statusline-command.sh` is my Claude Code statusline: location as
`repo:worktree branch`, model with context size and effort, context used, the
5h and 7d rate-limit windows, and session cost when it is real money. The
installer links it to `~/.claude/statusline-command.sh` and `settings.json`
already runs it, so a new machine needs nothing else. This file is the design
notes behind the script.

## Output format

```
healthy   frosty main | Opus 4.8 1M xhigh | ctx 34% | 5h 24% · 7d 42%
worktree  frosty:my-feature feat/add-auth | Opus 4.8 1M xhigh | ctx 34% | 5h 24% · 7d 42%
stressed  frosty main | Opus 4.8 1M xhigh | ctx 79% | 5h out 1h48m · 7d 88% 4d6h | $1.42
```

**Every percentage is "used", so bigger is always worse.** An earlier version
showed context as used and the rate-limit windows as remaining, which put two
opposite scales behind the identical `NN%` shape: a high number and a low number
both meant trouble, four tokens apart. One direction means one mental model and
one color function.

**Structure comes from spacing and tier, color is reserved for attention.** A
healthy line is entirely uncolored: gray marks everything structural (separators,
labels, and secondary values like the branch and the reset countdowns), and what
you actually read sits in the default foreground. Orange or red anywhere means
something wants attention, so it's findable without reading the line.

- **`frosty main`** — where you are, then the branch a tier down in gray. Shows
  the project alone if not in a repo; whole segment is dropped if there's no dir.
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
  (present only in a Claude worktree session) falling back to
  `workspace.git_worktree` (populated for any worktree, Claude's included, so it
  only means "made by hand" once `worktree.name` has come back empty).
- A `--worktree` session names its branch `worktree-<name>`, which would print
  the worktree name twice. That case **drops the branch**, since the place has
  already said it.
- **`Opus 4.8 1M xhigh`** — model name, then context-window size and effort in
  gray. Both are static session config, so they get their own segment
  away from the numbers that move. Size comes from `context_window_size` (`1M` /
  `200K`); effort from the live `/effort` (`low` / `medium` / `high` / `xhigh` /
  `max`; Ultracode reports as `xhigh`). The display name's built-in
  `(… context)` suffix is stripped so the size isn't stated twice.
- **`ctx 34%`** — context window used, labeled so it can't be confused with a
  rate-limit percentage. Colored on the room left rather than the percentage:
  orange under 70K tokens of headroom, red under 50K. On a 200K window that is
  the familiar 65 and 75; on a 1M window it holds off until 93 and 95, because
  auto-compact there fires far later.
- **`5h 24% · 7d 42%`** — 5-hour and 7-day rate-limit windows **used**.
  Uncolored below 75, orange at 75, red at 90. Pro/Max only, and only after the
  first API response of a session.
- **Time until reset** (`1h48m` / `4d6h`, gray) appears only on a window
  that's at 75 or above, or spent. The rest of the time it's noise: the segment's
  own labels are already durations, so a permanent countdown gives you four
  duration-shaped tokens to scan past. Omitted if missing or already past.
- A **spent window reads `5h out 1h48m`** in red rather than a percentage.
  Official docs still say `used_percentage` is 0–100
  ([statusline](https://code.claude.com/docs/en/statusline)). The script clamps
  display at 100 and treats **over** 100 as `out`, so `100%` means full and
  `out` means past the documented range (a payload over 100 has been seen).
  Nothing in the payload exposes credit balance or whether extra usage is even
  enabled, so the statusline can't say more than this.
- **Names are clipped with `…`** — 20 chars for the project and worktree, 24 for
  the branch. A ticket-id branch is easily long enough to wrap the line, and
  wrapping is far worse than losing the tail of a name you already know.
- **`$1.42`** — `cost.total_cost_usd`, the client-side session estimate (not the
  real bill), two decimals, gray. `/clear` resets it to $0; a rate-limit window
  resetting does not. It appears **only when tokens are actually being billed**:
  a window reading `out` (usage drawing on credits) or no `rate_limits` in the
  payload at all (API-key pricing). Inside the subscription allowance the figure
  isn't money, so showing it permanently would just be a number to ignore. Note
  it covers the whole session at list rates, so a window that flips to `out`
  mid-session reveals a figure that includes what you spent before credits
  started.

## Requirements (cross-platform)

Needs `bash`, `jq`, and `git` (plus `date`, always present):

- **macOS/Linux**: native bash (works on stock bash 3.2) + `brew install jq` /
  `apt install jq`. git is already present.
- **Windows**: runs under **Git Bash**, which ships all of these — no PowerShell
  version is maintained, and `settings.json` invokes the script with `bash` on
  every platform. The reset times use `date +%s` arithmetic (portable) rather
  than `date -d`/`date -r` formatting (which differs GNU vs BSD).

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
session start). Without it the reset countdowns freeze whenever the session
sits idle, so a terminal left open shows whatever was true at the last
message. 60s keeps them honest.

## Color thresholds

Both segments print a % used, and both mean "bigger is worse". Only the
rate-limit scale trips on that percentage. Context trips on the tokens behind
it, because its deadline is auto-compact and Claude Code derives that trigger
from the window minus reserved output, never from a fixed percentage. 50K of
room is the same amount of work whether the window is 200K or 1M, while 75%
used is 50K on one and 250K on the other.

|        | Context        | Rate-limit window   |
| ------ | -------------- | ------------------- |
| low    | none           | none                |
| orange | under 70K left | 75%+ used           |
| red    | under 50K left | 90%+ used, or `out` |

A window of 200K or less keeps the original 65 and 75 trip points exactly, since
70K and 50K left are 65% and 75% used there.

"None" is the terminal's default foreground, not a gray: uncolored values stay
fully legible, they just carry no signal. Green and yellow are gone entirely,
since a healthy value now says nothing rather than saying "green".

**One gray, ANSI bright black (`\033[90m`)**, covers everything structural: labels, separators, and
the secondary annotations that used to sit in parentheses (the worktree repo
prefix, the model's size + effort, the reset times, the cost). An earlier version
split this into two tiers, but in a healthy line the second tier landed on
exactly one token, so it read as a stumble rather than a hierarchy.

It's the terminal's own muted slot rather than a hex, for the same reason nothing
else here hardcodes color: bright black resolves through the active theme rather
than assuming one. The tradeoff is that the exact contrast now depends on the
palette. It should land near the 3:1 that a glanceable annotation wants,
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
and the gray tier replaced it: they already separate place from branch, so the
hue was doing nothing that layout wasn't, and dropping it means a colored token
on this line always means "attention" with no exceptions.

Codes: gray `\033[90m`, orange `\033[38;5;208m`, red `#BB6A7A`.
