---
name: statusline-install
description: Install/restore my personal Claude Code statusline (location as "repo:worktree branch", model with context size + effort, context % used, 5h/7d rate-limit % used each with time-to-reset, and session cost) to ~/.claude/statusline-command.sh and wire it into settings.json. Canonical cross-platform bash (macOS/Linux native, Windows via Git Bash). Use to set up my statusline on a new machine or after a reset.
model: haiku
context: fork
disable-model-invocation: true
---

# Statusline Install

The bash script in this skill is the **source of truth** for my statusline. The
installed file at `~/.claude/statusline-command.sh` is a generated artifact — it
is NOT committed anywhere. To set up a machine (or restore after edits), write
the script below verbatim and point `settings.json` at it.

## Output format

```
healthy   frosty main | Opus 4.8 1M xhigh | ctx 34% | 5h 24% · 7d 42%
worktree  frosty:my-feature tc/add-auth | Opus 4.8 1M xhigh | ctx 34% | 5h 24% · 7d 42%
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
- Inside a **worktree** it becomes **`frosty:my-feature tc/thing`**: repo bound
  to the worktree by a gray `:`, branch still held off by the space. The dir
  basename in a worktree is the worktree, not the repo, so without the prefix a
  worktree would look like an unrelated project.
- **Two rules keep the three names apart.** The branch is never joined with
  punctuation, because branch names carry their own slashes and a path-style
  joiner (`frosty/my-feature@tc/thing`) puts two kinds of slash in one token so
  neither reads. And the repo binds with `:` rather than `/`, so the only `/`
  left on the segment is the branch's own.
- The repo comes from `workspace.repo.name` (the `origin` remote), falling back
  to the dir basename, then dropping out entirely when there's no origin and the
  basename is already the worktree name. The worktree name is `worktree.name`
  (`--worktree` sessions) or `workspace.git_worktree` (any `git worktree add`
  tree).
- A `--worktree` session names its branch `worktree-<name>`, which would print
  the worktree name twice. That case **drops the branch**, since the place has
  already said it.
- **`Opus 4.8 1M xhigh`** — model name, then context-window size and effort in
  gray. Both are static session config, so they get their own segment
  away from the numbers that move. Size comes from `context_window_size` (`1M` /
  `200K`); effort from the live `/effort`. The display name's built-in
  `(… context)` suffix is stripped so the size isn't stated twice.
- **`ctx 34%`** — context window used, labeled so it can't be confused with a
  rate-limit percentage. Uncolored below 65, orange at 65, red at 75 as it
  approaches the ~78% auto-compact trigger.
- **`5h 24% · 7d 42%`** — 5-hour and 7-day rate-limit windows **used**.
  Uncolored below 75, orange at 75, red at 90. Pro/Max only, and only after the
  first API response of a session.
- **Time until reset** (`1h48m` / `4d6h`, gray) appears only on a window
  that's at 75 or above, or spent. The rest of the time it's noise: the segment's
  own labels are already durations, so a permanent countdown gives you four
  duration-shaped tokens to scan past. Omitted if missing or already past.
- A **spent window reads `5h out 1h48m`** in red rather than a percentage.
  `used_percentage` is documented as 0–100 but actually runs past it once the
  subscription window is gone and usage bills to credits (109 observed). The
  script clamps at 100 and switches to the `out` word, so `100%` still means
  "rounded up to full, not yet over" and `out` means "past the limit". Nothing in
  the payload exposes credit balance or whether extra usage is even enabled, so
  the statusline can't say more than this.
- **Names are clipped with `…`** — 20 chars for the project and worktree, 24 for
  the branch. A `tc/`-prefixed branch is easily long enough to wrap the line, and
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

## Install steps

1. Write the script below verbatim to `~/.claude/statusline-command.sh`. No
   chmod needed — `settings.json` invokes it via `bash`, so the exec bit is
   irrelevant on every platform.
2. In `~/.claude/settings.json`, set:

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

Both scales run the same direction (% used), so only the trip points differ.
Context trips earlier because it has a hard deadline: the ~78% auto-compact.

| % used | Context | Rate-limit window |
| ------ | ------- | ----------------- |
| low    | none    | none              |
| orange | 65+     | 75+               |
| red    | 75+     | 90+, or `out`     |

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

## Script

```bash
#!/usr/bin/env bash
# Claude Code Statusline
# Format: repo:worktree branch | Model size effort | ctx N% | 5h N% [reset] · 7d N% [reset] | $cost
# Structure comes from spacing and tier, not color: gray is chrome, orange/red
# mean attention, and a healthy line carries neither.

input=$(cat)
if [ -z "$(echo "$input" | tr -d '[:space:]')" ]; then echo "--"; exit 0; fi

# Pull all fields in one jq pass, joined by the unit separator (0x1f, defined in
# bash and passed via --arg) so empty fields are preserved on read. five_used and
# seven_used are percentages *used*, matching the context percentage so every
# number on the line runs the same direction; five_over and seven_over flag an
# exhausted window; size is the context window (1M / 200K); project is the dir
# basename.
us=$'\037'
IFS="$us" read -r model used_pct five_used five_over seven_used seven_over effort size project cur_dir five_reset seven_reset cost repo wt <<EOF
$(jq -r --arg us "$us" '
# used_percentage can exceed 100 once the subscription window is spent and usage
# is billed to credits (seen: 109). Clamp at 100 and flag the overage separately,
# since past the limit the exact number stops meaning anything.
def used: if . == null then "" else (floor | if . > 100 then 100 else . end | tostring) end;
def over: if . == null then "" elif . >= 100 then "1" else "" end;
[
  (.model.display_name // "--"),
  (.context_window.used_percentage // ""),
  ((.rate_limits.five_hour.used_percentage // null) | used),
  ((.rate_limits.five_hour.used_percentage // null) | over),
  ((.rate_limits.seven_day.used_percentage // null) | used),
  ((.rate_limits.seven_day.used_percentage // null) | over),
  (.effort.level // ""),
  ((.context_window.context_window_size // null) | if . == null then "" elif . >= 1000000 then ((. / 1000000) | floor | tostring) + "M" elif . >= 1000 then ((. / 1000) | floor | tostring) + "K" else tostring end),
  (((.workspace.project_dir // .workspace.current_dir // "") | gsub("\\\\"; "/") | split("/") | map(select(length > 0)) | last) // ""),
  ((.workspace.current_dir // "") | gsub("\\\\"; "/")),
  (.rate_limits.five_hour.resets_at // ""),
  (.rate_limits.seven_day.resets_at // ""),
  (.cost.total_cost_usd // ""),
  (.workspace.repo.name // ""),
  (.worktree.name // .workspace.git_worktree // "")
] | map(tostring) | join($us)' <<<"$input")
EOF

# display_name already carries a "(… context)" suffix on extended-context models;
# strip it so the size isn't stated twice.
model="${model% (*)}"

# Current git branch for the session's directory (empty if not a repo)
branch=""
[ -n "$cur_dir" ] && branch=$(git -C "$cur_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)

reset=$'\033[0m'
# One gray for everything structural, so the muting reads as a system rather than
# as a second tier applied to whichever token happened to get it. Nothing on a
# healthy line is colored: structure comes from spacing and tier, and ink is
# reserved for what needs attention.
#
# Bright black (the terminal's own muted slot) rather than a hex, so it tracks
# the terminal theme instead of assuming one. Claude Code calls its equivalent
# token "inactive"; the built-in presets don't publish a value for it, so this
# doesn't match the UI by construction. To make it exact, override the token to
# the same slot in ~/.claude/themes/<name>.json: {"base":"dark","overrides":
# {"inactive":"ansi:blackBright"}}.
muted=$'\033[90m'
orange=$'\033[38;5;208m'
red=$'\033[38;2;187;106;122m'

sep="${muted}|${reset}"
dot="${muted}·${reset}"

# Color for a "% used" value, shared by every percentage on the line so a bigger
# number always means worse and a colored one always means the same thing. A
# value with room to spare gets no color at all: ink here is reserved for what
# needs attention. Callers pass their own trip points, since context has a hard
# auto-compact trigger around 78 while a rate-limit window only matters near
# exhaustion.
color_used() {
  if [ "$1" -ge "$3" ]; then printf '%s' "$red"
  elif [ "$1" -ge "$2" ]; then printf '%s' "$orange"
  else printf '%s' "$reset"; fi
}

# Cap a name so a long branch can't push the line into a wrap. The ellipsis is
# the only signal, which keeps the segment a predictable width instead of leaving
# it to the terminal to cut wherever it happens to run out.
clip() {
  if [ "${#1}" -gt "$2" ]; then printf '%s…' "${1:0:$(($2 - 1))}"; else printf '%s' "$1"; fi
}

# Compact "time until" formatter (seconds -> e.g. 4d6h / 1h48m / 47m)
fmt_dur() {
  local s=$1 d h m
  d=$((s / 86400)); h=$(((s % 86400) / 3600)); m=$(((s % 3600) / 60))
  if [ "$d" -gt 0 ]; then
    if [ "$h" -gt 0 ]; then printf '%dd%dh' "$d" "$h"; else printf '%dd' "$d"; fi
  elif [ "$h" -gt 0 ]; then
    if [ "$m" -gt 0 ]; then printf '%dh%dm' "$h" "$m"; else printf '%dh' "$h"; fi
  else
    printf '%dm' "$m"
  fi
}

# Relative time until a reset epoch (empty if missing or already past)
reset_in() {
  local d
  [ -n "$1" ] || return
  d=$(( $1 - now ))
  [ "$d" -gt 0 ] && fmt_dur "$d"
}

# Render one rate-limit window: "<label> <pct>% <reset>", colored by usage. A
# spent window prints "out" instead of "100%" so it reads apart from "almost
# gone". Empty if the window is absent.
win_seg() {
  local label=$1 used=$2 over=$3 in=$4
  [ -n "$used" ] || return
  if [ -n "$over" ]; then
    printf '%s%s%s %sout%s' "$muted" "$label" "$reset" "$red" "$reset"
  else
    printf '%s%s%s %s%s%%%s' "$muted" "$label" "$reset" "$(color_used "$used" 75 90)" "$used" "$reset"
  fi
  # The countdown only matters once a window is nearly spent. Hiding it the rest
  # of the time keeps a second duration out of a segment whose labels are
  # already durations.
  if [ -n "$in" ] && { [ -n "$over" ] || [ "$used" -ge 75 ]; }; then
    printf ' %s%s%s' "$muted" "$in" "$reset"
  fi
}

now=$(date +%s)
five_in=$(reset_in "$five_reset")
seven_in=$(reset_in "$seven_reset")

# Segment 1 — location: "<place> <branch>", where place is the project, or
# "repo:worktree" inside a worktree. The dir basename in a worktree is the
# worktree, not the repo, so a worktree would otherwise read as an unrelated
# project.
#
# Two rules keep the three names apart. The branch is separated by a space and a
# tier drop, never by a joiner: branch names carry their own slashes
# (tc/add-auth), so anything path-shaped puts two kinds of slash in one token and
# neither reads. And the repo binds to the worktree with ":" rather than "/", so
# the only "/" left on the segment is the branch's own.
# The worktree only becomes a suffix when there's a name to prefix it with. With
# no repo and no usable dir basename it stands alone as the place, rather than
# hanging off an empty prefix and being dropped with it below.
name="$project"
wtpart=""
if [ -n "$wt" ]; then
  if [ -n "$repo" ]; then name="$repo"; wtpart="$wt"
  elif [ -n "$project" ] && [ "$project" != "$wt" ]; then wtpart="$wt"
  else name="$wt"; fi
fi
# A `claude --worktree` session names the branch "worktree-<name>", which would
# print the worktree name twice and say nothing the place hasn't already said.
[ -n "$wtpart" ] && [ "$branch" = "worktree-$wtpart" ] && branch=""
name=$(clip "$name" 20)
wtpart=$(clip "$wtpart" 20)
branch=$(clip "$branch" 24)
loc=""
if [ -n "$name" ]; then
  loc="${reset}${name}"
  [ -n "$wtpart" ] && loc="${loc}${muted}:${reset}${wtpart}"
  [ -n "$branch" ] && loc="${loc} ${muted}${branch}"
  loc="${loc}${reset}"
fi

# Segment 2 — model, trailed by size + effort a tier down. Both are static
# session config, so they sit apart from the numbers that move.
meta="$size"
[ -n "$effort" ] && meta="${meta:+$meta }$effort"
modelseg="${reset}${model}${reset}"
[ -n "$meta" ] && modelseg="${modelseg} ${muted}${meta}${reset}"

# Segment 3 — context window used, labeled so the % can't be mistaken for a
# rate-limit one. Uncolored until it nears the ~78% auto-compact trigger.
ctxseg=""
if [ -n "$used_pct" ]; then
  pct=$(printf "%.0f" "$used_pct")
  ctxseg="${muted}ctx${reset} $(color_used "$pct" 65 75)${pct}%${reset}"
fi

# Segment 4 — rate-limit usage: 5h · 7d (dot only between two present windows)
usage=""
for w in "$(win_seg 5h "$five_used" "$five_over" "$five_in")" "$(win_seg 7d "$seven_used" "$seven_over" "$seven_in")"; do
  [ -n "$w" ] || continue
  if [ -n "$usage" ]; then usage="${usage} ${dot} ${w}"; else usage="$w"; fi
done

# Segment 5 — estimated session cost, client-side and reset by /clear. Shown
# only when tokens are actually being billed: a spent window means usage is
# drawing on credits, and no rate-limit data at all means API pricing. Inside
# the subscription allowance the number isn't money, so it stays hidden.
costseg=""
if [ -n "$cost" ] && { [ -n "$five_over" ] || [ -n "$seven_over" ] || [ -z "$five_used$seven_used" ]; }; then
  costseg="${muted}\$$(printf '%.2f' "$cost")${reset}"
fi

# Join non-empty segments with the divider
out=""
for seg in "$loc" "$modelseg" "$ctxseg" "$usage" "$costseg"; do
  [ -n "$seg" ] || continue
  if [ -n "$out" ]; then out="${out} ${sep} ${seg}"; else out="${seg}"; fi
done

printf "%s\n" "$out"
```
