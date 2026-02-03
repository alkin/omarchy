#!/bin/bash

# Configure waybar to use different configs per monitor using array format

set +e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚙️  Configuring waybar with per-monitor configs...${NC}"

WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
WAYBAR_CONFIG="$WAYBAR_CONFIG_DIR/config.jsonc"

# Ensure waybar config directory exists
mkdir -p "$WAYBAR_CONFIG_DIR"

# Configure external monitor name - hardcoded from 'hyprctl monitors' output
# External monitor: DVI-I-1 (Philips Consumer Electronics Company PHL 231P4U)
# Laptop monitor: eDP-1 (LG Display)
EXTERNAL_MONITOR_NAME="${EXTERNAL_MONITOR_NAME:-DVI-I-1}"
LAPTOP_MONITOR_NAME="${LAPTOP_MONITOR_NAME:-eDP-1}"

echo -e "${YELLOW}  ℹ️  External monitor: ${EXTERNAL_MONITOR_NAME}${NC}"
echo -e "${YELLOW}  ℹ️  Laptop monitor: ${LAPTOP_MONITOR_NAME}${NC}"

# Check if jq is available, install if not
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}  Installing jq...${NC}"
    yay -S --noconfirm --needed jq 2>/dev/null || {
        echo -e "${RED}  ✗ Error: Failed to install jq${NC}"
        exit 1
    }
fi

# Backup existing config if it exists and is not already an array
if [ -f "$WAYBAR_CONFIG" ] && [ -s "$WAYBAR_CONFIG" ]; then
    # Check if config is already an array
    if jq -e 'type == "array"' "$WAYBAR_CONFIG" &>/dev/null; then
        echo -e "${GREEN}  ✓ Config is already an array format${NC}"
    else
        # Backup the original config
        BACKUP_FILE="${WAYBAR_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$WAYBAR_CONFIG" "$BACKUP_FILE" 2>/dev/null || {
            echo -e "${RED}  ✗ Error: Cannot backup config (permission issue?)${NC}"
            echo -e "${YELLOW}     Please check file permissions: ls -la $WAYBAR_CONFIG${NC}"
        }
        if [ -f "$BACKUP_FILE" ]; then
            echo -e "${YELLOW}  ℹ️  Backed up existing config to: ${BACKUP_FILE}${NC}"
        fi
    fi
fi

# Read the base config
if [ -f "$WAYBAR_CONFIG" ] && jq -e 'type == "array"' "$WAYBAR_CONFIG" &>/dev/null; then
    # Config is already an array, check if we need to update or use first element
    EXTERNAL_EXISTS=$(jq --arg monitor "$EXTERNAL_MONITOR_NAME" '[.[] | select(.output == $monitor)] | length' "$WAYBAR_CONFIG")
    LAPTOP_EXISTS=$(jq --arg monitor "$LAPTOP_MONITOR_NAME" '[.[] | select(.output == $monitor)] | length' "$WAYBAR_CONFIG")
    
    if [ "$EXTERNAL_EXISTS" -gt 0 ] && [ "$LAPTOP_EXISTS" -gt 0 ]; then
        echo -e "${GREEN}  ✓ Config already has both monitor configs, updating sizes...${NC}"
        # Update existing configs with correct sizes
        jq --arg ext_mon "$EXTERNAL_MONITOR_NAME" --arg lap_mon "$LAPTOP_MONITOR_NAME" '
          map(
            if .output == $ext_mon then
              .height = 36 | .tray = ((.tray // {}) | .["icon-size"] = 16 | .spacing = (.spacing // 17))
            elif .output == $lap_mon then
              .height = 26 | .tray = ((.tray // {}) | .["icon-size"] = 12 | .spacing = (.spacing // 17))
            else
              .
            end
          )
        ' "$WAYBAR_CONFIG" > "${WAYBAR_CONFIG}.tmp" && mv "${WAYBAR_CONFIG}.tmp" "$WAYBAR_CONFIG"
        echo -e "${GREEN}  ✓ Updated monitor configs with correct sizes${NC}"
        exit 0
    else
        # Extract first element as base, or merge all non-output-specific configs
        BASE_CONFIG=$(jq '[.[] | del(.output)] | add | .' "$WAYBAR_CONFIG" 2>/dev/null || jq '.[0] | del(.output)' "$WAYBAR_CONFIG")
    fi
elif [ -f "$WAYBAR_CONFIG" ] && jq -e 'type == "object"' "$WAYBAR_CONFIG" &>/dev/null; then
    # Config is an object, use it as base
    BASE_CONFIG=$(cat "$WAYBAR_CONFIG")
else
    # Config doesn't exist or is invalid, read from default location
    DEFAULT_CONFIG="$HOME/.local/share/omarchy/config/waybar/config.jsonc"
    if [ -f "$DEFAULT_CONFIG" ]; then
        BASE_CONFIG=$(cat "$DEFAULT_CONFIG")
    else
        echo -e "${RED}  ✗ Error: No waybar config found${NC}"
        exit 1
    fi
fi

# Remove output field if it exists in base config
BASE_CONFIG=$(echo "$BASE_CONFIG" | jq 'del(.output)')

# Create config for external monitor (larger sizes)
EXTERNAL_CONFIG=$(echo "$BASE_CONFIG" | jq --arg monitor "$EXTERNAL_MONITOR_NAME" '
  .output = $monitor |
  .height = 36 |
  .tray = ((.tray // {}) | .["icon-size"] = 16 | .spacing = (.spacing // 17)) |
  .
')

# Create config for laptop monitor (default sizes)
LAPTOP_CONFIG=$(echo "$BASE_CONFIG" | jq --arg monitor "$LAPTOP_MONITOR_NAME" '
  .output = $monitor |
  .height = 26 |
  .tray = ((.tray // {}) | .["icon-size"] = 12 | .spacing = (.spacing // 17)) |
  .
')

# Combine into array format
FINAL_CONFIG=$(jq -n --argjson external "$EXTERNAL_CONFIG" --argjson laptop "$LAPTOP_CONFIG" '[$external, $laptop]')

# Write the new config to a temp file first, then move it
TMP_CONFIG="${WAYBAR_CONFIG}.tmp.$$"
echo "$FINAL_CONFIG" | jq '.' > "$TMP_CONFIG" 2>/dev/null

if [ $? -eq 0 ] && [ -s "$TMP_CONFIG" ]; then
    # Validate JSON before moving
    if jq '.' "$TMP_CONFIG" > /dev/null 2>&1; then
        # Try to move the file, check for permission errors
        if mv "$TMP_CONFIG" "$WAYBAR_CONFIG" 2>/dev/null; then
            echo -e "${GREEN}  ✓ Updated waybar config with per-monitor settings${NC}"
            echo -e "${GREEN}    - ${EXTERNAL_MONITOR_NAME}: height 36px, icon-size 16px${NC}"
            echo -e "${GREEN}    - ${LAPTOP_MONITOR_NAME}: height 26px, icon-size 12px${NC}"
        else
            rm -f "$TMP_CONFIG"
            echo -e "${RED}  ✗ Error: Cannot write to config file (permission issue?)${NC}"
            echo -e "${YELLOW}     Please check file permissions: ls -la $WAYBAR_CONFIG${NC}"
            echo -e "${YELLOW}     You may need to run: sudo chown $USER:$USER $WAYBAR_CONFIG${NC}"
            exit 1
        fi
    else
        rm -f "$TMP_CONFIG"
        echo -e "${RED}  ✗ Error: Generated JSON is invalid${NC}"
        exit 1
    fi
else
    rm -f "$TMP_CONFIG"
    echo -e "${RED}  ✗ Error updating waybar config${NC}"
    exit 1
fi

# Update CSS to increase font size (applies globally, but helps with external monitor)
WAYBAR_STYLE="$WAYBAR_CONFIG_DIR/style.css"

if [ -f "$WAYBAR_STYLE" ]; then
    # Increase font-size from 12px to 16px for better visibility on external monitor
    # Note: This applies globally, but the waybar config handles per-monitor height/icon-size
    if grep -q "font-size: 12px" "$WAYBAR_STYLE"; then
        sed -i 's/font-size: 12px/font-size: 16px/' "$WAYBAR_STYLE"
        echo -e "${GREEN}  ✓ Updated CSS font-size to 16px${NC}"
    elif grep -q "font-size: 16px" "$WAYBAR_STYLE"; then
        echo -e "${GREEN}  ✓ CSS font-size already set to 16px${NC}"
    else
        echo -e "${YELLOW}  ℹ️  Could not find font-size in CSS to update${NC}"
    fi
else
    echo -e "${YELLOW}  ℹ️  Style.css not found, waybar will use default styles${NC}"
fi

echo ""
echo -e "${YELLOW}Notes:${NC}"
echo -e "  • Waybar will automatically use the correct config for each monitor"
echo -e "  • Config uses array format with 'output' field to specify monitor"
echo -e "  • Restart waybar to apply changes: ${GREEN}killall waybar && waybar &${NC}"
echo -e "  • Or restart Hyprland for all changes to take effect"
