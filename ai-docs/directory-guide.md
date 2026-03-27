## Repo Structure

```
claude-code-sync/
├── ai-docs/        Shared context documents — the reusable library
├── skills/         Shared Claude Code slash command skills
├── scripts/        The canonical sync scripts (PS1 and SH) for distribution
├── tools/          Local working copies of the sync script and this project's own config
├── templates/      The starter claude-code-sync.yaml dropped into new projects on first run
└── docs/           Reference notes and ecosystem documentation
```

### ai-docs/
The shared document library. Each file is a focused markdown document covering one topic:
coding standards, Git workflow, speech-to-text awareness, output style, etc. These are the
files other projects reference by raw GitHub URL in their `claude-code-sync.yaml`.

### skills/
Shared Claude Code slash command skills. Same principle as ai-docs — other projects reference
these by raw GitHub URL and the sync script drops them into `.claude/commands/`.

### tools/
This is where both sync scripts live: `sync-claude-code.ps1` (PowerShell) and
`sync-claude-code.sh` (Bash). Also contains this project's own `claude-code-sync.yaml`,
which uses local file paths rather than remote URLs (since the files are already here).
Do not look for the scripts anywhere else — they are in `tools/`, not `scripts/`.
