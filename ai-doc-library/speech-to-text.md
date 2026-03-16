# Speech-to-Text Input Guidelines

## Overview

The operator primarily uses speech-to-text software for input. This means text will frequently contain missing punctuation, inconsistent phrasing, homophones, and occasional spelling errors. This document defines how the AI assistant should handle these artifacts efficiently.

## Core Interpretation Rules

1. **Proceed when confident** — If you're reasonably certain of the intended meaning within context, act on it. Don't stall for clarification on obvious speech-to-text artifacts.
2. **Clarify when genuinely uncertain** — If context doesn't resolve ambiguity, ask. Don't guess blindly.
3. **Never overcorrect** — Favor the most contextually reasonable interpretation. Don't rewrite or reinterpret beyond what's needed.
4. **Track conversation patterns** — In longer sessions, remember terminology and concepts already established. Recognize later references even if slightly garbled.

## Common Speech-to-Text Patterns

### General Issues
- **Missing punctuation**: Sentences run together, missing capitals
- **Homophones**: to/too/two, there/their/they're, write/right, root/route
- **Run-on phrasing**: Commands and explanations may blend without clear breaks

### Admin/DevOps-Specific Misinterpretations

| Speech-to-Text Output | Likely Intended Meaning |
|---|---|
| "engine X" or "engine ex" | nginx |
| "my sequel" or "my SQL" | MySQL |
| "maria D B" | MariaDB |
| "SS H" or "assess H" | SSH |
| "SS L" or "assess L" | SSL |
| "docker compose" vs "docker-compose" | Context-dependent (v1 vs v2) |
| "let's encrypt" | Let's Encrypt |
| "power shell" | PowerShell |
| "cron tab" or "chrome tab" | crontab |
| "DNS" or "D N S" | DNS |
| "pseudo" or "sue do" | sudo |
| "post gress" or "post grey" | PostgreSQL |
| "lara vel" or "laravel" | Laravel |

This table is illustrative, not exhaustive. Apply the same pattern-matching logic to any admin/infrastructure terminology that gets mangled by speech-to-text.

## Processing Instructions

When processing input:

1. Consider the current conversation context and what infrastructure/task is being discussed
2. Assume technical interpretations over literal ones — this is a server administration environment
3. Match against previously used terminology in the session
4. If a command or path is referenced but slightly garbled, reconstruct the most likely version
5. When multiple valid interpretations exist and it materially affects the outcome, ask

## Key Principle

Efficient collaboration. Proceed when confident, clarify when uncertain. The goal is momentum, not perfection of input parsing.