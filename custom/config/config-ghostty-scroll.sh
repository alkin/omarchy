#!/bin/bash

# Configure Ghostty terminal to increase vertical scroll speed
# Increases mouse-scroll-multiplier from default 0.95 to 3 for faster scrolling

set +e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}⚙️  Configurando velocidade do scroll do Ghostty...${NC}\n"

# Ghostty config file path
GHOSTTY_CONFIG="$HOME/.config/ghostty/config"

# Check if Ghostty config directory exists
if [ ! -d "$(dirname "$GHOSTTY_CONFIG")" ]; then
    echo -e "${YELLOW}Criando diretório de configuração do Ghostty...${NC}"
    mkdir -p "$(dirname "$GHOSTTY_CONFIG")"
fi

# Create config file if it doesn't exist
if [ ! -f "$GHOSTTY_CONFIG" ]; then
    echo -e "${YELLOW}Arquivo de configuração não encontrado. Criando...${NC}"
    touch "$GHOSTTY_CONFIG"
fi

# Scroll multiplier value (3 = 3x faster than default 0.95)
SCROLL_MULTIPLIER="3"

# Check if mouse-scroll-multiplier already exists in config
# Use sudo if file is owned by root
if [ -w "$GHOSTTY_CONFIG" ]; then
    SUDO_CMD=""
    USE_SUDO=false
else
    # Check if sudo is available and working
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        SUDO_CMD="sudo"
        USE_SUDO=true
        echo -e "${YELLOW}Arquivo requer privilégios de root. Usando sudo...${NC}"
    else
        echo -e "${RED}⚠ Aviso: Arquivo requer privilégios de root mas sudo não está disponível.${NC}"
        echo -e "${YELLOW}Você precisará executar manualmente:${NC}"
        echo -e "  ${GREEN}sudo sed -i 's/^mouse-scroll-multiplier = .*/mouse-scroll-multiplier = $SCROLL_MULTIPLIER/' '$GHOSTTY_CONFIG'${NC}"
        echo ""
        exit 1
    fi
fi

if $SUDO_CMD grep -q "^mouse-scroll-multiplier" "$GHOSTTY_CONFIG" 2>/dev/null; then
    echo -e "${YELLOW}Atualizando configuração existente...${NC}"
    # Create temp file with updated content
    TEMP_FILE=$(mktemp)
    if [ "$USE_SUDO" = true ]; then
        $SUDO_CMD sh -c "cat '$GHOSTTY_CONFIG' > '$TEMP_FILE'"
        sed -i "s/^mouse-scroll-multiplier = .*/mouse-scroll-multiplier = $SCROLL_MULTIPLIER/" "$TEMP_FILE"
        cat "$TEMP_FILE" | $SUDO_CMD tee "$GHOSTTY_CONFIG" > /dev/null
        rm -f "$TEMP_FILE"
    else
        cp "$GHOSTTY_CONFIG" "$TEMP_FILE"
        sed -i "s/^mouse-scroll-multiplier = .*/mouse-scroll-multiplier = $SCROLL_MULTIPLIER/" "$TEMP_FILE"
        cp "$TEMP_FILE" "$GHOSTTY_CONFIG"
        rm -f "$TEMP_FILE"
    fi
    echo -e "${GREEN}✓ Velocidade do scroll atualizada para $SCROLL_MULTIPLIER${NC}"
else
    echo -e "${YELLOW}Adicionando configuração de velocidade do scroll...${NC}"
    # Add new configuration at the end of the file
    if [ "$USE_SUDO" = true ]; then
        {
            echo ""
            echo "# Increase vertical scroll speed"
            echo "mouse-scroll-multiplier = $SCROLL_MULTIPLIER"
        } | $SUDO_CMD tee -a "$GHOSTTY_CONFIG" > /dev/null
    else
        echo "" >> "$GHOSTTY_CONFIG"
        echo "# Increase vertical scroll speed" >> "$GHOSTTY_CONFIG"
        echo "mouse-scroll-multiplier = $SCROLL_MULTIPLIER" >> "$GHOSTTY_CONFIG"
    fi
    echo -e "${GREEN}✓ Velocidade do scroll configurada para $SCROLL_MULTIPLIER${NC}"
fi

echo ""
echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo ""
echo -e "${YELLOW}O que foi feito:${NC}"
echo -e "  • Configurado mouse-scroll-multiplier = $SCROLL_MULTIPLIER"
echo -e "  • Isso aumenta a velocidade do scroll vertical em 3x"
echo ""
echo -e "${BLUE}Nota:${NC} Reinicie o Ghostty para aplicar as mudanças."
if [ -n "$SUDO_CMD" ]; then
    echo -e "${BLUE}Valor atual:${NC} $($SUDO_CMD grep "^mouse-scroll-multiplier" "$GHOSTTY_CONFIG" 2>/dev/null || echo "não encontrado")"
else
    echo -e "${BLUE}Valor atual:${NC} $(grep "^mouse-scroll-multiplier" "$GHOSTTY_CONFIG" || echo "não encontrado")"
fi
echo ""
