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

# Run config-mirrors.sh
echo -e "${BLUE}Optimizing Arch Linux mirrors...${NC}"
bash ./config-mirrors.sh

# Run yay update
yay -Sy

# Run install-desktop.sh
echo -e "${BLUE}Installing Desktop Packages...${NC}"
bash ./install/install-desktop.sh
echo

# Run install-dev.sh
echo -e "${BLUE}Installing Development Environment...${NC}"
bash ./install/install-dev.sh
echo

# Run install-utils.sh
echo -e "${BLUE}Installing System Utilities...${NC}"
bash ./install/install-utils.sh
echo

# Run install-terminal.sh
echo -e "${BLUE}Installing Terminal & Shell Configuration...${NC}"
bash ./install/install-terminal.sh
echo

# Run install-dictation.sh
echo -e "${BLUE}Installing Dictation...${NC}"
bash ./install/install-dictation.sh
echo

# Run config-desktop.sh
echo -e "${BLUE}Configuring Desktop Workspaces...${NC}"
bash ./config-desktop.sh
echo

# Run config-laptop.sh
echo -e "${BLUE}Configuring Laptop Settings...${NC}"
bash ./config-laptop.sh
echo

# Run uninstall.sh
echo -e "${BLUE}Uninstalling Packages & Applications...${NC}"
bash ./uninstall.sh
echo

# Final summary
echo -e "${BLUE}All operations complete${NC}\n"
