#!/bin/bash

# Install development tools and packages for Omarchy
# This script installs PHP, Node.js tools, cloud CLIs, Kubernetes tools, and utilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Omarchy Development Environment Installation        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# mise is already installed, but ensure it's available (AUR)
if ! command -v mise &>/dev/null; then
    yay -S --noconfirm --needed mise
fi


# Install Node.js via mise
echo -e "${YELLOW}  Installing Node.js via mise...${NC}"
mise use --global node@lts 2>/dev/null || mise use --global node@latest

# Install Bun via mise
echo -e "${YELLOW}  Installing Bun via mise...${NC}"
mise use --global bun@latest 2>/dev/null || echo -e "${YELLOW}  Bun installation skipped (may already be installed)${NC}"

# npm and pnpm packages
echo -e "${YELLOW}  Installing npm and pnpm...${NC}"
yay -S --noconfirm --needed npm pnpm

echo -e "${GREEN}  ✓ Node.js ecosystem installed${NC}\n"

# PHP, Composer, Laravel
echo -e "${YELLOW}📦 Installing PHP, Composer, and Laravel...${NC}"
omarchy-install-dev-env laravel
echo -e "${GREEN}  ✓ PHP, Composer, and Laravel installed${NC}\n"

# Node.js ecosystem (mise, node, bun, npm, pnpm)
echo -e "${YELLOW}📦 Installing Node.js ecosystem...${NC}"

# Cloud CLIs
echo -e "${YELLOW}☁️  Installing Cloud CLIs...${NC}"
yay -S --noconfirm --needed azure-cli google-cloud-cli pulumi
echo -e "${GREEN}  ✓ Cloud CLIs installed${NC}\n"

# Kubernetes tools
echo -e "${YELLOW}☸️  Installing Kubernetes tools...${NC}"
yay -S --noconfirm --needed kubectl kubectx helm k9s

if command -v helm &>/dev/null; then
    helm repo add stable https://kubernetes-charts.storage.googleapis.com/ 2>/dev/null || true
    helm repo update 2>/dev/null || true
fi
echo -e "${GREEN}  ✓ Kubernetes tools installed${NC}\n"

# IDE (AUR)
echo -e "${YELLOW}💻 Installing IDE...${NC}"
yay -S --noconfirm --needed cursor-bin
echo -e "${GREEN}  ✓ IDE installed${NC}\n"

# System utilities
echo -e "${YELLOW}🔧 Installing system utilities...${NC}"
yay -S --noconfirm --needed cpupower dell-command-configure bind jq
echo -e "${GREEN}  ✓ System utilities installed${NC}\n"

# Summary
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Installation Complete!                      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Installed packages:${NC}"
echo -e "  • PHP, Composer, Laravel"
echo -e "  • mise, Node.js, Bun, npm, pnpm"
echo -e "  • Azure CLI, Google Cloud CLI, Pulumi"
echo -e "  • kubectl, kubectx, helm, k9s"
echo -e "  • Cursor IDE"
echo -e "  • cpupower, dell-command-configure (cctk), bind, jq"
echo -e "\n${YELLOW}Note: You may need to restart your shell or run 'source ~/.bashrc' to use some tools.${NC}\n"

