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

    # Show environment variables
    Write-Host ""
    Write-Host "Set these environment variables:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "`$env:PGHOST = '$PGHOST'"
    Write-Host "`$env:PGDATABASE = '$PGDATABASE'"
    Write-Host "`$env:PGUSER = '$PGUSER'"
    Write-Host "`$env:PGPORT = '$PGPORT'"

    if (-not [string]::IsNullOrWhiteSpace($AZURE_TENANT_ID)) {
        Write-Host "`$env:AZURE_TENANT_ID = '$AZURE_TENANT_ID'"
        Write-Host "`$env:AZURE_CLIENT_ID = '$AZURE_CLIENT_ID'"
        Write-Host "`$env:AZURE_CLIENT_SECRET = '***'"
    }

    Write-Host ""
    Write-Success "Configuration ready"
    Write-Host ""

    # Show next steps
    Write-Host "Next, install the MCP server:" -ForegroundColor Cyan
    Write-Host ""

    if ($InstallMethod -eq "1") {
        Write-Host "  # No installation needed - use with claude mcp add:"
        Write-Host ""
        Write-Info "Register in Claude Code:"
        Write-Host ""
        Write-Host "  claude mcp add pg-azure --transport stdio -- npx -y github:Ryzeon/mcp-server-azure-postgres"
        Write-Host ""
    }
    else {
        Write-Host "  npm install -g mcp-server-azure-postgres"
        Write-Host ""
        Write-Info "Then register in Claude Code:"
        Write-Host ""
        Write-Host "  claude mcp add pg-azure --transport stdio -- mcp-server-azure-postgres"
        Write-Host ""
    }

    if ($AuthMethod -eq "1") {
        Write-Host ""
        Write-Info "Make sure you've run 'az login' before using the MCP"
    }

    Write-Host ""
    Write-Success "Setup complete!"
    Write-Host ""
    Write-Host "For more info: https://github.com/Ryzeon/mcp-server-azure-postgres" -ForegroundColor Cyan
}

Main
