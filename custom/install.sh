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

# Run yay update
yay -Sy

# Check if current shell is zsh, if not install it
# Use ps to get the actual running shell, not $SHELL which is the default shell
CURRENT_SHELL=$(ps -p $$ -o comm= 2>/dev/null | xargs basename 2>/dev/null || echo "unknown")
if [ "$CURRENT_SHELL" != "zsh" ]; then
    echo -e "${BLUE}Installing zsh...${NC}"
    yay -S --noconfirm --needed omarchy-zsh
    omarchy-setup-zsh
    echo -e "${GREEN}zsh installed and configured${NC}"

    echo -e "${BLUE}Switching to zsh...${NC}"
    exec zsh "$0"
    exit 0
fi

# Run install-desktop.sh
echo -e "${BLUE}Installing Desktop Packages...${NC}"
bash ./install-desktop.sh
echo

# Run install-dev.sh
echo -e "${BLUE}Installing Development Environment...${NC}"
bash ./install-dev.sh
echo

# Run install-utils.sh
echo -e "${BLUE}Installing System Utilities...${NC}"
bash ./install-utils.sh
echo

# Run install-terminal.sh
echo -e "${BLUE}Installing Terminal & Shell Configuration...${NC}"
bash ./install-terminal.sh
echo


# Run config-desktop.sh
# echo -e "${BLUE}Configuring Desktop Workspaces...${NC}"
# bash ./config-desktop.sh
# echo

# Run uninstall.sh
echo -e "${BLUE}Uninstalling Packages & Applications...${NC}"
bash ./uninstall.sh
echo

# Final summary
echo -e "${BLUE}All operations complete${NC}\n"
