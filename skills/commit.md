---
name: commit
description: Stage and commit code changes with clean atomic commits. Use when the user says "commit", "git commit", "commit my changes", "stage and commit", or asks to save/record their work to git. Also trigger when the user has finished a task and needs to commit the result.
effort: medium
disable-model-invocation: true
allowed-tools:
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git add:*)
  - Bash(git commit:*)
---

# Git Commit Guidelines

---

## 🔒 ATTRIBUTION RULE (PARAMOUNT)

**Never include or suggest any attribution line** such as:
`🤖 Generated with [Claude Code](https://claude.ai/code)`

Strip completely from any commit message or summary output. No exceptions.

---

## 🎯 COMMIT PHILOSOPHY

### Atomic Commits — Consider Carefully

- **One logical change = one commit** (this does NOT mean one file per commit)
- **A logical change often spans multiple files** — "Update authentication system" affecting 3 files = ONE commit
- **Distinct logical changes = separate commits** — "Fix login bug" + "Add profile feature" = TWO commits

### When to Consider Multiple Commits
- Changes affect genuinely different features or subsystems
- Bug fixes mixed with unrelated feature work

### When a Single Commit Makes Sense
- All changes are tightly coupled for one feature/fix
- Splitting would be artificial — don't swim upstream to force separation

### No Partial Staging
**Whole files only.** No hunking, no selective line commits. If a file has changes, the entire file gets staged together.

---

## 📋 COMMIT WORKFLOW

### 1. Detect All Changes
Identify all uncommitted file changes in the current working project.

### 2. Consider Atomic Commits
- Look at what files changed and why
- Genuinely separate logical changes → propose multiple commits
- One coherent change across multiple files → one commit is fine

### 3. Generate Summary of Changes

```
### SUMMARY OF CHANGES

**Files changed:**
- `path/to/file.php` — modified
- `assets/js/script.js` — added
- `old-file.txt` — deleted

**Developer summary:**
[Brief description of what changed and why]

**Proposed commits:** [1 / 2 / 3 — state how many]
```

### 4. Present Commit Proposal(s)

For **each** proposed commit, show:

```
---
**Commit 1 of X:**

Title: [SUGGESTED COMMIT TITLE]

Description:
- [First key change]
- [Second key change]

Files included:
- file1.php
- file2.js
---
```

### 5. Await User Confirmation

```
Would you like to:
- 1: [Proceed] — Execute commit(s) as proposed
- 2: [Edit] — Modify the message(s)
- 3: [Combine] — Merge into fewer commits
- 4: [Split] — Break into more commits
- 5: [Cancel] — Abort
```

### 6. Execute Only After Confirmation
- Stage whole files (no partial staging)
- Commit to the current local branch
- **Never push to remote**

---

## 📝 COMMIT MESSAGE FORMAT

### Title
- Imperative mood ("Add feature" not "Added feature")
- Under 72 characters
- Clear and specific

### Description (when needed)
- Bullet points for distinct changes
- Explain *what* and *why*, not *how*

---

## 🚨 TLDR — NON-NEGOTIABLE RULES

- 🔒 **Attribution:** Never include. Strip completely. No exceptions.
- 📍 **Local only:** Never push to any remote.
- 📦 **Whole files only:** No partial staging.
- 🧩 **Atomic commits:** Use judgment — consider splitting, but don't force it.