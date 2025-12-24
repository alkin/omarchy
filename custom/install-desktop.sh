#!/bin/bash

# Install desktop packages and applications
# This script installs Google Chrome, DisplayLink drivers, Ventoy, and VeraCrypt

set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Desktop Packages Installation                      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Install Google Chrome (AUR)
echo -e "${YELLOW}🌐 Installing Google Chrome...${NC}"
yay -S --noconfirm --needed google-chrome
echo -e "${GREEN}  ✓ Google Chrome installed${NC}\n"

# Set Google Chrome as default browser
echo -e "${YELLOW}⚙️  Setting Google Chrome as default browser...${NC}"
if command -v google-chrome-stable &>/dev/null || command -v google-chrome &>/dev/null; then
    # Find the desktop file
    CHROME_DESKTOP=$(find /usr/share/applications ~/.local/share/applications -name "*google-chrome*.desktop" 2>/dev/null | head -1)

    if [ -n "$CHROME_DESKTOP" ]; then
        DESKTOP_BASENAME=$(basename "$CHROME_DESKTOP")
        xdg-settings set default-web-browser "$DESKTOP_BASENAME"
        xdg-mime default "$DESKTOP_BASENAME" x-scheme-handler/http
        xdg-mime default "$DESKTOP_BASENAME" x-scheme-handler/https
        echo -e "${GREEN}  ✓ Google Chrome set as default browser${NC}"
    else
        echo -e "${YELLOW}  ⚠ Could not find Google Chrome desktop file${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠ Google Chrome executable not found${NC}"
fi
echo ""

# Install DisplayLink drivers (AUR)
echo -e "${YELLOW}🖥️  Installing DisplayLink drivers...${NC}"
yay -S --noconfirm --needed evdi-dkms displaylink
echo -e "${GREEN}  ✓ DisplayLink drivers installed${NC}\n"

# Install Ventoy (AUR)
echo -e "${YELLOW}💾 Installing Ventoy...${NC}"
yay -S --noconfirm --needed ventoy-bin
echo -e "${GREEN}  ✓ Ventoy installed${NC}\n"

# Install VeraCrypt
echo -e "${YELLOW}🔒 Installing VeraCrypt...${NC}"
yay -S --noconfirm --needed veracrypt
echo -e "${GREEN}  ✓ VeraCrypt installed${NC}\n"

# Summary
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Installation Complete!                      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Installed packages:${NC}"
echo -e "  • Google Chrome (set as default browser)"
echo -e "  • DisplayLink drivers (evdi-dkms, displaylink)"
echo -e "  • Ventoy"
echo -e "  • VeraCrypt"
echo ""

