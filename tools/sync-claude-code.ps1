#Requires -Version 5.1
<#
.SYNOPSIS
    Assembles CLAUDE.md, web-ai-doc.md, and syncs Claude Code skills from claude-code-sync.yaml.

.DESCRIPTION
    Reads claude-code-sync.yaml (alongside this script), fetches remote docs via HTTP,
    reads local docs from ai-docs/, assembles output files, and syncs skill files to
    .claude/commands/. Run from the project root or from the tools/ folder.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
$ScriptVersion = '0.1.0'
$RemoteScriptUrl   = 'https://raw.githubusercontent.com/hsankala/claude-code-sync/main/scripts/sync-claude-code.ps1'
$RemoteTemplateUrl = 'https://raw.githubusercontent.com/hsankala/claude-code-sync/main/templates/claude-code-sync.yaml'

# ---------------------------------------------------------------------------
# Path setup — script lives in tools/, project root is one level up
# ---------------------------------------------------------------------------
$ScriptDirectory      = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot          = Split-Path -Parent $ScriptDirectory
$ConfigFilePath       = Join-Path $ScriptDirectory 'claude-code-sync.yaml'
$ClaudeMdOutputPath   = Join-Path $ProjectRoot 'CLAUDE.md'
$WebAiDocOutputPath   = Join-Path $ProjectRoot 'web-ai-doc.md'
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

# Resolve local docs directory (default: ai-docs/ in project root)
$LocalDocsOverride = Get-YamlScalarValue -Lines $YamlLines -Key 'local_docs_dir'
$LocalDocsDir = if ($LocalDocsOverride) { Join-Path $ProjectRoot $LocalDocsOverride } else { $DefaultLocalDocsDir }

$ClaudeMdEntries = Get-YamlListSection -Lines $YamlLines -SectionName 'claude_md'
$WebAiDocEntries = Get-YamlListSection -Lines $YamlLines -SectionName 'web_ai_doc'
$SkillsEntries   = Get-YamlListSection -Lines $YamlLines -SectionName 'skills'

Write-StepInfo "claude_md entries:  $($ClaudeMdEntries.Count)"
Write-StepInfo "web_ai_doc entries: $($WebAiDocEntries.Count)"
Write-StepInfo "skills entries:     $($SkillsEntries.Count)"
Write-StepInfo "Local docs dir:     $LocalDocsDir"

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
# Assemble web-ai-doc.md
# ---------------------------------------------------------------------------
Write-SectionHeader "Assembling web-ai-doc.md"

if ($WebAiDocEntries.Count -gt 0) {
    $WebAiDocIncluded = Invoke-DocAssembly `
        -Entries $WebAiDocEntries `
        -OutputPath $WebAiDocOutputPath `
        -LocalDocsDir $LocalDocsDir `
        -OutputLabel 'web-ai-doc.md'

    Write-Host ""
    Write-Host "  web-ai-doc.md written successfully" -ForegroundColor Green
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
# Done
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "================================" -ForegroundColor DarkGray
Write-Host "  Sync complete." -ForegroundColor Green
Write-Host "================================" -ForegroundColor DarkGray
Write-Host ""
