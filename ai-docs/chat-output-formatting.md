# Chat Output Formatting

---

## Why This Exists

The operator scans responses quickly. Long walls of text, uniform bullet lists, and undifferentiated paragraphs all blur together. The goal is not decoration — it's **readability at scanning speed**.

Format to support how the operator reads:

- Glance at structure first, then dive into detail
- Pick up headings, key points, and warnings at a glance
- Distinguish sections visually without needing to read every word

Good formatting makes information land faster. Bad formatting (or no formatting) makes it invisible.

---

## Principles

**None of these are hard rules.** They're loose examples of the kind of thinking that helps the operator read your responses more easily. Think of them as prompts for your own creativity, not a checklist to follow. If a plain one-liner answers the question best, write a plain one-liner. If a solid block of prose is the right call, go for it. If something not listed here would work better, use it. The goal is never "apply formatting" — it's "make this response land clearly." Formatting should support your response, never take over from it. The moment formatting becomes the thing the operator notices instead of the content, you've overdone it.

### White Space

White space is one of the most important tools you have. Use blank lines generously between distinct points, even within the same section. If two thoughts are related but separate, put a line between them — don't pack them into one dense paragraph. The operator scans line by line, and breathing room between ideas lets each one register before the next arrives. A response with good white space and no other formatting is better than a response with every fancy symbol but no breathing room.

### Write in Short Paragraphs

Two to four sentences per paragraph. If a paragraph is getting long, break it. White space is free — use it.

### Delineate Sections

Use headings and thin line separators to break responses into scannable sections. If your response covers more than one topic or step, give each one a heading. Don't make the reader guess where one idea ends and another begins.

### Section Headers

When a response covers three or more distinct areas, give each one a full-width header treatment — a separator line, the section title, another separator line:

```
─────────────────────────────────────────────────────────────────────
  SECTION TITLE
─────────────────────────────────────────────────────────────────────
```

This creates a proper chapter structure that's immediately scannable when scrolling. The operator can glance at the section headers alone and understand the whole shape of a response before reading a word.

A plain closing separator (no title) can optionally close the final section before the bottom banner — signals "this is done" clearly.

Don't force it onto short single-topic responses. A two-paragraph answer doesn't need chapters. Use it when the response genuinely has separate sections worth navigating between.

### Tables for Comparison

When comparing options, listing properties, or presenting structured data — use a table. Don't describe in prose what a table shows at a glance.

```
┌──────────────┬────────────┬────────────┐
│ Option       │ Speed      │ Complexity │
├──────────────┼────────────┼────────────┤
│ HTTPS clone  │ Fast       │ Low        │
│ SSH clone    │ Fast       │ Medium     │
│ SSHFS mount  │ Slow       │ High       │
└──────────────┴────────────┴────────────┘
```

Don't table everything. A two-item list doesn't need a table. Use judgment.

### Bullet Points

Use the filled arrow `►` as the default bullet. Nest where it naturally makes sense:

```
► Primary point
  ◆ Supporting detail
    · Granular note
```

Bullets are for discrete items. If your content is a flowing explanation, write it as prose — don't force it into bullets.

### Callout Boxes

Use for warnings, important notes, or anything the reader must not miss:

```
┏─ WARNING ────────────────────────────────────────┓
┃  This will restart the service.                  ┃
┃  Expect ~5 seconds of downtime.                  ┃
┗──────────────────────────────────────────────────┛
```

```
╭─ NOTE ───────────────────────────────────────────╮
│  This is a read-only operation.                  │
╰──────────────────────────────────────────────────╯
```

Use sparingly. If everything is in a box, nothing stands out.

### Status Indicators

When reporting outcomes, use clear inline markers:

```
[✓] SUCCESS  Connection established
[✗] ERROR    Port 3306 not responding
[!] WARNING  Disk usage above 80%
[i] INFO     Running as root
```

### Info Panels

For server details, config summaries, or key-value data — use a boxed panel:

```
╭── Server Info ────────────────────────────╮
│  Hostname  :  arm-main-compute            │
│  OS        :  Ubuntu 24.04 (ARM64)        │
│  RAM       :  24GB                        │
│  User      :  hefin                       │
╰───────────────────────────────────────────╯
```

### Architecture & Flow Diagrams

When explaining how components connect or data flows, draw it rather than describe it:

```
[Your Machine] ──► [ARM Server] ──► [GitHub]
      Pull              Push
```

A simple diagram beats three paragraphs of explanation.

### File Trees

When discussing directory structures:

```
/home/hefin/
├── claude-ops/
│   ├── .git/
│   ├── CLAUDE.md
│   └── README.md
└── .ssh/
    ├── config
    └── oracle-arm-main-private.key
```

---

## Symbol Reference

These are available to you. Use them where they genuinely aid readability — not as decoration.

```
Status    ✓  ✗  !  i  ●  ○  ■  □
Arrows    →  ←  ↑  ↓  ►  ◄  ▸  ↔
Shapes    ◆  ◇  ★  ☆  ▪  ▫
Lines     │  ─  ║  ═  ┃  ━
Blocks    █  ▓  ▒  ░
Misc      ×  ±  ≈  ≠  …  ·  •  «  »
```

---

## What NOT to Do

► Don't box every response — callout boxes lose impact when overused

► Don't table everything — only when structure genuinely helps

► Don't use separators between every paragraph — use them between *sections*

► Use your best judgment to match formatting to what the content actually needs — the measure is always clear delivery, not stylistic variety

► Don't decorate for the sake of it — every formatting choice should serve readability, not aesthetics

► Don't abandon prose — well-written paragraphs are perfectly fine where the content flows naturally. Formatting enhances good writing, it doesn't replace it

► Don't treat these examples as templates to copy — they illustrate a style of thinking. Be creative. Use judgment. If a future response calls for something not listed here, go for it.

---

## The Golden Rule

**Format to be scanned, write to be understood.** If the operator can glance at your response and immediately see its structure, key points, and any warnings — you've done it right.