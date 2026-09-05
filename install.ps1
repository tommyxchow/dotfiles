# Dotfiles installer - creates symlinks from this repo to config locations.
# Requires Developer Mode (Settings > System > For developers) for symlinks.
# Usage: pwsh -File install.ps1

$ErrorActionPreference = "Stop"
$dotfiles = $PSScriptRoot
$legacyOpenCodeSkills = "$HOME/.config/opencode/skills"
$legacyOpenCodeSkillsSource = Join-Path $dotfiles "plugins/tc/skills"
$legacyOpenCodeSkillsItem = Get-Item -LiteralPath $legacyOpenCodeSkills -Force -ErrorAction SilentlyContinue

# Migration from the pre-OpenCode compatibility setup, which linked every tc skill.
if ($legacyOpenCodeSkillsItem -and $legacyOpenCodeSkillsItem.LinkType -eq "SymbolicLink" -and $legacyOpenCodeSkillsItem.Target -eq (Resolve-Path $legacyOpenCodeSkillsSource -ErrorAction SilentlyContinue).Path) {
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
Prune-Stale "$HOME/.claude/skills/grilling"
Prune-Stale "$HOME/.agents/skills/grilling"
Prune-Stale "$HOME/.config/opencode/skills/grilling"
Prune-Stale "$HOME/.codex/AGENTS.md"

$links = @(
    @{ Source = "git/.gitconfig";           Target = "$HOME/.gitconfig" }
    @{ Source = "vscode/settings.json";     Target = "$env:APPDATA/Code/User/settings.json" }
    @{ Source = "vscode/keybindings.json";  Target = "$env:APPDATA/Code/User/keybindings.json" }
    @{ Source = "vscode/settings.json";     Target = "$env:APPDATA/Cursor/User/settings.json" }
    @{ Source = "vscode/keybindings.json";  Target = "$env:APPDATA/Cursor/User/keybindings.json" }
    @{ Source = ".claude/settings.json";    Target = "$HOME/.claude/settings.json" }
    @{ Source = ".claude/CLAUDE.md";        Target = "$HOME/.claude/CLAUDE.md" }
)

Get-ChildItem (Join-Path $dotfiles "plugins/tc/skills") -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.Name
    Prune-Stale "$HOME/.agents/skills/$name"
    Prune-Stale "$HOME/.config/opencode/skills/$name"
    $links += @{ Source = "plugins/tc/skills/$name"; Target = "$HOME/.claude/skills/$name" }
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
        # WriteAllText writes BOM-less UTF-8 on both PS 5.1 and 7; Set-Content's
        # utf8NoBOM encoding name only exists in PowerShell 7.
        [System.IO.File]::WriteAllText($manifest, $desiredManifest + [Environment]::NewLine)
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
        [System.IO.File]::WriteAllText($rule, $desired)
        Write-Host "  WRITE $rule" -ForegroundColor Cyan
    }
}
else {
    Write-Host "  SKIP  .claude/CLAUDE.md (not in repo)" -ForegroundColor DarkGray
}

# Grok Build reads ~/.grok/config.toml and writes runtime state back into it
# (marketplace bookkeeping, pinned sessions), so it is never symlinked. Seed a
# missing config from grok/config.toml; otherwise patch only our non-default
# keys in place, leaving everything Grok wrote untouched.
function Set-TomlKey([string]$text, [string]$section, [string]$key, [string]$value) {
    $lines = [System.Collections.Generic.List[string]]($text -split "`r?`n")
    $secRe = "^\[" + [regex]::Escape($section) + "\]\s*$"
    $secIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $secRe) { $secIdx = $i; break }
    }
    if ($secIdx -eq -1) {
        if ($lines.Count -gt 0 -and $lines[$lines.Count - 1].Trim() -ne "") { $lines.Add("") }
        $lines.Add("[$section]")
        $lines.Add("$key = $value")
        return @{ Text = ($lines -join "`n"); Changed = $true }
    }
    $keyRe = "^\s*" + [regex]::Escape($key) + "\s*=\s*(.*)$"
    for ($j = $secIdx + 1; $j -lt $lines.Count -and $lines[$j] -notmatch "^\s*\["; $j++) {
        if ($lines[$j] -match $keyRe) {
            if ($Matches[1].Trim() -eq $value) { return @{ Text = $text; Changed = $false } }
            $lines[$j] = "$key = $value"
            return @{ Text = ($lines -join "`n"); Changed = $true }
        }
    }
    $lines.Insert($secIdx + 1, "$key = $value")
    return @{ Text = ($lines -join "`n"); Changed = $true }
}

$grokSeed = Join-Path $dotfiles "grok/config.toml"
$grokConfig = Join-Path $HOME ".grok/config.toml"
if (-not (Test-Path $grokSeed)) {
    Write-Host "  SKIP  grok/config.toml (not in repo)" -ForegroundColor DarkGray
}
elseif (-not (Test-Path "$HOME/.grok")) {
    Write-Host "  SKIP  $grokConfig (no ~/.grok)" -ForegroundColor DarkGray
}
elseif (-not (Test-Path $grokConfig)) {
    Copy-Item $grokSeed $grokConfig
    Write-Host "  SEED  $grokConfig" -ForegroundColor Cyan
}
else {
    $text = Get-Content -Raw $grokConfig
    $changed = $false
    foreach ($k in @(
        @{ Section = "memory";   Key = "enabled";              Value = "true" }
        @{ Section = "features"; Key = "lsp_tools";            Value = "true" }
        @{ Section = "features"; Key = "two_pass_compaction";  Value = "true" }
        @{ Section = "ui";       Key = "theme";                Value = '"auto"' }
        @{ Section = "ui";       Key = "auto_dark_theme";      Value = '"oscura-midnight"' }
    )) {
        $r = Set-TomlKey $text $k.Section $k.Key $k.Value
        $text = $r.Text
        if ($r.Changed) { $changed = $true }
    }
    if ($changed) {
        [System.IO.File]::WriteAllText($grokConfig, $text)
        Write-Host "  PATCH $grokConfig" -ForegroundColor Cyan
    }
    else {
        Write-Host "  OK    $grokConfig" -ForegroundColor Green
    }
}

# Seed user-scoped LSP definitions. The repo file names the bare binary
# (macOS/Linux); Windows npm-style installs expose a .cmd shim, so rewrite
# that one field on seed. Existing files are left alone.
$grokLspSeed = Join-Path $dotfiles "grok/lsp.json"
$grokLsp = Join-Path $HOME ".grok/lsp.json"
if (-not (Test-Path $grokLspSeed)) {
    Write-Host "  SKIP  grok/lsp.json (not in repo)" -ForegroundColor DarkGray
}
elseif (-not (Test-Path "$HOME/.grok")) {
    Write-Host "  SKIP  $grokLsp (no ~/.grok)" -ForegroundColor DarkGray
}
elseif (-not (Test-Path $grokLsp)) {
    $lspText = Get-Content -Raw $grokLspSeed
    $lspText = $lspText.Replace('"typescript-language-server"', '"typescript-language-server.cmd"')
    [System.IO.File]::WriteAllText($grokLsp, $lspText)
    Write-Host "  SEED  $grokLsp" -ForegroundColor Cyan
}
else {
    Write-Host "  OK    $grokLsp" -ForegroundColor Green
}
if (Test-Path "$HOME/.grok") {
    if (Get-Command typescript-language-server -ErrorAction SilentlyContinue) {
        Write-Host "  OK    typescript-language-server on PATH" -ForegroundColor Green
    }
    else {
        Write-Host "  WARN  typescript-language-server not on PATH - pnpm add -g typescript-language-server typescript" -ForegroundColor Yellow
    }
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

# The Agent Skills spec caps description at 1024 characters and Claude Code
# allows more, so an over-cap description passes here and only misbehaves in
# the other harnesses reading the same files.
$skillsRoot = Join-Path $dotfiles "plugins/tc/skills"
if (Test-Path $skillsRoot) {
    $over = $false
    foreach ($skillDir in Get-ChildItem -Path $skillsRoot -Directory) {
        $skillFile = Join-Path $skillDir.FullName "SKILL.md"
        if (-not (Test-Path $skillFile)) { continue }
        $line = Get-Content $skillFile | Where-Object { $_ -match '^description:' } | Select-Object -First 1
        if (-not $line) { continue }
        $desc = $line -replace '^description:\s*', ''
        # A folded or literal block would measure as its marker, so the cap would
        # never fire. Say so instead of reporting a passing two-byte description.
        if ($desc -eq '' -or $desc.StartsWith('>') -or $desc.StartsWith('|')) {
            Write-Host "  WARN  $($skillDir.Name) description is empty or a YAML block; this check reads one line only" -ForegroundColor Yellow
            $over = $true
            continue
        }
        # Bytes, to match install.sh. Bytes are never fewer than characters, so
        # this warns slightly early and never too late.
        $len = [System.Text.Encoding]::UTF8.GetByteCount($desc)
        if ($len -gt 1024) {
            Write-Host "  WARN  $($skillDir.Name) description is $len bytes, over the 1024 spec cap" -ForegroundColor Yellow
            $over = $true
        }
    }
    if (-not $over) {
        Write-Host "  OK    skill descriptions within the 1024-char spec cap" -ForegroundColor Green
    }
}

# grok.com's Customize Grok box holds 4000 characters and truncates silently
# past that. Nothing loads this file, so an over-length paste is only found by
# pasting it.
$webMd = Join-Path $dotfiles ".claude/CLAUDE.web.md"
if (Test-Path $webMd) {
    $webLen = [System.Text.Encoding]::UTF8.GetByteCount((Get-Content -Raw $webMd))
    if ($webLen -gt 4000) {
        Write-Host "  WARN  CLAUDE.web.md is $webLen chars, over grok.com's 4000 limit" -ForegroundColor Yellow
    }
    else {
        Write-Host "  OK    CLAUDE.web.md fits grok.com's 4000-char limit ($webLen)" -ForegroundColor Green
    }
}

Write-Host "`nDone." -ForegroundColor Green
