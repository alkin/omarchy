#!/bin/bash

# Install terminal and shell configuration
# This script installs ghostty, configures zsh with plugins, and sets up aliases

set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Terminal and Shell Configuration                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Check if omarchy-pkg-add exists
if ! command -v omarchy-pkg-add &>/dev/null; then
    echo -e "${RED}Error: omarchy-pkg-add not found. Make sure Omarchy is properly installed.${NC}"
    exit 1
fi

# Install ghostty and set as default terminal (AUR)
echo -e "${YELLOW}📦 Installing Ghostty terminal...${NC}"
if command -v omarchy-install-terminal &>/dev/null; then
    omarchy-install-terminal ghostty
else
    yay -S --noconfirm --needed ghostty
    # Set ghostty as default terminal
    mkdir -p ~/.config
    cat > ~/.config/xdg-terminals.list << EOF
# Terminal emulator preference order for xdg-terminal-exec
# The first found and valid terminal will be used
com.mitchellh.ghostty.desktop
EOF
fi
echo -e "${GREEN}  ✓ Ghostty installed and set as default terminal${NC}\n"

# Install zsh and plugins
echo -e "${YELLOW}📦 Installing Zsh and plugins...${NC}"
omarchy-pkg-add zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search
echo -e "${GREEN}  ✓ Zsh and plugins installed${NC}\n"

# Configure zsh
echo -e "${YELLOW}⚙️  Configuring Zsh...${NC}"

ZSH_RC="$HOME/.zshrc"
ZSH_PLUGINS_DIR="/usr/share/zsh/plugins"

# Create .zshrc if it doesn't exist
if [ ! -f "$ZSH_RC" ]; then
    echo "# Zsh configuration" > "$ZSH_RC"
fi

# Function to add configuration if it doesn't exist
add_config_if_missing() {
    local config_line="$1"
    local config_file="$2"

    if ! grep -Fxq "$config_line" "$config_file" 2>/dev/null; then
        echo "$config_line" >> "$config_file"
    fi
}

# Source zsh plugins
if [ -f "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    add_config_if_missing "source $ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" "$ZSH_RC"
fi

if [ -f "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    add_config_if_missing "source $ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" "$ZSH_RC"
fi

if [ -f "$ZSH_PLUGINS_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" ]; then
    add_config_if_missing "source $ZSH_PLUGINS_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" "$ZSH_RC"
fi

# Configure history substring search key bindings
add_config_if_missing "bindkey '^[[A' history-substring-search-up" "$ZSH_RC"
add_config_if_missing "bindkey '^[[B' history-substring-search-down" "$ZSH_RC"
add_config_if_missing "bindkey -M vicmd 'k' history-substring-search-up" "$ZSH_RC"
add_config_if_missing "bindkey -M vicmd 'j' history-substring-search-down" "$ZSH_RC"

# Configure fzf for fuzzy history search
if command -v fzf &>/dev/null; then
    if [ -f /usr/share/fzf/key-bindings.zsh ]; then
        add_config_if_missing "source /usr/share/fzf/key-bindings.zsh" "$ZSH_RC"
    fi
    if [ -f /usr/share/fzf/completion.zsh ]; then
        add_config_if_missing "source /usr/share/fzf/completion.zsh" "$ZSH_RC"
    fi
fi

# Initialize mise if available
if command -v mise &>/dev/null; then
    add_config_if_missing 'eval "$(mise activate zsh)"' "$ZSH_RC"
fi

# Initialize zoxide if available
if command -v zoxide &>/dev/null; then
    add_config_if_missing 'eval "$(zoxide init zsh)"' "$ZSH_RC"
fi

# Initialize starship (default config, omarchy config will be removed)
if command -v starship &>/dev/null; then
    add_config_if_missing 'eval "$(starship init zsh)"' "$ZSH_RC"
fi

echo -e "${GREEN}  ✓ Zsh configured with plugins${NC}\n"

# Set zsh as default shell
echo -e "${YELLOW}🔧 Setting Zsh as default shell...${NC}"
ZSH_PATH=$(which zsh)
if [ -n "$ZSH_PATH" ]; then
    if [ "$SHELL" != "$ZSH_PATH" ]; then
        echo -e "${YELLOW}  Changing default shell to zsh (requires password)...${NC}"
        chsh -s "$ZSH_PATH"
        echo -e "${GREEN}  ✓ Zsh set as default shell${NC}"
        echo -e "${YELLOW}  Note: You may need to log out and back in for this to take effect${NC}"
    else
        echo -e "${GREEN}  ✓ Zsh is already the default shell${NC}"
    fi
else
    echo -e "${RED}  ✗ Could not find zsh binary${NC}"
fi
echo ""

# Remove omarchy starship config and use default
echo -e "${YELLOW}🎨 Configuring Starship...${NC}"
STARSHIP_CONFIG="$HOME/.config/starship.toml"
if [ -f "$STARSHIP_CONFIG" ]; then
    # Check if it's the omarchy config by looking for omarchy-specific content
    if grep -q "repo_root_style\|repo_root_format" "$STARSHIP_CONFIG" 2>/dev/null; then
        echo -e "${YELLOW}  Removing Omarchy starship config...${NC}"
        rm -f "$STARSHIP_CONFIG"
        echo -e "${GREEN}  ✓ Removed Omarchy starship config (using default)${NC}"
    else
        echo -e "${YELLOW}  Starship config exists but doesn't appear to be Omarchy's default${NC}"
    fi
else
    echo -e "${GREEN}  ✓ No starship config found (will use default)${NC}"
fi
echo ""

# Add aliases if they don't exist
echo -e "${YELLOW}📝 Adding aliases...${NC}"

# Check if alias already exists in .zshrc
alias_exists() {
    local alias_name="$1"
    # Check for various alias formats: alias k=, alias k =, alias k=", etc.
    grep -qE "^alias $alias_name[= ]" "$ZSH_RC" 2>/dev/null
}

# Add k=kubectl alias
if ! alias_exists "k"; then
    echo 'alias k="kubectl"' >> "$ZSH_RC"
    echo -e "${GREEN}  ✓ Added alias: k=kubectl${NC}"
else
    echo -e "${YELLOW}  ⚠ Alias k already exists, skipping${NC}"
fi

# Add g=git alias (check if it exists)
if ! alias_exists "g"; then
    echo 'alias g="git"' >> "$ZSH_RC"
    echo -e "${GREEN}  ✓ Added alias: g=git${NC}"
else
    echo -e "${YELLOW}  ⚠ Alias g already exists, skipping${NC}"
fi

# Add sail alias
if ! alias_exists "sail"; then
    echo 'alias sail="vendor/bin/sail"' >> "$ZSH_RC"
    echo -e "${GREEN}  ✓ Added alias: sail=vendor/bin/sail${NC}"
else
    echo -e "${YELLOW}  ⚠ Alias sail already exists, skipping${NC}"
fi

echo ""

# Summary
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Configuration Complete!                      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Configuration summary:${NC}"
echo -e "  • Ghostty installed and set as default terminal"
echo -e "  • Zsh configured with:"
echo -e "    - Auto-completion (zsh-completions)"
echo -e "    - Auto-suggestions (zsh-autosuggestions)"
echo -e "    - Syntax highlighting (zsh-syntax-highlighting)"
echo -e "    - Fuzzy history search (fzf + history-substring-search)"
echo -e "  • Zsh set as default shell"
echo -e "  • Starship using default configuration"
echo -e "  • Aliases added: k=kubectl, g=git, sail=vendor/bin/sail"
echo -e "\n${YELLOW}Note: You may need to log out and back in for zsh to become your default shell.${NC}"
echo -e "${YELLOW}      Or run: exec zsh${NC}\n"

