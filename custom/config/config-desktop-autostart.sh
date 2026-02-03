#!/bin/bash

# Configure desktop autostart - launch apps in specific workspaces on boot
# - Workspace 1: Chrome
# - Workspace 2: Cursor
# - Workspace 3: 3 Ghostty terminal windows
# - Workspace 6: Spotify
#
# Strategy: Use a startup script that opens apps and moves windows via hyprctl.
# No windowrules in config files = no persistence issues with new windows.

set +e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}⚙️  Configurando autostart do desktop...${NC}\n"

# Hyprland config directory
HYPR_CONFIG_DIR="$HOME/.config/hypr"
AUTOSTART_CONF="$HYPR_CONFIG_DIR/autostart.conf"

# Ensure config directory exists
if [ ! -d "$HYPR_CONFIG_DIR" ]; then
    echo -e "${YELLOW}Criando diretório de configuração do Hyprland...${NC}"
    mkdir -p "$HYPR_CONFIG_DIR"
fi

# Marker comments for idempotency
START_MARKER="# >>> Desktop Autostart Configuration >>>"
END_MARKER="# <<< Desktop Autostart Configuration <<<"

# Remove existing desktop autostart configuration if present
if [ -f "$AUTOSTART_CONF" ]; then
    if grep -q "$START_MARKER" "$AUTOSTART_CONF"; then
        echo -e "${YELLOW}Removendo configuração anterior de autostart...${NC}"
        sed -i "/$START_MARKER/,/$END_MARKER/d" "$AUTOSTART_CONF"
    fi
fi

# Create or append to autostart.conf
echo -e "${YELLOW}Adicionando configuração de autostart...${NC}"

cat >> "$AUTOSTART_CONF" << 'EOF'

# >>> Desktop Autostart Configuration >>>
# Launch apps in specific workspaces on boot
# Uses a startup script - NO windowrules here to avoid persistence issues

exec-once = $HOME/.local/bin/omarchy-desktop-autostart

# <<< Desktop Autostart Configuration <<<
EOF

echo -e "${GREEN}✓ Configuração de autostart adicionada${NC}"

# Create the autostart script
echo -e "${YELLOW}Criando script de autostart...${NC}"

AUTOSTART_SCRIPT="$HOME/.local/bin/omarchy-desktop-autostart"
mkdir -p "$HOME/.local/bin"

cat > "$AUTOSTART_SCRIPT" << 'SCRIPT'
#!/bin/bash
# Desktop autostart script - opens apps and moves them to specific workspaces
# No windowrules = new instances open in current workspace (normal behavior)

# Function to wait for a window by class and move it to workspace
launch_and_move() {
    local cmd="$1"
    local class_pattern="$2"
    local workspace="$3"
    local max_wait="${4:-10}"
    
    # Get current window count for this class
    local initial_count=$(hyprctl clients -j | jq "[.[] | select(.class | test(\"$class_pattern\"; \"i\"))] | length")
    
    # Launch the app
    eval "$cmd" &
    
    # Wait for new window to appear
    local waited=0
    while [ $waited -lt $max_wait ]; do
        sleep 0.1
        waited=$((waited + 1))
        
        local current_count=$(hyprctl clients -j | jq "[.[] | select(.class | test(\"$class_pattern\"; \"i\"))] | length")
        
        if [ "$current_count" -gt "$initial_count" ]; then
            # New window appeared, get its address
            local window_addr=$(hyprctl clients -j | jq -r "[.[] | select(.class | test(\"$class_pattern\"; \"i\"))] | last | .address")
            
            if [ -n "$window_addr" ] && [ "$window_addr" != "null" ]; then
                # Move window to workspace silently
                hyprctl dispatch movetoworkspacesilent "$workspace,address:$window_addr"
                return 0
            fi
        fi
    done
    
    return 1
}

# Wait a moment for Hyprland to be fully ready
sleep 0.5

# Launch Chrome -> Workspace 1
launch_and_move "uwsm-app -- google-chrome-stable" "google-chrome|Google-chrome|chromium" 1 10
sleep 0.1

# Launch Cursor -> Workspace 2
launch_and_move "uwsm-app -- cursor" "Cursor|cursor|code-url-handler" 2 10
sleep 0.1


# Launch Spotify -> Workspace 6
launch_and_move "uwsm-app -- spotify" "Spotify|spotify" 6 10
sleep 0.1


# Launch 3 Ghostty terminals -> Workspace 3
launch_and_move "ghostty" "com.mitchellh.ghostty" 3 5
sleep 0.1
launch_and_move "ghostty" "com.mitchellh.ghostty" 3 5
sleep 0.1
launch_and_move "ghostty -e bash -ic 'c'" "com.mitchellh.ghostty" 3 5
sleep 0.1


# Switch to workspace 1
sleep 0.2
hyprctl dispatch workspace 1
SCRIPT

chmod +x "$AUTOSTART_SCRIPT"
echo -e "${GREEN}✓ Script de autostart criado: $AUTOSTART_SCRIPT${NC}"

# Remove old cleanup script if exists
OLD_CLEANUP="$HOME/.local/bin/omarchy-desktop-autostart-cleanup"
if [ -f "$OLD_CLEANUP" ]; then
    rm -f "$OLD_CLEANUP"
    echo -e "${YELLOW}✓ Script de cleanup antigo removido${NC}"
fi

# Clean up multiple blank lines
if [ -f "$AUTOSTART_CONF" ]; then
    sed -i '/^$/N;/^\n$/d' "$AUTOSTART_CONF" 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo ""
echo -e "${YELLOW}O que foi configurado:${NC}"
echo -e "  • Workspace 1: Google Chrome"
echo -e "  • Workspace 2: Cursor"
echo -e "  • Workspace 3: 3 janelas de terminal Ghostty"
echo -e "  • Workspace 6: Spotify"
echo ""
echo -e "${YELLOW}Notas:${NC}"
echo -e "  • Apps são movidos para workspaces apenas na inicialização"
echo -e "  • Novas instâncias abrem no workspace atual (comportamento normal)"
echo -e "  • Não usa windowrules - evita problemas de persistência"
echo ""
echo -e "${BLUE}Reinicie o Hyprland ou faça logout/login para aplicar as mudanças.${NC}"
echo ""
