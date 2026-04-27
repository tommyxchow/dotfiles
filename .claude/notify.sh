#!/usr/bin/env bash
# Windows notification for Claude Code hooks (uses PowerShell BalloonTip).
# Usage: notify.sh <subtitle> <message> [unused] [win_icon]
SUBTITLE="${1}" MESSAGE="${2}" ICON="${4:-Information}"

powershell.exe -NoProfile -Command "[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); \$n=New-Object System.Windows.Forms.NotifyIcon; \$n.Icon=[System.Drawing.SystemIcons]::${ICON}; \$n.BalloonTipTitle='Claude Code - ${SUBTITLE}'; \$n.BalloonTipText='${MESSAGE}'; \$n.Visible=\$true; \$n.ShowBalloonTip(3000); \$n.Dispose()"
