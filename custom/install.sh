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

# Banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║           Omarchy Custom Configuration Manager                 ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Track exit codes
EXIT_CODES=0

# Run yay update
yay -Sy

# Run install-dev.sh
if [ -f "$SCRIPT_DIR/install-dev.sh" ]; then
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        Installing Development Environment...              ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    bash "$SCRIPT_DIR/install-dev.sh"
    EXIT_CODE=$?
    EXIT_CODES=$((EXIT_CODES + EXIT_CODE))
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "\n${GREEN}✓ Development tools installation completed successfully!${NC}\n"
    else
        echo -e "\n${RED}✗ Development tools installation encountered errors.${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠ install-dev.sh not found, skipping...${NC}\n"
fi

# Run install-terminal.sh
if [ -f "$SCRIPT_DIR/install-terminal.sh" ]; then
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        Installing Terminal & Shell Configuration...      ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    bash "$SCRIPT_DIR/install-terminal.sh"
    EXIT_CODE=$?
    EXIT_CODES=$((EXIT_CODES + EXIT_CODE))
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "\n${GREEN}✓ Terminal configuration completed successfully!${NC}\n"
    else
        echo -e "\n${RED}✗ Terminal configuration encountered errors.${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠ install-terminal.sh not found, skipping...${NC}\n"
fi

# Run install-desktop.sh
if [ -f "$SCRIPT_DIR/install-desktop.sh" ]; then
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        Installing Desktop Packages...                    ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    bash "$SCRIPT_DIR/install-desktop.sh"
    EXIT_CODE=$?
    EXIT_CODES=$((EXIT_CODES + EXIT_CODE))
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "\n${GREEN}✓ Desktop packages installation completed successfully!${NC}\n"
    else
        echo -e "\n${RED}✗ Desktop packages installation encountered errors.${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠ install-desktop.sh not found, skipping...${NC}\n"
fi

# Run config-desktop.sh
if [ -f "$SCRIPT_DIR/config-desktop.sh" ]; then
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        Configuring Desktop Workspaces...                 ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    bash "$SCRIPT_DIR/config-desktop.sh"
    EXIT_CODE=$?
    EXIT_CODES=$((EXIT_CODES + EXIT_CODE))
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "\n${GREEN}✓ Desktop workspace configuration completed successfully!${NC}\n"
    else
        echo -e "\n${RED}✗ Desktop workspace configuration encountered errors.${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠ config-desktop.sh not found, skipping...${NC}\n"
fi

# Run uninstall.sh
if [ -f "$SCRIPT_DIR/uninstall.sh" ]; then
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        Uninstalling Packages & Applications...           ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    bash "$SCRIPT_DIR/uninstall.sh"
    EXIT_CODE=$?
    EXIT_CODES=$((EXIT_CODES + EXIT_CODE))
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "\n${GREEN}✓ Uninstallation completed successfully!${NC}\n"
    else
        echo -e "\n${RED}✗ Uninstallation encountered errors.${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠ uninstall.sh not found, skipping...${NC}\n"
fi

# Final summary
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    All Operations Complete                ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Exit with error if any script failed
if [ $EXIT_CODES -ne 0 ]; then
    exit 1
fi

exit 0
