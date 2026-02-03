#!/bin/bash

# Configure desktop autostart - launch apps in specific workspaces on boot
# - Workspace 1: Chrome
# - Workspace 2: Cursor
# - Scratchpad: 3 Ghostty terminal windows
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

# Window rules - assign apps to workspaces
windowrule = workspace 1 silent, match:class ^(google-chrome|Google-chrome|chromium|Chromium)$
windowrule = workspace 2 silent, match:class ^(Cursor|cursor|code-url-handler)$
windowrule = workspace 6 silent, match:class ^(Spotify|spotify)$
windowrule = workspace special:scratchpad silent, match:class ^(com.mitchellh.ghostty)$, match:title ^(scratchpad-term)

# Autostart apps with small delays to ensure proper workspace assignment
exec-once = sleep 1 && uwsm-app -- google-chrome-stable
exec-once = sleep 2 && uwsm-app -- cursor
exec-once = sleep 3 && uwsm-app -- spotify

# Launch 3 terminal windows for scratchpad with specific title for identification
exec-once = sleep 4 && ghostty --title=scratchpad-term
exec-once = sleep 4.5 && ghostty --title=scratchpad-term
exec-once = sleep 5 && ghostty --title=scratchpad-term

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
echo -e "  • Workspace 6: Spotify"
echo -e "  • Scratchpad: 3 janelas de terminal Ghostty"
echo ""
echo -e "${YELLOW}Notas:${NC}"
echo -e "  • As regras de janela garantem que os apps abram no workspace correto"
echo -e "  • Os apps são iniciados com pequenos atrasos para evitar conflitos"
echo -e "  • Os terminais no scratchpad são identificados pelo título 'scratchpad-term'"
echo -e "  • Use ${GREEN}SUPER + S${NC} para mostrar/esconder o scratchpad"
echo ""
echo -e "${BLUE}Reinicie o Hyprland ou faça logout/login para aplicar as mudanças.${NC}"
echo ""
