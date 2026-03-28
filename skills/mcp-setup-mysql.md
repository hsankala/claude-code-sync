---
name: mcp-setup-mysql
description: Set up a MySQL MCP server for a Claude Code project. Use this skill whenever the user wants to add MySQL database access, connect to a database, enable Claude Code to query MySQL, or configure database MCP. Also trigger for "mysql mcp", "database mcp", "connect to my database", or when the user wants Claude Code to read or write their MySQL database.
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

> ⚠️ These flags are baked into the MCP server at startup — they cannot be changed at runtime. If permissions need changing later, remove and re-add: `claude mcp remove mysql`.
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

```bash
claude mcp add \
  --scope local \
  -e MYSQL_HOST="<host>" \
  -e MYSQL_PORT="<port>" \
  -e MYSQL_USER="<user>" \
  -e MYSQL_PASS="<password>" \
  -e MYSQL_DB="<database>" \
  -e ALLOW_INSERT_OPERATION="<true|false>" \
  -e ALLOW_UPDATE_OPERATION="<true|false>" \
  -e ALLOW_DELETE_OPERATION="<true|false>" \
  mysql \
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
| Connection refused | Confirm the database server is running and accessible from this environment |
| Access denied | Double-check credentials — try connecting manually with `mysql -u <user> -p<pass> -h <host> <db>` |
| Wrong database | Confirm `MYSQL_DB` — the database name in config files doesn't always match what you expect |
| Want to remove it | `claude mcp remove mysql` from the project root |
| Need to change permissions | Remove and re-add — permissions are baked into the server at startup and cannot be changed at runtime |
| `npx` not found | Install Node.js 18+ |

---

## Notes

- The MCP config is stored in `~/.claude.json` — do not edit this file manually
- **Always use `--scope local`** — this config applies only to the current project directory, which is almost always what you want
- `--scope user` would make this MCP active across every project you open, globally — do not use this unless the user explicitly requests it and understands the implication
- The MCP server uses stdio transport — it spawns a local Node.js process on demand
- If the project uses a non-standard config location, ask the user where their database credentials are stored
