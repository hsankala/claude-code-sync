# MCP Servers

Instructions for AI agents on available MCP servers and how to use them.

---

## Important: Deferred Tool Schemas

MCP tools are deferred — only their names are loaded at session start, not their full parameter schemas. **Before calling any MCP tool for the first time in a session, fetch its schema:**

```
ToolSearch: "select:mcp__<server>__<tool-name>"
```

Attempting to call a tool without its schema will produce an input validation error.

---

## Context7 — Live Library Documentation

Use Context7 to fetch up-to-date documentation and code examples for any library, framework, SDK, API, or CLI tool. Use it even for well-known libraries — training data may be outdated. Prefer it over web search for library docs.

**Do not use for:** general programming concepts, refactoring, writing scripts, debugging business logic.

### Tools

**`mcp__context7__resolve-library-id`**

Resolves a plain library name to a Context7-compatible library ID. Required before `query-docs` unless you already know the ID.

| Parameter | Required | Description |
|---|---|---|
| `libraryName` | ✅ | Plain name, e.g. `"react"`, `"next.js"` |
| `query` | ✅ | Your actual question — used to rank results by relevance |

Returns multiple candidates. Pick by: highest benchmark score, `High` source reputation, best name match. If the user specifies a version, use the versioned ID format `/org/project/version`.

**`mcp__context7__query-docs`**

Fetches actual documentation snippets and code examples.

| Parameter | Required | Description |
|---|---|---|
| `libraryId` | ✅ | Context7 ID, e.g. `/vercel/next.js` |
| `query` | ✅ | Specific question — be precise, not vague |

Be specific with `query`. "How to configure middleware in Express" beats "middleware".

### Workflow

```
1. resolve-library-id  →  get the library ID
2. query-docs          →  fetch the docs using that ID
```

Skip step 1 if the library ID is already known — saves one call.

**Limits:** No more than 3 calls per tool per question.

### Example

```
resolve-library-id:
  libraryName: "next.js"
  query: "How to use the App Router"

→ returns /vercel/next.js (benchmark: 88.6, High reputation)

query-docs:
  libraryId: "/vercel/next.js"
  query: "How to use the App Router"

→ returns documentation snippets and code examples
```
