# Dotfiles installer — creates symlinks from this repo to config locations.
# Requires Developer Mode (Settings > System > For developers) for symlinks.
# Usage: pwsh -File install.ps1

$ErrorActionPreference = "Stop"
$dotfiles = $PSScriptRoot
$legacyOpenCodeSkills = "$HOME/.config/opencode/skills"
$legacyOpenCodeSkillsSource = Join-Path $dotfiles "plugins/tc/skills"
$legacyOpenCodeSkillsItem = Get-Item -LiteralPath $legacyOpenCodeSkills -Force -ErrorAction SilentlyContinue

# Migration from the pre-OpenCode compatibility setup, which linked every tc skill.
if ($legacyOpenCodeSkillsItem -and $legacyOpenCodeSkillsItem.LinkType -eq "SymbolicLink" -and $legacyOpenCodeSkillsItem.Target -eq (Resolve-Path $legacyOpenCodeSkillsSource).Path) {
    Remove-Item -LiteralPath $legacyOpenCodeSkills -Force
}

function Clean-Bak([string]$sourcePath, [string]$target) {
    $backup = "$target.bak"
    if (-not (Test-Path $backup)) { return }
    $bakItem = Get-Item $backup
    $identical = $false
    if ($bakItem.PSIsContainer -and (Test-Path $sourcePath -PathType Container)) {
        $identical = -not (Compare-Object `
            (Get-ChildItem -Recurse -File $sourcePath | ForEach-Object { [PSCustomObject]@{ rel = $_.FullName.Substring($sourcePath.Length); hash = (Get-FileHash $_.FullName).Hash } }) `
            (Get-ChildItem -Recurse -File $backup     | ForEach-Object { [PSCustomObject]@{ rel = $_.FullName.Substring($backup.Length);     hash = (Get-FileHash $_.FullName).Hash } }) `
            -Property rel, hash)
    }
    elseif (-not $bakItem.PSIsContainer -and (Test-Path $sourcePath -PathType Leaf)) {
        $identical = (Get-FileHash $backup).Hash -eq (Get-FileHash $sourcePath).Hash
    }
    if ($identical) {
        Remove-Item -Recurse -Force $backup
        Write-Host "  CLEAN $backup (identical)" -ForegroundColor DarkGray
    }
}

function Prune-Stale([string]$path) {
    $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if (-not $item -or $item.LinkType -ne "SymbolicLink") { return }
    $target = [string]$item.Target
    $dangling = -not (Test-Path $path)
    $fromRepo = $target.StartsWith($dotfiles)
    if ($dangling -or $fromRepo) {
        Remove-Item -LiteralPath $path -Force
        Write-Host "  PRUNE $path" -ForegroundColor DarkGray
    }
}

Prune-Stale "$HOME/.claude/notify.sh"
Prune-Stale "$HOME/.claude/skills/understand"
Prune-Stale "$HOME/.agents/skills/understand"
Prune-Stale "$HOME/.claude/skills/resync"
Prune-Stale "$HOME/.agents/skills/resync"
Prune-Stale "$HOME/.config/opencode/skills/resync"
Prune-Stale "$HOME/.config/opencode/commands/resync.md"

$links = @(
    @{ Source = "git/.gitconfig";           Target = "$HOME/.gitconfig" }
    @{ Source = "vscode/settings.json";     Target = "$env:APPDATA/Code/User/settings.json" }
    @{ Source = "vscode/keybindings.json";  Target = "$env:APPDATA/Code/User/keybindings.json" }
    @{ Source = "vscode/settings.json";     Target = "$env:APPDATA/Cursor/User/settings.json" }
    @{ Source = "vscode/keybindings.json";  Target = "$env:APPDATA/Cursor/User/keybindings.json" }
    @{ Source = ".claude/settings.json";    Target = "$HOME/.claude/settings.json" }
    @{ Source = ".claude/CLAUDE.md";        Target = "$HOME/.claude/CLAUDE.md" }
    @{ Source = ".claude/CLAUDE.md";        Target = "$HOME/.codex/AGENTS.md" }
)

Get-ChildItem (Join-Path $dotfiles "plugins/tc/skills") -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.Name
    Prune-Stale "$HOME/.agents/skills/$name"
    $links += @{ Source = "plugins/tc/skills/$name"; Target = "$HOME/.claude/skills/$name" }
    if ($name -ne "statusline-install") {
        $links += @{ Source = "plugins/tc/skills/$name"; Target = "$HOME/.config/opencode/skills/$name" }
    }
}
Get-ChildItem (Join-Path $dotfiles "opencode/commands") -Filter "*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
    $links += @{ Source = "opencode/commands/$($_.Name)"; Target = "$HOME/.config/opencode/commands/$($_.Name)" }
}
foreach ($emptyDir in @("$HOME/.agents/skills", "$HOME/.agents")) {
    if ((Test-Path $emptyDir) -and -not (Get-ChildItem $emptyDir -Force -ErrorAction SilentlyContinue)) {
        Remove-Item $emptyDir -Force
    }
}

foreach ($link in $links) {
    $source = Join-Path $dotfiles $link.Source
    $target = $link.Target

    if (-not (Test-Path $source)) {
        Write-Host "  SKIP  $($link.Source) (not in repo)" -ForegroundColor DarkGray
        continue
    }

    $sourcePath = (Resolve-Path $source).Path
    $backup = "$target.bak"
    $targetDir = Split-Path $target -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $existing = Get-Item $target -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType -eq "SymbolicLink") {
        if ($existing.Target -eq $sourcePath) {
            Write-Host "  OK    $target" -ForegroundColor Green
            Clean-Bak $sourcePath $target
            continue
        }
        Remove-Item $target -Force
    }
    elseif ($existing) {
        Move-Item $target $backup -Force
        Write-Host "  BAK   $target -> $backup" -ForegroundColor Yellow
    }

    New-Item -ItemType SymbolicLink -Path $target -Value $sourcePath | Out-Null
    Write-Host "  LINK  $target -> $($link.Source)" -ForegroundColor Cyan
    Clean-Bak $sourcePath $target
}

# Cursor rejects a plugin folder that symlinks to this repo. Write a real
# directory under ~/.cursor/plugins/local and copy CLAUDE.md into an
# alwaysApply rule. Re-run the installer after editing CLAUDE.md, then
# Developer: Reload Window. Do not put a description on the rule; Cursor has
# mapped alwaysApply + description to agent-requestable.
$claudeMd = Join-Path $dotfiles ".claude/CLAUDE.md"
if (Test-Path $claudeMd) {
    $pluginDir = Join-Path $HOME ".cursor/plugins/local/tc"
    $manifest = Join-Path $pluginDir ".cursor-plugin/plugin.json"
    $rule = Join-Path $pluginDir "rules/global.mdc"
    New-Item -ItemType Directory -Path (Split-Path $manifest -Parent) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path $rule -Parent) -Force | Out-Null
    $desiredManifest = '{"name":"tc","description":"Personal global instructions from dotfiles"}'
    $currentManifest = if (Test-Path $manifest) { (Get-Content -Raw $manifest).Trim() } else { "" }
    if ($currentManifest -ne $desiredManifest) {
        Set-Content -Path $manifest -Value $desiredManifest -Encoding utf8NoBOM
    }
    $desired = @"
---
alwaysApply: true
---

$((Get-Content -Raw $claudeMd).TrimEnd())

"@
    $current = if (Test-Path $rule) { Get-Content -Raw $rule } else { "" }
    if ($current -eq $desired) {
        Write-Host "  OK    $rule" -ForegroundColor Green
    }
    else {
        Set-Content -Path $rule -Value $desired -Encoding utf8NoBOM -NoNewline
        Write-Host "  WRITE $rule" -ForegroundColor Cyan
    }
}
else {
    Write-Host "  SKIP  .claude/CLAUDE.md (not in repo)" -ForegroundColor DarkGray
}

$skillMd = Join-Path $dotfiles "plugins/tc/skills/statusline-install/SKILL.md"
$statusline = Join-Path $HOME ".claude/statusline-command.sh"
if (Test-Path $skillMd) {
    $lines = Get-Content $skillMd
    $code = New-Object System.Collections.Generic.List[string]
    $want = $false
    $inCode = $false
    $fence = '```'
    foreach ($line in $lines) {
        if (-not $want -and $line -eq "## Script") { $want = $true; continue }
        if ($want -and -not $inCode -and $line -eq ($fence + "bash")) { $inCode = $true; continue }
        if ($inCode -and $line -eq $fence) { break }
        if ($inCode) { [void]$code.Add($line) }
    }
    if ($code.Count -eq 0) {
        Write-Host "  SKIP  statusline script missing from skill" -ForegroundColor DarkGray
    }
    else {
        $desired = ($code -join "`n") + "`n"
        $current = if (Test-Path $statusline) { Get-Content -Raw $statusline } else { "" }
        if ($current -eq $desired) {
            Write-Host "  OK    $statusline" -ForegroundColor Green
        }
        else {
            New-Item -ItemType Directory -Path (Split-Path $statusline -Parent) -Force | Out-Null
            Set-Content -Path $statusline -Value $desired -Encoding utf8NoBOM -NoNewline
            Write-Host "  WRITE $statusline" -ForegroundColor Cyan
        }
    }
}
else {
    Write-Host "  SKIP  statusline-install skill (not in repo)" -ForegroundColor DarkGray
}

Write-Host "`nDone." -ForegroundColor Green
