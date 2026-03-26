---
description: Generate a session handoff document for the next Claude Code instance
allowed-tools: Bash(date:*), Bash(mkdir:*), Bash(ls:*)
---

## Task

Generate a session summary that enables a fresh Claude Code instance to resume work immediately with full context of this session.

## Output

1. Determine the current date and time using `date`.
2. Create the output directory if it doesn't exist: `context-summary/`
3. Generate the filename using this pattern:

```
context-summary/session-YYYY-MM-DD-{period}.md
```

Where `{period}` is determined by time of day:
- Before 12:00 → `morning`
- 12:00–17:59 → `afternoon`
- 18:00+ → `evening`

If a file with the same name already exists, append `-2`, `-3`, etc.

## Content Structure

Write the summary using this structure:

```markdown
# Session Summary — {date} {period}

## What Was Done
- Recent changes, decisions, and implementations
- Key architectural or technical decisions (and why)
- Any pivots, corrections, or direction changes

## What Remains
- Incomplete work, explicitly listed
- Next logical steps in sequence
- Blockers, pending decisions, or unknowns

## Critical Context
- Decisions that affect ongoing work
- Gotchas, edge cases, or warnings discovered
- Any operator preferences or constraints established this session

## Files Changed
- List files created, modified, or deleted this session
```

## Rules

- **Do NOT include**: General project overview, standard architecture details, stack information, or anything already in `.claude/` memory files.
- **Do include**: Only what the next instance needs that it cannot infer from existing memory.
- Write for a future instance of yourself that has memory access but zero conversation history.
- Be concise but complete on what matters right now.