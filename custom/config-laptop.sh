#!/bin/bash

# Configure laptop-specific settings
# This script runs all laptop configuration scripts

set +e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"

echo -e "${BLUE}Configuring Laptop Settings...${NC}\n"

# Ensure config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo -e "${YELLOW}Error: Config directory not found at $CONFIG_DIR${NC}"
    exit 1
fi

# Run each configuration script
bash "$CONFIG_DIR/config-trackpad.sh"
echo ""

bash "$CONFIG_DIR/config-f9-playpause.sh"
echo ""

bash "$CONFIG_DIR/config-remove-ctrl-f1.sh"
echo ""

bash "$CONFIG_DIR/config-waybar-monitor.sh"
echo ""

bash "$CONFIG_DIR/config-numlock.sh"
echo ""

bash "$CONFIG_DIR/config-zsh-keybindings.sh"
echo ""

bash "$CONFIG_DIR/config-ghostty-scroll.sh"
echo ""

bash "$CONFIG_DIR/config-opacity.sh"
echo ""

bash "$CONFIG_DIR/config-microphone.sh"
echo ""

# Clean up any duplicate blank lines in bindings.conf (idempotent cleanup)
BINDINGS_CONF="$HOME/.config/hypr/bindings.conf"
if [ -f "$BINDINGS_CONF" ]; then
    # Remove multiple consecutive blank lines, keeping only one
    sed -i '/^$/N;/^\n$/d' "$BINDINGS_CONF" 2>/dev/null || true
    # Remove trailing blank lines
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$BINDINGS_CONF" 2>/dev/null || true
fi

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
echo -e "  • Trackpad natural scroll enabled (inverted vertical scroll)"
echo -e "  • F9 key mapped to play/pause"
echo -e "  • CTRL F1 keybinding removed"
echo -e "  • Waybar scaling script created for external monitors (DVI-I-1)"
echo -e "  • Voxtype dictation configured with Portuguese Brazil model"
echo -e "  • Num Lock enabled automatically at boot (including disk encryption screen)"
echo -e "  • ZSH keybindings configured (HOME, END, INSERT, DELETE keys)"
echo -e "  • Ghostty scroll speed increased (mouse-scroll-multiplier = 1.5)"
echo -e "  • Window opacity disabled for all windows (opacity 1.0 1.0)"
echo -e "  • Microphone configuration: monitor mic disabled, internal mic set as default"
echo ""
echo -e "${YELLOW}Notes:${NC}"
echo -e "  • This script is idempotent - safe to run multiple times"
echo -e "  • Restart Hyprland or log out/in for all changes to take effect"
echo -e "  • After connecting/disconnecting an external monitor, run:"
echo -e "    ${BLUE}$HOME/.local/bin/omarchy-waybar-scale-monitor${NC}"
echo -e "  • The waybar scaling script will automatically adjust:"
echo -e "    - Height: 26px (laptop) → 36px (external monitor)"
echo -e "    - Font size: 12px (laptop) → 16px (external monitor)"
echo -e "    - Icon size: 12px (laptop) → 16px (external monitor)"
echo ""
