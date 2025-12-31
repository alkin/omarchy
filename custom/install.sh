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
