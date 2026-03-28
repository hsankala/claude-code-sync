---
name: mcp-setup-mysql
description: Set up a MySQL MCP server for a Claude Code project. Use this skill whenever the user wants to add MySQL database access, connect to a database, enable Claude Code to query MySQL, or configure database MCP. Also trigger for "mysql mcp", "database mcp", "connect to my database", or when the user wants Claude Code to read or write their MySQL database.
effort: medium
disable-model-invocation: true
---

# MySQL MCP Setup

Adds a MySQL MCP server to the current Claude Code project using `@benborla29/mcp-server-mysql` with local (project-scoped) configuration via stdio transport.

Once set up, Claude Code can inspect schemas, run queries, and optionally perform write operations against the connected database.

---

## Step 1 — Pre-flight: Establish database credentials

You likely already have context about this project — its stack, framework, and possibly its database config. Use what you know. The goal here is to arrive at five values before asking the user for anything:

- `MYSQL_HOST`
- `MYSQL_PORT` (usually `3306`)
- `MYSQL_USER`
- `MYSQL_PASS`
- `MYSQL_DB`

If you don't already have these from project context, look for them. Common places depending on the stack — these examples are not exhaustive, use your judgment:

| File to look for | What to extract |
|---|---|
| `wp-config.php` | `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST` constants |
| `.env` | `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT` |
| `config/database.yml` | host, database, username, password under the relevant environment |
| `settings.php`, `config.php`, or any bootstrap file | Any database connection block |

If the project has a non-standard layout or the config isn't where you'd expect it, ask the user directly. Don't guess credential values.

---

## Step 2 — Confirm credentials with the user

Present what you found (or didn't find). Ask the user to confirm each value or provide corrections/missing values.

Show them a summary like:

> I found the following database credentials from `wp-config.php`:
>
> - Host: `localhost`
> - Port: `3306`
> - User: `wordpress_user`
> - Password: `[found]`
> - Database: `wordpress_db`
>
> Do these look right, or do any need changing?

If nothing was found, just ask for all five values directly. Do not assume defaults — the user knows their setup.

---

## Step 3 — Ask about write permissions

All three write permission flags default to **`true`** — full access. Claude Code works best when it can read, write, and delete without hitting artificial walls during development.

| Operation | Env var | Default |
|---|---|---|
| INSERT | `ALLOW_INSERT_OPERATION` | `true` |
| UPDATE | `ALLOW_UPDATE_OPERATION` | `true` |
| DELETE | `ALLOW_DELETE_OPERATION` | `true` |

Ask the user if they want to restrict anything:

> Write permissions default to full access (INSERT, UPDATE, DELETE all enabled). Do you want to lock any of these down for this project?

If they don't raise a concern, proceed with all three as `true`.

> ⚠️ These flags are baked into the MCP server at startup — they cannot be changed at runtime. If permissions need changing later, edit `~/.claude.json` directly (see **Editing config directly** below) and restart Claude Code.
>
> ⚠️ **Production environments** — always confirm with the user before setting up against a production database. Full write access on a live system is the user's call to make explicitly, not a default to accept without thought.

---

## Step 4 — Run the setup command

Check that `npx` is available first:

```bash
command -v npx
```

If not found, tell the user to install Node.js 18+ and stop.

Check whether MySQL MCP is already configured:

```bash
claude mcp get mysql
```

If it's already there, tell the user and offer to remove and re-add if they want to change the config:

```bash
claude mcp remove mysql
```

Then add the MCP server:

> ⚠️ The server name (`mysql`) must come **immediately after `add`**, before any flags. The `-e` option is variadic and will greedily consume positional arguments — if the name comes after the env vars, it gets parsed as an invalid env var and the command fails.

```bash
# ⚠️ Name 'mysql' MUST come immediately after 'add', before any -e flags
claude mcp add mysql --scope local \
  -e MYSQL_HOST="<host>" \
  -e MYSQL_PORT="<port>" \
  -e MYSQL_USER="<user>" \
  -e MYSQL_PASS="<password>" \
  -e MYSQL_DB="<database>" \
  -e ALLOW_INSERT_OPERATION="<true|false>" \
  -e ALLOW_UPDATE_OPERATION="<true|false>" \
  -e ALLOW_DELETE_OPERATION="<true|false>" \
  -- npx -y @benborla29/mcp-server-mysql
```

Substitute the actual values confirmed in Step 2 and the flags from Step 3.

---

## Step 5 — Verify

```bash
claude mcp get mysql
```

Confirm the output shows:
- **Scope**: Local config
- **Type**: stdio

If the command fails or mysql doesn't appear, show the user the full `claude mcp add` command with their values filled in, so they can run it manually and see the raw error.

---

## Step 6 — Confirm to the user

Tell them:
- ✅ MySQL MCP is now active for this project
- 🔍 Claude Code can inspect schemas and run queries against the database
- ⚠️ Remind them of the write permission state (read-only, or what was enabled)
- 💡 They can try: *"Show me all tables"*, *"Describe the users table"*, *"How many records are in the orders table?"*

---

## Troubleshooting

| Issue | Fix |
|---|---|
| `mysql` not found in `claude mcp list` | Re-run the add command and check for errors |
| `-32000: Connection closed` | MCP server is crashing at startup — almost always a credentials or config issue. Test the raw connection first (see below), then verify credentials in `~/.claude.json` |
| Connection refused | Confirm the database server is running and accessible from this environment |
| Access denied | Wrong username or password — test the raw connection (see below) to confirm what works |
| Database doesn't exist | Run `SHOW DATABASES` via the raw connection test (below) to see what's actually there — the database may not have been created yet |
| Wrong database | Confirm `MYSQL_DB` in `~/.claude.json` — the database name in config files doesn't always match what you expect |
| Want to remove it | `claude mcp remove mysql` from the project root |
| Need to change credentials or permissions | Edit `~/.claude.json` directly (see below) — no need to remove and re-add for simple value changes |
| `npx` not found | Install Node.js 18+ |

### Testing the raw connection

When the MCP server won't connect, cut it out of the picture entirely and test MySQL directly. This immediately tells you whether the problem is credentials, the server not running, or the database not existing:

```bash
mysql -h 127.0.0.1 -P 3306 -u root --password="" -e "SHOW DATABASES;"
```

Substitute the actual host, port, user, and password. If this succeeds, the MySQL server is reachable and the credentials work — the problem is likely the database name or the MCP config values. If it fails, the database server itself is the issue.

---

## Editing config directly

For minor changes — password, port, database name, write permissions — you don't need to remove and re-add. Edit `~/.claude.json` directly and restart Claude Code.

**File location:** `~/.claude.json` — home directory root. Note: this is NOT inside `~/.claude/` — it sits one level up at `~/.claude.json`.

**Structure to navigate:**

```
~/.claude.json
  └── projects
        └── "/absolute/path/to/your/project"   ← keyed by project path
              └── mcpServers
                    └── mysql
                          └── env
                                ├── MYSQL_HOST
                                ├── MYSQL_PORT
                                ├── MYSQL_USER
                                ├── MYSQL_PASS
                                ├── MYSQL_DB
                                ├── ALLOW_INSERT_OPERATION
                                ├── ALLOW_UPDATE_OPERATION
                                └── ALLOW_DELETE_OPERATION
```

To find the right block quickly, grep the file:

```bash
grep -n "MYSQL_DB\|MYSQL_PASS\|MYSQL_HOST" ~/.claude.json
```

Make the targeted change, save, and restart Claude Code. The MCP server will pick up the new values on next launch.

---

## Notes

- **Always use `--scope local`** — this config applies only to the current project directory, which is almost always what you want
- `--scope user` would make this MCP active across every project you open, globally — do not use this unless the user explicitly requests it and understands the implication
- The MCP server uses stdio transport — it spawns a local Node.js process on demand
- If the project uses a non-standard config location, ask the user where their database credentials are stored
