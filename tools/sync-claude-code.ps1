﻿#Requires -Version 5.1
<#
.SYNOPSIS
    Assembles CLAUDE.md, web-ai-doc.md, and syncs Claude Code skills from claude-code-sync.yaml.

.DESCRIPTION
    Reads claude-code-sync.yaml (alongside this script), fetches remote docs via HTTP,
    reads local docs from ai-docs/, assembles output files, syncs skill files to
    .claude/commands/, and optionally generates a Windows Terminal launcher script
    (open-claude.ps1) from the launcher section of the config.
    Run from the project root or from the tools/ folder.

.PARAMETER Config
    Name of the config file to use (must be in the same directory as this script).
    Defaults to claude-code-sync.yaml.
#>
param(
    [string]$Config = 'claude-code-sync.yaml'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
$ScriptVersion = '0.1.3'

# ---------------------------------------------------------------------------
# Path setup — script lives in tools/, project root is one level up
# ---------------------------------------------------------------------------
$ScriptDirectory      = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot          = Split-Path -Parent $ScriptDirectory
$ConfigFilePath       = Join-Path $ScriptDirectory $Config
$ClaudeMdOutputPath   = Join-Path $ProjectRoot 'CLAUDE.md'
$WebAiDocOutputPath   = $null  # resolved after config is loaded
$SkillsOutputDir      = Join-Path $ProjectRoot '.claude\commands'
$DefaultLocalDocsDir  = Join-Path $ProjectRoot 'ai-docs'

# ---------------------------------------------------------------------------
# Console output helpers
# ---------------------------------------------------------------------------
function Write-SectionHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

function Write-StepInfo {
    param([string]$Message)
    Write-Host "  -> $Message" -ForegroundColor White
}

function Write-StepSuccess {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-StepSkipped {
    param([string]$Message)
    Write-Host "  [--] $Message" -ForegroundColor DarkGray
}

function Write-StepWarning {
    param([string]$Message)
    Write-Host "  [!!] $Message" -ForegroundColor Yellow
}

function Write-StepError {
    param([string]$Message)
    Write-Host "  [XX] $Message" -ForegroundColor Red
}

# ---------------------------------------------------------------------------
# YAML parsing — no external dependencies, handles our simple flat structure
# ---------------------------------------------------------------------------
function Get-YamlListSection {
    param(
        [string[]]$Lines,
        [string]$SectionName
    )

    $Items = [System.Collections.Generic.List[string]]::new()
    $InsideSection = $false

    foreach ($Line in $Lines) {
        # key: []  — explicitly empty list
        if ($Line -match "^${SectionName}:\s*\[\]") {
            return @()
        }
        # Section header line
        if ($Line -match "^${SectionName}:") {
            $InsideSection = $true
            continue
        }
        if ($InsideSection) {
            # Any new top-level key ends this section
            if ($Line -match '^[a-zA-Z_]') { break }
            # List item — strip inline comments and trailing whitespace
            if ($Line -match '^\s+-\s+(.+)') {
                $Value = $Matches[1] -replace '\s*#.*$', '' -replace '\s+$', ''
                if ($Value) { $Items.Add($Value) }
            }
        }
    }

    return , $Items.ToArray()
}

function Get-YamlScalarValue {
    param(
        [string[]]$Lines,
        [string]$Key
    )

    foreach ($Line in $Lines) {
        if ($Line -match "^${Key}:\s*(.+)") {
            return $Matches[1].Trim()
        }
    }
    return $null
}

# Reads a scalar value from within a named section, e.g. 'wsl_distro' inside 'launcher:'
function Get-YamlNestedScalarValue {
    param(
        [string[]]$Lines,
        [string]  $SectionName,
        [string]  $Key
    )

    $InsideSection = $false

    foreach ($Line in $Lines) {
        if ($Line -match "^${SectionName}:") {
            $InsideSection = $true
            continue
        }
        if ($InsideSection) {
            # Any new top-level key ends this section
            if ($Line -match '^[a-zA-Z_]') { break }
            # Match indented key: value — strip comments, whitespace, and surrounding quotes
            if ($Line -match "^\s+${Key}:\s*(.+)") {
                $Value = $Matches[1] -replace '\s*#.*$', '' -replace '\s+$', ''
                $Value = $Value     -replace '^"(.*)"$', '$1' -replace "^'(.*)'$", '$1'
                return $Value
            }
        }
    }
    return $null
}

# Reads a list sub-section from within a named section, e.g. 'extra_dirs' inside 'launcher:'
function Get-YamlNestedListSection {
    param(
        [string[]]$Lines,
        [string]  $SectionName,
        [string]  $SubSectionName
    )

    $Items            = [System.Collections.Generic.List[string]]::new()
    $InsideSection    = $false
    $InsideSubSection = $false

    foreach ($Line in $Lines) {
        if ($Line -match "^${SectionName}:") {
            $InsideSection = $true
            continue
        }
        if ($InsideSection) {
            # Any new top-level key ends the whole section
            if ($Line -match '^[a-zA-Z_]') { break }

            if ($InsideSubSection) {
                # List items are indented deeper than the sub-section header (4+ spaces)
                if ($Line -match '^\s{4,}-\s+(.+)') {
                    $Value = $Matches[1] -replace '\s*#.*$', '' -replace '\s+$', ''
                    if ($Value) { $Items.Add($Value) }
                }
                # Any other non-blank indented line is a sibling key — end sub-section
                elseif ($Line -notmatch '^\s*$') {
                    $InsideSubSection = $false
                }
            }
            else {
                # Look for the sub-section header (indented key at 2-space level)
                if ($Line -match "^\s+${SubSectionName}:") {
                    $InsideSubSection = $true
                }
            }
        }
    }

    return , $Items.ToArray()
}

# ---------------------------------------------------------------------------
# Fetch a remote URL — fails loudly on any non-200 or network error
# ---------------------------------------------------------------------------
function Invoke-RemoteFetch {
    param([string]$Url)

    Write-StepInfo "Fetching: $Url"
    try {
        $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -ErrorAction Stop
    }
    catch {
        Write-StepError "Network error fetching: $Url"
        Write-StepError "$_"
        exit 1
    }

    if ($Response.StatusCode -ne 200) {
        Write-StepError "HTTP $($Response.StatusCode) — $Url"
        exit 1
    }

    return $Response.Content
}

# ---------------------------------------------------------------------------
# Read a single doc entry — remote URL, relative path, or ai-docs/ filename
# ---------------------------------------------------------------------------
function Read-DocEntry {
    param(
        [string]$Entry,
        [string]$LocalDocsDir
    )

    if ($Entry -match '^https?://') {
        # Remote — fetch via HTTP
        return Invoke-RemoteFetch -Url $Entry
    }
    elseif ($Entry -match '[/\\]') {
        # Contains path separator — resolve relative to project root
        $FullPath = Join-Path $ProjectRoot $Entry
        if (-not (Test-Path $FullPath)) {
            Write-StepError "Local file not found: $FullPath"
            exit 1
        }
        Write-StepInfo "Reading: $Entry"
        return Get-Content -Path $FullPath -Raw -Encoding UTF8
    }
    else {
        # Plain filename — look up in local docs directory
        $FullPath = Join-Path $LocalDocsDir $Entry
        if (-not (Test-Path $FullPath)) {
            Write-StepError "Local file not found: $FullPath"
            Write-StepError "Expected in: $LocalDocsDir"
            exit 1
        }
        Write-StepInfo "Reading: $Entry"
        return Get-Content -Path $FullPath -Raw -Encoding UTF8
    }
}

# ---------------------------------------------------------------------------
# Assemble a list of doc entries into a single output file
# Returns the list of entries that were included
# ---------------------------------------------------------------------------
function Invoke-DocAssembly {
    param(
        [string[]]$Entries,
        [string]$OutputPath,
        [string]$LocalDocsDir,
        [string]$OutputLabel
    )

    $IncludedEntries = [System.Collections.Generic.List[string]]::new()
    $ContentParts    = [System.Collections.Generic.List[string]]::new()

    foreach ($Entry in $Entries) {
        $Content = Read-DocEntry -Entry $Entry -LocalDocsDir $LocalDocsDir
        $ContentParts.Add($Content.TrimEnd())
        $IncludedEntries.Add($Entry)
        Write-StepSuccess "Included: $Entry"
    }

    $GeneratedHeader = "<!-- Auto-generated by sync-claude-code. Do not edit manually. -->"
    $Separator       = "`n`n---`n`n"
    $Body            = $ContentParts -join $Separator
    $FullContent     = $GeneratedHeader + "`n`n" + $Body

    # Append a generation summary at the end of the file
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $Summary = @"


---

## Sync Summary

**Generated:** $Timestamp
**Output:** $OutputPath
**Documents included ($($IncludedEntries.Count)):**
$($IncludedEntries | ForEach-Object { "- $_" } | Out-String)
"@

    [System.IO.File]::WriteAllText($OutputPath, $FullContent + $Summary, [System.Text.Encoding]::UTF8)

    return , $IncludedEntries.ToArray()
}

# ---------------------------------------------------------------------------
# Sync skills to .claude/commands/
# ---------------------------------------------------------------------------
function Invoke-SkillsSync {
    param(
        [string[]]$Entries,
        [string]$LocalDocsDir
    )

    if (-not (Test-Path $SkillsOutputDir)) {
        New-Item -ItemType Directory -Path $SkillsOutputDir -Force | Out-Null
        Write-StepInfo "Created: $SkillsOutputDir"
    }

    $SyncedSkills = [System.Collections.Generic.List[string]]::new()

    foreach ($Entry in $Entries) {
        $Content   = Read-DocEntry -Entry $Entry -LocalDocsDir $LocalDocsDir
        $FileName  = Split-Path -Leaf $Entry
        $DestPath  = Join-Path $SkillsOutputDir $FileName
        [System.IO.File]::WriteAllText($DestPath, $Content, [System.Text.Encoding]::UTF8)
        Write-StepSuccess "Synced skill: $FileName -> $DestPath"
        $SyncedSkills.Add($FileName)
    }

    return , $SyncedSkills.ToArray()
}

# ---------------------------------------------------------------------------
# Generate the Claude Code launcher script (open-claude.ps1)
# Writes to the same directory as the sync script (tools/)
# ---------------------------------------------------------------------------
function Invoke-LauncherGeneration {
    param(
        [string]   $WslDistro,
        [string]   $ProjectPath,
        [string]   $ClaudePath,
        [string]   $TabTitle,
        [string]   $TabColor,
        [string[]] $ExtraDirs
    )

    $LauncherOutputPath = Join-Path $ScriptDirectory 'open-claude.ps1'

    # Build the --add-dir argument string from the extra_dirs list
    $ExtraDirArgs = ''
    foreach ($Dir in $ExtraDirs) {
        $ExtraDirArgs += " --add-dir $Dir"
    }

    # Generate the launcher script content.
    # Variables prefixed with a backtick (e.g. `$WslCommand) are passed through
    # as literal variable references into the output file. Un-prefixed variables
    # (e.g. $WslDistro) are substituted with their values from this script.
    $LauncherContent = @"
# open-claude.ps1
# Auto-generated by sync-claude-code.ps1 — do not edit manually.
# To change these values, update the launcher section in claude-code-sync.yaml
# and re-run the sync script.

function Open-ClaudeCode {
    # Claude executable path note:
    # Claude is installed locally (not system-wide) and aliased in ~/.bashrc.
    # Aliases only load in interactive shells — PowerShell WSL commands run
    # non-interactive shells that skip ~/.bashrc. We use the full executable path.
    #
    # To update: open WSL, run: type claude
    # Copy the path and update claude_path in claude-code-sync.yaml, then resync.

    `$WslCommand = "wsl -d $WslDistro -e bash -c 'cd $ProjectPath && $ClaudePath$ExtraDirArgs'"

    `$WindowsTerminalPath = "`$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
    & `$WindowsTerminalPath -w 0 new-tab --title "$TabTitle" --tabColor "$TabColor" pwsh.exe -NoExit -Command `$WslCommand
}

Open-ClaudeCode
"@

    [System.IO.File]::WriteAllText($LauncherOutputPath, $LauncherContent, [System.Text.Encoding]::UTF8)

    return $LauncherOutputPath
}

# ===========================================================================
# MAIN
# ===========================================================================

Write-Host ""
Write-Host "Claude Code Sync  v$ScriptVersion" -ForegroundColor Cyan
Write-Host "Project root: $ProjectRoot" -ForegroundColor DarkGray
Write-Host "Config:       $ConfigFilePath" -ForegroundColor DarkGray

# ---------------------------------------------------------------------------
# Load config
# ---------------------------------------------------------------------------
Write-SectionHeader "Loading Config"

if (-not (Test-Path $ConfigFilePath)) {
    Write-StepError "Config file not found: $ConfigFilePath"
    Write-StepError "Expected claude-code-sync.yaml alongside this script in $ScriptDirectory"
    exit 1
}

$YamlLines = Get-Content -Path $ConfigFilePath -Encoding UTF8
Write-StepSuccess "Config loaded: $ConfigFilePath"

# Resolve GitHub base URL (used for self-update and template bootstrap)
$GitHubBaseUrl     = Get-YamlScalarValue -Lines $YamlLines -Key 'github_base_url'
$ScriptPath        = Get-YamlScalarValue -Lines $YamlLines -Key 'script_path_ps1'
if (-not $ScriptPath) { $ScriptPath = Get-YamlScalarValue -Lines $YamlLines -Key 'script_path' }
$RemoteScriptUrl   = if ($GitHubBaseUrl -and $ScriptPath) { "$GitHubBaseUrl/$ScriptPath" } else { $null }
$RemoteTemplateUrl = if ($GitHubBaseUrl) { "$GitHubBaseUrl/templates/claude-code-sync.yaml" } else { $null }

# Resolve local docs directory (default: ai-docs/ in project root)
$LocalDocsOverride = Get-YamlScalarValue -Lines $YamlLines -Key 'local_docs_dir'
$LocalDocsDir = if ($LocalDocsOverride) { Join-Path $ProjectRoot $LocalDocsOverride } else { $DefaultLocalDocsDir }

# Resolve web AI doc output filename
$WebAiDocFilename   = Get-YamlScalarValue -Lines $YamlLines -Key 'web_ai_doc_filename'
if (-not $WebAiDocFilename) { $WebAiDocFilename = 'web-ai-doc.md' }
$WebAiDocOutputPath = Join-Path $ProjectRoot $WebAiDocFilename

$ClaudeMdEntries = Get-YamlListSection -Lines $YamlLines -SectionName 'claude_md'
$WebAiDocEntries = Get-YamlListSection -Lines $YamlLines -SectionName 'web_ai_doc'
$SkillsEntries   = Get-YamlListSection -Lines $YamlLines -SectionName 'skills'

Write-StepInfo "claude_md entries:  $($ClaudeMdEntries.Count)"
Write-StepInfo "web_ai_doc entries: $($WebAiDocEntries.Count)"
Write-StepInfo "skills entries:     $($SkillsEntries.Count)"
Write-StepInfo "Local docs dir:     $LocalDocsDir"
if ($GitHubBaseUrl) { Write-StepInfo "GitHub base URL:    $GitHubBaseUrl" }

# ---------------------------------------------------------------------------
# Self-update — fetch remote script, compare hashes, overwrite if changed
# ---------------------------------------------------------------------------
Write-SectionHeader "Checking for Script Updates"

if (-not $RemoteScriptUrl) {
    Write-StepSkipped "No github_base_url/script_path in config — skipping self-update"
}
else {
    Write-StepInfo "Remote: $RemoteScriptUrl"

    $RemoteContent = Invoke-RemoteFetch -Url $RemoteScriptUrl

    # Normalize line endings to LF before hashing — local file is CRLF on Windows,
    # GitHub serves LF. Without normalization hashes always differ and self-update
    # fires on every run.
    $Sha256           = [System.Security.Cryptography.SHA256]::Create()
    $LocalRaw         = Get-Content -Path $MyInvocation.MyCommand.Path -Raw -Encoding UTF8
    $RemoteNormalized = $RemoteContent -replace "`r`n", "`n" -replace "`r", "`n"
    $LocalNormalized  = $LocalRaw      -replace "`r`n", "`n" -replace "`r", "`n"
    $RemoteBytes      = [System.Text.Encoding]::UTF8.GetBytes($RemoteNormalized)
    $LocalBytes       = [System.Text.Encoding]::UTF8.GetBytes($LocalNormalized)
    $RemoteHash       = [BitConverter]::ToString($Sha256.ComputeHash($RemoteBytes)) -replace '-', ''
    $LocalHash        = [BitConverter]::ToString($Sha256.ComputeHash($LocalBytes))  -replace '-', ''

    if ($RemoteHash -eq $LocalHash) {
        Write-StepSuccess "Script is up to date"
    }
    else {
        Write-StepInfo "Update found — overwriting script"
        [System.IO.File]::WriteAllText($MyInvocation.MyCommand.Path, $RemoteContent, [System.Text.Encoding]::UTF8)
        Write-StepSuccess "Script updated successfully"
        Write-Host ""
        Write-Host "  Script has been updated. Please rerun to continue with the latest version." -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }
}

# ---------------------------------------------------------------------------
# Assemble CLAUDE.md
# ---------------------------------------------------------------------------
Write-SectionHeader "Assembling CLAUDE.md"

if ($ClaudeMdEntries.Count -gt 0) {
    $ClaudeMdIncluded = Invoke-DocAssembly `
        -Entries $ClaudeMdEntries `
        -OutputPath $ClaudeMdOutputPath `
        -LocalDocsDir $LocalDocsDir `
        -OutputLabel 'CLAUDE.md'

    Write-Host ""
    Write-Host "  CLAUDE.md written successfully" -ForegroundColor Green
    Write-Host "  Output:   $ClaudeMdOutputPath" -ForegroundColor Cyan
    Write-Host "  Included: $($ClaudeMdIncluded.Count) document(s)" -ForegroundColor Yellow
}
else {
    Write-StepSkipped "No claude_md entries in config — skipping"
}

# ---------------------------------------------------------------------------
# Assemble Web AI Documentation
# ---------------------------------------------------------------------------
Write-SectionHeader "Assembling Web AI Documentation"

if ($WebAiDocEntries.Count -gt 0) {
    $WebAiDocIncluded = Invoke-DocAssembly `
        -Entries $WebAiDocEntries `
        -OutputPath $WebAiDocOutputPath `
        -LocalDocsDir $LocalDocsDir `
        -OutputLabel $WebAiDocFilename

    Write-Host ""
    Write-Host "  $WebAiDocFilename written successfully" -ForegroundColor Green
    Write-Host "  Output:   $WebAiDocOutputPath" -ForegroundColor Cyan
    Write-Host "  Included: $($WebAiDocIncluded.Count) document(s)" -ForegroundColor Yellow
}
else {
    Write-StepSkipped "No web_ai_doc entries in config — skipping"
}

# ---------------------------------------------------------------------------
# Sync skills
# ---------------------------------------------------------------------------
Write-SectionHeader "Syncing Skills"

if ($SkillsEntries.Count -gt 0) {
    $SyncedSkills = Invoke-SkillsSync `
        -Entries $SkillsEntries `
        -LocalDocsDir $LocalDocsDir

    Write-Host ""
    Write-Host "  Skills synced successfully" -ForegroundColor Green
    Write-Host "  Output:  $SkillsOutputDir" -ForegroundColor Cyan
    Write-Host "  Synced:  $($SyncedSkills.Count) skill(s)" -ForegroundColor Yellow
}
else {
    Write-StepSkipped "No skills entries in config — skipping"
}

# ---------------------------------------------------------------------------
# Generate launcher script
# ---------------------------------------------------------------------------
Write-SectionHeader "Generating Launcher Script"

$LauncherWslDistro   = Get-YamlNestedScalarValue  -Lines $YamlLines -SectionName 'launcher' -Key 'wsl_distro'
$LauncherProjectPath = Get-YamlNestedScalarValue  -Lines $YamlLines -SectionName 'launcher' -Key 'project_path'
$LauncherClaudePath  = Get-YamlNestedScalarValue  -Lines $YamlLines -SectionName 'launcher' -Key 'claude_path'
$LauncherTabTitle    = Get-YamlNestedScalarValue  -Lines $YamlLines -SectionName 'launcher' -Key 'tab_title'
$LauncherTabColor    = Get-YamlNestedScalarValue  -Lines $YamlLines -SectionName 'launcher' -Key 'tab_color'
$LauncherExtraDirs   = Get-YamlNestedListSection  -Lines $YamlLines -SectionName 'launcher' -SubSectionName 'extra_dirs'

if (-not $LauncherWslDistro) {
    Write-StepSkipped "No launcher section in config — skipping"
}
else {
    Write-StepInfo "WSL distro:   $LauncherWslDistro"
    Write-StepInfo "Project path: $LauncherProjectPath"
    Write-StepInfo "Claude path:  $LauncherClaudePath"
    Write-StepInfo "Tab title:    $LauncherTabTitle"
    Write-StepInfo "Extra dirs:   $($LauncherExtraDirs.Count)"

    $LauncherOutputPath = Invoke-LauncherGeneration `
        -WslDistro   $LauncherWslDistro   `
        -ProjectPath $LauncherProjectPath `
        -ClaudePath  $LauncherClaudePath  `
        -TabTitle    $LauncherTabTitle    `
        -TabColor    $LauncherTabColor    `
        -ExtraDirs   $LauncherExtraDirs

    Write-Host ""
    Write-Host "  open-claude.ps1 generated successfully" -ForegroundColor Green
    Write-Host "  Output: $LauncherOutputPath"            -ForegroundColor Cyan
}

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "================================" -ForegroundColor DarkGray
Write-Host "  Sync complete." -ForegroundColor Green
Write-Host "================================" -ForegroundColor DarkGray
Write-Host ""
