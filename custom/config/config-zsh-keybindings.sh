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
cat > "$ZSH_CONFIG_DIR/keybindings.zsh" << 'EOF'
# ZSH keybindings for terminal navigation keys
# This fixes HOME, INSERT, DELETE, END, Page Up/Down keys

# Enable emacs mode keybindings (works best with these settings)
bindkey -e

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

# HOME key - all common variations (xterm-256color, xterm, rxvt, etc.)
bindkey "^[[H"    beginning-of-line  # xterm, xterm-256color
bindkey "^[[1~"   beginning-of-line  # vt100, rxvt
bindkey "^[OH"    beginning-of-line  # tmux, screen
bindkey "\eOH"    beginning-of-line  # alternative
bindkey "\e[H"    beginning-of-line  # alternative
bindkey "^A"      beginning-of-line  # emacs style (always works)

# END key - all common variations
bindkey "^[[F"    end-of-line        # xterm, xterm-256color
bindkey "^[[4~"   end-of-line        # vt100, rxvt
bindkey "^[OF"    end-of-line        # tmux, screen
bindkey "\eOF"    end-of-line        # alternative
bindkey "\e[F"    end-of-line        # alternative
bindkey "^E"      end-of-line        # emacs style (always works)

# DELETE key - all common variations
bindkey "^[[3~"   delete-char        # xterm, xterm-256color, vt100
bindkey "^?"      delete-char        # some terminals
bindkey "\e[3~"   delete-char        # alternative

# INSERT key - all common variations
bindkey "^[[2~"   overwrite-mode     # xterm, xterm-256color, vt100
bindkey "\e[2~"   overwrite-mode     # alternative

# Page Up/Down
bindkey "^[[5~"   up-line-or-history    # Page Up
bindkey "^[[6~"   down-line-or-history  # Page Down

# Arrow keys (for terminals that send different sequences)
bindkey "^[[A"    up-line-or-search     # Up arrow
bindkey "^[[B"    down-line-or-search   # Down arrow
bindkey "^[[C"    forward-char          # Right arrow
bindkey "^[[D"    backward-char         # Left arrow

# CTRL + arrow keys for word navigation
bindkey "^[[1;5C" forward-word          # Ctrl + Right
bindkey "^[[1;5D" backward-word         # Ctrl + Left
bindkey "\e[1;5C" forward-word          # alternative
bindkey "\e[1;5D" backward-word         # alternative
bindkey "^[[C"    forward-char          # Right (if not bound)
bindkey "^[[D"    backward-char         # Left (if not bound)

# ALT + arrow keys for word navigation (alternative)
bindkey "^[[1;3C" forward-word          # Alt + Right
bindkey "^[[1;3D" backward-word         # Alt + Left

# CTRL + DELETE / BACKSPACE for word deletion
bindkey "^[[3;5~" kill-word             # Ctrl + Delete
bindkey "^H"      backward-kill-word    # Ctrl + Backspace
bindkey "^W"      backward-kill-word    # Ctrl + W (emacs style)

# Backspace key
bindkey "^?"      backward-delete-char  # Standard backspace
bindkey "^H"      backward-delete-char  # Alternative backspace

# Additional useful keybindings
bindkey "^[[Z"    reverse-menu-complete # Shift+Tab for reverse completion
bindkey "^U"      backward-kill-line    # Ctrl + U - kill to beginning of line
bindkey "^K"      kill-line             # Ctrl + K - kill to end of line

# Make sure the terminal is in application mode when zle is active
# This ensures the correct escape sequences are sent
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget
    function zle_application_mode_start { 
        echoti smkx 2>/dev/null
    }
    function zle_application_mode_stop { 
        echoti rmkx 2>/dev/null
    }
    add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
    add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi
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
echo -e "  • Criado arquivo de keybindings para zsh com todas as sequências de escape"
echo -e "  • Configurado mapeamento de teclas: HOME, END, INSERT, DELETE"
echo -e "  • Adicionado suporte a CTRL+Arrows e ALT+Arrows para navegação por palavras"
echo -e "  • Configurado CTRL+DELETE e CTRL+Backspace para deletar palavras"
echo -e "  • Adicionado source ao ~/.zshrc"
echo ""
echo -e "${BLUE}Para aplicar as mudanças:${NC}"
echo -e "  ${RED}1. FECHE E REABRA o Ghostty${NC} ${YELLOW}(para aplicar a nova configuração de TERM)${NC}"
echo -e "  ${GREEN}2. No novo terminal, execute: source ~/.zshrc${NC}"
echo ""
echo -e "${YELLOW}Testar as teclas:${NC}"
echo -e "  • Digite: ${GREEN}echo \$TERM${NC} - deve mostrar ${GREEN}xterm-256color${NC}"
echo -e "  • HOME: Ir para o início da linha (também CTRL+A)"
echo -e "  • END: Ir para o fim da linha (também CTRL+E)"
echo -e "  • DELETE: Deletar caractere à direita"
echo -e "  • INSERT: Alternar modo de sobrescrever"
echo -e "  • CTRL+Arrows: Navegar por palavras"
echo -e "  • CTRL+DELETE: Deletar palavra à direita"
echo ""
