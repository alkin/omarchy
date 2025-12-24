#!/bin/bash

# Install system utilities
# This script installs system-level utilities and tools

set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing System Utilities...${NC}\n"

# System utilities
echo -e "${YELLOW}🔧 Installing system utilities...${NC}"
yay -S --noconfirm --needed cpupower dell-command-configure bind jq
echo -e "${GREEN}  ✓ System utilities installed${NC}\n"

echo -e "${GREEN}Installation complete:${NC}"
echo -e "  • cpupower"
echo -e "  • dell-command-configure (cctk)"
echo -e "  • bind"
echo -e "  • jq"
echo ""

