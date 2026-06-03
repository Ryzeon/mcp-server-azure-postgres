# Installation Guide

This guide covers installing `mcp-server-azure-postgres` for any MCP client.

## Prerequisites

Before starting, make sure you have:

- **Node.js v20+** — [Download](https://nodejs.org/)
- **npm** — Usually comes with Node.js
- **Azure CLI** (recommended) — [Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
  - Or use `az login` to authenticate locally
- **Claude Code** — [Download](https://www.claude.com/code)

## Quick Start (Recommended)

Use the setup helper to generate your configuration:

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/Ryzeon/mcp-server-azure-postgres/main/install.sh | bash
```

### Windows (PowerShell)

Open PowerShell as Administrator, then:

```powershell
iex (irm https://raw.githubusercontent.com/Ryzeon/mcp-server-azure-postgres/main/install.ps1)
```

The helper will:
1. ✅ Check your Node.js and npm versions
2. ✅ Ask for PostgreSQL connection details
3. ✅ Ask your Azure auth method (`az login` or Service Principal)
4. ✅ Ask which installation method you prefer (npx or npm install -g)
5. ✅ Ask what to name this MCP configuration
6. ✅ **Generate the JSON configuration to copy**

Then paste the generated JSON into your tool's configuration file and restart.

## Where to Paste the Configuration

After running the setup helper, paste the generated JSON into your tool's configuration file:

| Tool | Settings File | Format |
|------|---|---|
| **Claude Code** | `~/.claude/settings.json` | JSON (inside `"mcpServers"`) |
| **Cline** | `~/.cline/settings.json` | JSON (inside `"mcpServers"`) |
| **Continue** | `~/.continue/config.json` | JSON (inside `"codeModels"`) |
| **Custom Apps** | Your config file | JSON (your format) |

**Example for Claude Code (`~/.claude/settings.json`):**
```json
{
  "theme": "auto",
  "mcpServers": {
    "pg-azure": {
      "command": "npx",
      "args": ["-y", "mcp-server-azure-postgres"],
      "env": {
        "PGHOST": "...",
        "PGDATABASE": "...",
        ...
      }
    }
  }
}
```

Then restart your application.

## Installation Methods

Choose one of these two methods:

| Method | Setup | Speed | Updates | Best For |
|--------|-------|-------|---------|----------|
| **npx** | 0s | Slower first run | Auto | Most users |
| **npm install -g** | 30s | Very fast | Manual | Frequent use |

### Method 1: npx (Recommended)

Zero setup, always latest version:

```bash
claude mcp add pg-azure --transport stdio -- npx -y github:Ryzeon/mcp-server-azure-postgres
```

- No installation needed
- Always uses the latest version
- First run downloads ~150MB (slower)
- Subsequent runs are faster

**Best for:** Most users, simple setup, always up-to-date

### Method 2: npm install -g

Install globally for faster execution:

```bash
npm install -g mcp-server-azure-postgres
claude mcp add pg-azure --transport stdio -- mcp-server-azure-postgres
```

- Requires 30 seconds to install
- Very fast execution after installation
- Manual updates needed: `npm update -g mcp-server-azure-postgres`
- Takes ~100MB of disk space

**Best for:** Frequent MCP usage, when speed matters

## Manual Setup

If the installer doesn't work for you, edit `~/.claude/settings.json` directly:

### With `az login` (recommended)

```json
{
  "theme": "auto",
  "mcpServers": {
    "pg-azure": {
      "command": "npx",
      "args": ["-y", "mcp-server-azure-postgres"],
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

Or with `npm install -g`:
```json
{
  "mcpServers": {
    "pg-azure": {
      "command": "mcp-server-azure-postgres",
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

### With Service Principal

```json
{
  "mcpServers": {
    "pg-azure": {
      "command": "npx",
      "args": ["-y", "mcp-server-azure-postgres"],
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

Then restart Claude Code or use `/mcp` to reload.

## Getting Azure Service Principal Credentials

If you don't use `az login` and need Service Principal credentials:

```bash
az ad sp create-for-rbac --name mcp-server-azure-postgres --role Contributor
```

Output:
```json
{
  "appId": "...",           // AZURE_CLIENT_ID
  "password": "...",        // AZURE_CLIENT_SECRET
  "tenant": "..."           // AZURE_TENANT_ID
}
```

Use these values in your environment variables.

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
