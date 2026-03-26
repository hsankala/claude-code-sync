# Claude Code Sync — Project Guide

This project uses **Claude Code Sync** to manage AI context. A sync script assembles
shared and local documents into `CLAUDE.md` and keeps slash command skills current.

---

## Project Folder Roles

**`ai-docs/`** — First-class memory. Every document in this folder is assembled directly
into `CLAUDE.md` and is part of your active context. Project-specific docs (about the
project, architecture notes, conventions) live here.

**`docs/`** — Reference material. These documents are not loaded into `CLAUDE.md`
automatically. They exist for detailed documentation that doesn't need to be in context
on every session — specs, designs, runbooks. Reference them when relevant, but don't
assume they're loaded.

**`tools/`** — Project tooling and scripting. The sync script lives here alongside any
other project-specific scripts or utilities.

---

## The Config File

`tools/claude-code-sync.yaml` controls what gets assembled into `CLAUDE.md`. Its key
sections:

```yaml
claude_md:        # Documents assembled into CLAUDE.md (local filenames or remote URLs)
skills:           # Slash command skills synced to .claude/commands/
launcher:         # Optional: generates open-claude.ps1 to launch Claude Code
web_ai_doc:       # Optional: subset assembled for web-based AI assistants
```

When a project needs a new shared doc or skill, add it here and run the sync script.

---

## Running the Sync Script

Two versions exist — use whichever matches the environment:

**Windows / WSL:**
```powershell
pwsh tools/sync-claude-code.ps1
```

**Linux / macOS:**
```bash
bash tools/sync-claude-code.sh
```

Run from the project root. If you are unsure of the current directory, prefix with a `cd`:

```powershell
cd C:\path\to\project && pwsh tools/sync-claude-code.ps1
```
```bash
cd /path/to/project && bash tools/sync-claude-code.sh
```

The sync script: fetches any remote docs and skills, assembles `CLAUDE.md`, and writes
skills to `.claude/commands/`. It fails loudly — a bad URL or missing file halts
immediately with a clear message.

---

## Sync Is One-Way

The sync script only pulls — it fetches shared docs and skills from the central
claude-code-sync repository and writes them into this project. It does not push local
changes back anywhere. Editing a skill file in `.claude/commands/` locally has no effect
on the central library and will be overwritten on the next sync.

Changes to the central library (new shared docs, updated skills) are picked up
automatically the next time the sync script runs.

## When to Sync

Sync whenever:
- A document in `ai-docs/` is added, updated, or edited
- `tools/claude-code-sync.yaml` is modified (new docs or skills referenced)
- You want to pull the latest versions of any shared docs or skills

**After any such change, ask the operator:**

> The docs have been updated. Would you like me to run the sync script now,
> or would you prefer to run it yourself?

If the operator wants to run it themselves, give them a ready-to-paste command using
the actual absolute path to this project. Determine the project root (use `pwd` or
check the known project path from context), then present:

**Windows / WSL:**
```
cd C:\actual\path\to\project && pwsh tools\sync-claude-code.ps1
```

**Linux:**
```
cd /actual/path/to/project && bash tools/sync-claude-code.sh
```

Fill in the real path — do not give a generic placeholder. The operator should be able
to open any terminal, paste the command, and have it work immediately.
