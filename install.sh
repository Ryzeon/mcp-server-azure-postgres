#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} mcp-server-azure-postgres Setup               ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
    echo -e "${BLUE}→${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC}  $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Main
main() {
    print_header

    # Check Node.js
    print_step "Checking Node.js..."
    if check_command "node"; then
        NODE_VERSION=$(node -v)
        print_success "Node.js $NODE_VERSION found"
    else
        print_error "Node.js is not installed"
        echo "Please install Node.js (v20+) from https://nodejs.org/"
        exit 1
    fi

    # Check npm
    print_step "Checking npm..."
    if check_command "npm"; then
        NPM_VERSION=$(npm -v)
        print_success "npm $NPM_VERSION found"
    else
        print_error "npm is not installed"
        exit 1
    fi

    # Get PostgreSQL connection info
    echo ""
    print_step "PostgreSQL Configuration"
    echo "Enter your Azure PostgreSQL connection details:"
    echo ""

    read -p "  PGHOST (e.g., myserver.postgres.database.azure.com): " PGHOST
    read -p "  PGDATABASE (e.g., mydb): " PGDATABASE
    read -p "  PGUSER (e.g., myapp): " PGUSER
    read -p "  PGPORT (default 5432): " PGPORT
    PGPORT=${PGPORT:-5432}

    # Get authentication method
    echo ""
    print_step "Azure Authentication Method"
    echo "  1) az login (recommended - login locally with 'az login')"
    echo "  2) Service Principal (provide credentials)"
    echo ""
    read -p "  Select [1-2] (default 1): " AUTH_METHOD
    AUTH_METHOD=${AUTH_METHOD:-1}

    AZURE_TENANT_ID=""
    AZURE_CLIENT_ID=""
    AZURE_CLIENT_SECRET=""

    if [ "$AUTH_METHOD" = "2" ]; then
        echo ""
        read -p "  AZURE_TENANT_ID: " AZURE_TENANT_ID
        read -p "  AZURE_CLIENT_ID: " AZURE_CLIENT_ID
        read -sp "  AZURE_CLIENT_SECRET: " AZURE_CLIENT_SECRET
        echo ""
    fi

    # Choose installation method
    echo ""
    print_step "Installation Method"
    echo "  1) npx (recommended - always latest, no setup)"
    echo "  2) npm install -g (install globally, faster)"
    echo ""
    read -p "  Select [1-2] (default 1): " INSTALL_METHOD
    INSTALL_METHOD=${INSTALL_METHOD:-1}

    # Create/update .claude/settings.json
    echo ""
    print_step "Configuring Claude Code..."

    mkdir -p "$HOME/.claude"
    SETTINGS_FILE="$HOME/.claude/settings.json"

    # Backup if exists
    if [ -f "$SETTINGS_FILE" ]; then
        cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%s)"
        print_success "Backed up existing settings"
    fi

    # Determine command based on method
    if [ "$INSTALL_METHOD" = "1" ]; then
        COMMAND="npx"
        ARGS='["-y", "github:Ryzeon/mcp-server-azure-postgres"]'
    else
        COMMAND="mcp-server-azure-postgres"
        ARGS="null"
    fi

    # Build Python script to merge JSON
    python3 << PYTHON_EOF
import json
import os

settings_file = "$SETTINGS_FILE"
command = "$COMMAND"
args = $ARGS

# Build env object
env = {
    "PGHOST": "$PGHOST",
    "PGDATABASE": "$PGDATABASE",
    "PGUSER": "$PGUSER",
    "PGPORT": "$PGPORT"
}

# Add Azure credentials if provided
if "$AZURE_TENANT_ID":
    env["AZURE_TENANT_ID"] = "$AZURE_TENANT_ID"
    env["AZURE_CLIENT_ID"] = "$AZURE_CLIENT_ID"
    env["AZURE_CLIENT_SECRET"] = "$AZURE_CLIENT_SECRET"

# Build MCP config
mcp_config = {
    "command": command,
    "env": env
}

if args is not None:
    mcp_config["args"] = args

# Load existing settings or create new
if os.path.exists(settings_file):
    with open(settings_file, 'r') as f:
        settings = json.load(f)
else:
    settings = {"theme": "auto"}

# Ensure mcpServers exists
if "mcpServers" not in settings:
    settings["mcpServers"] = {}

# Add/update pg-azure
settings["mcpServers"]["pg-azure"] = mcp_config

# Write back
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)

print("✓ Updated at " + settings_file)
PYTHON_EOF

    print_success "Settings configured"

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC} Setup Complete! ✓                            ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Restart Claude Code or reload MCP with /mcp"
    echo "  2. Test with: /mcp"
    echo ""

    if [ "$INSTALL_METHOD" = "2" ]; then
        echo "First time setup:"
        echo "  npm install -g mcp-server-azure-postgres"
        echo ""
    fi

    if [ "$AUTH_METHOD" = "1" ]; then
        echo -e "${YELLOW}ℹ${NC}  Make sure you've run 'az login' before using the MCP"
        echo ""
    fi

    echo "For more info: https://github.com/Ryzeon/mcp-server-azure-postgres"
}

main "$@"
