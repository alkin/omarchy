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
if [ -f "$SCRIPT_DIR/install-terminal.sh" ]; then
    echo -e "${BLUE}Installing Terminal & Shell Configuration...${NC}"
    bash "$SCRIPT_DIR/install-terminal.sh"
    echo
else
    echo -e "${YELLOW}⚠ install-terminal.sh not found, skipping...${NC}\n"
fi

# Check if shell is zsh, if not exec zsh
CURRENT_SHELL=$(basename "$SHELL" 2>/dev/null || echo "unknown")
if [ "$CURRENT_SHELL" != "zsh" ]; then
    echo -e "${YELLOW}Switching to zsh...${NC}"
    exec zsh
fi

# Run install-dev.sh (only if shell is zsh)
if [ -f "$SCRIPT_DIR/install-dev.sh" ]; then
    echo -e "${BLUE}Installing Development Environment...${NC}"
    bash "$SCRIPT_DIR/install-dev.sh"
    echo
else
    echo -e "${YELLOW}⚠ install-dev.sh not found, skipping...${NC}\n"
fi

# Run install-desktop.sh
if [ -f "$SCRIPT_DIR/install-desktop.sh" ]; then
    echo -e "${BLUE}Installing Desktop Packages...${NC}"
    bash "$SCRIPT_DIR/install-desktop.sh"
    echo
else
    echo -e "${YELLOW}⚠ install-desktop.sh not found, skipping...${NC}\n"
fi

# Run config-desktop.sh
if [ -f "$SCRIPT_DIR/config-desktop.sh" ]; then
    echo -e "${BLUE}Configuring Desktop Workspaces...${NC}"
    bash "$SCRIPT_DIR/config-desktop.sh"
    echo
else
    echo -e "${YELLOW}⚠ config-desktop.sh not found, skipping...${NC}\n"
fi

# Run uninstall.sh
if [ -f "$SCRIPT_DIR/uninstall.sh" ]; then
    echo -e "${BLUE}Uninstalling Packages & Applications...${NC}"
    bash "$SCRIPT_DIR/uninstall.sh"
    echo
else
    echo -e "${YELLOW}⚠ uninstall.sh not found, skipping...${NC}\n"
fi

# Final summary
echo -e "${BLUE}All operations complete${NC}\n"
