#!/bin/bash

# Configure Ghostty terminal font size
# Increases font-size by 2 levels from the current value

set +e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}⚙️  Configurando tamanho da fonte do Ghostty...${NC}\n"

# Ghostty config file path
GHOSTTY_CONFIG="$HOME/.config/ghostty/config"

# Check if Ghostty config exists
if [ ! -f "$GHOSTTY_CONFIG" ]; then
    echo -e "${RED}❌ Arquivo de configuração do Ghostty não encontrado: $GHOSTTY_CONFIG${NC}"
    exit 1
fi

# Get current font-size
CURRENT_SIZE=$(grep "^font-size = " "$GHOSTTY_CONFIG" | sed 's/font-size = //')

if [ -z "$CURRENT_SIZE" ]; then
    echo -e "${YELLOW}font-size não encontrado na configuração. Usando valor padrão 9...${NC}"
    CURRENT_SIZE=9
fi

# Calculate new size (2 levels up)
NEW_SIZE=$((CURRENT_SIZE + 2))

echo -e "${YELLOW}Tamanho atual: ${CURRENT_SIZE}${NC}"
echo -e "${YELLOW}Novo tamanho: ${NEW_SIZE}${NC}"

# Update font-size in config
if grep -q "^font-size = " "$GHOSTTY_CONFIG"; then
    sed -i "s/^font-size = .*/font-size = $NEW_SIZE/" "$GHOSTTY_CONFIG"
    echo -e "${GREEN}✓ font-size atualizado de $CURRENT_SIZE para $NEW_SIZE${NC}"
else
    # Add font-size after font-style line if it exists, otherwise at the end
    if grep -q "^font-style = " "$GHOSTTY_CONFIG"; then
        sed -i "/^font-style = /a font-size = $NEW_SIZE" "$GHOSTTY_CONFIG"
    else
        echo "font-size = $NEW_SIZE" >> "$GHOSTTY_CONFIG"
    fi
    echo -e "${GREEN}✓ font-size adicionado: $NEW_SIZE${NC}"
fi

echo ""
echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo ""
echo -e "${YELLOW}O que foi feito:${NC}"
echo -e "  • font-size alterado de $CURRENT_SIZE para $NEW_SIZE"
echo ""
echo -e "${BLUE}Nota:${NC} Reinicie o Ghostty para aplicar as mudanças."
echo ""
