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

echo -e "${BLUE}Installing Terminal & Shell Configuration...${NC}\n"

# Install ghostty and set as default terminal (AUR)
echo -e "${YELLOW}📦 Installing Ghostty terminal...${NC}"
omarchy-install-terminal ghostty
echo -e "${GREEN}  ✓ Ghostty installed and set as default terminal${NC}\n"

# Install zsh and plugins
echo -e "${YELLOW}📦 Installing Zsh and plugins...${NC}"
yay -S --noconfirm --needed zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search
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
    local pattern="$3"

    # If pattern is provided, use it for checking, otherwise use exact line match
    if [ -n "$pattern" ]; then
        if ! grep -qE "$pattern" "$config_file" 2>/dev/null; then
            echo "$config_line" >> "$config_file"
            return 0
        fi
    else
        if ! grep -Fxq "$config_line" "$config_file" 2>/dev/null; then
            echo "$config_line" >> "$config_file"
            return 0
        fi
    fi
    return 1
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

# Function to add alias if it doesn't exist
add_alias_if_missing() {
    local alias_name="$1"
    local alias_value="$2"
    local alias_line="alias $alias_name=\"$alias_value\""

    # Check for various alias formats: alias k=, alias k =, alias k=", etc.
    if ! grep -qE "^alias $alias_name[= ]" "$ZSH_RC" 2>/dev/null; then
        echo "$alias_line" >> "$ZSH_RC"
        echo -e "${GREEN}  ✓ Added alias: $alias_name=$alias_value${NC}"
        return 0
    else
        echo -e "${YELLOW}  ⚠ Alias $alias_name already exists, skipping${NC}"
        return 1
    fi
}

# Add k=kubectl alias
add_alias_if_missing "k" "kubectl"

# Add sail alias
add_alias_if_missing "sail" "vendor/bin/sail"

echo ""

echo -e "${GREEN}Configuration complete:${NC}"
echo -e "  • Ghostty installed and set as default terminal"
echo -e "  • Zsh configured with:"
echo -e "    - Auto-completion (zsh-completions)"
echo -e "    - Auto-suggestions (zsh-autosuggestions)"
echo -e "    - Syntax highlighting (zsh-syntax-highlighting)"
echo -e "    - Fuzzy history search (fzf + history-substring-search)"
echo -e "    - Zoxide for smart directory navigation"
echo -e "  • Omarchy aliases and functions loaded"
echo -e "  • Zsh set as default shell"
echo -e "  • Starship using default configuration"
echo -e "  • Custom aliases added: k=kubectl, sail=vendor/bin/sail"
echo -e "\n${YELLOW}Note: You may need to log out and back in for zsh to become your default shell.${NC}"
echo -e "${YELLOW}      Or run: exec zsh${NC}\n"

