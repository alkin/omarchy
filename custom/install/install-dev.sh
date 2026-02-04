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

echo -e "${BLUE}Installing Development Environment...${NC}\n"

# mise is already installed, but ensure it's available (AUR)
if ! command -v mise &>/dev/null; then
    yay -S --noconfirm --needed mise
fi

# Node.js ecosystem (mise, node, bun, npm, pnpm)
echo -e "${YELLOW}📦 Installing Node.js ecosystem...${NC}"

# Install Node.js via mise
echo -e "${YELLOW}  Installing Node.js via mise...${NC}"
mise use --global node@lts 2>/dev/null || mise use --global node@latest

# Install Bun via mise
echo -e "${YELLOW}  Installing Bun via mise...${NC}"
mise use --global bun@latest 2>/dev/null || echo -e "${YELLOW}  Bun installation skipped (may already be installed)${NC}"

# npm and pnpm packages
echo -e "${YELLOW}  Installing npm and pnpm...${NC}"
yay -S --noconfirm --needed npm pnpm yarn
echo -e "${GREEN}  ✓ Node.js ecosystem installed${NC}\n"

# PHP, Composer, Laravel
echo -e "${YELLOW}📦 Installing PHP and Composer...${NC}"
# Update pacman database to ensure keys are up to date
sudo pacman -Sy 2>/dev/null || true
omarchy-install-dev-env php

yay -S --noconfirm --needed php-gd php-sodium svt-av1

# Enable some extensions
local php_ini_path="/etc/php/php.ini"
local extensions_to_enable=(
"gd"
"sodium"
)

for ext in "${extensions_to_enable[@]}"; do
sudo sed -i "s/^;extension=${ext}/extension=${ext}/" "$php_ini_path"
done

echo -e "${GREEN}  ✓ PHP and Composer installed${NC}\n"

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

echo -e "${GREEN}Installation complete:${NC}"
echo -e "  • PHP, Composer"
echo -e "  • mise, Node.js, Bun, npm, pnpm"
echo -e "  • Azure CLI, Google Cloud CLI, Pulumi"
echo -e "  • kubectl, kubectx, helm, k9s"
echo -e "  • Cursor IDE"
echo -e "\n${YELLOW}Note: You may need to restart your shell or run 'source ~/.zshrc' (or 'source ~/.bashrc' if using bash) to use some tools.${NC}\n"

