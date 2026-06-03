# mcp-server-azure-postgres Setup Script for PowerShell
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1

function Write-Header {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║ mcp-server-azure-postgres Setup               ║" -ForegroundColor Blue
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

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ  $Message" -ForegroundColor Yellow
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
    Write-Host "  1) az login (recommended - login locally with 'az login')" -ForegroundColor Cyan
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

    # Choose installation method
    Write-Host ""
    Write-Step "Installation Method"
    Write-Host "  1) npx (recommended - always latest, no setup)" -ForegroundColor Cyan
    Write-Host "  2) npm install -g (install globally, faster)"
    Write-Host ""
    $InstallMethodInput = Read-Host "  Select [1-2] (default 1)"
    $InstallMethod = if ([string]::IsNullOrWhiteSpace($InstallMethodInput)) { "1" } else { $InstallMethodInput }

    # Create/update .claude/settings.json
    Write-Host ""
    Write-Step "Configuring Claude Code..."

    $ClaudeDir = "$env:USERPROFILE\.claude"
    if (-not (Test-Path $ClaudeDir)) {
        New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
    }

    $SettingsFile = "$ClaudeDir\settings.json"

    # Backup if exists
    if (Test-Path $SettingsFile) {
        $BackupFile = "$SettingsFile.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $SettingsFile -Destination $BackupFile
        Write-Success "Backed up existing settings"
    }

    # Build settings object
    $Settings = @{
        theme      = "auto"
        mcpServers = @{
            "pg-azure" = @{
                env = @{
                    PGHOST     = $PGHOST
                    PGDATABASE = $PGDATABASE
                    PGUSER     = $PGUSER
                    PGPORT     = $PGPORT
                }
            }
        }
    }

    # Add command and args
    if ($InstallMethod -eq "1") {
        $Settings.mcpServers["pg-azure"]["command"] = "npx"
        $Settings.mcpServers["pg-azure"]["args"] = @("-y", "github:Ryzeon/mcp-server-azure-postgres")
    }
    else {
        $Settings.mcpServers["pg-azure"]["command"] = "mcp-server-azure-postgres"
    }

    # Add Azure credentials if Service Principal
    if ($AuthMethod -eq "2") {
        $Settings.mcpServers["pg-azure"].env["AZURE_TENANT_ID"] = $AZURE_TENANT_ID
        $Settings.mcpServers["pg-azure"].env["AZURE_CLIENT_ID"] = $AZURE_CLIENT_ID
        $Settings.mcpServers["pg-azure"].env["AZURE_CLIENT_SECRET"] = $AZURE_CLIENT_SECRET
    }

    # Write settings
    $Settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $SettingsFile -Encoding UTF8
    Write-Success "Configured at $SettingsFile"

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║ Setup Complete! ✓                            ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Restart Claude Code or reload MCP with /mcp"
    Write-Host "  2. Test with: /mcp"
    Write-Host ""

    if ($InstallMethod -eq "2") {
        Write-Host "First time setup:"
        Write-Host "  npm install -g mcp-server-azure-postgres"
        Write-Host ""
    }

    if ($AuthMethod -eq "1") {
        Write-Info "Make sure you've run 'az login' before using the MCP"
        Write-Host ""
    }

    Write-Host "For more info: https://github.com/Ryzeon/mcp-server-azure-postgres" -ForegroundColor Cyan
}

Main
