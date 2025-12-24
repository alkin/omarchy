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

# Remove any existing workspace configuration to avoid duplicates
if [ -f "$AUTOSTART_CONFIG" ]; then
    # Remove lines from "# Custom workspace configuration" to end of file
    if grep -q "# Custom workspace configuration" "$AUTOSTART_CONFIG" 2>/dev/null; then
        sed -i '/^# Custom workspace configuration/,$d' "$AUTOSTART_CONFIG"
        # Remove trailing empty lines
        sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$AUTOSTART_CONFIG"
    fi
fi

# Detect Chrome profiles
COMUNITIVE_PROFILE="Default"
RICARDO_PROFILE="Profile 1"
if [ -n "$CHROME_EXEC" ]; then
    CHROME_PROFILES_DIR="$HOME/.config/google-chrome"
    if [ ! -d "$CHROME_PROFILES_DIR" ]; then
        CHROME_PROFILES_DIR="$HOME/.config/chromium"
    fi

    if [ -d "$CHROME_PROFILES_DIR" ]; then
        for profile_dir in "$CHROME_PROFILES_DIR"/Profile* "$CHROME_PROFILES_DIR"/Default; do
            if [ -f "$profile_dir/Preferences" ]; then
                profile_name=$(grep -o '"name":"[^"]*"' "$profile_dir/Preferences" 2>/dev/null | head -1 | cut -d'"' -f4)
                if echo "$profile_name" | grep -qi "comunitive"; then
                    COMUNITIVE_PROFILE=$(basename "$profile_dir")
                fi
                if echo "$profile_name" | grep -qi "ricardo"; then
                    RICARDO_PROFILE=$(basename "$profile_dir")
                fi
            fi
        done
    fi
fi

# Build complete workspace configuration
WORKSPACE_CONFIG=""
WORKSPACE_CONFIG+="# Custom workspace configuration\n"
WORKSPACE_CONFIG+="# Workspace 1: Google Chrome (Comunitive Profile)\n"
if [ -n "$CHROME_EXEC" ]; then
    WORKSPACE_CONFIG+="exec-once = [workspace 1 silent] uwsm-app -- $CHROME_EXEC --profile-directory=\"$COMUNITIVE_PROFILE\"\n"
else
    WORKSPACE_CONFIG+="# exec-once = [workspace 1 silent] uwsm-app -- google-chrome-stable --profile-directory=\"Default\"\n"
fi

WORKSPACE_CONFIG+="\n"
WORKSPACE_CONFIG+="# Workspace 2: Cursor\n"
if [ -n "$CURSOR_EXEC" ]; then
    WORKSPACE_CONFIG+="exec-once = [workspace 2 silent] uwsm-app -- $CURSOR_EXEC\n"
else
    WORKSPACE_CONFIG+="# exec-once = [workspace 2 silent] uwsm-app -- cursor\n"
fi

WORKSPACE_CONFIG+="\n"
WORKSPACE_CONFIG+="# Workspace 3: Three terminal instances\n"
if [ -n "$TERMINAL_EXEC" ]; then
    WORKSPACE_CONFIG+="exec-once = [workspace 3 silent] uwsm-app -- $TERMINAL_EXEC\n"
    WORKSPACE_CONFIG+="exec-once = [workspace 3 silent] uwsm-app -- $TERMINAL_EXEC\n"
    WORKSPACE_CONFIG+="exec-once = [workspace 3 silent] uwsm-app -- $TERMINAL_EXEC\n"
else
    WORKSPACE_CONFIG+="# exec-once = [workspace 3 silent] uwsm-app -- xdg-terminal-exec\n"
    WORKSPACE_CONFIG+="# exec-once = [workspace 3 silent] uwsm-app -- xdg-terminal-exec\n"
    WORKSPACE_CONFIG+="# exec-once = [workspace 3 silent] uwsm-app -- xdg-terminal-exec\n"
fi

WORKSPACE_CONFIG+="\n"
WORKSPACE_CONFIG+="# Workspace 4: Empty\n"

WORKSPACE_CONFIG+="\n"
WORKSPACE_CONFIG+="# Workspace 5: Google Chrome (Ricardo Profile)\n"
if [ -n "$CHROME_EXEC" ]; then
    WORKSPACE_CONFIG+="exec-once = [workspace 5 silent] uwsm-app -- $CHROME_EXEC --profile-directory=\"$RICARDO_PROFILE\"\n"
else
    WORKSPACE_CONFIG+="# exec-once = [workspace 5 silent] uwsm-app -- google-chrome-stable --profile-directory=\"Profile 1\"\n"
fi

# Append workspace configuration to autostart.conf
# Ensure file exists with header if it doesn't exist
if [ ! -f "$AUTOSTART_CONFIG" ]; then
    cat > "$AUTOSTART_CONFIG" << 'AUTOSTART_EOF'
# Extra autostart processes
# exec-once = uwsm-app -- my-service

AUTOSTART_EOF
fi

# Add workspace configuration
echo -e "$WORKSPACE_CONFIG" >> "$AUTOSTART_CONFIG"

# Display configured workspaces
if [ -n "$CHROME_EXEC" ]; then
    echo -e "${GREEN}  ✓ Workspace 1: Google Chrome (Comunitive Profile - using '$COMUNITIVE_PROFILE')${NC}"
else
    echo -e "${YELLOW}  ⚠ Workspace 1: Skipped (Chrome not found)${NC}"
fi

if [ -n "$CURSOR_EXEC" ]; then
    echo -e "${GREEN}  ✓ Workspace 2: Cursor${NC}"
else
    echo -e "${YELLOW}  ⚠ Workspace 2: Skipped (Cursor not found)${NC}"
fi

if [ -n "$TERMINAL_EXEC" ]; then
    echo -e "${GREEN}  ✓ Workspace 3: Three terminal instances${NC}"
else
    echo -e "${YELLOW}  ⚠ Workspace 3: Skipped (Terminal not found)${NC}"
fi

echo -e "${GREEN}  ✓ Workspace 4: Empty${NC}"

if [ -n "$CHROME_EXEC" ]; then
    echo -e "${GREEN}  ✓ Workspace 5: Google Chrome (Ricardo Profile - using '$RICARDO_PROFILE')${NC}"
else
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

