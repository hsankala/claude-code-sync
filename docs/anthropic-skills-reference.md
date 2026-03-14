# Agent Skills Ecosystem — Reference Notes

> As of early 2026. Fast-moving space — treat as directional, verify before acting.

---

## Key URLs

| Resource | URL | Purpose |
|----------|-----|---------|
| Anthropic official skills | https://github.com/anthropics/skills | Source for high-quality, vendor-published skills |
| Tessl registry | https://tessl.io/registry/skills/github/anthropics/skills/ | Quality-evaluated skill registry (credible — Guy Podjarny, Snyk founder) |
| SkillsMP | https://skillsmp.com | Community discovery — 400k+ indexed skills, good for finding what exists |

---

## What Are Skills?

Reusable `SKILL.md` files that give AI coding agents (Claude Code, Cursor, Codex CLI, Copilot, etc.)
procedural knowledge for specific tasks. Open standard originated by Anthropic (December 2025),
now cross-agent. Same file format across all tools.

---

## The Ecosystem

**skills.sh (Vercel)** — the install CLI:
```bash
npx skills add anthropics/skills --skill docx
```
Auto-detects your agent and drops the skill into the right directory. Emerging de facto standard.

**SkillsMP** — discovery/search. Not affiliated with Anthropic. Good for finding skills, not a
quality signal on its own.

**Tessl** — quality evaluation scoring. Paste a GitHub skill URL, get a trust score. Smaller
registry than SkillsMP but higher signal-to-noise.

---

## Suggested Workflow

```
1. DISCOVER  → Browse skillsmp.com or github.com/anthropics/skills
2. CHECK     → Paste URL into tessl.io to see quality score
3. INSTALL   → npx skills add owner/repo  (or copy manually)
```

---

## Where Skills Install

For Claude Code:
- **Project-level:** `.claude/skills/`
- **Global:** `~/.claude/skills/`

---

## Quality Guidance

> "80% of skills in skills.sh are AI slop. Go for the vendor-provided ones." — community feedback

Prefer in order:
1. `anthropics/skills` — Anthropic official
2. `vercel-labs/agent-skills`, `microsoft/agent-skills` — other vendor-published
3. Community skills — review before using, same as any open-source code

---

## Relevance to This Project

- `claude-code-sync` syncs skills via URL entries in `claude-code-sync.yaml`
- Skills from `anthropics/skills` or other trusted sources can be referenced directly as remote URLs
- Tessl quality scores are a useful filter before adding a community skill to a project's config
