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
    [DONE] STEP 5: create or update .gitignore
    [DONE] STEP 6: VS Code task buttons
    [DONE] STEP 7: summary output

  Known gaps / future work:
    - Could prompt for extra_dirs on WSL mode
    - Could offer to add more shared docs beyond the standard three
    - Could offer to pre-populate the about doc interactively
    - Tab colour is hardcoded to #002B36 — could make configurable
    - STEP 5 (.gitignore) runs after STEP 4 so it can read web_ai_doc_filename from the yaml
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

### 2. Global Settings Setup

**Read `~/.claude/settings.json` in full before doing anything else.** If the file does not
exist, treat it as an empty object `{}`. Do not assume its contents — read the whole file and
understand its current state before checking anything.

Then check two things:

#### 2a. Attribution suppression

Check for an `attribution` block with both `commit` and `pr` set to empty strings.

- ✅ Present and correct — note it and move on
- ⚠️ Missing or not set to empty strings — flag it

Attribution should only ever be set at the global level (`~/.claude/settings.json`), never
in project-level settings files.

#### 2b. Baseline permissions

Compare the existing `permissions.allow` array against the baseline list in
**Appendix A** at the end of this skill. Identify which entries from the baseline are
absent from the current file.

- ✅ All baseline entries present — note it and move on
- ⚠️ Some or all missing — list how many are absent

#### 2c. Offer to merge

If either check flagged a gap, present a single combined offer:

```
⚠️  ~/.claude/settings.json is missing the following:

    [ ] Attribution suppression  (commit + pr set to "")
    [ ] Baseline read permissions  (N entries missing from allow list)

    This is a non-destructive merge — nothing currently in your settings
    will be removed or changed. Only missing items will be added.

    Apply now? (y/n)
```

If the operator confirms, perform a single write:
- Merge in any missing baseline permissions (additive — do not remove existing entries)
- Set attribution suppression if not already correct
- Preserve everything else in the file exactly as found

If both checks passed, show a single clean confirmation and move on:

```
✅  ~/.claude/settings.json — attribution suppressed, baseline permissions present
```

---

### 3. Project Name

Look at the current working directory name. Suggest four name options derived from it:
- The raw directory name as-is
- Lowercased and hyphenated
- A cleaned-up title-case version
- A short abbreviated form if one is obvious

Present these as a numbered list with your recommendation marked. Ask the operator to
pick one or enter their own. The name will be used for the about doc filename:
`about-{project-name}.md` — always lowercase, hyphen-separated.

### 4. Launcher Mode

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

## STEP 5: Create or Update .gitignore

The sync script generates assembled output files that should not be committed to source
control — they are regenerated on every sync. Session context summaries are also transient
and typically belong outside version control.

### 5a. Determine which files to ignore

Read `tools/claude-code-sync.yaml` and extract the following values:

- `web_ai_doc_filename` — the generated web AI doc (e.g. `CLAUDE-WEB-AI.md`). If the field
  is absent or commented out, default to `CLAUDE-WEB-AI.md`.

Always include these regardless of config:

```
# Claude Code Sync — generated outputs (regenerated by sync script, do not commit)
CLAUDE.md
{web_ai_doc_filename}
ai-docs/file-tree.md

# Claude Code session context summaries
context-summary/
```

### 5b. Check for an existing .gitignore

- **If `.gitignore` does not exist** — create it with the block above.
- **If `.gitignore` exists** — check whether `CLAUDE.md` is already present anywhere in the
  file. If it is, skip (assume the block was already added). If it is not, append the block
  to the end of the file, preceded by a blank line.

Do not modify any existing content in the file.

---

## STEP 6: VS Code Task Buttons

Create `.vscode/tasks.json` with the two standard tasks.

For the Generate Docs task, check which environment the project is running in:

- **Windows / WSL** — read `script_path_ps1` from `tools/claude-code-sync.yaml` and use
  `pwsh.exe` as the command (as shown in the template below)
- **Linux native** — read `script_path_sh` from `tools/claude-code-sync.yaml` and replace
  the command with `bash` and the `-File` arg with the shell script path instead

When in doubt, check the `launcher` section of `tools/claude-code-sync.yaml` — a `mode: wsl`
or `mode: ssh` entry confirms Windows/WSL; absence of a launcher and a Linux environment
confirms native Linux.

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Open Claude",
      "type": "shell",
      "command": "pwsh.exe -File tools/open-claude.ps1",
      "presentation": {
        "panel": "new",
        "focus": true,
        "reveal": "always"
      }
    },
    {
      "label": "Generate Docs",
      "type": "shell",
      "command": "pwsh.exe",
      "args": [
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "{script_path_ps1}"
      ],
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared",
        "showReuseMessage": false,
        "clear": false
      },
      "runOptions": {
        "runOn": "folderOpen"
      },
      "problemMatcher": []
    }
  ]
}
```

Then add the VsCodeTaskButtons settings. Where they go depends on how the project is opened:

**If a `.code-workspace` file exists in the project root** — add to its `settings` block.
VS Code reads workspace settings from the workspace file, not from `.vscode/settings.json`,
when a project is opened via a workspace file. Writing to `.vscode/settings.json` will have
no effect in this case.

```json
"settings": {
  "VsCodeTaskButtons.showCounter": true,
  "VsCodeTaskButtons.tasks": [
    {
      "label": "$(rocket) Open Claude",
      "task": "Open Claude",
      "tooltip": "Launch Claude Code",
      "alignment": "left"
    },
    {
      "label": "$(book) Generate Docs",
      "task": "Generate Docs",
      "tooltip": "Run the sync script and regenerate AI context docs",
      "alignment": "left"
    }
  ]
}
```

**If no `.code-workspace` file exists** — create `.vscode/settings.json` with the same
VsCodeTaskButtons block.

The `task` field in each button must exactly match the `label` in `tasks.json`.

---

## STEP 7: Summary

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
   .gitignore                        (excludes CLAUDE.md, web AI doc, context-summary/)
   .vscode/tasks.json                (Open Claude + Generate Docs tasks)

🚀 Next steps:
   1. Fill in ai-docs/about-{project-name}.md with project context
   2. Review tools/claude-code-sync.yaml — adjust shared docs as needed
   3. Push this project to GitHub (if not already)
   4. Run the sync script to generate CLAUDE.md and open-claude.ps1
```

---

## Appendix A — Global Settings Baseline

This is the minimum baseline for `~/.claude/settings.json`. Used by Pre-flight Step 2 to
check and merge global settings. **Merge is always additive** — entries already present are
never removed or modified.

```json
{
  "attribution": {
    "commit": "",
    "pr": ""
  },
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "WebSearch",
      "WebFetch",
      "Bash(cat *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(less *)",
      "Bash(grep *)",
      "Bash(find *)",
      "Bash(ls *)",
      "Bash(tree *)",
      "Bash(pwd *)",
      "Bash(echo *)",
      "Bash(wc *)",
      "Bash(file *)",
      "Bash(stat *)",
      "Bash(which *)",
      "Bash(whereis *)",
      "Bash(env *)",
      "Bash(printenv *)",
      "Bash(whoami *)",
      "Bash(id *)",
      "Bash(groups *)",
      "Bash(hostname *)",
      "Bash(uname *)",
      "Bash(uptime *)",
      "Bash(df *)",
      "Bash(du *)",
      "Bash(free *)",
      "Bash(ps *)",
      "Bash(git status *)",
      "Bash(git log *)",
      "Bash(git diff *)",
      "Bash(git branch *)",
      "Bash(git remote *)",
      "Bash(git show *)",
      "Bash(git blame *)",
      "Bash(git check-ignore *)",
      "Bash(ddev exec *)",
      "mcp__context7__*",
      "mcp__chrome-devtools__*",
      "mcp__mysql_database__*",
      "mcp__stripe__*",
      "mcp__laravel-boost__*"
    ]
  }
}
```
