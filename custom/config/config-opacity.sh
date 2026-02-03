#!/bin/bash

# Configure Hyprland to remove opacity from all windows except terminals
# Overrides the default opacity rule (0.97 0.9) with full opacity (1.0 1.0) for all windows
# But keeps the default opacity (0.97 0.9) for terminals (Ghostty, Alacritty, Kitty)

set +e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}⚙️  Configurando opacidade das janelas...${NC}\n"

# Hyprland config directory
HYPR_CONFIG_DIR="$HOME/.config/hypr"
WINDOWS_CONF="$HYPR_CONFIG_DIR/windows.conf"
HYPRLAND_CONF="$HYPR_CONFIG_DIR/hyprland.conf"

# Ensure config directory exists
if [ ! -d "$HYPR_CONFIG_DIR" ]; then
    echo -e "${YELLOW}Criando diretório de configuração do Hyprland...${NC}"
    mkdir -p "$HYPR_CONFIG_DIR"
fi

# Create windows.conf with opacity override
echo -e "${YELLOW}Criando configuração de opacidade...${NC}"

cat > "$WINDOWS_CONF" << 'EOF'
# Override default opacity - remove transparency from all windows except terminals
# This overrides the default rule in ~/.local/share/omarchy/default/hypr/windows.conf
# First, set full opacity for all windows
windowrule = opacity 1.0 1.0, match:class .*

# Then, restore default opacity for terminals (Ghostty, Alacritty, Kitty)
# This rule comes after the general rule, so it takes precedence for terminals
windowrule = opacity 0.97 0.9, match:class (Alacritty|kitty|com.mitchellh.ghostty)
EOF

echo -e "${GREEN}✓ Arquivo windows.conf criado${NC}"

# Ensure windows.conf is sourced in hyprland.conf
if [ -f "$HYPRLAND_CONF" ]; then
    if ! grep -q "^source = ~/.config/hypr/windows.conf" "$HYPRLAND_CONF"; then
        echo -e "${YELLOW}Adicionando windows.conf ao hyprland.conf...${NC}"
        # Add after the user configs section, before the comment about personal config
        if grep -q "# Add any other personal Hyprland configuration below" "$HYPRLAND_CONF"; then
            sed -i '/# Add any other personal Hyprland configuration below/i source = ~/.config/hypr/windows.conf' "$HYPRLAND_CONF"
        else
            # If the comment doesn't exist, add at the end
            echo "" >> "$HYPRLAND_CONF"
            echo "# Override window opacity" >> "$HYPRLAND_CONF"
            echo "source = ~/.config/hypr/windows.conf" >> "$HYPRLAND_CONF"
        fi
        echo -e "${GREEN}✓ windows.conf adicionado ao hyprland.conf${NC}"
    else
        echo -e "${GREEN}✓ windows.conf já está incluído no hyprland.conf${NC}"
    fi
else
    echo -e "${RED}⚠ Aviso: hyprland.conf não encontrado em $HYPRLAND_CONF${NC}"
    echo -e "${YELLOW}Você precisará adicionar manualmente:${NC}"
    echo -e "  ${GREEN}source = ~/.config/hypr/windows.conf${NC}"
fi

# Reload Hyprland to apply changes
echo ""
echo -e "${YELLOW}Aplicando configurações...${NC}"

if command -v hyprctl >/dev/null 2>&1; then
    if hyprctl reload >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Hyprland recarregado${NC}"
    else
        echo -e "${YELLOW}⚠ Não foi possível recarregar o Hyprland automaticamente${NC}"
        echo -e "${YELLOW}Execute manualmente: ${GREEN}hyprctl reload${NC}"
    fi
else
    echo -e "${YELLOW}⚠ hyprctl não encontrado. Execute manualmente: ${GREEN}hyprctl reload${NC}"
fi

echo ""
echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo ""
echo -e "${YELLOW}O que foi feito:${NC}"
echo -e "  • Criado arquivo ~/.config/hypr/windows.conf com regra de opacidade"
echo -e "  • Configurado opacity 1.0 1.0 para todas as janelas (sem transparência)"
echo -e "  • Mantida opacidade padrão (0.97 0.9) para terminais (Ghostty, Alacritty, Kitty)"
echo -e "  • Adicionado source no hyprland.conf (se necessário)"
echo -e "  • Hyprland recarregado para aplicar mudanças"
echo ""
echo -e "${BLUE}Nota:${NC} A opacidade padrão do Omarchy (0.97 0.9) foi mantida apenas para terminais."
echo -e "Todas as outras janelas agora têm opacidade total (1.0 1.0)."
echo ""
