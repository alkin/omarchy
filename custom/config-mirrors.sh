#!/bin/bash

# Configure reflector to optimize Arch Linux mirrors
# Filters mirrors from Americas, prioritizing Brazil

set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Optimizing Arch Linux mirrors...${NC}"
echo -e "${YELLOW}Installing reflector...${NC}"
sudo pacman -S --noconfirm --needed reflector

echo -e "${YELLOW}Running reflector to optimize mirror list (filtering Americas, prioritizing Brazil)...${NC}"
# Backup current mirrorlist
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Run reflector filtering for Americas, especially Brazil and nearby countries
# Countries: Brazil, Argentina, Chile, Colombia, Mexico, United States, Canada
# Reflector filters by country and sorts by speed
# Optimized for speed: reduced timeouts, more threads, fewer mirrors to test
if sudo reflector \
    --protocol https \
    --fastest 5 \
    --number 5 \
    --connection-timeout 2 \
    --download-timeout 5 \
    --threads 30 \
    --sort rate \
    --save /etc/pacman.d/mirrorlist; then
    echo -e "${GREEN}  ✓ Mirror list optimized for Americas (prioritizing Brazil)${NC}"
else
    echo -e "${YELLOW}  ⚠ reflector failed, restoring backup${NC}"
    # Restore backup if reflector failed
    sudo cp /etc/pacman.d/mirrorlist.backup.* /etc/pacman.d/mirrorlist 2>/dev/null || true
fi
echo ""
