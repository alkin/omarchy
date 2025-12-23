#!/bin/bash

# Configure desktop workspace layout
# This script configures 5 workspaces with default applications

set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Desktop Workspace Configuration                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Check if hyprland config directory exists
HYPR_CONFIG="$HOME/.config/hypr"
AUTOSTART_CONFIG="$HYPR_CONFIG/autostart.conf"

if [ ! -d "$HYPR_CONFIG" ]; then
    echo -e "${RED}Error: Hyprland config directory not found at $HYPR_CONFIG${NC}"
    exit 1
fi

# Backup existing autostart config if it has content
if [ -f "$AUTOSTART_CONFIG" ]; then
    if [ -s "$AUTOSTART_CONFIG" ] && ! grep -q "# Custom workspace configuration" "$AUTOSTART_CONFIG" 2>/dev/null; then
        echo -e "${YELLOW}📋 Backing up existing autostart.conf...${NC}"
        cp "$AUTOSTART_CONFIG" "$AUTOSTART_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    fi
fi

# Find Google Chrome executable
CHROME_EXEC=""
if command -v google-chrome-stable &>/dev/null; then
    CHROME_EXEC="google-chrome-stable"
elif command -v google-chrome &>/dev/null; then
    CHROME_EXEC="google-chrome"
else
    echo -e "${YELLOW}⚠ Google Chrome not found. Workspace 1 and 5 will not be configured.${NC}"
fi

# Find Cursor executable
CURSOR_EXEC=""
if command -v cursor &>/dev/null; then
    CURSOR_EXEC="cursor"
else
    echo -e "${YELLOW}⚠ Cursor not found. Workspace 2 will not be configured.${NC}"
fi

# Find terminal executable
TERMINAL_EXEC=""
if command -v xdg-terminal-exec &>/dev/null; then
    TERMINAL_EXEC="xdg-terminal-exec"
elif command -v ghostty &>/dev/null; then
    TERMINAL_EXEC="ghostty"
elif command -v alacritty &>/dev/null; then
    TERMINAL_EXEC="alacritty"
else
    echo -e "${YELLOW}⚠ Terminal not found. Workspace 3 will not be configured.${NC}"
fi

echo -e "${YELLOW}⚙️  Configuring workspaces...${NC}\n"

# Create or update autostart.conf
cat > "$AUTOSTART_CONFIG" << 'AUTOSTART_EOF'
# Extra autostart processes
# exec-once = uwsm-app -- my-service

# Custom workspace configuration
# Workspace 1: Google Chrome (Comunitive Profile)
AUTOSTART_EOF

# Add workspace 1: Google Chrome (Comunitive Profile)
if [ -n "$CHROME_EXEC" ]; then
    # Try to find the Comunitive profile directory
    CHROME_PROFILES_DIR="$HOME/.config/google-chrome"
    if [ ! -d "$CHROME_PROFILES_DIR" ]; then
        CHROME_PROFILES_DIR="$HOME/.config/chromium"
    fi

    COMUNITIVE_PROFILE="Default"
    if [ -d "$CHROME_PROFILES_DIR" ]; then
        # Look for a profile that might be Comunitive (check Preferences.json for profile name)
        for profile_dir in "$CHROME_PROFILES_DIR"/Profile* "$CHROME_PROFILES_DIR"/Default; do
            if [ -f "$profile_dir/Preferences" ]; then
                profile_name=$(grep -o '"name":"[^"]*"' "$profile_dir/Preferences" 2>/dev/null | head -1 | cut -d'"' -f4)
                if echo "$profile_name" | grep -qi "comunitive"; then
                    COMUNITIVE_PROFILE=$(basename "$profile_dir")
                    break
                fi
            fi
        done
    fi

    echo "exec-once = [workspace 1 silent] uwsm-app -- $CHROME_EXEC --profile-directory=\"$COMUNITIVE_PROFILE\"" >> "$AUTOSTART_CONFIG"
    echo -e "${GREEN}  ✓ Workspace 1: Google Chrome (Comunitive Profile - using '$COMUNITIVE_PROFILE')${NC}"
else
    echo "# exec-once = [workspace 1 silent] uwsm-app -- google-chrome-stable --profile-directory=\"Default\"" >> "$AUTOSTART_CONFIG"
    echo -e "${YELLOW}  ⚠ Workspace 1: Skipped (Chrome not found)${NC}"
fi

# Add workspace 2: Cursor
echo "" >> "$AUTOSTART_CONFIG"
if [ -n "$CURSOR_EXEC" ]; then
    echo "exec-once = [workspace 2 silent] uwsm-app -- $CURSOR_EXEC" >> "$AUTOSTART_CONFIG"
    echo -e "${GREEN}  ✓ Workspace 2: Cursor${NC}"
else
    echo "# exec-once = [workspace 2 silent] uwsm-app -- cursor" >> "$AUTOSTART_CONFIG"
    echo -e "${YELLOW}  ⚠ Workspace 2: Skipped (Cursor not found)${NC}"
fi

# Add workspace 3: Three terminal instances
echo "" >> "$AUTOSTART_CONFIG"
if [ -n "$TERMINAL_EXEC" ]; then
    echo "exec-once = [workspace 3 silent] uwsm-app -- $TERMINAL_EXEC" >> "$AUTOSTART_CONFIG"
    echo "exec-once = [workspace 3 silent] uwsm-app -- $TERMINAL_EXEC" >> "$AUTOSTART_CONFIG"
    echo "exec-once = [workspace 3 silent] uwsm-app -- $TERMINAL_EXEC" >> "$AUTOSTART_CONFIG"
    echo -e "${GREEN}  ✓ Workspace 3: Three terminal instances${NC}"
else
    echo "# exec-once = [workspace 3 silent] uwsm-app -- xdg-terminal-exec" >> "$AUTOSTART_CONFIG"
    echo "# exec-once = [workspace 3 silent] uwsm-app -- xdg-terminal-exec" >> "$AUTOSTART_CONFIG"
    echo "# exec-once = [workspace 3 silent] uwsm-app -- xdg-terminal-exec" >> "$AUTOSTART_CONFIG"
    echo -e "${YELLOW}  ⚠ Workspace 3: Skipped (Terminal not found)${NC}"
fi

# Add workspace 4: Empty
echo "" >> "$AUTOSTART_CONFIG"
echo "# Workspace 4: Empty" >> "$AUTOSTART_CONFIG"
echo -e "${GREEN}  ✓ Workspace 4: Empty${NC}"

# Add workspace 5: Google Chrome (Ricardo Profile)
echo "" >> "$AUTOSTART_CONFIG"
if [ -n "$CHROME_EXEC" ]; then
    # Try to find the Ricardo profile directory
    CHROME_PROFILES_DIR="$HOME/.config/google-chrome"
    if [ ! -d "$CHROME_PROFILES_DIR" ]; then
        CHROME_PROFILES_DIR="$HOME/.config/chromium"
    fi

    RICARDO_PROFILE="Profile 1"
    if [ -d "$CHROME_PROFILES_DIR" ]; then
        # Look for a profile that might be Ricardo (check Preferences.json for profile name)
        for profile_dir in "$CHROME_PROFILES_DIR"/Profile* "$CHROME_PROFILES_DIR"/Default; do
            if [ -f "$profile_dir/Preferences" ]; then
                profile_name=$(grep -o '"name":"[^"]*"' "$profile_dir/Preferences" 2>/dev/null | head -1 | cut -d'"' -f4)
                if echo "$profile_name" | grep -qi "ricardo"; then
                    RICARDO_PROFILE=$(basename "$profile_dir")
                    break
                fi
            fi
        done
    fi

    echo "exec-once = [workspace 5 silent] uwsm-app -- $CHROME_EXEC --profile-directory=\"$RICARDO_PROFILE\"" >> "$AUTOSTART_CONFIG"
    echo -e "${GREEN}  ✓ Workspace 5: Google Chrome (Ricardo Profile - using '$RICARDO_PROFILE')${NC}"
else
    echo "# exec-once = [workspace 5 silent] uwsm-app -- google-chrome-stable --profile-directory=\"Profile 1\"" >> "$AUTOSTART_CONFIG"
    echo -e "${YELLOW}  ⚠ Workspace 5: Skipped (Chrome not found)${NC}"
fi

echo ""

# Summary
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Configuration Complete!                      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Workspace configuration:${NC}"
echo -e "  • Workspace 1: Google Chrome (Comunitive Profile)"
echo -e "  • Workspace 2: Cursor IDE"
echo -e "  • Workspace 3: Three terminal instances"
echo -e "  • Workspace 4: Empty"
echo -e "  • Workspace 5: Google Chrome (Ricardo Profile)"
echo -e "\n${YELLOW}Note: Configuration saved to $AUTOSTART_CONFIG${NC}"
echo -e "${YELLOW}      Restart Hyprland or log out/in for changes to take effect.${NC}"
echo -e "${YELLOW}      Chrome profiles were auto-detected. If incorrect, edit the file manually.${NC}"
echo -e "${YELLOW}      To find your Chrome profile directories, check: ~/.config/google-chrome/${NC}\n"

