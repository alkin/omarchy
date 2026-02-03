#!/bin/bash

# Configure zsh keybindings for terminal navigation keys
# Fixes HOME, INSERT, DELETE, END keys in Ghostty and other terminals
# These keys often send different escape sequences depending on the terminal

set +e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}⚙️  Configurando keybindings do zsh e Ghostty...${NC}\n"

# Check if zsh is installed
if ! command -v zsh &>/dev/null; then
    echo -e "${RED}✗ zsh não está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Detectado: zsh${NC}"
echo ""

# Configure Ghostty terminal settings
GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
if [ -f "$GHOSTTY_CONFIG" ]; then
    echo -e "${YELLOW}Configurando Ghostty para suportar teclas especiais...${NC}"
    
    # Check if term is already set
    if ! grep -q "^term = " "$GHOSTTY_CONFIG"; then
        # Add term configuration
        cat >> "$GHOSTTY_CONFIG" << 'EOF'

# Terminal type for proper key sequences (HOME, END, DELETE, INSERT, etc.)
term = xterm-256color
EOF
        echo -e "${GREEN}✓ Adicionado 'term = xterm-256color' ao Ghostty config${NC}"
    else
        echo -e "${GREEN}✓ Ghostty já tem configuração de term${NC}"
    fi
    
    # Add Page Up/Down keybindings for scrolling
    if ! grep -q "keybind.*page_up.*scroll_page_up" "$GHOSTTY_CONFIG"; then
        cat >> "$GHOSTTY_CONFIG" << 'EOF'

# Page Up/Down for terminal scrolling (not command history)
keybind = page_up=scroll_page_up
keybind = page_down=scroll_page_down
keybind = shift+page_up=scroll_page_up
keybind = shift+page_down=scroll_page_down
EOF
        echo -e "${GREEN}✓ Adicionado keybindings de Page Up/Down para scroll${NC}"
    else
        echo -e "${GREEN}✓ Ghostty já tem keybindings de Page Up/Down${NC}"
    fi
    echo ""
else
    echo -e "${YELLOW}⚠ Ghostty config não encontrado em $GHOSTTY_CONFIG${NC}"
    echo -e "${YELLOW}  As configurações de keybindings do zsh ainda serão aplicadas${NC}"
    echo ""
fi

# Create zsh configuration directory if it doesn't exist
ZSH_CONFIG_DIR="$HOME/.config/zsh"
mkdir -p "$ZSH_CONFIG_DIR"

echo -e "${YELLOW}Criando arquivo de configuração de keybindings...${NC}"

# Create keybindings configuration file
# NOTE: This file is designed to work WITH zsh plugins (autosuggestions, syntax-highlighting, etc.)
# It does NOT override arrow keys or force emacs mode to avoid conflicts
cat > "$ZSH_CONFIG_DIR/keybindings.zsh" << 'EOF'
# ZSH keybindings for terminal navigation keys
# This fixes HOME, INSERT, DELETE, END, Page Up/Down keys
# Compatible with zsh-autosuggestions, zsh-syntax-highlighting, and history-substring-search

# First, try to use terminfo if available
if [[ -n "${terminfo[khome]}" ]]; then
    bindkey "${terminfo[khome]}" beginning-of-line
fi
if [[ -n "${terminfo[kend]}" ]]; then
    bindkey "${terminfo[kend]}" end-of-line
fi
if [[ -n "${terminfo[kich1]}" ]]; then
    bindkey "${terminfo[kich1]}" overwrite-mode
fi
if [[ -n "${terminfo[kdch1]}" ]]; then
    bindkey "${terminfo[kdch1]}" delete-char
fi

# Remove Page Up/Down bindings from terminfo to let Ghostty handle them for scrolling
if [[ -n "${terminfo[kpp]}" ]]; then
    bindkey -r "${terminfo[kpp]}"
fi
if [[ -n "${terminfo[knp]}" ]]; then
    bindkey -r "${terminfo[knp]}"
fi

# HOME key - all common variations (xterm-256color, xterm, rxvt, etc.)
bindkey "^[[H"    beginning-of-line  # xterm, xterm-256color
bindkey "^[[1~"   beginning-of-line  # vt100, rxvt
bindkey "^[OH"    beginning-of-line  # tmux, screen
bindkey "\eOH"    beginning-of-line  # alternative
bindkey "\e[H"    beginning-of-line  # alternative

# END key - all common variations
bindkey "^[[F"    end-of-line        # xterm, xterm-256color
bindkey "^[[4~"   end-of-line        # vt100, rxvt
bindkey "^[OF"    end-of-line        # tmux, screen
bindkey "\eOF"    end-of-line        # alternative
bindkey "\e[F"    end-of-line        # alternative

# DELETE key - all common variations
bindkey "^[[3~"   delete-char        # xterm, xterm-256color, vt100
bindkey "\e[3~"   delete-char        # alternative

# INSERT key - all common variations
bindkey "^[[2~"   overwrite-mode     # xterm, xterm-256color, vt100
bindkey "\e[2~"   overwrite-mode     # alternative

# Page Up/Down - Remove bindings to let Ghostty handle scrolling
bindkey -r "^[[5~"    # Remove Page Up binding
bindkey -r "^[[6~"    # Remove Page Down binding
bindkey -r "\e[5~"    # Remove Page Up binding (alternative)
bindkey -r "\e[6~"    # Remove Page Down binding (alternative)
bindkey -r "^[[5;5~"  # Ctrl+Page Up
bindkey -r "^[[6;5~"  # Ctrl+Page Down
bindkey -r "^[[5;2~"  # Shift+Page Up
bindkey -r "^[[6;2~"  # Shift+Page Down

# NOTE: Arrow keys (up/down) are NOT configured here to preserve
# history-substring-search plugin bindings

# Right/Left arrows for character navigation
bindkey "^[[C"    forward-char          # Right arrow
bindkey "^[[D"    backward-char         # Left arrow

# CTRL + arrow keys for word navigation
bindkey "^[[1;5C" forward-word          # Ctrl + Right
bindkey "^[[1;5D" backward-word         # Ctrl + Left
bindkey "\e[1;5C" forward-word          # alternative
bindkey "\e[1;5D" backward-word         # alternative

# ALT + arrow keys for word navigation (alternative)
bindkey "^[[1;3C" forward-word          # Alt + Right
bindkey "^[[1;3D" backward-word         # Alt + Left

# CTRL + DELETE for word deletion
bindkey "^[[3;5~" kill-word             # Ctrl + Delete

# Backspace key
bindkey "^?"      backward-delete-char  # Standard backspace

# Additional useful keybindings
bindkey "^[[Z"    reverse-menu-complete # Shift+Tab for reverse completion
EOF

echo -e "${GREEN}✓ Arquivo de keybindings criado em: $ZSH_CONFIG_DIR/keybindings.zsh${NC}"

# Check if .zshrc exists
ZSHRC="$HOME/.zshrc"
if [ ! -f "$ZSHRC" ]; then
    echo -e "${YELLOW}Criando ~/.zshrc...${NC}"
    touch "$ZSHRC"
fi

# Check if keybindings are already sourced in .zshrc
if grep -q "source.*zsh/keybindings.zsh" "$ZSHRC" 2>/dev/null; then
    echo -e "${GREEN}✓ Keybindings já estão configurados no .zshrc${NC}"
else
    echo -e "${YELLOW}Adicionando source do keybindings ao .zshrc...${NC}"
    
    # Add source line to .zshrc
    cat >> "$ZSHRC" << 'EOF'

# Load terminal keybindings (HOME, END, DELETE, INSERT, etc.)
if [ -f "$HOME/.config/zsh/keybindings.zsh" ]; then
    source "$HOME/.config/zsh/keybindings.zsh"
fi
EOF
    
    echo -e "${GREEN}✓ Configuração adicionada ao .zshrc${NC}"
fi

echo ""
echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo ""
echo -e "${YELLOW}O que foi feito:${NC}"
echo -e "  • Configurado Ghostty para usar term = xterm-256color"
echo -e "  • Adicionado Page Up/Down para fazer scroll do terminal no Ghostty"
echo -e "  • Criado arquivo de keybindings para zsh (compatível com plugins)"
echo -e "  • Configurado mapeamento de teclas: HOME, END, INSERT, DELETE"
echo -e "  • Adicionado suporte a CTRL+Arrows e ALT+Arrows para navegação por palavras"
echo -e "  • Adicionado source ao ~/.zshrc"
echo ""
echo -e "${YELLOW}Compatibilidade:${NC}"
echo -e "  • ✓ zsh-autosuggestions"
echo -e "  • ✓ zsh-syntax-highlighting"
echo -e "  • ✓ zsh-history-substring-search"
echo ""
echo -e "${BLUE}Para aplicar as mudanças:${NC}"
echo -e "  ${RED}1. FECHE E REABRA o Ghostty${NC} ${YELLOW}(para aplicar todas as configurações)${NC}"
echo -e "  ${GREEN}2. No novo terminal, execute: source ~/.zshrc${NC}"
echo ""
echo -e "${YELLOW}Testar as teclas:${NC}"
echo -e "  • HOME: Ir para o início da linha"
echo -e "  • END: Ir para o fim da linha"
echo -e "  • DELETE: Deletar caractere à direita"
echo -e "  • INSERT: Alternar modo de sobrescrever"
echo -e "  • PAGE UP/DOWN: Scroll do terminal"
echo -e "  • CTRL+Arrows: Navegar por palavras"
echo -e "  • Up/Down: history-substring-search (se configurado)"
echo ""
