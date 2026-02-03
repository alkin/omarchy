#!/bin/bash

# Configure desktop autostart - launch apps in specific workspaces on boot
# - Workspace 1: Chrome
# - Workspace 2: Cursor
# - Workspace 3: 3 Ghostty terminal windows
# - Workspace 6: Spotify

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
HYPRLAND_CONF="$HYPR_CONFIG_DIR/hyprland.conf"

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
# Note: Using hyprctl to move windows only at startup, so new instances open in current workspace

# Autostart apps and move them to specific workspaces
exec-once = sleep 1 && uwsm-app -- google-chrome-stable && sleep 2 && hyprctl dispatch movetoworkspacesilent 1,class:^(google-chrome|Google-chrome)$
exec-once = sleep 2 && uwsm-app -- cursor && sleep 2 && hyprctl dispatch movetoworkspacesilent 2,class:^(Cursor|cursor|code-url-handler)$
exec-once = sleep 3 && uwsm-app -- spotify && sleep 2 && hyprctl dispatch movetoworkspacesilent 6,class:^(Spotify|spotify)$

# Launch 3 terminal windows in workspace 3
exec-once = sleep 4 && ghostty --title=workspace-term & sleep 1 && hyprctl dispatch movetoworkspacesilent 3,title:^(workspace-term)$
exec-once = sleep 5 && ghostty --title=workspace-term & sleep 1 && hyprctl dispatch movetoworkspacesilent 3,title:^(workspace-term)$
exec-once = sleep 6 && ghostty --title=workspace-term -e bash -ic "c" & sleep 1 && hyprctl dispatch movetoworkspacesilent 3,title:^(workspace-term)$

# <<< Desktop Autostart Configuration <<<
EOF

echo -e "${GREEN}✓ Configuração de autostart adicionada${NC}"

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
echo -e "  • Os terminais iniciais são identificados pelo título 'workspace-term'"
echo ""
echo -e "${BLUE}Reinicie o Hyprland ou faça logout/login para aplicar as mudanças.${NC}"
echo ""
