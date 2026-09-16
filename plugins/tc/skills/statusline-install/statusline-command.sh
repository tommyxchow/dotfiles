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
# exhausted window; size is the context window formatted (1M / 200K) and size_raw
# the same value in tokens, which the context color scales its trip points from;
# project is the dir basename.
us=$'\037'
IFS="$us" read -r model used_pct five_used five_over seven_used seven_over effort size size_raw project cur_dir five_reset seven_reset cost repo wt <<EOF
$(jq -r --arg us "$us" '
# used_percentage is documented 0–100. Clamp display at 100; flag only values
# over 100 as spent (`out`), so 100% still means full.
def used: if . == null then "" else (floor | if . > 100 then 100 else . end | tostring) end;
def over: if . == null then "" elif . > 100 then "1" else "" end;
[
  (.model.display_name // "--"),
  (.context_window.used_percentage // ""),
  ((.rate_limits.five_hour.used_percentage // null) | used),
  ((.rate_limits.five_hour.used_percentage // null) | over),
  ((.rate_limits.seven_day.used_percentage // null) | used),
  ((.rate_limits.seven_day.used_percentage // null) | over),
  (.effort.level // ""),
  ((.context_window.context_window_size // null) | if . == null then "" elif . >= 1000000 then ((. / 1000000) | floor | tostring) + "M" elif . >= 1000 then ((. / 1000) | floor | tostring) + "K" else tostring end),
  ((.context_window.context_window_size // null) | if type == "number" then floor else "" end),
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
# needs attention. Callers pass their own trip points, since context scales its
# own to the window's headroom while a rate-limit window only matters near
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
# rate-limit one. The trip points are headroom, not percentage: orange under 70K
# tokens left, red under 50K, so the same amount of remaining room colors the
# same on any window. A 200K window resolves to the original 65 and 75, and
# anything smaller or unreported keeps those rather than scaling past them.
ctxseg=""
if [ -n "$used_pct" ]; then
  pct=$(printf "%.0f" "$used_pct")
  ctx_orange=65
  ctx_red=75
  if [ -n "$size_raw" ] && [ "$size_raw" -gt 200000 ]; then
    ctx_orange=$(( 100 - 70000 * 100 / size_raw ))
    ctx_red=$(( 100 - 50000 * 100 / size_raw ))
  fi
  ctxseg="${muted}ctx${reset} $(color_used "$pct" "$ctx_orange" "$ctx_red")${pct}%${reset}"
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
