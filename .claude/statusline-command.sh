#!/usr/bin/env bash
# Claude Code Statusline
# Format: repo:worktree branch | Model effort [fast] | ctx N% Nk/size [cold] | 5h N% [reset] · 7d N% [reset] | $cost
# Structure comes from spacing and tier, not color: gray is chrome, orange/red
# mean attention, and a healthy line carries neither.

input=$(cat)
if [ -z "$(printf '%s' "$input" | tr -d '[:space:]')" ]; then echo "--"; exit 0; fi

# Pull all fields in one jq pass, joined by the unit separator (0x1f, defined in
# bash and passed via --arg) so empty fields are preserved on read. five_used and
# seven_used are percentages *used*, matching the context count so every number
# on the line runs the same direction; five_over and seven_over flag an
# exhausted window; size is the context window formatted (1M / 200k) and size_raw
# the same value in tokens, which the context red scales its trip point from;
# used_k is the context in use, formatted the same way; cold is set when the
# prompt cache has expired; fast is set in fast mode; project is the dir basename.
us=$'\037'
IFS="$us" read -r model five_used five_over seven_used seven_over effort size size_raw project cur_dir five_reset seven_reset cost repo wt used_k used_raw cold fast <<EOF
$(jq -r --arg us "$us" '
# used_percentage is documented 0–100. Clamp display at 100; flag only values
# over 100 as spent (`out`), so 100% still means full.
def used: if . == null then "" else (floor | if . > 100 then 100 else . end | tostring) end;
def over: if . == null then "" elif . > 100 then "1" else "" end;
# Tokens in k, or M with one decimal from a million up (1M, 1.2M).
def tok: if type != "number" then "" elif . >= 999500 then (([., 1000000] | max) / 100000 | floor) / 10 | tostring + "M" else ((. / 1000) | round | tostring) + "k" end;
[
  (.model.display_name // "--"),
  ((.rate_limits.five_hour.used_percentage // null) | used),
  ((.rate_limits.five_hour.used_percentage // null) | over),
  ((.rate_limits.seven_day.used_percentage // null) | used),
  ((.rate_limits.seven_day.used_percentage // null) | over),
  (.effort.level // ""),
  ((.context_window.context_window_size // null) | tok),
  ((.context_window.context_window_size // null) | if type == "number" then floor else "" end),
  (((.workspace.project_dir // .workspace.current_dir // "") | gsub("\\\\"; "/") | split("/") | map(select(length > 0)) | last) // ""),
  ((.workspace.current_dir // "") | gsub("\\\\"; "/")),
  (.rate_limits.five_hour.resets_at // ""),
  (.rate_limits.seven_day.resets_at // ""),
  (.cost.total_cost_usd // ""),
  (.workspace.repo.name // ""),
  (.worktree.name // .workspace.git_worktree // ""),
  ((.context_window.total_input_tokens // null) | tok),
  ((.context_window.total_input_tokens // null) | if type == "number" then floor else "" end),
  (if .prompt_cache.warm == false and .prompt_cache.caching_observed == true then "1" else "" end),
  (if .fast_mode == true then "1" else "" end)
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
# needs attention. Callers pass their own trip points, since context red scales
# to the window's headroom while a rate-limit window only matters near
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

# Segment 1: location, "<place> <branch>", where place is the project, or
# "repo:worktree" inside a worktree. The dir basename in a worktree is the
# worktree, not the repo, so a worktree would otherwise read as an unrelated
# project.
#
# Two rules keep the three names apart. The branch is separated by a space and a
# tier drop, never by a joiner: branch names carry their own slashes
# (feat/add-auth), so anything path-shaped puts two kinds of slash in one token and
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

# Segment 2: model, trailed by effort and fast mode a tier down. Both are
# session config, so they sit apart from the numbers that move. Fast mode is
# named because it bills at a higher rate.
meta="$effort"
[ -n "$fast" ] && meta="${meta:+$meta }fast"
modelseg="${reset}${model}${reset}"
[ -n "$meta" ] && modelseg="${modelseg} ${muted}${meta}${reset}"

# Segment 3: context used as a percentage, the quick read that matches the
# rate-limit windows, then the tokens over the window (34% 340k/1M) a tier down
# for the exact size. Both come from the same token count.
# Orange is the soft ceiling of 50% on a window of 1M or more,
# where compacting at the next break pays off; the herdr token below trips at
# the same point. A smaller window has no soft ceiling, since auto-compact
# handles it, so 101 keeps orange from ever tripping there. Red means auto-compact is close, so it trips on room left rather than
# percentage: under 50K tokens, which is 75% on a 200K window and 95% on 1M.
# Anything smaller or unreported keeps 75 rather than scaling past it.
ctxseg=""
pct=""
if [ -n "$used_raw" ] && [ "$used_raw" -gt 0 ] && [ -n "$size_raw" ] && [ "$size_raw" -gt 0 ]; then
  pct=$(( used_raw * 100 / size_raw ))
  ctx_orange=101
  ctx_red=75
  if [ -n "$size_raw" ] && [ "$size_raw" -ge 1000000 ]; then
    ctx_orange=50
  fi
  if [ -n "$size_raw" ] && [ "$size_raw" -gt 200000 ]; then
    ctx_red=$(( 100 - 50000 * 100 / size_raw ))
  fi
  ctxseg="${muted}ctx${reset} $(color_used "$pct" "$ctx_orange" "$ctx_red")${pct}%${reset} ${muted}${used_k}"
  [ -n "$size" ] && ctxseg="${ctxseg}/${size}"
  ctxseg="${ctxseg}${reset}"
  # An expired prompt cache means the next message re-caches the whole
  # conversation, which only costs enough to matter on a large one.
  if [ -n "$cold" ] && [ -n "$used_raw" ] && [ "$used_raw" -ge 50000 ]; then
    ctxseg="${ctxseg} ${orange}cold${reset}"
  fi
fi

# Inside a herdr pane, publish the agent's effort and context as pane tokens,
# so the sidebar shows them and an hq session reads them from `herdr agent
# list`. The agent's name is the `tc` herdr plugin's token, and pane tokens are
# shared across sources, so this never touches `name`. The model itself never
# sees this line. Context goes out as `ctxhigh` instead of
# `ctx` once it reaches the orange point above. The sidebar config can only
# color a token by name, so the threshold lives here rather than in a sidebar
# rule. The TTL outlives the 60s refresh, so the values vanish soon after Claude
# exits. It runs in the background because the statusline must never wait on
# herdr.
if [ -n "$HERDR_PANE_ID" ]; then
  herdr_bin="${HERDR_BIN_PATH:-herdr}"
  if command -v "$herdr_bin" >/dev/null 2>&1; then
    # A session with no context number yet, like one just after /clear,
    # clears both so an older value doesn't linger until its TTL runs out.
    ctx_args=(--clear-token ctx --clear-token ctxhigh)
    # A model with no effort setting clears the token rather than sending an empty value.
    effort_args=(--clear-token effort)
    [ -n "$effort" ] && effort_args=(--token "effort=${effort}")
    if [ -n "$pct" ]; then
      if [ "$pct" -ge "$ctx_orange" ]; then
        ctx_args=(--token "ctxhigh=ctx ${used_k}" --clear-token ctx)
      else
        ctx_args=(--token "ctx=ctx ${used_k}" --clear-token ctxhigh)
      fi
    fi
    "$herdr_bin" pane report-metadata "$HERDR_PANE_ID" --source tc.statusline \
      "${effort_args[@]}" "${ctx_args[@]}" --ttl-ms 180000 >/dev/null 2>&1 &
  fi
fi

# Segment 4: rate-limit usage, 5h · 7d (dot only between two present windows)
usage=""
for w in "$(win_seg 5h "$five_used" "$five_over" "$five_in")" "$(win_seg 7d "$seven_used" "$seven_over" "$seven_in")"; do
  [ -n "$w" ] || continue
  if [ -n "$usage" ]; then usage="${usage} ${dot} ${w}"; else usage="$w"; fi
done

# Segment 5: estimated session cost, client-side and reset by /clear. Shown
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
