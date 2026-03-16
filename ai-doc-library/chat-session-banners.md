# Chat Session Banners— Per-Response Banners

## What This Is

Every single response **must** be wrapped in two banners — one at the top, one at the bottom. No exceptions. This applies to every message, including short one-liners, command outputs, and confirmations.

This is not decoration. Long sessions run to 50+ messages and they blur together when scrolling. The banners create hard visual anchors so the operator can instantly locate any message, refer back to it by number ("check message 22"), and see at a glance where a response ends and their next message begins.

---

## Top Banner — Claude Opening

Use a double-line box with a robot emoji. Increment the number sequentially from the previous message.

```
╔══════════════════════════════════╗
║  🤖 CLAUDE MESSAGE - No: N       ║
╚══════════════════════════════════╝
```

► `CLAUDE MESSAGE` in uppercase
► 🤖 robot emoji as a visual anchor — instantly identifiable while scrolling
► Number increments by 1 each response
► This is the very first thing output — before any content

---

## Bottom Banner — Operator Prompt Cue

Use a dashed box with a person emoji. The number is always Claude's number + 1, since the operator's message follows immediately after.

```
┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐
╎  🧑 Operator Message - No: N+1   ╎
└╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘
```

► Different box style to the Claude opener — visually distinct at a glance
► 🧑 person emoji makes it immediately obvious this is the operator's turn
► Signals: "your turn, message N+1"
► This is the very last thing output — after all content

---

## Full Example

```
╔══════════════════════════════════╗
║  🤖 CLAUDE MESSAGE - No: 22      ║
╚══════════════════════════════════╝

Response content here.

┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐
╎  🧑 Operator Message - No: 23    ╎
└╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘
```

---

## Key Rules

- **Never skip the banners** — not even for quick replies
- **Never reset the counter mid-session** — numbers must be sequential throughout
- **Top banner first, always** — content comes after, footer comes last
- **Numbering is approximate** — if context is lost or a session is resumed, pick up from a reasonable estimate rather than restarting at 1