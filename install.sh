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
    echo -e "${BLUE}║${NC} mcp-server-azure-postgres Installation        ${BLUE}║${NC}"
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

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Main installation
main() {
    print_header

    # Check Node.js
    print_step "Checking Node.js..."
    if check_command "node"; then
        NODE_VERSION=$(node -v)
        print_success "Node.js $NODE_VERSION found"
    else
        print_error "Node.js is not installed"
        echo -e "Please install Node.js (v20+) from https://nodejs.org/"
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

    # Check Azure CLI
    print_step "Checking Azure CLI..."
    if check_command "az"; then
        AZ_VERSION=$(az version --output json 2>/dev/null | grep -o '"azure-cli": "[^"]*' | cut -d'"' -f4)
        print_success "Azure CLI $AZ_VERSION found"
    else
        print_warning "Azure CLI not found - you'll need it for 'az login' auth"
        echo -e "Install from: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
    fi

    # Check Claude Code
    print_step "Checking Claude Code..."
    if [ -f "$HOME/.claude/settings.json" ]; then
        print_success "Claude Code settings found"
    else
        print_warning "Claude Code settings not found yet (will be created)"
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
    echo "How do you want to authenticate with Azure?"
    echo "  1) az login (login locally)"
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

    # Create settings
    echo ""
    print_step "Configuring Claude Code..."

    mkdir -p "$HOME/.claude"

    # Read existing settings or create new
    SETTINGS_FILE="$HOME/.claude/settings.json"
    if [ -f "$SETTINGS_FILE" ]; then
        # Backup existing
        cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%s)"
        print_success "Backed up existing settings to $SETTINGS_FILE.backup.*"
    fi

    # Create settings JSON
    cat > "$SETTINGS_FILE" <<EOF
{
  "theme": "auto",
  "mcpServers": {
    "pg-azure": {
      "command": "npx",
      "args": ["-y", "github:Ryzeon/mcp-server-azure-postgres"],
      "env": {
        "PGHOST": "$PGHOST",
        "PGDATABASE": "$PGDATABASE",
        "PGUSER": "$PGUSER",
        "PGPORT": "$PGPORT"
EOF

    if [ -n "$AZURE_TENANT_ID" ]; then
        cat >> "$SETTINGS_FILE" <<EOF
,
        "AZURE_TENANT_ID": "$AZURE_TENANT_ID",
        "AZURE_CLIENT_ID": "$AZURE_CLIENT_ID",
        "AZURE_CLIENT_SECRET": "$AZURE_CLIENT_SECRET"
EOF
    fi

    cat >> "$SETTINGS_FILE" <<EOF
      }
    }
  }
}
EOF

    print_success "Claude Code configured at $SETTINGS_FILE"

    # Final instructions
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC} Installation Complete! ✓                    ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""

    print_success "MCP server configured and ready to use"
    echo ""
    echo "Next steps:"
    echo "  1. Restart Claude Code or reload MCP with /mcp"
    echo "  2. Test with: /mcp"
    echo "  3. Use tools: query, list_schemas, list_tables, describe_table"
    echo ""

    if [ "$AUTH_METHOD" = "1" ]; then
        echo -e "${YELLOW}ℹ${NC}  Make sure you've run 'az login' before using the MCP server"
        echo ""
    fi

    echo "For more info: https://github.com/Ryzeon/mcp-server-azure-postgres"
}

main "$@"
