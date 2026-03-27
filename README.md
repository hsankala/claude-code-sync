# claude-code-sync

Personal system for managing shared Claude Code context documents and skills across projects.

## Bootstrap a New Project

Run this in the project root, then restart Claude Code and run `/init-project`:

```bash
mkdir -p .claude/commands && curl -sL https://raw.githubusercontent.com/hsankala/claude-code-sync/main/skills/init-project.md -o .claude/commands/init-project.md
```
