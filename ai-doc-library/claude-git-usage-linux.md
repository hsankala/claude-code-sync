# Git Usage Guidelines

## Claude Code's Git Access

Git is installed on this server (`/usr/bin/git`, version 2.43.0). Claude Code has access to one local repository only:

- **Local repo:** `/home/operator/project`
- **Remote:** `git@github.com:operator/main-server.git`
- **No SSH key is present on this server** — Claude Code has no ability to push to GitHub

## User Workflow

**Claude Code's responsibility:**
- Stage files and commit to the local repository only
- Confirm commit message with the user before committing
- Never attempt to push to any remote repository

**User's responsibility:**
- User connects to the server's local repo via Git Extensions on Windows
- User is a visual Git user — Git Extensions is their preferred tool, not the command line
- User reviews all local commits in Git Extensions before pushing
- User handles all pushes to the remote GitHub repository

**In plain terms:** Claude commits locally. The operator pulls those commits down to their Windows machine, reviews them visually in Git Extensions, then pushes to GitHub when satisfied.

## CRITICAL: No Claude Code Attribution

**NEVER include any attribution in commit messages such as:**
- "Generated with Claude Code"
- "Co-Authored-By: Claude Sonnet"
- Any variation of Claude/AI attribution whatsoever

**Strip these completely from all commit messages.**

## Commit Message Format

```bash
git commit -m "Commit title here

- First key change
- Second key change
- Additional detail if needed"
```

**Rules:**
- First line: clear, concise title (imperative tense — "Add", "Fix", "Update")
- Blank line after title
- Bullet points for detail using dashes
- No emojis unless explicitly requested
- No AI attribution

## Key Principles

- Local commits only — no pushing under any circumstances
- Always confirm the commit message with the user before committing
- Work with Linux paths (`/home/operator/...`) at all times
- No Claude Code attribution in any commit messages
