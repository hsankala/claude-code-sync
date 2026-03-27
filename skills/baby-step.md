---
name: baby-step
description: >
  Activates Baby Step Mode — a structured, incremental approach to implementing changes one small step at a time.
  Use this skill whenever the user says "baby step", "baby step mode", "let's baby step this", "run me through the baby steps",
  or asks to approach a task incrementally, carefully, or step-by-step. Works across ALL project types — web development,
  systems administration, Rust/compiled code, databases, DevOps, configuration, refactoring, or anything else.
  Baby Step Mode is about breaking work into manageable, reviewable chunks and reporting progress clearly after each one.
  Trigger this skill even when the user just implies they want a careful, staged approach.
---

# Baby Step Mode

## What This Is

Baby Step Mode is a **lightweight, flexible framework** for breaking work into small, reviewable increments.

It's not a rigid protocol — it's a working style. The steps, format, and pacing should adapt to whatever the task actually needs. Use this as a strong default, not a straitjacket.

It works across any domain:

- Web or app development
- Systems and server administration
- Compiled languages (Rust, Go, C++)
- Databases and migrations
- Config and infrastructure changes
- Refactoring or debugging sessions
- Anything that benefits from staged progress

---

## Core Principles

**One thing at a time.** Each Baby Step does one meaningful unit of work — a single file, a single config change, a single function, a single command. If a step feels too large, break it down further.

**Plan first, then act.** Before starting, outline the full list of Baby Steps. This gives a shared map of where we're going. Steps can be revised mid-flight as reality dictates — that's expected and fine.

**Report after each step.** After completing a step, use the reporting format below. This keeps the human in the loop and makes it easy to catch problems early.

**Ask before proceeding.** Don't chain steps automatically. After each report, wait for the go-ahead before moving to the next step — unless the user has explicitly said to keep going.

---

## Step Planning

When entering Baby Step Mode, start by:

1. Understanding the goal
2. Proposing a numbered list of Baby Steps to get there
3. Asking for confirmation before starting Step 1

The initial plan is a **living document** — steps may be added, removed, or reordered as the work unfolds. That's not failure, that's good engineering.

**Examples of well-scoped Baby Steps:**

- Install a single dependency
- Create or edit one file
- Write one function or component
- Add one route, one rule, one record
- Run one diagnostic command
- Enable or configure one service
- Write one test

**Examples of steps that need breaking down further:**

- "Set up the full auth system" → split into: schema, model, routes, middleware, tests
- "Configure the server" → split into: install, config file, firewall, test
- "Build the dashboard" → split into: layout, data fetch, chart component, wire-up

---

## Reporting Format

After each Baby Step, report using this structure. Adapt labels as needed for the domain — don't force server terminology onto a frontend task, for example.

```
## 📝 What Was Done
-------------------
**Baby Step [N]: [Short description]**

📁 **Target:** `file, component, service, or system affected`
🔧 **Action:** What was done
🧪 **Verification:** How we know it worked (command output, test result, visual check, etc.)

**Changes:**
- [Change 1]
- [Change 2]

## 🎯 Progress
--------------
✅ Step 1: [Done]
✅ Step 2: [Done]
⏳ Step 3: [Pending]
⏳ Step 4: [Pending]

## 💡 Next Step
---------------
**Proposed Baby Step [N+1]:** [Clear description of what's next]
- What it will do
- Any files or components it will touch
- Any risk or caveat worth flagging
```

**Formatting notes:**

- Use ✅ for completed, ⏳ for pending
- Use ⚠️ before any step that could cause downtime, data loss, or is hard to reverse
- Keep bullet points short and scannable
- Always state the target — what file, function, service, or component is being touched

---

## Tone and Flexibility

This is a **collaborative working mode**, not a bureaucratic checklist. The format exists to keep things clear and safe — not to slow things down unnecessarily.

- If steps are trivial and low-risk, the reports can be lighter
- If the project context is already well established, skip restating it every time
- If the user is moving fast and trusts the process, adapt pacing accordingly
- Use judgment. The goal is clear, incremental progress — not ceremony for its own sake.