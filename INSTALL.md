# Installation Guide

This guide covers installing `mcp-server-azure-postgres` on different platforms.

## Prerequisites

Before starting, make sure you have:

- **Node.js v20+** — [Download](https://nodejs.org/)
- **npm** — Usually comes with Node.js
- **Azure CLI** (recommended) — [Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
  - Or use `az login` to authenticate locally
- **Claude Code** — [Download](https://www.claude.com/code)

## Quick Install (Recommended)

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/Ryzeon/mcp-server-azure-postgres/main/install.sh | bash
```

### Windows (PowerShell)

Open PowerShell as Administrator, then:

```powershell
iex (irm https://raw.githubusercontent.com/Ryzeon/mcp-server-azure-postgres/main/install.ps1)
```

The installer will:
1. ✅ Check your Node.js and npm versions
2. ✅ Check for Azure CLI
3. ✅ Ask for your PostgreSQL connection details:
   - `PGHOST` (e.g., `myserver.postgres.database.azure.com`)
   - `PGDATABASE` (e.g., `mydb`)
   - `PGUSER` (e.g., `myapp`)
   - `PGPORT` (default: `5432`)
4. ✅ Ask how you want to authenticate:
   - **Option 1: `az login`** — Works if you've already logged into Azure locally
   - **Option 2: Service Principal** — For CI/CD or another machine
5. ✅ Configure your `~/.claude/settings.json` automatically
6. ✅ Show you next steps

## Manual Installation

If you prefer to configure manually or the installer fails:

### 1. Verify Prerequisites

```bash
node --version     # Should be v20+
npm --version
az --version       # Optional but recommended
```

### 2. Create or Edit `~/.claude/settings.json`

#### With `az login`

1. Run `az login` first to authenticate
2. Add to your settings:

```json
{
  "mcpServers": {
    "pg-azure": {
      "command": "npx",
      "args": ["-y", "github:Ryzeon/mcp-server-azure-postgres"],
      "env": {
        "PGHOST": "myserver.postgres.database.azure.com",
        "PGDATABASE": "mydb",
        "PGUSER": "myapp",
        "PGPORT": "5432"
      }
    }
  }
}
```

#### With Service Principal

If you're setting this up for CI/CD or on a machine without `az login`:

```json
{
  "mcpServers": {
    "pg-azure": {
      "command": "npx",
      "args": ["-y", "github:Ryzeon/mcp-server-azure-postgres"],
      "env": {
        "PGHOST": "myserver.postgres.database.azure.com",
        "PGDATABASE": "mydb",
        "PGUSER": "myapp",
        "PGPORT": "5432",
        "AZURE_TENANT_ID": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "AZURE_CLIENT_ID": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "AZURE_CLIENT_SECRET": "your-secret-value"
      }
    }
  }
}
```

To get Service Principal credentials:

```bash
az ad sp create-for-rbac --name mcp-server-azure-postgres --role Contributor
```

This outputs:
```json
{
  "appId": "...",           // Use as AZURE_CLIENT_ID
  "password": "...",        // Use as AZURE_CLIENT_SECRET
  "tenant": "..."           // Use as AZURE_TENANT_ID
}
```

### 3. Restart Claude Code

- Close and reopen Claude Code
- Or use `/mcp` to reload MCP servers

### 4. Verify Installation

In Claude Code, run:
```
/mcp
```

You should see `pg-azure` in the list.

## Troubleshooting

### "Node.js not found"
- Install Node.js from https://nodejs.org/ (v20+)
- Restart your terminal after installation

### "Azure CLI not found"
- **Recommended**: Install Azure CLI from https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
- **Alternative**: Use Service Principal credentials instead

### "Command not found: npx"
- Make sure npm is installed: `npm --version`
- Try `npm install -g npm` to update npm

### "settings.json not found"
- The installer creates it automatically
- For manual: Create the directory `~/.claude/` if it doesn't exist
- Then create or edit `settings.json` in that directory

### "Error: credential not found" (at runtime)

**If using `az login`:**
- Run `az login` before using the MCP server
- Verify: `az account show`

**If using Service Principal:**
- Verify `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET` are set correctly
- Test credentials: `az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID`

### "Connection timeout"
- Verify `PGHOST` and `PGPORT` are correct
- Check that your IP is allowed in Azure PostgreSQL firewall
- Verify Azure AD authentication is enabled on the server

### "Permission denied" (PowerShell on Windows)

If you get "PowerShell script execution is disabled":

```powershell
# Run once to enable script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then run the installer
iex (irm https://raw.githubusercontent.com/Ryzeon/mcp-server-azure-postgres/main/install.ps1)
```

### Still having issues?

1. Check that all env vars are set: `echo $PGHOST` (bash) or `echo $env:PGHOST` (PowerShell)
2. Try the manual installation steps
3. Open an issue on [GitHub](https://github.com/Ryzeon/mcp-server-azure-postgres/issues)

## Next Steps

After installation:

1. **Test the connection:**
   ```
   /mcp list_schemas
   ```

2. **Run a query:**
   ```
   /mcp query "SELECT version();"
   ```

3. **List your tables:**
   ```
   /mcp list_tables schema:public
   ```

## Upgrading

To get the latest version:

```bash
# Re-run the installer (it will overwrite settings)
curl -fsSL https://raw.githubusercontent.com/Ryzeon/mcp-server-azure-postgres/main/install.sh | bash
```

Or update manually by changing the version in `github:Ryzeon/mcp-server-azure-postgres@latest` in your settings.

---

For more details, see the [main README](README.md).
