# About Claude Code Sync

> **Status note:** This project is in active early development. The architecture described here
> is largely in place but some parts are still being built out. If something described here
> doesn't match what you see on disk, the code is ahead of this doc or vice versa — use your
> judgement and check the actual files. This document will be kept current as the project matures.

---

## What This Project Is

Claude Code Sync is a lightweight system for managing shared Claude Code context documents and
skills across multiple projects. It solves a simple, recurring problem: reusable AI context
(coding standards, Git workflow, output style preferences, tool usage patterns) needs to live
in one place but be available to many projects.

Without this system, those documents get duplicated across every repo, go out of sync, and
become a maintenance burden. With it, there is one source of truth — this repo — and every
project that uses Claude Code can pull from it on demand.

---

## The Core Idea

Each project that uses Claude Code has a small config file (`claude-code-sync.yaml`) that
declares which context documents and skills it needs. A sync script reads that config, fetches
or reads each document, assembles them into a `CLAUDE.md` file, and syncs any skills to
`.claude/commands/`. The developer runs the sync script whenever they want everything current.

That's the whole system. There is no package manager, no dependency graph, no version pinning,
no lock files. The config is a flat list. The order in the list is the order in the output.

---

## How a Consumer Project Uses This

A project that wants to use shared context from this repo puts entries like this in its
`claude-code-sync.yaml`:

```yaml
claude_md:
  - about-my-project.md
  - https://raw.githubusercontent.com/hsankala/claude-code-sync/main/ai-docs/speech-to-text.md
  - https://raw.githubusercontent.com/hsankala/claude-code-sync/main/ai-docs/chat-output-formatting.md

skills:
  - https://raw.githubusercontent.com/hsankala/claude-code-sync/main/skills/commit.md
```

Local entries (plain filenames) are read from the project's own `ai-docs/` folder.
Remote entries (full `https://` URLs) are fetched at sync time from GitHub.
The assembled output is written to `CLAUDE.md` in the project root.

---

## How This Repo Uses Itself

This repo is also a Claude Code project with its own `tools/claude-code-sync.yaml`. Because
all the documents are already local, it references everything by local path rather than remote
URL. The sync script behaviour is identical — it just happens that every entry resolves to a
local file read rather than an HTTP fetch.

This means the `CLAUDE.md` at the root of this repo is itself assembled by the sync script,
giving you the full context you need to work on this project.

---

## The Sync Script

Two versions exist: `sync-claude-code.ps1` (PowerShell, Windows) and `sync-claude-code.sh`
(Bash, Linux/macOS/WSL). Both do the same thing in the same order:

1. **Self-update** — fetches the latest version of itself from GitHub, compares hashes, and
   if different, overwrites itself and exits asking the user to rerun. Keeps the script current
   across all projects without manual intervention.

2. **Config bootstrap** — if no `claude-code-sync.yaml` exists, fetches the template from
   GitHub, drops it in, and exits asking the user to edit it and rerun.

3. **Doc assembly** — reads the YAML config, fetches or reads each entry, stitches them
   together with separators, writes `CLAUDE.md` (and optionally `web-ai-doc.md`).

4. **Skills sync** — fetches or reads each skill entry, writes to `.claude/commands/`.

The script fails loudly on any error — a missing file or failed HTTP fetch halts immediately
with a clear message. It never silently produces incomplete output.

---

## Two Output Targets

**`CLAUDE.md`** — the full context file for Claude Code. Includes everything: project-specific
docs, shared guidelines, tooling patterns, Git workflow. This is what Claude Code reads.

**`CLAUDE-WEB-AI.md`** — an optional subset for sharing with web-based AI assistants (ChatGPT,
Claude.ai, etc.). Typically excludes Claude-Code-specific docs like tool execution patterns,
and includes only the substantive project and style docs that make sense outside Claude Code.
Only generated if the `web_ai_doc` section in the config has entries.

---

## Design Principles

**No submodules, no cloning.** All shared docs are fetched via HTTP at sync time. No secondary
Git repo fighting in the same directory.

**No package manager.** The YAML config is a flat list. There is no dependency resolution,
no version pinning, no lock files. All projects always get the latest version of shared docs
when they sync.

**Loud failures.** A bad URL or missing file halts the script immediately. No silent partial
output.

**The config belongs to the project.** The sync script creates `claude-code-sync.yaml` from
the template on first run, then never touches it again. The developer owns it and customises
it freely.

**Skills are always overwritten.** No diffing, no comparison. Fetch, write, done.

---

## Working on This Project

If you are a Claude Code instance working on this repo, here is the lay of the land:

- Both sync scripts are in `tools/` — `sync-claude-code.ps1` (PowerShell) and `sync-claude-code.sh` (Bash)
- This project's own config is at `tools/claude-code-sync.yaml`
- Shared docs being built out live in `ai-docs/`
- Skills live in `skills/`

The developer runs the PowerShell script on Windows and the Bash script in WSL/Linux.
Both environments are in active use. Changes to one script should be reflected in the other.

---

## Self-Update Behaviour

The sync scripts include a self-update step that fetches the latest version from GitHub and
overwrites the local file if the hashes differ. **For this project, `disable_self_update: true`
is set in `tools/claude-code-sync.yaml` and should remain that way.** This is the normal
working state — the scripts are actively developed here and the self-update would overwrite
local changes.

If `disable_self_update` is ever changed to `false` during a session, flag it to the operator
before running the sync script:

> Self-update is currently enabled (`disable_self_update: false`). Any uncommitted changes to
> the sync scripts will be overwritten when the sync runs. Commit and push first, or set
> `disable_self_update: true` to skip the check for this run.

The self-update exists for consumer projects — it keeps their copy of the script current
without manual intervention. For this repo, it is an active hazard and should stay disabled.
