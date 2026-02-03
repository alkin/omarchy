#!/bin/bash

# Uninstall and completely remove Voxtype dictation
# This script removes voxtype packages, all configuration files, models, state files, and systemd services
# Based on omarchy-voxtype-remove but more thorough

set +e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Desinstalando e removendo todas as configurações do Voxtype...${NC}\n"

# Ensure Omarchy scripts are in PATH
if [ -n "$OMARCHY_PATH" ]; then
    export PATH="$OMARCHY_PATH/bin:$PATH"
elif [ -d "$HOME/.local/share/omarchy/bin" ]; then
    export OMARCHY_PATH="$HOME/.local/share/omarchy"
    export PATH="$OMARCHY_PATH/bin:$PATH"
fi

# Step 1: Stop voxtype daemon and processes
echo -e "${YELLOW}Parando processos do Voxtype...${NC}"

# Stop systemd service if running
if systemctl --user is-active voxtype.service >/dev/null 2>&1; then
    systemctl --user stop voxtype.service 2>&1 || true
    echo -e "${GREEN}✓ Serviço systemd parado${NC}"
fi

# Kill any running voxtype processes
if pgrep -x voxtype >/dev/null 2>&1; then
    pkill -x voxtype 2>&1 || true
    sleep 1
    # Force kill if still running
    if pgrep -x voxtype >/dev/null 2>&1; then
        pkill -9 -x voxtype 2>&1 || true
    fi
    echo -e "${GREEN}✓ Processos do Voxtype parados${NC}"
else
    echo -e "${GREEN}✓ Nenhum processo do Voxtype rodando${NC}"
fi

echo ""

# Step 2: Remove systemd service files
echo -e "${YELLOW}Removendo serviços systemd...${NC}"

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
if [ -d "$SYSTEMD_USER_DIR" ]; then
    # Remove all voxtype service files
    REMOVED_SERVICES=0
    for service_file in "$SYSTEMD_USER_DIR"/voxtype*; do
        if [ -f "$service_file" ]; then
            rm -f "$service_file"
            echo -e "  ${GREEN}✓ Removido: $(basename "$service_file")${NC}"
            REMOVED_SERVICES=$((REMOVED_SERVICES + 1))
        fi
    done
    
    if [ $REMOVED_SERVICES -eq 0 ]; then
        echo -e "  ${YELLOW}Nenhum serviço systemd encontrado${NC}"
    else
        # Reload systemd daemon
        systemctl --user daemon-reload 2>&1 || true
        echo -e "${GREEN}✓ Daemon systemd recarregado${NC}"
    fi
else
    echo -e "  ${YELLOW}Diretório de serviços systemd não encontrado${NC}"
fi

echo ""

# Step 3: Remove configuration files
echo -e "${YELLOW}Removendo arquivos de configuração...${NC}"

VOXTYPE_CONFIG_DIR="$HOME/.config/voxtype"
if [ -d "$VOXTYPE_CONFIG_DIR" ]; then
    # List what will be removed
    CONFIG_FILES=$(find "$VOXTYPE_CONFIG_DIR" -type f 2>/dev/null | wc -l)
    if [ "$CONFIG_FILES" -gt 0 ]; then
        echo -e "  ${BLUE}Removendo $CONFIG_FILES arquivo(s) de configuração...${NC}"
        rm -rf "$VOXTYPE_CONFIG_DIR"
        echo -e "${GREEN}✓ Diretório de configuração removido: $VOXTYPE_CONFIG_DIR${NC}"
    else
        echo -e "  ${YELLOW}Diretório de configuração vazio${NC}"
        rmdir "$VOXTYPE_CONFIG_DIR" 2>/dev/null || true
    fi
else
    echo -e "  ${YELLOW}Diretório de configuração não encontrado${NC}"
fi

echo ""

# Step 4: Remove models and data files
echo -e "${YELLOW}Removendo modelos e arquivos de dados...${NC}"

VOXTYPE_DATA_DIR="$HOME/.local/share/voxtype"
if [ -d "$VOXTYPE_DATA_DIR" ]; then
    # Calculate size before removal
    DATA_SIZE=$(du -sh "$VOXTYPE_DATA_DIR" 2>/dev/null | cut -f1)
    echo -e "  ${BLUE}Removendo dados (~${DATA_SIZE})...${NC}"
    
    # List models if they exist
    MODELS_DIR="$VOXTYPE_DATA_DIR/models"
    if [ -d "$MODELS_DIR" ]; then
        MODEL_COUNT=$(find "$MODELS_DIR" -name "*.bin" -type f 2>/dev/null | wc -l)
        if [ "$MODEL_COUNT" -gt 0 ]; then
            echo -e "  ${BLUE}Removendo $MODEL_COUNT modelo(s) baixado(s)...${NC}"
        fi
    fi
    
    rm -rf "$VOXTYPE_DATA_DIR"
    echo -e "${GREEN}✓ Diretório de dados removido: $VOXTYPE_DATA_DIR${NC}"
else
    echo -e "  ${YELLOW}Diretório de dados não encontrado${NC}"
fi

echo ""

# Step 5: Remove runtime state files and lock files
echo -e "${YELLOW}Removendo arquivos de estado e locks...${NC}"

if [ -n "$XDG_RUNTIME_DIR" ] && [ -d "$XDG_RUNTIME_DIR/voxtype" ]; then
    # Check if files are owned by root
    if [ ! -w "$XDG_RUNTIME_DIR/voxtype" ]; then
        echo -e "  ${YELLOW}Arquivos de estado pertencem ao root, tentando remover com sudo...${NC}"
        if command -v sudo &>/dev/null; then
            sudo rm -rf "$XDG_RUNTIME_DIR/voxtype" 2>&1 || true
            echo -e "${GREEN}✓ Arquivos de estado removidos (com sudo): $XDG_RUNTIME_DIR/voxtype${NC}"
        else
            echo -e "  ${YELLOW}⚠ sudo não disponível. Execute manualmente: sudo rm -rf $XDG_RUNTIME_DIR/voxtype${NC}"
        fi
    else
        rm -rf "$XDG_RUNTIME_DIR/voxtype"
        echo -e "${GREEN}✓ Arquivos de estado removidos: $XDG_RUNTIME_DIR/voxtype${NC}"
    fi
else
    echo -e "  ${YELLOW}Diretório de estado não encontrado${NC}"
fi

# Also check for lock files in common locations
LOCK_FILES=(
    "/tmp/voxtype.lock"
    "$HOME/.voxtype.lock"
)

for lock_file in "${LOCK_FILES[@]}"; do
    if [ -f "$lock_file" ]; then
        if [ ! -w "$lock_file" ] && command -v sudo &>/dev/null; then
            sudo rm -f "$lock_file" 2>&1 || true
        else
            rm -f "$lock_file"
        fi
        echo -e "  ${GREEN}✓ Lock file removido: $lock_file${NC}"
    fi
done

echo ""

# Step 6: Remove packages using omarchy commands
echo -e "${YELLOW}Removendo pacotes...${NC}"

if command -v voxtype &>/dev/null; then
    echo -e "  ${BLUE}Voxtype está instalado, removendo pacotes...${NC}"
    
    # Use omarchy-pkg-drop if available (follows omarchy-voxtype-remove pattern)
    if command -v omarchy-pkg-drop &>/dev/null; then
        if omarchy-pkg-drop wtype voxtype-bin 2>&1; then
            echo -e "${GREEN}✓ Pacotes removidos usando omarchy-pkg-drop${NC}"
        else
            echo -e "${YELLOW}⚠ Erro ao remover pacotes com omarchy-pkg-drop${NC}"
            echo -e "  ${BLUE}Tentando com pacman...${NC}"
            # Fallback to pacman
            sudo pacman -Rns --noconfirm wtype voxtype-bin 2>&1 || true
        fi
    else
        # Fallback to pacman
        echo -e "  ${BLUE}omarchy-pkg-drop não encontrado, usando pacman...${NC}"
        sudo pacman -Rns --noconfirm wtype voxtype-bin 2>&1 || true
    fi
else
    echo -e "  ${YELLOW}Voxtype não está instalado ou não encontrado no PATH${NC}"
    echo -e "  ${BLUE}Verificando se os pacotes estão instalados...${NC}"
    
    # Check if packages are installed
    if pacman -Q wtype voxtype-bin &>/dev/null 2>&1; then
        echo -e "  ${BLUE}Pacotes encontrados, removendo...${NC}"
        sudo pacman -Rns --noconfirm wtype voxtype-bin 2>&1 || true
        echo -e "${GREEN}✓ Pacotes removidos${NC}"
    else
        echo -e "  ${GREEN}✓ Pacotes não estão instalados${NC}"
    fi
fi

echo ""

# Step 7: Clean up any remaining cache files
echo -e "${YELLOW}Limpando arquivos de cache...${NC}"

CACHE_DIRS=(
    "$HOME/.cache/voxtype"
    "$HOME/.local/cache/voxtype"
)

CACHE_REMOVED=false
for cache_dir in "${CACHE_DIRS[@]}"; do
    if [ -d "$cache_dir" ]; then
        rm -rf "$cache_dir"
        echo -e "  ${GREEN}✓ Cache removido: $cache_dir${NC}"
        CACHE_REMOVED=true
    fi
done

if [ "$CACHE_REMOVED" = false ]; then
    echo -e "  ${YELLOW}Nenhum arquivo de cache encontrado${NC}"
fi

echo ""

# Step 8: Summary
echo -e "${GREEN}Desinstalação concluída!${NC}\n"
echo -e "${YELLOW}Resumo do que foi removido:${NC}"
echo -e "  • Processos do Voxtype parados"
echo -e "  • Serviços systemd removidos"
echo -e "  • Arquivos de configuração removidos (~/.config/voxtype)"
echo -e "  • Modelos e dados removidos (~/.local/share/voxtype)"
echo -e "  • Arquivos de estado e locks removidos"
echo -e "  • Pacotes removidos (wtype, voxtype-bin)"
echo -e "  • Arquivos de cache removidos"
echo ""
echo -e "${BLUE}Nota:${NC} Se você reinstalar o Voxtype depois, precisará baixar os modelos novamente."
echo ""
