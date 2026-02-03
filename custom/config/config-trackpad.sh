#!/bin/bash

# Configure trackpad natural scroll (invert vertical scroll direction)

set +e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚙️  Configuring trackpad natural scroll...${NC}"

INPUT_CONF="$HOME/.config/hypr/input.conf"

# Uncomment natural_scroll if commented, or add it if missing in touchpad section
if grep -q "^[[:space:]]*#[[:space:]]*natural_scroll" "$INPUT_CONF"; then
    # Uncomment natural_scroll
    sed -i 's/^[[:space:]]*#[[:space:]]*natural_scroll = true/natural_scroll = true/' "$INPUT_CONF"
    echo -e "${GREEN}  ✓ Enabled natural_scroll${NC}"
elif ! grep -A 5 "touchpad {" "$INPUT_CONF" | grep -q "natural_scroll = true"; then
    # Add natural_scroll to touchpad section
    sed -i '/touchpad {/a\    natural_scroll = true' "$INPUT_CONF"
    echo -e "${GREEN}  ✓ Added natural_scroll to touchpad section${NC}"
else
    echo -e "${GREEN}  ✓ natural_scroll already configured${NC}"
fi
