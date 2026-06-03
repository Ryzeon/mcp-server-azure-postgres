# mcp-server-azure-postgres

[![npm version](https://img.shields.io/npm/v/mcp-server-azure-postgres.svg)](https://npm.im/mcp-server-azure-postgres)
[![npm downloads](https://img.shields.io/npm/dw/mcp-server-azure-postgres)](https://npm.im/mcp-server-azure-postgres)
[![Build & Publish](https://github.com/Ryzeon/mcp-server-azure-postgres/actions/workflows/publish.yml/badge.svg)](https://github.com/Ryzeon/mcp-server-azure-postgres/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/node-%3E%3D20-brightgreen)](https://nodejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5-blue.svg)](https://www.typescriptlang.org/)

A Model Context Protocol (MCP) server for Azure Database for PostgreSQL with **automatic Azure AD token refresh**. Works with **Claude Code**, **Cursor**, **Cline**, **Continue**, **Antigratuity**, and other MCP clients. No token expiry, no manual password updates.

## Why This?

[`mcp-server-postgres`](https://github.com/modelcontextprotocol/servers/tree/main/src/postgres) works great but requires a static connection string. With Azure AD authentication, tokens expire after ~1 hour. This server solves that by internally using [`@azure/identity`](https://github.com/Azure/azure-sdk-for-js/tree/main/sdk/identity/identity) — the same approach used by Azure SDK clients and Node.js microservices — to refresh tokens automatically before each database connection.

## Features

- ✅ **Auto token refresh** — Uses `DefaultAzureCredential` to automatically refresh Azure AD tokens
- ✅ **Works with `az login`** — Zero Azure configuration if you're already logged in locally
- ✅ **Managed Identity ready** — Works in Azure VMs, App Service, AKS without any credentials
- ✅ **Service Principal support** — Pass `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET` for CI/CD
- ✅ **Standard MCP interface** — 4 tools: `query`, `list_schemas`, `list_tables`, `describe_table`
- ✅ **TypeScript + source maps** — Easy to debug and extend

## Installation

### Quick Start (2 minutes)

Run the setup helper to generate your configuration:

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/Ryzeon/mcp-server-azure-postgres/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iex (irm https://raw.githubusercontent.com/Ryzeon/mcp-server-azure-postgres/main/install.ps1)
```

The helper will:
- ✓ Check Node.js and npm
- ✓ Ask for PostgreSQL connection details
- ✓ Ask for Azure auth method (`az login` or Service Principal)
- ✓ Choose installation method (npx or npm install -g)
- ✓ **Generate the JSON configuration**
- ✓ Show you the configuration to copy

Then paste the generated JSON into your tool's settings file and restart.

**Works with any MCP client:**
- **Claude Code** (`~/.claude/settings.json`)
- **Cursor** (`~/.cursor/settings.json`)
- **Cline** (`~/.cline/settings.json`)
- **Continue** (`~/.continue/config.json`)
- **Antigratuity**
- **ChatGPT** (via MCP marketplace)
- Custom MCP applications

For detailed setup and troubleshooting, see [INSTALL.md](INSTALL.md).

## Configuration

### Required Environment Variables

| Variable | Example | Description |
|----------|---------|-------------|
| `PGHOST` | `myserver.postgres.database.azure.com` | Azure PostgreSQL server hostname |
| `PGDATABASE` | `mydb` | Database name |
| `PGUSER` | `myapp` | Database user (Azure AD identity) |
| `PGPORT` | `5432` | PostgreSQL port (default: 5432) |

### Optional: Azure Authentication

`DefaultAzureCredential` tries credentials in this order:

1. **`az login`** — Works locally if you've run `az login`
2. **Managed Identity** — Works in Azure VMs, App Service, AKS, Functions
3. **Azure CLI** — Falls back to Azure CLI configuration
4. **Service Principal** — If env vars are set:
   - `AZURE_TENANT_ID`
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`

**No additional setup needed if you already have `az login` or Managed Identity.**

## Tools

### `query`

Execute any SQL statement.

**Input:**
```json
{
  "sql": "SELECT * FROM users WHERE id = $1",
  "params": [42]
}
```

**Output:** Query result as JSON.

---

### `list_schemas`

List all schemas in the database (excluding system schemas).

**Input:** (none)

**Output:**
```json
["public", "staging", "analytics"]
```

---

### `list_tables`

List all tables in a schema.

**Input:**
```json
{
  "schema": "public"
}
```

**Output:**
```json
["users", "orders", "products"]
```

---

### `describe_table`

Get column definitions for a table.

**Input:**
```json
{
  "table": "users",
  "schema": "public"
}
```

**Output:**
```json
[
  {
    "column_name": "id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": "nextval('users_id_seq'::regclass)"
  },
  {
    "column_name": "email",
    "data_type": "character varying",
    "is_nullable": "NO",
    "column_default": null
  }
]
```

## Authentication Methods

### Local Development (with `az login`)

```bash
az login
# Then just set the 4 Postgres env vars above
```

### Managed Identity (Azure VMs, App Service, AKS)

Enable Managed Identity on the resource in Azure Portal. No env vars needed except Postgres config.

### Service Principal (CI/CD, Another Machine)

1. Create a Service Principal:
   ```bash
   az ad sp create-for-rbac --name mcp-server --role Contributor
   ```

2. Grant access to the PostgreSQL server (via Azure Portal or Azure CLI)

3. Set env vars in your CI/CD or `.env`:
   ```
   AZURE_TENANT_ID=<tenant-id>
   AZURE_CLIENT_ID=<client-id>
   AZURE_CLIENT_SECRET=<client-secret>
   ```

## Building from Source

```bash
git clone https://github.com/ryzeon/mcp-server-azure-postgres
cd mcp-server-azure-postgres
npm install
npm run build
node dist/index.js
```

### Development

```bash
npm run dev  # Watch mode with tsc --watch
```

## How It Works

Under the hood:

1. `DefaultAzureCredential` manages token acquisition and caching
2. The pg pool's `password` option is set to an async function
3. Before each new connection, the async function calls `credential.getToken()`
4. If the token is expired or about to expire, Azure AD is called to refresh it
5. The fresh token is passed to PostgreSQL's connection

Result: **Tokens are always fresh, automatically.**

This is identical to how Azure SDKs and microservices handle authentication — zero manual token management.

## Troubleshooting

For detailed troubleshooting guides, installation issues, and common problems, see [INSTALL.md](INSTALL.md#troubleshooting).

### Common Issues

| Issue | Solution |
|-------|----------|
| "Error: credential not found" | Run `az login` first, or set Service Principal env vars |
| "Connection timeout" | Verify `PGHOST`, firewall rules, Azure AD auth enabled |
| "Token refresh fails" | Check that your Azure identity has database login rights |
| "PowerShell execution disabled" | Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` |

For more, see [INSTALL.md → Troubleshooting](INSTALL.md#troubleshooting).

## Contributing

Contributions welcome! Please:

1. Fork the repo
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

MIT — See LICENSE file.

## Related

- [MCP Official Servers](https://github.com/modelcontextprotocol/servers)
- [pg-node](https://node-postgres.com/)
- [Azure Identity for JavaScript](https://github.com/Azure/azure-sdk-for-js/tree/main/sdk/identity/identity)
