#!/bin/bash

# Main installation script for custom Omarchy configurations
# This script runs all installation and configuration scripts

set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run yay update
yay -Sy

# Run install-terminal.sh FIRST
echo -e "${BLUE}Installing Terminal & Shell Configuration...${NC}"
bash "$SCRIPT_DIR/install-terminal.sh"
echo

# Check if shell is zsh, if not exec zsh
CURRENT_SHELL=$(basename "$SHELL" 2>/dev/null || echo "unknown")
if [ "$CURRENT_SHELL" != "zsh" ]; then
    echo -e "${YELLOW}Switching to zsh...${NC}"
    exec zsh
fi

# Run install-dev.sh (only if shell is zsh)
echo -e "${BLUE}Installing Development Environment...${NC}"
bash "$SCRIPT_DIR/install-dev.sh"
echo

# Run install-desktop.sh
echo -e "${BLUE}Installing Desktop Packages...${NC}"
bash "$SCRIPT_DIR/install-desktop.sh"
echo

# Run config-desktop.sh
echo -e "${BLUE}Configuring Desktop Workspaces...${NC}"
bash "$SCRIPT_DIR/config-desktop.sh"
echo

# Run uninstall.sh
echo -e "${BLUE}Uninstalling Packages & Applications...${NC}"
bash "$SCRIPT_DIR/uninstall.sh"
echo

# Final summary
echo -e "${BLUE}All operations complete${NC}\n"
