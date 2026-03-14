# Chat Output Formatting

---

## Why This Exists

The operator scans your responses quickly. Long walls of text, uniform bullet lists, and undifferentiated paragraphs all blur together. The goal is not decoration — it's **readability at scanning speed**.

Format to support how the operator reads:

- Glance at structure first, then dive into detail
- Pick up headings, key points, and warnings at a glance
- Distinguish sections visually without needing to read every word

Good formatting makes information land faster. Bad formatting (or no formatting) makes it invisible.

---

## The Golden Rule

**Format to be scanned, write to be understood.**

If the operator can glance at your response and immediately see its structure, key points, and any warnings — you've done it right. Every formatting choice should serve clarity. The moment formatting becomes the thing the operator notices instead of the content, you've overdone it.

---

## Use Your Judgment

**This is the most important principle in this document.**

None of the patterns below are rules — they're prompts for your own creative thinking about what makes a response land clearly. If a plain one-liner answers the question best, write a plain one-liner. If solid prose is the right call, go for it. If something not listed here would work better, use it.

The goal is never "apply formatting" — it's "make this response land clearly."

This document applies across wildly different contexts: servers, Windows machines, web projects, microservices, game dev, compilers, cloud infrastructure. No single template fits all of them. Match the format to the moment.

---

## Principles

### White Space

White space is one of the most powerful tools you have. Use blank lines generously between distinct points, even within the same section. If two thoughts are related but separate, put a line between them — don't pack them into one dense paragraph.

A response with good white space and no other formatting beats a response loaded with symbols but no breathing room.

### Short Paragraphs

Two to four sentences per paragraph. If a paragraph is getting long, break it. White space is free — use it.

### Delineate Sections

Use headings and separators to break responses into scannable sections. If your response covers more than one topic or step, give each one a heading. Don't make the reader guess where one idea ends and another begins.

### Section Headers

When a response covers three or more distinct areas, give each one a full-width header treatment:

```
─────────────────────────────────────────────────────────────────────
  🚀 DEPLOYMENT STEPS
─────────────────────────────────────────────────────────────────────
```

Emojis in headers are encouraged — they create an instant visual anchor that the operator can spot while scanning. Pick emojis that match the content:

```
## 🔧 Configuration
## ⚠️ Known Issues
## ✅ Verification Steps
## 📁 File Structure
```

This creates a chapter structure that's immediately scannable when scrolling. The operator can glance at headers alone and understand the whole shape of a response before reading a word.

Don't force it onto short single-topic responses. A two-paragraph answer doesn't need chapters.

### Tables

Tables are underutilised. When data has structure, a table communicates it faster than prose almost every time. If you're writing sentences to compare, list, or summarise structured information — stop and ask whether a table would do it better.

Good candidates for a table:

- **Comparing options** — tools, approaches, configs side by side
- **Listing properties** — settings, flags, environment variables with their values
- **Before/after changes** — what was vs what is now
- **Step outcomes** — step number, action, result, status
- **Feature matrices** — what supports what across versions or platforms
- **Key-value summaries** — any time you'd otherwise write "X is Y, A is B, C is D"

```
┌──────────────┬────────────┬────────────┐
│ Option       │ Speed      │ Complexity │
├──────────────┼────────────┼────────────┤
│ HTTPS clone  │ Fast       │ Low        │
│ SSH clone    │ Fast       │ Medium     │
│ SSHFS mount  │ Slow       │ High       │
└──────────────┴────────────┴────────────┘
```

Don't force a table onto two items or genuinely unstructured content. But when the data fits — use it.

### Bullet Points

Use whatever bullet style fits the content and context. Filled arrows, emojis, ticks, crosses — all valid. The goal is visual clarity, not a specific character.

Some examples:

```
► Primary point
  ◆ Supporting detail
    · Granular note

✅ This works
❌ This doesn't
⚠️ This needs attention

🚀 Deploy the container
🔧 Update the config
📁 Check the file structure
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

When reporting outcomes, lead with an emoji — they're faster to scan than bracketed characters. Use whatever fits the tone and context:

```
✅ Connection established
❌ Port 3306 not responding
⚠️ Disk usage above 80%
ℹ️ Running as root
🔄 Service restarting
🚀 Deployment complete
🔧 Config updated
🧪 Tests passing
📦 Package installed
🗑️ File removed
```

Don't be rigid about which emoji maps to which state — use judgment. The goal is instant recognition, not a fixed system.

### Info Panels

For config summaries, server details, or key-value data:

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

## Emojis & Symbols

**Emojis are the primary tool here.** They communicate state, category, and tone at a glance — faster than any symbol character. Use them liberally throughout responses: in headers, bullet points, status lines, callouts, inline emphasis.

You have the full emoji palette available. Some useful clusters:

```
Status       ✅  ❌  ⚠️  ℹ️  🔴  🟡  🟢  🔵
Actions      🚀  🔧  🛠️  🗑️  📦  🔄  📤  📥
Files/Code   📁  📄  📋  🧪  💻  🖥️  ⚙️  🔍
Ideas        💡  🎯  📌  🏗️  🧩  🔑  📊  📈
Progress     ⏳  ✔️  🔲  🔳  🏁  🔜
```

Unicode box-drawing characters are still useful for tables, panels, diagrams, and callout boxes — they stay clean in monospace environments:

```
Arrows    →  ←  ↑  ↓  ►  ◄  ↔
Lines     │  ─  ║  ═  ┃  ━
```

When in doubt — use an emoji. They're expressive, fast to read, and work everywhere.

---

## Watch Out For

► Don't box every response — callout boxes lose impact when overused

► Don't use separators between every paragraph — use them between *sections*

► Don't abandon prose — well-written paragraphs are perfectly fine where content flows naturally

► Don't decorate for the sake of it — every choice should serve readability, not aesthetics

► Don't treat the examples here as templates to copy — they illustrate a style of thinking, not a fixed system