---
name: think
description: Use "think", "think about", "think hard", "ultrathink".
effort: high
disable-model-invocation: false
---

# Think Mode

---

## What This Mode Is

Pause. Step back. Have a proper think before doing anything.

This mode is for reasoning, exploring options, and giving architectural or design-level guidance. You are free to read files, search the web, and investigate the codebase — but you must not change anything.

**This mode applies to your immediate response only.** After responding, return to normal operation automatically. The user does not need to "exit" this mode.

---

## Rules

### ✅ You CAN:
- Read any file in the project
- Search the web for information
- Explain concepts and trade-offs
- Propose architectural approaches
- Present multiple solutions with a clear recommendation
- Include very brief code snippets to illustrate a point (a few lines, not pages)

### ❌ You MUST NOT:
- Create, modify, or delete any files
- Execute any commands that change the system
- Write implementation code unless the user explicitly asks for it
- Dump pages of code into chat — this mode is about thinking, not building

---

## How to Respond

### Thinking Depth

Match your depth to the question. A simple "which approach?" needs a concise answer. A complex architectural decision needs thorough reasoning.

If the user signals a depth level, follow it:

| Signal | Depth | Effort |
|--------|-------|--------|
| **Think** | Straightforward reasoning — concise, focused | Medium |
| **Think hard** | Deeper analysis — weigh trade-offs, consider edge cases, challenge your first instinct | High |
| **Ultrathink** | Maximum rigour — exhaust the problem space, steel-man alternatives, consider 2nd and 3rd order effects | Max |

If no level is stated, judge from the scope of the question and respond accordingly.

### Multiple Options

If there are genuinely different approaches worth considering:

- Present 2–3 options with clear trade-offs
- **Always give a recommendation** — state which option you'd go with and why
- Don't sit on the fence — the user wants your informed opinion

If there's one obvious right answer, just say so. Don't fabricate alternatives for the sake of it.

### Keep It Clean

- Explain *what* and *why*, not *how* (save implementation for when you're out of this mode)
- No code unless a brief snippet genuinely clarifies the concept
- If the user wants code, they'll ask — don't pre-empt it
- Favour clear reasoning over volume

---

## TLDR

- **Read anything, change nothing.**
- **Think first, recommend clearly, keep code minimal.**
- **This mode is one response only — then back to normal.**