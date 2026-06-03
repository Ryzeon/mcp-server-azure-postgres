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

    # Ask for MCP name
    Write-Host ""
    Write-Step "MCP Configuration Name"
    $MCPNameInput = Read-Host "  Name for this MCP (default pg-azure)"
    $MCPName = if ([string]::IsNullOrWhiteSpace($MCPNameInput)) { "pg-azure" } else { $MCPNameInput }

    # Generate configuration
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║ Configuration Generated ✓                   ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""

    Write-Host "Add this to your settings file (inside ""mcpServers""):" -ForegroundColor Cyan
    Write-Host ""

    # Build env object for display
    $EnvLines = @(
        '  "PGHOST": "' + $PGHOST + '",'
        '  "PGDATABASE": "' + $PGDATABASE + '",'
        '  "PGUSER": "' + $PGUSER + '",'
        '  "PGPORT": "' + $PGPORT + '"'
    )

    if (-not [string]::IsNullOrWhiteSpace($AZURE_TENANT_ID)) {
        $EnvLines += '  "AZURE_TENANT_ID": "' + $AZURE_TENANT_ID + '",'
        $EnvLines += '  "AZURE_CLIENT_ID": "' + $AZURE_CLIENT_ID + '",'
        $EnvLines[-1] = $EnvLines[-1] -replace ',$', ','
        $EnvLines += '  "AZURE_CLIENT_SECRET": "' + $AZURE_CLIENT_SECRET + '"'
    }

    Write-Host ('"' + $MCPName + '": {') -ForegroundColor Blue

    if ($InstallMethod -eq "1") {
        Write-Host '  "command": "npx",'
        Write-Host '  "args": ["-y", "github:Ryzeon/mcp-server-azure-postgres"],'
    }
    else {
        Write-Host '  "command": "mcp-server-azure-postgres",'
    }

    Write-Host '  "env": {'
    foreach ($line in $EnvLines) {
        Write-Host $line
    }
    Write-Host '  }'
    Write-Host ('}') -ForegroundColor Blue

    Write-Host ""
    Write-Host "Configuration details:" -ForegroundColor Cyan
    Write-Host "  - MCP Name: $MCPName"
    Write-Host "  - Command: $(if ($InstallMethod -eq '1') { 'npx' } else { 'mcp-server-azure-postgres' })"
    if ($InstallMethod -eq "2") {
        Write-Host "  - Install: npm install -g mcp-server-azure-postgres"
    }
    Write-Host "  - Auth: $(if ($AuthMethod -eq '1') { 'az login' } else { 'Service Principal' })"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Copy the configuration above"
    Write-Host "  2. Open your settings file (Claude: ~/.claude/settings.json, etc.)"
    Write-Host "  3. Find or create the ""mcpServers"" section"
    Write-Host "  4. Paste the configuration"
    Write-Host "  5. Restart your application"
    Write-Host ""

    if ($AuthMethod -eq "1") {
        Write-Info "Reminder: Run 'az login' before using the MCP"
        Write-Host ""
    }

    if ($InstallMethod -eq "2") {
        Write-Info "Install first: npm install -g mcp-server-azure-postgres"
        Write-Host ""
    }

    Write-Host "For more info: https://github.com/Ryzeon/mcp-server-azure-postgres" -ForegroundColor Cyan
}

Main
