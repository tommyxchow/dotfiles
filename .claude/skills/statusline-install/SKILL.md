---
name: statusline-install
description: Install/restore my personal Claude Code statusline — model name, context-window %, and 5h/7d usage remaining — to ~/.claude/statusline-command.sh and wire it into settings.json. Canonical cross-platform bash (macOS/Linux native, Windows via Git Bash). Use to set up my statusline on a new machine or after a reset.
argument-hint: 'Opus 4.8 23% | 5h 76% · 7d 58%'
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
Opus 4.8 23% | 5h 76% · 7d 58%
```

- **`Opus 4.8 23%`** — model name + context-window % used, grouped together (no
  divider, since they're related). Color ramps green → yellow → orange → red as
  context fills toward the ~78% auto-compact trigger.
- **`5h 76% · 7d 58%`** — percentage of the 5-hour and 7-day rate-limit windows
  **remaining** (100 − used). Color ramps the opposite way: green when plenty is
  left, red when nearly out. These appear only on Pro/Max accounts and only after
  the first API response of a session — before that, just `Model ctx%` shows. If
  only one window is present it renders alone with no stray separator.

## Requirements (cross-platform)

Needs `bash` and `jq`:

- **macOS/Linux**: native bash (works on stock bash 3.2) + `brew install jq` /
  `apt install jq`.
- **Windows**: runs under **Git Bash**, which ships both — no PowerShell version
  is maintained, and `settings.json` invokes the script with `bash` on every
  platform.

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
# Format: Model <ctx%> | 5h <left%> · 7d <left%>

input=$(cat)
if [ -z "$(echo "$input" | tr -d '[:space:]')" ]; then
  echo "--"
  exit 0
fi

model=$(echo "$input" | jq -r '.model.display_name // "--"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // ""')
five_left=$(echo "$input" | jq -r 'if (.rate_limits.five_hour.used_percentage // null) != null then (100 - .rate_limits.five_hour.used_percentage | floor | tostring) else "" end')
seven_left=$(echo "$input" | jq -r 'if (.rate_limits.seven_day.used_percentage // null) != null then (100 - .rate_limits.seven_day.used_percentage | floor | tostring) else "" end')

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

out="${reset}${model}${reset}"

# Context % used — grouped with the model (no divider); color ramps up toward the ~78% auto-compact trigger
if [ -n "$used_pct" ]; then
  pct=$(printf "%.0f" "$used_pct")
  if [ "$pct" -lt 50 ]; then ctx_color="$green"
  elif [ "$pct" -lt 65 ]; then ctx_color="$yellow"
  elif [ "$pct" -lt 75 ]; then ctx_color="$orange"
  else ctx_color="$red"; fi
  out="${out} ${ctx_color}${pct}%${reset}"
fi

# Rate-limit usage remaining: 5h and 7d (present only for Pro/Max, after the first API response)
usage=""
if [ -n "$five_left" ]; then
  usage="${dim}5h${reset} $(color_left "$five_left")${five_left}%${reset}"
fi
if [ -n "$seven_left" ]; then
  if [ -n "$usage" ]; then usage="${usage} ${dot} "; fi
  usage="${usage}${dim}7d${reset} $(color_left "$seven_left")${seven_left}%${reset}"
fi
if [ -n "$usage" ]; then
  out="${out} ${sep} ${usage}"
fi

printf "%s\n" "$out"
```
