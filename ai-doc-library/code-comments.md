# Commenting Style Guide

---

> **This document is language-agnostic.** All examples use `/* */` block comment syntax with pipe characters for illustration purposes only. Adapt comment delimiters to whatever the file and language require — `#` for shell scripts and Python, `//` for C#, JavaScript and others, `<!-- -->` for HTML, and so on. The structures, conventions, and intent described throughout apply regardless of the characters used. Always use context-specific knowledge of the language and environment you are working in.

---

## Core Philosophy

Comments exist for two audiences: **the human orchestrator** reading and reviewing the code, and **the AI agent** building and maintaining it. Good comments serve both.

**The golden rule:** If a future reader has to overly think to understand intent, the code is under-commented. If the comment just restates what the code already says clearly, delete it.

- Comment the **why**, not the **what**
- Prefer clarity over brevity — slight over-commenting is acceptable
- Comments should still make sense **6+ months from now** — describe the enduring truth about the code, not the circumstances of the moment it was written. Avoid context-specific notes that only make sense today ("fixed because X was happening") — those belong in a commit message, not the codebase
- Structure beats verbosity — bullets and sections beat walls of text
- Verbose, self-documenting names reduce the *need* for inline comments

---

## Section Banner Headers

Use large visual banners to divide code into logical regions. Consistent formatting across all projects means headers always look the same — this is intentional and worth being prescriptive about.

**Standard width:** 80 characters
**Text indent:** 5 spaces from the left border character
**Border character:** dashes (`-`) throughout — not equals signs

### Primary File Header

Use on any file that owns a named responsibility or domain concept — classes, services, controllers, modules, scripts, jobs. Skip it for thin wrappers, simple components, config files, and obvious plumbing where the filename says it all.

The header exists primarily for the agentic coder — it provides immediate orientation when dropping into a file cold, and constrains scope so the AI knows what this file owns and what belongs elsewhere.

```
/*
|------------------------------------------------------------------------------
|  ComponentOrModuleName
|------------------------------------------------------------------------------
|  Purpose:
|     One or two sentences. What is this file for? What problem does it solve?
|     Where does it fit in the overall structure? Be specific — "manages X" is
|     better than "handles stuff related to X".
|
|  Responsibilities:
|     - What this file owns — be explicit about the boundary
|     - Each bullet is a discrete thing this file is responsible for
|     - Implicitly, anything NOT listed here belongs somewhere else
|     - Keep the list honest — if it's doing too many things, that's a signal
|
|  Design Notes:
|     - Non-obvious decisions and why they were made
|     - Hard constraints that must never be violated
|     - Dependencies or integrations worth flagging
|     - Side effects — what does this touch outside itself?
|     - Anything an AI or developer needs to know that isn't obvious from the code
|     - Omit this section entirely if there is nothing meaningful to say here
|
|------------------------------------------------------------------------------
*/
```

**Optional additional sections:** If a file has something important to communicate that doesn't fit neatly into the three sections above, add a clearly named section beneath Design Notes. This should be rare — the three sections above cover the vast majority of cases — but the door is open when genuinely needed.

**Reminder:** All examples below use `/* */` syntax for illustration. Use the correct comment delimiter for the language you are working in.

### Section Headers — With Description

Use when the section benefits from a brief explanation of its purpose, flow, or scope.

```
/*------------------------------------------------------------------------------
 |  Section Title Here
 |------------------------------------------------------------------------------
 |  Brief description of what this section covers.
 |
 |  Flow (if applicable):
 |     1. First step
 |     2. Second step
 |     3. Third step
 |
 ------------------------------------------------------------------------------*/
```

For `#`-comment languages:

```
#------------------------------------------------------------------------------
#  Section Title Here
#------------------------------------------------------------------------------
#  Brief description of what this section covers.
#
#  Notes:
#     - Any relevant detail
#
#------------------------------------------------------------------------------
```

### Section Headers — Title Only

Use when the title alone is self-explanatory and no further description is needed. The header still provides clear visual delineation and grouping.

```
/*------------------------------------------------------------------------------
 |  Section Title Here
 ------------------------------------------------------------------------------*/
```

For `#`-comment languages:

```
#------------------------------------------------------------------------------
#  Section Title Here
#------------------------------------------------------------------------------
```

**Rules for section headers:**
- Use for *conceptual* groupings — pipelines, strategies, workflows, grouped methods
- Titles should be explicit — avoid vague labels like "Helpers", "Misc", "Utils", "Stuff"
- Choose title-only vs with-description based on whether context genuinely adds value

### Sub-Section Headers

Use when a section contains multiple strategies, branches, or distinct phases that benefit from further visual separation.

```
/*
 |==============================================================================
 |  Sub-Section Title
 |==============================================================================
 |  Description of what this sub-section handles.
 |
 */
```

### Micro-Region Markers

Use inside long functions or methods (roughly 30+ lines) to break up the internal flow into named chunks.

```
// -------------------------------------------------------------------------
//     Input Validation
// -------------------------------------------------------------------------
```

```
// -------------------------------------------------------------------------
//     State Transition Guard Checks
// -------------------------------------------------------------------------
```

**Rules:**
- Dashes only — consistent with all other header types
- 5 spaces before the label text
- Keep labels short and descriptive

---

## Temporary Code Marking

Any code that is temporary — scaffolding, debugging aids, workarounds, or placeholders — must be explicitly marked so it doesn't accidentally survive into production.

```
// ⚠️ TEMPORARY — Remove before production
// Reason: Bypassing auth check during local dev setup
// TODO: Remove once [condition] is resolved
```

For larger temporary blocks, use a banner:

```
/*------------------------------------------------------------------------------
 |  ⚠️  TEMPORARY BLOCK — MUST BE REMOVED
 |------------------------------------------------------------------------------
 |  Reason:  [Why this exists]
 |  Added:   [When / context]
 |  Remove:  [Condition that triggers removal]
 |
 |  If this is still here and the above condition is met,
 |  this block should be deleted entirely.
 |
 ------------------------------------------------------------------------------*/
```

**Rule:** Never leave temporary code without a clear marker. When in doubt, be more explicit, not less.

---

## Function and Method Documentation

### When to Write a Docblock

✅ **Always document:**
- Business logic and domain rules
- Public API methods
- Methods with side effects (emails, audit logs, webhooks, external calls)
- Anything with non-obvious behaviour or edge cases
- Methods that throw exceptions

✅ **Usually document:**
- Private/protected methods in service or utility classes where intent isn't obvious
- Methods where parameters need explanation
- Anything that took time to figure out — document it so nobody has to figure it out again

❌ **Skip the docblock:**
- Trivial getters/setters where the name says it all
- Standard framework convention methods with no complex logic
- Obvious single-line operations

**When in doubt:** Add it. Over-commenting slightly is always better than confusion.

### Docblock Format

Adapt to the language's standard (`/** */` for PHP/JS/Java, `"""` for Python, `///` for C#), but the *content* follows the same pattern:

```
/**
 * Short description of what this method does.
 *
 * Why this exists:
 *  - Reason one
 *  - Reason two (especially if it replaced a naive approach)
 *
 * Edge cases:
 *  - Describe any non-obvious behaviour
 *  - Document what happens at the boundaries
 *
 * Side effects:
 *  - List anything this method does beyond returning a value
 *
 * @param  Type  $paramName   Description
 * @return Type               Description
 * @throws ExceptionType      When this is thrown
 */
```

**Key rule:** Explain *why* this method exists. Document edge cases. Call out side effects.

---

## Inline Comments

Use inline comments for:

- **Non-obvious decisions** — why a particular approach was chosen over the obvious one
- **Workarounds** — especially when dealing with third-party quirks, platform limitations, or known bugs
- **Multi-step logic** — a short note before each logical chunk inside a longer function
- **Anything that took time to figure out** — if it wasn't obvious when writing it, it won't be obvious to the next reader

```javascript
// Add visitorData to context if available — helps avoid bot detection on some endpoints
if (visitorData) {
    requestBody.context.client.visitorData = visitorData;
}
```

### What NOT to Comment

```
// ❌ States the obvious — adds zero value
// Increment the counter
$counter++;

// ❌ Just restates the method name
// Get the user
$user = getUser();

// ✅ Explains the non-obvious behaviour
// Returns null if the user has never had a subscription.
// Cancelled subscriptions still in grace period return with status 'cancelled'.
$subscription = getActiveSubscription($userId);
```

---

## Structured Long Comments

When a comment needs to explain a complex decision, structure it — not a wall of text.

```javascript
// ⚠️  IMPORTANT: Use WEB client, not ANDROID client for this request.
//
// After testing both approaches, only the WEB client returns the microformat
// object needed for upload date extraction:
//
//  ANDROID client:
//   ✅ Transcript extraction works
//   ❌ No microformat object in response
//   ❌ No upload date available
//
//  WEB client (current):
//   ✅ Transcript extraction works
//   ✅ microformat.playerMicroformatRenderer present
//   ✅ Upload date available via publishDate field
```

---

## Emoji Usage in Comments

Emojis are encouraged in code comments and documentation. Used well, they make comments **faster to scan** and easier to parse at a glance — particularly in lists, status indicators, and warnings. Think of them as functional markers, not decoration.

A ✅ or ❌ in a comparison list is worth more than a bullet point. A ⚠️ on a warning jumps out immediately. A 🐛 next to a known issue is impossible to miss.

| Emoji | Use for |
|-------|---------|
| ✅ | Something that works, is valid, or is confirmed |
| ❌ | Something that doesn't work, is invalid, or should be avoided |
| ⚠️ | Warning, important caveat, or gotcha |
| 🐛 | Known bug or limitation |
| 🔧 | Configuration or setup note |
| 💡 | Non-obvious tip or insight |
| 🚨 | Critical — must not be missed |
| 📝 | Documentation note |
| 🔒 | Security-related |
| 🚧 | Work in progress |

Use common, widely-supported Unicode emoji for maximum compatibility across platforms and editors.

**One important exception:** Avoid emojis in **log output** — console logs, file logs, system logs. Log output may pass through pipelines, monitoring tools, or systems with encoding constraints where emoji can corrupt entries or display as garbage. Keep log strings plain text.

---

## Console and Debug Logging

Where debug or trace logging is used, consistent text prefixes make logs scannable and filterable:

```javascript
console.log('FLOW: Starting payment intent creation for:', userId);
console.log('DEBUG: Full Stripe response:', JSON.stringify(response));
console.warn('WARN: Subscription state mismatch — falling back to Stripe lookup');
console.error('ERROR: Payment intent creation failed:', errorCode);
```

The goal is logs that can be read and filtered at a glance. Consistent prefix style matters more than which specific convention is chosen — pick one and stick to it across the project.

---

## API and Integration Documentation

For projects that expose or consume external interfaces — REST endpoints, webhooks, message queue handlers — a header documenting the contract pays dividends for future maintenance. Not every project needs this, but where APIs exist it should be used.

```
/*------------------------------------------------------------------------------
 |  API Endpoint: [Short Name]
 |------------------------------------------------------------------------------
 |  Route:   POST /api/v1/endpoint-path
 |
 |  Consumer:
 |     Who or what calls this (e.g. mobile app, desktop client, cron job)
 |
 |  Purpose:
 |     What this endpoint does and why it exists
 |
 |  Authentication:
 |     What auth is required
 |
 |  Response Codes:
 |     200  Success — describe payload
 |     401  Unauthorised — condition
 |     402  Payment required — condition
 |     422  Validation error — condition
 |
 ------------------------------------------------------------------------------*/
```

---

## Applying These Guidelines

These are **best practice guidelines**, not a rigid checklist. Apply them with judgment:

- A simple utility script does not need a full file header
- A 5-line method does not need a docblock if the name explains it completely
- Over-commenting obvious code is noise, not signal

The test is always: **would a capable developer — or a fresh AI session — understand the intent and any non-obvious decisions without having to dig through the implementation?**

If yes, the comments are doing their job. If no, add more.

---

## Quick Reference

| Comment Type | When to Use |
|---|---|
| File header | Major classes, services, controllers, scripts |
| Section banner (with description) | Logical regions where context adds value |
| Section banner (title only) | Logical regions where the title is self-explanatory |
| Sub-section header | Multiple strategies or branches within a section |
| Micro-region marker | Inside long methods (30+ lines) |
| Temporary marker | Any code that will be removed — always |
| Method docblock | Non-trivial logic, side effects, edge cases, public APIs |
| Inline comment | Non-obvious decisions, workarounds, multi-step logic |
| API endpoint header | Projects with external interfaces or integrations |