#!/bin/bash

# Uninstall script for custom Omarchy packages and applications
# This script removes specified packages and web applications

# Don't exit on error - we want to continue removing other packages even if one fails
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting uninstallation of packages and applications...${NC}\n"

# Packages to uninstall
PACKAGES=(
    "1password-beta"
    "1password-cli"
    "alacritty"
    "obsidian"
    "obs-studio"
    "omarchy-chromium"
    "typora"
)

# Web applications to uninstall
WEBAPPS=(
    "HEY"
    "Basecamp"
    "ChatGPT"
    "X"
    "Figma"
    "Discord"
    "Zoom"
    "Fizzy"
)

# Uninstall packages
echo -e "${YELLOW}Uninstalling packages...${NC}"
INSTALLED_PACKAGES=()

# Collect installed packages
for pkg in "${PACKAGES[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        INSTALLED_PACKAGES+=("$pkg")
        echo -e "  Found ${GREEN}$pkg${NC}"
    else
        echo -e "  ${YELLOW}$pkg${NC} is not installed, skipping..."
    fi
done

# Uninstall all installed packages in a single call
if [[ ${#INSTALLED_PACKAGES[@]} -gt 0 ]]; then
    echo -e "\n  Removing ${#INSTALLED_PACKAGES[@]} package(s) in a single operation..."
    if ! sudo pacman -Rns --noconfirm "${INSTALLED_PACKAGES[@]}"; then
        echo -e "  ${RED}Failed to remove some packages${NC}"
    fi
else
    echo -e "  No packages to uninstall"
fi

# Uninstall web applications
echo -e "\n${YELLOW}Uninstalling web applications...${NC}"
ICON_DIR="$HOME/.local/share/applications/icons"
DESKTOP_DIR="$HOME/.local/share/applications"

for app in "${WEBAPPS[@]}"; do
    desktop_file="$DESKTOP_DIR/$app.desktop"
    icon_file="$ICON_DIR/$app.png"

    if [[ -f "$desktop_file" ]]; then
        echo -e "  Removing ${GREEN}$app${NC}"
        rm -f "$desktop_file"
        rm -f "$icon_file"
    else
        echo -e "  ${YELLOW}$app${NC} is not installed, skipping..."
    fi
done

# Clean up any remaining configuration files
echo -e "\n${YELLOW}Cleaning up configuration files...${NC}"

# Remove alacritty config if it exists
if [[ -d "$HOME/.config/alacritty" ]]; then
    echo -e "  Removing alacritty configuration"
    rm -rf "$HOME/.config/alacritty"
fi

# Remove typora config if it exists
if [[ -d "$HOME/.config/Typora" ]]; then
    echo -e "  Removing Typora configuration"
    rm -rf "$HOME/.config/Typora"
fi

# Remove typora desktop entry if it exists
if [[ -f "$HOME/.local/share/applications/typora.desktop" ]]; then
    echo -e "  Removing Typora desktop entry"
    rm -f "$HOME/.local/share/applications/typora.desktop"
fi

# Refresh applications database
if command -v update-desktop-database &>/dev/null; then
    echo -e "\n${YELLOW}Updating desktop database...${NC}"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

echo -e "\n${GREEN}Uninstallation complete!${NC}"

