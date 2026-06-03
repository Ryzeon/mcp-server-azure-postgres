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

    # Generate environment variables export
    echo ""
    echo "Set these environment variables:"
    echo ""
    echo "export PGHOST='$PGHOST'"
    echo "export PGDATABASE='$PGDATABASE'"
    echo "export PGUSER='$PGUSER'"
    echo "export PGPORT='$PGPORT'"

    if [ -n "$AZURE_TENANT_ID" ]; then
        echo "export AZURE_TENANT_ID='$AZURE_TENANT_ID'"
        echo "export AZURE_CLIENT_ID='$AZURE_CLIENT_ID'"
        echo "export AZURE_CLIENT_SECRET='$AZURE_CLIENT_SECRET'"
    fi

    echo ""
    print_success "Configuration ready"
    echo ""

    # Show installation method
    echo "Next, install the MCP server:"
    echo ""

    if [ "$INSTALL_METHOD" = "1" ]; then
        echo "  # No installation needed - use with claude mcp add:"
        echo ""
        print_info "Register in Claude Code:"
        echo ""
        echo "  claude mcp add pg-azure --transport stdio -- npx -y github:Ryzeon/mcp-server-azure-postgres"
        echo ""
    else
        echo "  npm install -g mcp-server-azure-postgres"
        echo ""
        print_info "Then register in Claude Code:"
        echo ""
        echo "  claude mcp add pg-azure --transport stdio -- mcp-server-azure-postgres"
        echo ""
    fi

    if [ "$AUTH_METHOD" = "1" ]; then
        echo ""
        print_info "Make sure you've run 'az login' before using the MCP"
    fi

    echo ""
    echo -e "${GREEN}✓${NC} Setup complete!"
    echo ""
    echo "For more info: https://github.com/Ryzeon/mcp-server-azure-postgres"
}

main "$@"
