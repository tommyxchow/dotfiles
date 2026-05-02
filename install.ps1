# Dotfiles installer — creates symlinks from this repo to config locations.
# Requires Developer Mode (Settings > System > For developers) for symlinks.
# Usage: pwsh -File install.ps1

$ErrorActionPreference = "Stop"
$dotfiles = $PSScriptRoot

$links = @(
    @{ Source = "git/.gitconfig";                              Target = "$HOME/.gitconfig" }
    @{ Source = "vscode/settings.json";                        Target = "$env:APPDATA/Code/User/settings.json" }
    @{ Source = "vscode/keybindings.json";                     Target = "$env:APPDATA/Code/User/keybindings.json" }
    @{ Source = "powershell/Microsoft.PowerShell_profile.ps1"; Target = "$HOME/Documents/PowerShell/Microsoft.PowerShell_profile.ps1" }
    @{ Source = ".claude/settings.json";                       Target = "$HOME/.claude/settings.json" }
    @{ Source = ".claude/CLAUDE.md";                           Target = "$HOME/.claude/CLAUDE.md" }
    @{ Source = ".claude/CLAUDE.md";                           Target = "$HOME/.codex/AGENTS.md" }
    @{ Source = ".claude/notify.sh";                           Target = "$HOME/.claude/notify.sh" }
)

# Skills that depend on Claude Code-specific features (subagents, statusline
# JSON schema, etc.) — linked only to ~/.claude/skills, never the shared
# ~/.agents/skills picked up by codex/opencode.
$claudeOnlySkills = @("statusline-install")

foreach ($skillName in $claudeOnlySkills) {
    $sharedSkillTarget = "$HOME/.agents/skills/$skillName"
    $repoSkillSource = Join-Path $dotfiles ".claude/skills/$skillName"
    $sharedSkillItem = Get-Item $sharedSkillTarget -ErrorAction SilentlyContinue
    if ($sharedSkillItem -and
        $sharedSkillItem.LinkType -eq "SymbolicLink" -and
        (Test-Path $repoSkillSource) -and
        $sharedSkillItem.Target -eq (Resolve-Path $repoSkillSource).Path) {
        Remove-Item $sharedSkillTarget -Force
        Write-Host "  CLEAN $sharedSkillTarget (Claude-only skill)" -ForegroundColor DarkGray
    }
}

# Shared skills: symlink each skill dir individually so future untracked skills
# at ~/.claude/skills/ or ~/.agents/skills/ aren't swept inside the repo.
$skillsDir = Join-Path $dotfiles ".claude/skills"
if (Test-Path $skillsDir) {
    foreach ($skill in Get-ChildItem $skillsDir -Directory) {
        $skillSource = ".claude/skills/$($skill.Name)"
        $links += @{
            Source = $skillSource
            Target = "$HOME/.claude/skills/$($skill.Name)"
        }
        if ($skill.Name -notin $claudeOnlySkills) {
            $links += @{
                Source = $skillSource
                Target = "$HOME/.agents/skills/$($skill.Name)"
            }
        }
    }
}

$codexConfigSource = Join-Path $dotfiles "codex/config.toml"
$codexConfigTarget = "$HOME/.codex/config.toml"
if (Test-Path $codexConfigSource) {
    $targetDir = Split-Path $codexConfigTarget -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $sourceSettings = @()
    foreach ($line in Get-Content $codexConfigSource) {
        if ($line -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.+?)\s*$') {
            $sourceSettings += [PSCustomObject]@{
                Key  = $Matches[1]
                Line = "$($Matches[1]) = $($Matches[2])"
            }
        }
    }

    $targetLines = if (Test-Path $codexConfigTarget) { @(Get-Content -LiteralPath $codexConfigTarget) } else { @() }
    $tableIndex = -1
    for ($i = 0; $i -lt $targetLines.Count; $i++) {
        if ($targetLines[$i] -match '^\s*\[') {
            $tableIndex = $i
            break
        }
    }

    if ($tableIndex -eq 0) {
        $head = @()
        $tail = @($targetLines)
    }
    elseif ($tableIndex -gt 0) {
        $head = @($targetLines[0..($tableIndex - 1)])
        $tail = @($targetLines[$tableIndex..($targetLines.Count - 1)])
    }
    else {
        $head = @($targetLines)
        $tail = @()
    }

    foreach ($setting in $sourceSettings) {
        $updated = $false
        for ($i = 0; $i -lt $head.Count; $i++) {
            if ($head[$i] -match "^\s*$([regex]::Escape($setting.Key))\s*=") {
                $head[$i] = $setting.Line
                $updated = $true
                break
            }
        }
        if (-not $updated) {
            $head += $setting.Line
        }
    }

    if ($head.Count -gt 0) {
        $lastNonBlank = $head.Count - 1
        while ($lastNonBlank -ge 0 -and $head[$lastNonBlank] -match '^\s*$') {
            $lastNonBlank--
        }
        $head = if ($lastNonBlank -ge 0) { @($head[0..$lastNonBlank]) } else { @() }
    }

    $outputLines = @($head)
    if ($tail.Count -gt 0) {
        if ($outputLines.Count -gt 0) {
            $outputLines += ""
        }
        $outputLines += $tail
    }
    $output = [string]::Join("`r`n", $outputLines)
    if ($output.Length -gt 0) {
        $output += "`r`n"
    }
    Set-Content -LiteralPath $codexConfigTarget -Value $output -NoNewline
    Write-Host "  MERGE $codexConfigTarget <- codex/config.toml" -ForegroundColor Cyan
}

$staleOpenCodeAgents = "$HOME/.config/opencode/AGENTS.md"
$sharedInstructionsSource = Join-Path $dotfiles ".claude/CLAUDE.md"
if (Test-Path $sharedInstructionsSource) {
    $sharedInstructions = (Resolve-Path $sharedInstructionsSource).Path
    $staleOpenCodeItem = Get-Item $staleOpenCodeAgents -ErrorAction SilentlyContinue
    if ($staleOpenCodeItem -and
        $staleOpenCodeItem.LinkType -eq "SymbolicLink" -and
        $staleOpenCodeItem.Target -eq $sharedInstructions) {
        Remove-Item $staleOpenCodeAgents -Force
        Write-Host "  CLEAN $staleOpenCodeAgents (opencode uses ~/.claude fallback)" -ForegroundColor DarkGray
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

    # Cleanup: drop .bak if it's byte-identical to the new symlink target.
    # Keeps .bak only when it actually preserves unique content.
    if (Test-Path $backup) {
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
}

Write-Host "`nDone." -ForegroundColor Green
