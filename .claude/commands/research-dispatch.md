---
name: research-dispatch
description: >
  Generates a well-crafted prompt to hand off to a web-based LLM (Claude.ai, ChatGPT, Gemini,
  Grok, etc.) for research, investigation, or problem solving — leveraging their web search
  capability and speed. Trigger this skill when the operator says things like: "create a prompt
  for the web AIs", "farm this out", "build me a prompt to take to Claude web", "I want to ask
  another AI about this", "research dispatch", "create a handoff prompt", or any variation of
  wanting to package a problem up for a browser-based model. Produces a clean, copy-paste-ready
  prompt and guidance on parsing the results when they come back.
---

# Research Dispatch

## What This Skill Does

Packages a problem into a well-structured prompt ready to hand to a web-based LLM.

Web LLMs are fast, have live web search, and excel at broad research and investigation. This skill
leverages that — generating a prompt that gives them enough context to work effectively, room to
search thoroughly, and instructions to return findings in a format that feeds straight back into
this session.

When the operator pastes the results back, this skill also guides how to parse and evaluate them.

---

## Process

### Step 1 — Understand the Problem

Read the operator's description carefully. If it's ambiguous or underspecified, ask one clarifying
question before generating. A vague prompt produces vague results.

### Step 2 — Assess Context Needs

Decide whether broader project context would genuinely help the web LLM.

**Don't suggest the web-ai-doc if:**
- The problem is self-contained and all necessary context fits cleanly in the prompt itself
- Adding project scope would dilute focus rather than add value
- It's a specific, tight question where broader context would just introduce noise

**Do suggest the web-ai-doc if:**
- The problem is architectural or spans multiple parts of the codebase
- The web LLM needs to understand the stack, structure, or history to give useful answers
- Without it, the prompt would require a lot of inline explanation to orient them

If the web-ai-doc would help, flag it clearly:

```
╭─ NOTE ────────────────────────────────────────────────────────╮
│  This prompt would benefit from project context. Consider     │
│  providing your web-ai-doc alongside it so the LLM            │
│  understands the stack and structure.                         │
╰───────────────────────────────────────────────────────────────╯
```

### Step 3 — Generate the Prompt

Compose the prompt naturally — don't follow a rigid template. Shape it to what the problem actually
needs. Every good dispatch prompt covers these things, in whatever form fits:

- **Orientation** — enough background for the web LLM to understand the context without being overwhelmed
- **The problem or question** — precise and specific; if there are multiple angles, state them clearly
- **Investigation guidance** — give them a leash. Tell them to follow leads, pursue rabbit holes, search
  broadly. A thorough answer is more valuable than a fast one
- **Response format** — instruct them to structure their response clearly, lead with a summary of
  findings, support with detail and reasoning, include relevant code examples where useful, and
  list any helpful links at the bottom in a clearly labelled section
- **Recipient context** — make clear the response will be handed back to Claude Code (a coding AI
  with full project access) for evaluation and action

Wrap the finished prompt in a clean copy-paste block:

```
┌─────────────────────────────────────────────────────────────┐
│  📋 RESEARCH DISPATCH — COPY & PASTE                        │
└─────────────────────────────────────────────────────────────┘

[generated prompt here]

┌─────────────────────────────────────────────────────────────┐
│  END OF PROMPT                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Parsing the Response

When the operator pastes web LLM results back into the session, evaluate them critically.

**Stand on your own feet.** You are closer to the codebase than any web LLM. You have full project
context, direct file access, and a deeper understanding of the actual problem. Their response is
useful research input — not a directive.

**Look for corroboration.** Where multiple sources or responses point in the same direction, that's
a strong signal worth taking seriously. Where they diverge or contradict, treat with caution and
apply your own judgment.

**Mine for gold nuggets.** Web LLMs may surface relevant library changes, known bugs, community
discussions, or approaches you hadn't considered. Extract what's genuinely useful. Discard what
doesn't fit the actual codebase and problem.

**Be appropriately sceptical.** They are working from a thin slice of context. They don't know the
full architecture, the constraints, or the history of decisions already made. Weigh their
suggestions against what you actually know about this project.

---

## Principles

**Tight context beats broad context.** Give the web LLM what they need — no more. Scope creep in
the prompt leads to unfocused responses.

**Give leash.** Explicitly encourage thorough searching. Web search is their superpower — the prompt
should invite them to use it properly.

**The response comes back to you.** Claude Code receives the output and has the final say. Web LLM
responses inform the work — they don't direct it.