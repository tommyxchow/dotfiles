---
name: statusline-install
description: Install/restore my personal Claude Code statusline — project:branch, model with context size + effort, context %, and 5h/7d usage remaining (each with time-to-reset) — to ~/.claude/statusline-command.sh and wire it into settings.json. Canonical cross-platform bash (macOS/Linux native, Windows via Git Bash). Use to set up my statusline on a new machine or after a reset.
model: haiku
context: fork
agent: statusline-setup
disable-model-invocation: true
---

# Statusline Install

The bash script in this skill is the **source of truth** for my statusline. The
installed file at `~/.claude/statusline-command.sh` is a generated artifact — it
is NOT committed anywhere. To set up a machine (or restore after edits), write
the script below verbatim and point `settings.json` at it.

## Output format

```
frosty:main | Opus 4.8 (1M, xhigh) 34% | 5h 76% (1h48m) · 7d 58% (4d6h)
```

- **`frosty:main`** — project (basename of the project/current dir) and the git
  branch for the session's directory. Shows the project alone if not in a repo;
  whole segment is dropped if there's no dir.
- **`Opus 4.8 (1M, xhigh) 34%`** — model name, then `(context-window size, effort)`
  and the context-window % used, grouped together. Size comes from
  `context_window_size` (`1M` / `200K`); effort from the live `/effort`. The
  display name's built-in `(… context)` suffix is stripped so the parenthetical
  isn't doubled. The `%` color ramps green → yellow → orange → red toward the
  ~78% auto-compact trigger.
- **`5h 76% (1h48m) · 7d 58% (4d6h)`** — 5-hour and 7-day rate-limit windows
  **remaining** (100 − used). Color ramps the opposite way (green when plenty
  left, red when nearly out). Each window also shows **time until it resets** in
  dim parens (relative, e.g. `1h48m` / `4d6h`; omitted if missing or already
  past). Pro/Max only, and only after the first API response of a session.

## Requirements (cross-platform)

Needs `bash`, `jq`, and `git` (plus `date`, always present):

- **macOS/Linux**: native bash (works on stock bash 3.2) + `brew install jq` /
  `apt install jq`. git is already present.
- **Windows**: runs under **Git Bash**, which ships all of these — no PowerShell
  version is maintained, and `settings.json` invokes the script with `bash` on
  every platform. The reset times use `date +%s` arithmetic (portable) rather
  than `date -d`/`date -r` formatting (which differs GNU vs BSD).

## Install steps

1. Write the script below verbatim to `~/.claude/statusline-command.sh` and make
   it executable: `chmod +x ~/.claude/statusline-command.sh`.
2. In `~/.claude/settings.json`, set:

   ```json
   "statusLine": {
     "type": "command",
     "command": "bash \"$HOME/.claude/statusline-command.sh\""
   }
   ```

## Color thresholds

| Context % used | Color  |        | Usage % left | Color  |
| -------------- | ------ | ------ | ------------ | ------ |
| 0–49           | green  |        | >50          | green  |
| 50–64          | yellow |        | 26–50        | yellow |
| 65–74          | orange |        | 11–25        | orange |
| 75+            | red    |        | ≤10          | red    |

True-color codes: dim `#999999`, green `#37A660`, yellow `\033[33m`, orange
`\033[38;5;208m`, red `#BB6A7A`.

## Script

```bash
#!/usr/bin/env bash
# Claude Code Statusline
# Format: project:branch | Model (size, effort) ctx% | 5h left% (reset) · 7d left% (reset)

input=$(cat)
if [ -z "$(echo "$input" | tr -d '[:space:]')" ]; then echo "--"; exit 0; fi

# Pull all fields in one jq pass, joined by the unit separator (0x1f, defined in
# bash and passed via --arg) so empty fields are preserved on read. five_left and
# seven_left are "remaining" (100 - used, floored); size is the context window
# (1M / 200K); project is the dir basename.
us=$'\037'
IFS="$us" read -r model used_pct five_left seven_left effort size project cur_dir five_reset seven_reset <<EOF
$(jq -r --arg us "$us" '[
  (.model.display_name // "--"),
  (.context_window.used_percentage // ""),
  (if (.rate_limits.five_hour.used_percentage // null) != null then (100 - .rate_limits.five_hour.used_percentage | floor | tostring) else "" end),
  (if (.rate_limits.seven_day.used_percentage // null) != null then (100 - .rate_limits.seven_day.used_percentage | floor | tostring) else "" end),
  (.effort.level // ""),
  ((.context_window.context_window_size // null) | if . == null then "" elif . >= 1000000 then ((. / 1000000) | floor | tostring) + "M" elif . >= 1000 then ((. / 1000) | floor | tostring) + "K" else tostring end),
  (((.workspace.project_dir // .workspace.current_dir // "") | gsub("\\\\"; "/") | split("/") | map(select(length > 0)) | last) // ""),
  ((.workspace.current_dir // "") | gsub("\\\\"; "/")),
  (.rate_limits.five_hour.resets_at // ""),
  (.rate_limits.seven_day.resets_at // "")
] | map(tostring) | join($us)' <<<"$input")
EOF

# display_name already carries a "(… context)" suffix on extended-context models;
# strip it so our own "(size, effort)" parenthetical isn't doubled.
model="${model% (*)}"

# Current git branch for the session's directory (empty if not a repo)
branch=""
[ -n "$cur_dir" ] && branch=$(git -C "$cur_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)

reset=$'\033[0m'
dim=$'\033[38;2;153;153;153m'
green=$'\033[38;2;55;166;96m'
yellow=$'\033[33m'
orange=$'\033[38;5;208m'
red=$'\033[38;2;187;106;122m'

sep="${dim}|${reset}"
dot="${dim}·${reset}"

# Color for a "remaining %" value (more left = greener)
color_left() {
  if [ "$1" -gt 50 ]; then printf '%s' "$green"
  elif [ "$1" -gt 25 ]; then printf '%s' "$yellow"
  elif [ "$1" -gt 10 ]; then printf '%s' "$orange"
  else printf '%s' "$red"; fi
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

# Render one rate-limit window: "<label> <pct>% (<reset>)", colored by remaining; empty if no pct
win_seg() {
  [ -n "$2" ] || return
  printf '%s%s%s %s%s%%%s' "$dim" "$1" "$reset" "$(color_left "$2")" "$2" "$reset"
  [ -n "$3" ] && printf ' %s(%s)%s' "$dim" "$3" "$reset"
}

now=$(date +%s)
five_in=$(reset_in "$five_reset")
seven_in=$(reset_in "$seven_reset")

# Segment 1 — location: project[:branch]
loc=""
[ -n "$project" ] && loc="${dim}${project}${branch:+:$branch}${reset}"

# Segment 2 — model (size, effort) ctx%; context grouped with the model, color ramps up toward the ~78% auto-compact trigger
paren="$size"
[ -n "$effort" ] && paren="${paren:+$paren, }$effort"
modelseg="${reset}${model}${reset}"
[ -n "$paren" ] && modelseg="${modelseg} ${dim}(${paren})${reset}"
if [ -n "$used_pct" ]; then
  pct=$(printf "%.0f" "$used_pct")
  if [ "$pct" -lt 50 ]; then ctx_color="$green"
  elif [ "$pct" -lt 65 ]; then ctx_color="$yellow"
  elif [ "$pct" -lt 75 ]; then ctx_color="$orange"
  else ctx_color="$red"; fi
  modelseg="${modelseg} ${ctx_color}${pct}%${reset}"
fi

# Segment 3 — rate-limit usage remaining: 5h · 7d (dot only between two present windows)
usage=""
for w in "$(win_seg 5h "$five_left" "$five_in")" "$(win_seg 7d "$seven_left" "$seven_in")"; do
  [ -n "$w" ] || continue
  if [ -n "$usage" ]; then usage="${usage} ${dot} ${w}"; else usage="$w"; fi
done

# Join non-empty segments with the divider
out=""
for seg in "$loc" "$modelseg" "$usage"; do
  [ -n "$seg" ] || continue
  if [ -n "$out" ]; then out="${out} ${sep} ${seg}"; else out="${seg}"; fi
done

printf "%s\n" "$out"
```
