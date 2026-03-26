# Init Project — Claude Code Sync Initialiser

Initialise a new project with the Claude Code Sync structure: folder layout, about doc,
sync script, and a pre-filled claude-code-sync.yaml ready to run.

---

<!--
  ============================================================
  WORK IN PROGRESS — DRAFT SKILL
  ============================================================
  This skill is partially implemented. Steps marked [DONE] are
  complete and tested. Steps marked [TODO] are stubs or notes
  for future sessions.

  Current status:
    [DONE] PRE-FLIGHT: detect environment, gather project name + launcher mode
    [DONE] STEP 1: create folder structure
    [DONE] STEP 2: create about doc
    [DONE] STEP 3: download sync script
    [DONE] STEP 4: download + configure claude-code-sync.yaml
    [DONE] STEP 5: summary output

  Known gaps / future work:
    - Could prompt for extra_dirs on WSL mode
    - Could offer to add more shared docs beyond the standard three
    - Could offer to pre-populate the about doc interactively
    - Tab colour is hardcoded to #002B36 — could make configurable
  ============================================================
-->

---

## PRE-FLIGHT: Information Gathering

Run the following before asking the operator anything.

### 1. Detect Environment

Run:

```bash
uname -r
```

- If the kernel string contains `microsoft` → running inside WSL on a Windows machine
- Otherwise → running on native Linux (remote server or local Linux install)

Use this to form a launcher mode recommendation for the next step.

### 2. Project Name

Look at the current working directory name. Suggest four name options derived from it:
- The raw directory name as-is
- Lowercased and hyphenated
- A cleaned-up title-case version
- A short abbreviated form if one is obvious

Present these as a numbered list with your recommendation marked. Ask the operator to
pick one or enter their own. The name will be used for the about doc filename:
`about-{project-name}.md` — always lowercase, hyphen-separated.

### 3. Launcher Mode

Based on the environment detected in step 1, present a recommendation:

```
Environment detected: [WSL / native Linux]
Recommended launcher mode: [WSL / SSH]

Which launcher mode for this project?

  1: WSL  — opens Claude Code via the local WSL layer on this Windows machine
             (recommended if you're running inside WSL)
  2: SSH  — opens Claude Code by SSHing into a remote Linux server
             (recommended if this project lives on a remote host)
  3: None — skip launcher generation entirely
```

For **WSL mode**, also gather:
- Tab title for Windows Terminal (suggest: `CLAUDE CODE - {PROJECT-NAME}`)

For **SSH mode**, also gather:
- SSH host (format: `user@hostname-or-ip`)
- Tab title for Windows Terminal (suggest: `CLAUDE - {PROJECT-NAME}`)

For both modes, `claude_path` defaults to `/home/{user}/.local/bin/claude` — confirm or
let the operator override. Derive `{user}` from the current user if possible (`whoami`).

---

## STEP 1: Create Folder Structure

Create the following directories at the project root (skip silently if they already exist):

```
.claude/commands/
ai-docs/
docs/
context-summary/
tools/
```

```bash
mkdir -p .claude/commands ai-docs docs context-summary tools
```

---

## STEP 2: Create About Doc

Create `ai-docs/about-{project-name}.md` using the name confirmed in PRE-FLIGHT.
If the file already exists, ask before overwriting.

```markdown
# About {Project Name}

> **Status note:** This document is a work in progress. Fill in the sections below
> to give Claude Code the context it needs to work effectively on this project.

---

## What This Project Is

<!-- Describe what the project does and what problem it solves -->

---

## Tech Stack

<!-- List the main languages, frameworks, and tools in use -->
```

---

## STEP 3: Download Sync Script

Use `curl` to download the appropriate sync script into `tools/`. `curl` is available on
WSL2 and most Linux distros by default.

If running in WSL, download the PS1:

```bash
curl -fsSL https://raw.githubusercontent.com/hsankala/claude-code-sync/main/tools/sync-claude-code.ps1 \
  -o tools/sync-claude-code.ps1
```

If running on native Linux, download the SH and make it executable:

```bash
curl -fsSL https://raw.githubusercontent.com/hsankala/claude-code-sync/main/tools/sync-claude-code.sh \
  -o tools/sync-claude-code.sh
chmod +x tools/sync-claude-code.sh
```

If uncertain, download both. The `-fsSL` flags mean: fail on error, silent progress,
follow redirects.

---

## STEP 4: Download and Configure claude-code-sync.yaml

Download the template config using `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/hsankala/claude-code-sync/main/templates/claude-code-sync.yaml \
  -o tools/claude-code-sync.yaml
```

If `tools/claude-code-sync.yaml` already exists, ask before overwriting.

Then make the following edits:

### 4a. Fill in the launcher section

Uncomment and populate the correct block based on the operator's choice in PRE-FLIGHT.

**WSL mode:**
```yaml
launcher:
  mode:          wsl
  project_path:  {linux-path-to-project}
  claude_path:   /home/{user}/.local/bin/claude
  tab_title:     {tab-title}
  tab_color:     "#002B36"
```

**SSH mode:**
```yaml
launcher:
  mode:          ssh
  ssh_host:      {user@host}
  project_path:  {path-on-remote}
  claude_path:   /home/{user}/.local/bin/claude
  tab_title:     {tab-title}
  tab_color:     "#002B36"
```

If the operator chose no launcher, leave the launcher section commented out.

### 4b. Pre-fill the claude_md section

```yaml
claude_md:
  # Project-specific local doc:
  - about-{project-name}.md

  # Shared docs from claude-code-sync:
  - https://raw.githubusercontent.com/hsankala/claude-code-sync/main/ai-doc-library/speech-to-text.md
  - https://raw.githubusercontent.com/hsankala/claude-code-sync/main/ai-doc-library/chat-guidelines.md
  - https://raw.githubusercontent.com/hsankala/claude-code-sync/main/ai-doc-library/chat-response-style-guide.md
  - https://raw.githubusercontent.com/hsankala/claude-code-sync/main/ai-doc-library/chat-session-banners.md
  - https://raw.githubusercontent.com/hsankala/claude-code-sync/main/ai-doc-library/tool-transparency.md
  - https://raw.githubusercontent.com/hsankala/claude-code-sync/main/ai-doc-library/claude-git-usage-windows.md
```

---

## STEP 5: Summary

```
╔══════════════════════════════════════════════════════╗
║  ✅  Project initialised — claude-code-sync ready    ║
╚══════════════════════════════════════════════════════╝

📁 Folders created:
   .claude/commands/   ai-docs/   docs/   context-summary/   tools/

📄 Files created:
   ai-docs/about-{project-name}.md   (placeholder — fill in later)
   tools/sync-claude-code.{ext}      (downloaded from GitHub)
   tools/claude-code-sync.yaml       (configured and ready)

🚀 Next steps:
   1. Fill in ai-docs/about-{project-name}.md with project context
   2. Review tools/claude-code-sync.yaml — adjust shared docs as needed
   3. Push this project to GitHub (if not already)
   4. Run the sync script to generate CLAUDE.md and open-claude.ps1
```
