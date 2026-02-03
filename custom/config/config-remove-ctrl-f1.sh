#!/bin/bash

# Remove CTRL F1 keybinding

set +e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚙️  Removing CTRL F1 keybinding...${NC}"

BINDINGS_CONF="$HOME/.config/hypr/bindings.conf"

# Remove CTRL F1 binding from bindings.conf if present (idempotent: remove all instances)
sed -i '/bindd.*CTRL.*F1.*Apple Display brightness down/d' "$BINDINGS_CONF"
sed -i '/# Laptop: Remove CTRL F1 keybinding/d' "$BINDINGS_CONF"
sed -i '/^unbind = CTRL, F1$/d' "$BINDINGS_CONF"

# Add unbind to remove CTRL F1 (only if not already present)
if ! grep -q "^unbind = CTRL, F1$" "$BINDINGS_CONF"; then
    cat >> "$BINDINGS_CONF" << 'EOF'

# Laptop: Remove CTRL F1 keybinding
unbind = CTRL, F1
EOF
    echo -e "${GREEN}  ✓ Removed CTRL F1 keybinding${NC}"
else
    echo -e "${GREEN}  ✓ CTRL F1 unbind already configured${NC}"
fi
