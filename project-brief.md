# Claude Code Sync — Project Brief

## What Is This?

Claude Code Sync is a lightweight system for managing shared Claude Code memory docs and skills across multiple projects. It solves a simple problem: reusable AI context documents (code commenting guidelines, Git usage patterns, text-to-speech awareness, output preferences, etc.) need to live in one place but deploy to many projects.

Instead of duplicating markdown files across every repo, or relying on a monolithic Claude master memory file at the installation level, this system uses a centralised GitHub repo as the single source of truth. Each project declares what it needs via a YAML config file, and a sync script fetches and assembles everything.

## The Architecture

### Core Components

**1. The `claude-code-sync` GitHub repo (this repo)**

This is the central library. It contains:

- **Shared memory docs** — reusable markdown files that provide Claude Code with context (e.g., how the developer uses speech-to-text, code commenting standards, Git workflow preferences, tool execution patterns, output formatting preferences)
- **Shared skills** — Claude Code slash commands that are useful across multiple projects
- **The sync scripts** — `sync-claude-code.ps1` (Windows/PowerShell) and `sync-claude-code.sh` (Linux/Bash) that any project can use
- **A template config** — a starter `claude-code-sync.yaml` that new projects receive on first run

Suggested repo structure:

```
claude-code-sync/
├── docs/
│   ├── code-comments.md
│   ├── claude-git-usage.md
│   ├── tool-execution.md
│   ├── speech-to-text.md
│   └── output-style.md
├── skills/
│   ├── refactor.md
│   └── test-writer.md
├── scripts/
│   ├── sync-claude-code.ps1
│   └── sync-claude-code.sh
├── templates/
│   └── claude-code-sync.yaml
└── README.md
```

**2. The YAML config file (`claude-code-sync.yaml`)**

Each project that uses Claude Code gets one of these. It declares which docs and skills that project needs, and in what order they should be assembled. This file is the contract — any sync script in any language reads it and knows exactly what to do.

The config supports two types of entries:
- **Local files** — project-specific markdown docs that live in the project's own `ai-docs/` directory (e.g., `about-my-project.md`)
- **Remote URLs** — shared docs fetched from GitHub raw URLs (e.g., `https://raw.githubusercontent.com/hefin/claude-code-sync/main/docs/code-comments.md`)

The sync script distinguishes between them by a simple rule: if the entry starts with `https://`, fetch it. Otherwise, read it from the local `ai-docs/` folder.

Example config:

```yaml
claude_md:
  - about-my-project.md
  - project-specific-notes.md
  - https://raw.githubusercontent.com/hefin/claude-code-sync/main/docs/code-comments.md
  - https://raw.githubusercontent.com/hefin/claude-code-sync/main/docs/claude-git-usage.md
  - https://raw.githubusercontent.com/hefin/claude-code-sync/main/docs/tool-execution.md

web_ai_doc:
  - about-my-project.md
  - https://raw.githubusercontent.com/hefin/claude-code-sync/main/docs/code-comments.md

skills:
  - https://raw.githubusercontent.com/hefin/claude-code-sync/main/skills/refactor.md
  - https://raw.githubusercontent.com/hefin/claude-code-sync/main/skills/test-writer.md
```

The order in the YAML is the order in the output. The list *is* the ordering mechanism — no separate ordering config needed.

There are two output targets:
- `claude_md` — the full CLAUDE.md memory file for Claude Code (includes everything: tooling docs, meta docs, project-specific docs)
- `web_ai_doc` — a subset for sharing with web-based AI assistants (excludes tool execution patterns, Claude-specific Git usage, and other docs that only make sense inside Claude Code)

**3. The sync script**

The sync script is the engine. It does three things in sequence:

1. **Self-update check** — fetches the latest version of itself from the GitHub raw URL, hash-compares against the local copy, and if different, overwrites itself and prompts the user to rerun. This means the sync script stays current across all projects without manual intervention.

2. **Memory doc assembly** — reads the YAML config, fetches any remote URLs, reads any local files, stitches them together with appropriate separators and headers, and outputs the assembled CLAUDE.md (and optionally the web AI doc).

3. **Skills sync** — fetches any skills listed in the config and writes them to the `.claude/commands/` directory, overwriting existing copies (no version comparison needed — just overwrite every time, these are small text files).

Both PowerShell and Bash versions should exist. The logic is identical in both — parse YAML, fetch URLs, read local files, stitch, write output. The developer uses whichever matches their environment.

### How a Developer Uses This

**New project setup (one-time, ~30 seconds):**

1. Download the sync script into the project root (copy-paste from GitHub, or use the one-liner from the README)
2. Run the sync script
3. The script detects no `claude-code-sync.yaml` exists, fetches the template from the central repo, drops it in
4. The developer edits the YAML to add project-specific local docs and adjust which shared docs they want
5. Run the sync script again — CLAUDE.md is assembled, skills are synced

**Ongoing usage (zero thought):**

- Run the sync script whenever you want everything current
- The script self-updates, fetches latest shared docs, rebuilds CLAUDE.md, syncs skills
- One command, everything's current

### Important Design Decisions

**No submodules, no cloning, no repo-in-repo.** Every shared doc is fetched via HTTP from GitHub raw URLs at sync time. This avoids the complexity of having two Git repos fighting in the same directory, gitignore gymnastics, and the mental overhead of remembering to pull a secondary repo.

**No package manager, no dependency resolution, no lock files.** The YAML config is a flat list. The sync script fetches what's listed. That's the entire system.

**No version pinning on individual docs.** All projects get the latest version of shared docs when they sync. If a shared doc is updated in the central repo, the next sync on any project picks it up automatically. Git history on the central repo serves as the version trail if you ever need to look back.

**The YAML config is never overwritten after first creation.** The sync script creates it from the template on first run, then never touches it again. It belongs to the project and the developer customises it freely.

**Skills are overwritten every sync.** No comparison, no diffing. Fetch, write, done. They're small text files and the overhead of checking staleness exceeds the cost of just writing them.

**Self-update uses hash comparison, not version numbers.** The sync script doesn't track its own version. It hashes the local copy, hashes the remote copy, and if they differ, it overwrites and exits with a message to rerun. No version numbers to forget to bump.

**Error handling should be loud.** If a remote fetch fails (network issue, URL typo, GitHub down), the script should fail immediately and clearly, not silently produce a CLAUDE.md with missing sections. Non-200 HTTP responses should halt the process.

### The Self-Updating Sync Script

The self-update mechanism deserves specific attention:

- PowerShell reads the entire script into memory before execution, so the script can safely overwrite its own file on disk while running
- Bash reads line-by-line, so the entire script body needs to be wrapped in a `{ ... ; exit; }` block to force bash to read it all into memory first
- After overwriting itself, the script should print a clear message like "Sync script updated. Please rerun." and exit — no automatic re-execution, no recursion

### The Template Config

The template (`templates/claude-code-sync.yaml`) should be a sensible starting point with two or three commonly-used shared docs pre-populated, plus comments guiding the developer on how to add their own local docs:

```yaml
# claude-code-sync.yaml
# Defines which memory docs and skills to sync for this project.
# Local entries: filename looked up in ai-docs/ folder
# Remote entries: full URL fetched via HTTP (e.g., GitHub raw URLs)
# Order in the list = order in the assembled output

claude_md:
  # Add your project-specific local docs here:
  # - about-my-project.md

  # Shared docs from claude-code-sync:
  - https://raw.githubusercontent.com/hefin/claude-code-sync/main/docs/code-comments.md
  - https://raw.githubusercontent.com/hefin/claude-code-sync/main/docs/tool-execution.md

web_ai_doc: []

skills: []
```

### This Repo Uses Itself

The claude-code-sync repo is itself a Claude Code project. Its own `claude-code-sync.yaml` will reference only local files (since all the shared docs live here). No remote URLs needed — everything is already local. The sync script still works identically; it just happens that every entry resolves to a local file read.

## Context for the Developer

- The developer primarily works in two environments: Windows (PowerShell) and Linux (Bash)
- The developer uses speech-to-text input extensively, so memory docs often include instructions about interpreting imperfect input
- Projects range from Chrome extensions to Laravel apps to Docker infrastructure — the shared memory docs need to be generic enough to apply broadly
- The developer currently has an existing assembler script (PowerShell) that concatenates local markdown files into CLAUDE.md with hardcoded file lists — this system replaces that pattern with a declarative, centralised approach
- The developer values pragmatic, right-sized solutions and explicitly chose not to over-engineer this with version pinning, dependency resolution, or conditional includes

## What Needs Building

1. The repo structure (docs/, skills/, scripts/, templates/)
2. The initial shared memory docs (start with whatever foundational docs make sense — code comments, tool execution, etc. — these can be populated over time)
3. `sync-claude-code.ps1` — the PowerShell sync script with self-update, YAML parsing, doc assembly, and skills sync
4. `sync-claude-code.sh` — the Bash equivalent
5. The template `claude-code-sync.yaml`
6. A README with the quick-start one-liners for both platforms

The existing PowerShell assembler script (attached to this brief as context, not as a template to copy) shows the current pattern being replaced — it demonstrates the doc ordering, the two output targets (CLAUDE.md and web AI doc), and the base introduction/header content that gets prepended to assembled docs. The new system should handle these same concerns but driven by the YAML config rather than hardcoded arrays.