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
