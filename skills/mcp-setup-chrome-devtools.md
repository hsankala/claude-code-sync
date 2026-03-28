---
name: mcp-setup-chrome-devtools
description: Set up the Chrome DevTools MCP server for Claude Code. Use this skill whenever the user wants to add browser control, connect Claude Code to Chrome, enable Puppeteer automation, run Lighthouse audits, capture console errors, or debug a live web app from within Claude Code. Also trigger for "chrome mcp", "browser mcp", "devtools mcp", "puppeteer mcp", or when the user wants Claude Code to interact with or inspect a web page.
effort: medium
disable-model-invocation: true
---

# Chrome DevTools MCP Setup

Adds the Chrome DevTools MCP server (`chrome-devtools-mcp`) to Claude Code, giving it **eyes and hands inside a live Chrome browser** via Puppeteer and the Chrome DevTools Protocol.

Once configured, Claude Code can navigate to pages, click and fill forms, capture console errors and network failures in real time, take screenshots, run Lighthouse audits, and then act on what it finds — all without back-and-forth screenshots from the user.

---

## Pre-flight — Check Node.js and existing config

### 1. Check Node.js version

```bash
node -v
```

Node.js **20.19 or later** is required. If the version is lower or Node isn't installed, stop and tell the user:

> ⚠️ Chrome DevTools MCP requires Node.js 20.19+. Please update Node.js and rerun this skill.

### 2. Check if already configured

```bash
claude mcp get chrome-devtools
```

If it's **already there**, tell the user:

> ⚠️ Chrome DevTools MCP is already configured.
>
> Do you want to remove it and re-add with different settings, or leave it as-is?

If they want to reconfigure:

```bash
claude mcp remove chrome-devtools
```

If it's **not configured**, proceed to Step 1.

---

## Step 1 — Choose connection mode

This is the key decision that determines everything that follows. Ask the user:

> **How do you want Claude Code to connect to Chrome?**
>
> **Mode A — Auto-Launch** *(recommended for most work)*
> Claude Code starts its own Chrome instance with a dedicated profile. Simple, no manual setup. Best for general development, testing public-facing pages, and quick audits.
>
> **Mode B — Remote Debug Port** *(for authenticated testing)*
> You start Chrome yourself with a debug port open. Claude Code connects to your running browser, inheriting your login sessions and cookies. Best when you need to test behind auth or share state between manual browsing and agent testing.
>
> Which do you want to set up?

Wait for the user's answer before proceeding.

---

## Step 2A — Install: Auto-Launch mode

```bash
claude mcp add chrome-devtools --scope user -- npx -y chrome-devtools-mcp@latest --channel=stable --viewport=1920x1080 --no-usage-statistics
```

> 💡 `--scope user` makes this available across all Claude Code projects. Use `--scope local` if you only want it for the current project.

Skip to **Step 4 — Verify**.

---

## Step 2B — Install: Remote Debug Port mode

This mode requires two things: Chrome started with a debug port, and the MCP server told where to find it.

### Start Chrome with the debug port open

> ⚠️ **This step is for the user to do manually** — these are not commands for Claude Code to run. Chrome needs to be running with a debug port open before Claude Code can connect to it.

> ⚠️ **Close all running Chrome instances first.** Chrome will refuse the debug port if another instance is already using the same profile.

> 🔒 **Security note**: The debug port exposes Chrome to any application on your machine. Always use `--user-data-dir` to point at a dedicated debug profile — never your default profile.

Ask the user where Chrome is installed:

> Is Chrome installed on Windows, or natively inside WSL2/Linux?

**If Chrome is on Windows** — ask the user to run this in PowerShell or CMD on Windows:

```powershell
"C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --user-data-dir="%TEMP%\chrome-debug-profile"
```

**If Chrome is installed natively in WSL2/Linux** — run:

```bash
google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug-profile
```

Chrome will open with the debug profile. Leave it running and continue below.

### Add the MCP server

**Standard (Linux, macOS, WSL2 with mirrored networking):**

```bash
claude mcp add chrome-devtools --scope user -- npx -y chrome-devtools-mcp@latest --browser-url=http://127.0.0.1:9222 --viewport=1920x1080 --no-usage-statistics
```

**WSL2 without mirrored networking** — if `127.0.0.1` doesn't reach Windows Chrome, get the Windows host IP first:

```bash
WIN_HOST=$(ip route show default | awk '{print $3}')
echo $WIN_HOST
```

Then use that IP:

```bash
claude mcp add chrome-devtools --scope user -- npx -y chrome-devtools-mcp@latest --browser-url="http://${WIN_HOST}:9222" --viewport=1920x1080 --no-usage-statistics
```

> 💡 If you're on WSL2 and unsure whether mirrored networking is enabled, check `%USERPROFILE%\.wslconfig` on Windows for `networkingMode=mirrored`. If it's set, use `127.0.0.1`. If not set or set to something else, use the host IP method above.

---

## Step 3 — WSL2 note (if applicable)

If the user is running Claude Code in WSL2 with Chrome on Windows, ask:

> Are you running Claude Code in WSL2 with Chrome on Windows?

If yes, surface this:

> ⚠️ **WSL2 + Windows Chrome**: The MCP server may auto-detect Windows Chrome via `/mnt/c/` and fail with `ECONNRESET` or `Target closed` errors. The fix is to use Remote Debug Port mode (Mode B) so the MCP server connects via a URL rather than launching Chrome itself.
>
> If you're using Mode A (Auto-Launch) and hitting these errors, switch to Mode B.
>
> If you want Mode A to work cleanly without these issues, install Chrome natively inside WSL2 instead — this avoids all cross-boundary networking. See **Troubleshooting** below.

---

## Step 4 — Verify

```bash
claude mcp get chrome-devtools
```

Confirm the output shows:
- **Scope**: User config (or Local config if you used `--scope local`)
- **Type**: stdio

If the command fails or `chrome-devtools` doesn't appear in `claude mcp list`, show the user the full add command with their values filled in so they can run it manually and see the raw error.

---

## Step 5 — Test

Tell the user:

> ✅ Chrome DevTools MCP is configured. Let's run a quick test.
>
> Start a new Claude Code session (or use `/reload-plugins` if available), then try:
>
> *"Navigate to https://example.com and take a screenshot"*
>
> or
>
> *"Run a Lighthouse audit on https://web.dev"*
>
> If Claude Code navigates, interacts, or returns results — it's working.

For **Mode B only** — remind the user:

> 🔧 Remember: with Remote Debug Port mode, you need to manually start Chrome with `--remote-debugging-port=9222` before starting Claude Code. If Chrome isn't running with the debug port open, the MCP server will fail to connect.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `ECONNRESET` or `Target closed` | Close all Chrome instances and relaunch with debug port. In WSL2, this usually means the MCP server picked up Windows `chrome.exe` — switch to Mode B or install Chrome natively in WSL2 |
| Browser doesn't start | Confirm Node.js is 20.19+ (`node -v`). Run `npx chrome-devtools-mcp@latest --help` to test the package directly |
| `chrome-devtools` not in `claude mcp list` | Re-run the add command, check for errors in the output |
| WSL2 can't reach Windows Chrome on `127.0.0.1` | Enable mirrored networking in `%USERPROFILE%\.wslconfig` (`networkingMode=mirrored`) OR use the Windows host IP from `ip route show default` |
| MCP connects but tools fail | Check Chrome version — update to current stable if needed |
| Stale cache causing strange behaviour after update | `rm -rf ~/.npm/_npx && npm cache clean --force`, then restart Claude Code |
| Want to remove it | `claude mcp remove chrome-devtools` |

### Installing Chrome natively in WSL2

If WSL2/Windows networking issues are a recurring problem, installing Chrome in WSL2 directly eliminates all cross-boundary issues and lets you use Auto-Launch mode cleanly:

```bash
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
sudo apt update && sudo apt install google-chrome-stable
```

This requires WSLg (GUI support) to be enabled. After installation, use Auto-Launch mode as normal.

---

## Notes

- **`--scope user` is the right default here** — Chrome DevTools is a general-purpose browser control tool, not project-specific. Unlike MySQL (which connects to a project's database), you want this available everywhere
- **Only Google Chrome and Chrome for Testing are officially supported** — other Chromium browsers may work but aren't guaranteed
- **The debug port is a local security boundary** — never expose port 9222 externally (firewall rules, not just local trust). Always use `--user-data-dir` for a dedicated profile separate from your personal browsing data
- **For CI or ephemeral testing**, add `--isolated` to the args — the profile is auto-cleaned when the browser closes
- **For simple tasks only** (navigation + screenshots + script execution), add `--slim --headless` to reduce the tool surface to 3 tools instead of 29
- The MCP config is stored in `~/.claude.json` — do not edit this file manually. Use `claude mcp remove` + re-add to change settings
