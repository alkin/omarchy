#!/bin/bash

# Configure desktop-specific settings
# This script runs all desktop configuration scripts

set +e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"

echo -e "${BLUE}Configuring Desktop Settings...${NC}\n"

# Ensure config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo -e "${YELLOW}Error: Config directory not found at $CONFIG_DIR${NC}"
    exit 1
fi

# Run desktop autostart configuration
bash "$CONFIG_DIR/config-desktop-autostart.sh"
echo ""

# Clean up any duplicate blank lines in autostart.conf (idempotent cleanup)
AUTOSTART_CONF="$HOME/.config/hypr/autostart.conf"
if [ -f "$AUTOSTART_CONF" ]; then
    # Remove multiple consecutive blank lines, keeping only one
    sed -i '/^$/N;/^\n$/d' "$AUTOSTART_CONF" 2>/dev/null || true
    # Remove trailing blank lines
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$AUTOSTART_CONF" 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}Configuration complete!${NC}"
echo ""
echo -e "${GREEN}Summary of changes:${NC}"
echo -e "  • Workspace 1: Google Chrome (auto-launch on boot)"
echo -e "  • Workspace 2: Cursor (auto-launch on boot)"
echo -e "  • Workspace 6: Spotify (auto-launch on boot)"
echo -e "  • Scratchpad: 3 Ghostty terminal windows (auto-launch on boot)"
echo ""
echo -e "${YELLOW}Notes:${NC}"
echo -e "  • This script is idempotent - safe to run multiple times"
echo -e "  • Restart Hyprland or log out/in for all changes to take effect"
echo -e "  • Use ${BLUE}SUPER + S${NC} to toggle the scratchpad terminals"
echo ""
