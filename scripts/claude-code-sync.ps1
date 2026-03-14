# Document order for CLAUDE.md — full set including tooling and meta docs
$claudeDocOrder = @(
    "about-tubescribe.md",
    "yt-dlp-config.md",
    "yt-dlp-cache-and-troubleshooting.md",
    "testing.md",
    "tool-execution.md",
    "code-comments.md",
    "claude-git-usage.md"
)

# Document order for web-ai-context-doc.md — substance only, no tooling/meta docs
$webAiDocOrder = @(
    "about-tubescribe.md",
    "yt-dlp-config.md",
    "yt-dlp-cache-and-troubleshooting.md",
    "testing.md"
)

# Set paths relative to script location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$aiDocsPath = Join-Path $projectRoot "ai-docs"
$claudeOutputPath = Join-Path $projectRoot ".claude"
$aiContextWebDocPath = Join-Path $scriptPath "web-ai-context-doc.md"
$claudeMemoryOutputPath = Join-Path $claudeOutputPath "CLAUDE.md"

# Function to write the base introduction
function Get-BaseIntroduction {
    param($includeClaudeCommands = $false)

    $intro = @"
# TubeScribe - Complete AI Context

## Welcome AI Assistant!

This document provides comprehensive context about the **TubeScribe** project - a personal Chrome extension for extracting YouTube video transcripts with a simple right-click.

### Purpose of This Document

This is a concatenated collection of all AI-focused documentation for the TubeScribe project. It gives AI assistants like you the complete understanding of:
- Project overview and two-engine architecture (yt-dlp + Python API)
- How transcript extraction works and how to switch engines
- yt-dlp configuration, flags, and the EJS challenge solver cache
- Test suite structure and how to run diagnostics
- Tool execution patterns
- Code commenting guidelines
- Git workflow and version control

"@

    if ($includeClaudeCommands) {
        $intro += @"

### Getting Started

When working with this project, familiarize yourself with:
- The two-engine architecture (yt-dlp and Python API as independent fallbacks)
- How the Node server routes requests by engine
- The test suite in tests/ and how to run diagnostics bottom-up
- Tool execution and automation patterns
- Git workflow and version control practices
- Code commenting guidelines

"@
    }

    $intro += @"

### How to Use This Context

- Read "About TubeScribe" first to understand the architecture and current strategies
- Check the troubleshooting section if transcript extraction is failing
- Use the test suite (tests/) to isolate which layer is broken before touching code
- Reference code comments guidelines when writing/modifying code
- Follow established patterns for consistency across the codebase

### Important Notes

- This is a **personal tool** for a single developer - not distributed publicly
- YouTube's extraction mechanisms change frequently - expect things to break and require fixes
- Two engines exist for resilience: when one breaks, flip the dropdown in the settings page

---

"@

    return $intro
}

# Ensure .claude directory exists
if (-not (Test-Path $claudeOutputPath)) {
    New-Item -ItemType Directory -Path $claudeOutputPath -Force | Out-Null
}

# Write the web AI context doc (for sharing with online AIs)
Get-BaseIntroduction -includeClaudeCommands $false | Out-File $aiContextWebDocPath -Force -Encoding UTF8

# Write the CLAUDE.md version with commands (for local Claude Code)
Get-BaseIntroduction -includeClaudeCommands $true | Out-File $claudeMemoryOutputPath -Force -Encoding UTF8

# WHY $script: is needed here:
# • These variables are WRITTEN TO inside functions (+=)
# • PowerShell's default: Write operations create NEW local variables
# • Without $script: → function creates its own copy → original stays unchanged
# • With $script: → modifies the actual script-level variable
# • Only needed for WRITES - READ operations work fine without it
# • Yes, this is weird! But it's standard PowerShell behavior

# Function to append documents to a file
function Append-Documents {
    param($targetPath, $docOrder)

    $script:foundFiles = @()
    $script:missingFiles = @()

    foreach ($doc in $docOrder) {
        $docPath = Join-Path $aiDocsPath $doc
        if (Test-Path $docPath) {
            $script:foundFiles += $doc
            "## === $doc ===`n" | Out-File $targetPath -Append -Force -Encoding UTF8
            Get-Content $docPath -Encoding UTF8 | Out-File $targetPath -Append -Force -Encoding UTF8
            "`n`n---`n`n" | Out-File $targetPath -Append -Force -Encoding UTF8
        } else {
            $script:missingFiles += $doc
        }
    }
}

# Function to add summary
function Add-Summary {
    param($targetPath, $totalDocs)

    @"

## Document Generation Summary

**Files included:** $($script:foundFiles.Count)
$($script:foundFiles | ForEach-Object { "- $_" } | Out-String)

$(if ($script:missingFiles.Count -gt 0) {
@"
**Files not found:** $($script:missingFiles.Count)
$($script:missingFiles | ForEach-Object { "- $_" } | Out-String)
"@
})

**Generated on:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Output location:** $targetPath

"@ | Out-File $targetPath -Append -Force -Encoding UTF8
}

# Generate web AI context doc
Append-Documents -targetPath $aiContextWebDocPath -docOrder $webAiDocOrder
Add-Summary -targetPath $aiContextWebDocPath -totalDocs $webAiDocOrder.Count
Write-Host "Web AI Context Doc generated successfully!" -ForegroundColor Green
Write-Host "Output: $aiContextWebDocPath" -ForegroundColor Cyan
Write-Host "Files included: $($script:foundFiles.Count) of $($webAiDocOrder.Count)" -ForegroundColor Yellow
if ($script:missingFiles.Count -gt 0) {
    Write-Host "Missing files: $($script:missingFiles -join ', ')" -ForegroundColor Red
}

Write-Host ""

# Generate CLAUDE.md
Append-Documents -targetPath $claudeMemoryOutputPath -docOrder $claudeDocOrder
Add-Summary -targetPath $claudeMemoryOutputPath -totalDocs $claudeDocOrder.Count
Write-Host "CLAUDE.md generated successfully!" -ForegroundColor Green
Write-Host "Output: $claudeMemoryOutputPath" -ForegroundColor Cyan
Write-Host "Files included: $($script:foundFiles.Count) of $($claudeDocOrder.Count)" -ForegroundColor Yellow
if ($script:missingFiles.Count -gt 0) {
    Write-Host "Missing files: $($script:missingFiles -join ', ')" -ForegroundColor Red
}