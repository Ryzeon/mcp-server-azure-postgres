# mcp-server-azure-postgres Installation Script for PowerShell
# For Windows: Run as Administrator
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1

param()

# Colors & Formatting
$Colors = @{
    Reset   = "`e[0m"
    Red     = "`e[31m"
    Green   = "`e[32m"
    Blue    = "`e[34m"
    Yellow  = "`e[33m"
}

function Write-Header {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║ mcp-server-azure-postgres Installation        ║" -ForegroundColor Blue
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "→ $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Main {
    Write-Header

    # Check Node.js
    Write-Step "Checking Node.js..."
    if (Test-CommandExists "node") {
        $NodeVersion = node --version
        Write-Success "Node.js $NodeVersion found"
    }
    else {
        Write-Error-Custom "Node.js is not installed"
        Write-Host "Please install Node.js (v20+) from https://nodejs.org/" -ForegroundColor Cyan
        exit 1
    }

    # Check npm
    Write-Step "Checking npm..."
    if (Test-CommandExists "npm") {
        $NpmVersion = npm --version
        Write-Success "npm $NpmVersion found"
    }
    else {
        Write-Error-Custom "npm is not installed"
        exit 1
    }

    # Check Azure CLI
    Write-Step "Checking Azure CLI..."
    if (Test-CommandExists "az") {
        Write-Success "Azure CLI found"
    }
    else {
        Write-Warning-Custom "Azure CLI not found - you'll need it for 'az login' auth"
        Write-Host "Install from: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Cyan
    }

    # Check Claude Code
    Write-Step "Checking Claude Code..."
    $SettingsPath = "$env:USERPROFILE\.claude\settings.json"
    if (Test-Path $SettingsPath) {
        Write-Success "Claude Code settings found"
    }
    else {
        Write-Warning-Custom "Claude Code settings not found yet (will be created)"
    }

    # Get PostgreSQL connection info
    Write-Host ""
    Write-Step "PostgreSQL Configuration"
    Write-Host "Enter your Azure PostgreSQL connection details:" -ForegroundColor Cyan
    Write-Host ""

    $PGHOST = Read-Host "  PGHOST (e.g., myserver.postgres.database.azure.com)"
    $PGDATABASE = Read-Host "  PGDATABASE (e.g., mydb)"
    $PGUSER = Read-Host "  PGUSER (e.g., myapp)"
    $PGPORTInput = Read-Host "  PGPORT (default 5432)"
    $PGPORT = if ([string]::IsNullOrWhiteSpace($PGPORTInput)) { "5432" } else { $PGPORTInput }

    # Get authentication method
    Write-Host ""
    Write-Step "Azure Authentication Method"
    Write-Host "How do you want to authenticate with Azure?" -ForegroundColor Cyan
    Write-Host "  1) az login (login locally)"
    Write-Host "  2) Service Principal (provide credentials)"
    Write-Host ""
    $AuthMethodInput = Read-Host "  Select [1-2] (default 1)"
    $AuthMethod = if ([string]::IsNullOrWhiteSpace($AuthMethodInput)) { "1" } else { $AuthMethodInput }

    $AZURE_TENANT_ID = ""
    $AZURE_CLIENT_ID = ""
    $AZURE_CLIENT_SECRET = ""

    if ($AuthMethod -eq "2") {
        Write-Host ""
        $AZURE_TENANT_ID = Read-Host "  AZURE_TENANT_ID"
        $AZURE_CLIENT_ID = Read-Host "  AZURE_CLIENT_ID"
        $AZURE_CLIENT_SECRET = Read-Host "  AZURE_CLIENT_SECRET (input hidden)" -AsSecureString
        $AZURE_CLIENT_SECRET = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AZURE_CLIENT_SECRET))
    }

    # Create settings
    Write-Host ""
    Write-Step "Configuring Claude Code..."

    $ClaudeDir = "$env:USERPROFILE\.claude"
    if (-not (Test-Path $ClaudeDir)) {
        New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
    }

    $SettingsFile = "$ClaudeDir\settings.json"

    # Backup existing
    if (Test-Path $SettingsFile) {
        $BackupFile = "$SettingsFile.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $SettingsFile -Destination $BackupFile
        Write-Success "Backed up existing settings to $BackupFile"
    }

    # Create settings object
    $Settings = @{
        theme      = "auto"
        mcpServers = @{
            "pg-azure" = @{
                command = "npx"
                args    = @("-y", "github:Ryzeon/mcp-server-azure-postgres")
                env     = @{
                    PGHOST     = $PGHOST
                    PGDATABASE = $PGDATABASE
                    PGUSER     = $PGUSER
                    PGPORT     = $PGPORT
                }
            }
        }
    }

    # Add Azure credentials if Service Principal
    if ($AuthMethod -eq "2") {
        $Settings.mcpServers["pg-azure"].env["AZURE_TENANT_ID"] = $AZURE_TENANT_ID
        $Settings.mcpServers["pg-azure"].env["AZURE_CLIENT_ID"] = $AZURE_CLIENT_ID
        $Settings.mcpServers["pg-azure"].env["AZURE_CLIENT_SECRET"] = $AZURE_CLIENT_SECRET
    }

    # Write settings
    $Settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $SettingsFile -Encoding UTF8
    Write-Success "Claude Code configured at $SettingsFile"

    # Final instructions
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║ Installation Complete! ✓                    ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""

    Write-Success "MCP server configured and ready to use"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Restart Claude Code or reload MCP with /mcp"
    Write-Host "  2. Test with: /mcp"
    Write-Host "  3. Use tools: query, list_schemas, list_tables, describe_table"
    Write-Host ""

    if ($AuthMethod -eq "1") {
        Write-Host "ℹ Make sure you've run 'az login' before using the MCP server" -ForegroundColor Yellow
        Write-Host ""
    }

    Write-Host "For more info: https://github.com/Ryzeon/mcp-server-azure-postgres" -ForegroundColor Cyan
}

Main
