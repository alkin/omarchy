#!/bin/bash

# Install dictation (voxtype) with Portuguese (PT-BR) large-v3-turbo model
# This script installs voxtype and configures it for Portuguese transcription

set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing Dictation (Voxtype) with PT-BR support...${NC}\n"

# Install voxtype packages
echo -e "${YELLOW}📦 Installing Voxtype packages...${NC}"
yay -S --noconfirm --needed vulkan-icd-loader vulkan-radeon lib32-vulkan-radeon lib32-vulkan-icd-loader
omarchy-pkg-add wtype voxtype-bin
echo -e "${GREEN}  ✓ Voxtype packages installed${NC}\n"

# Setup voxtype config directory
echo -e "${YELLOW}⚙️  Configuring Voxtype...${NC}"
mkdir -p ~/.config/voxtype

# Copy default config and modify for PT-BR
cp $OMARCHY_PATH/default/voxtype/config.toml ~/.config/voxtype/

# Configure for Portuguese with large-v3-turbo model
VOXTYPE_CONFIG="$HOME/.config/voxtype/config.toml"

# Update model to large-v3-turbo (multilingual, supports Portuguese, optimized for speed)
# Note: .en models are English-only, so we use "large-v3-turbo" for Portuguese support
sed -i 's/^model = "base.en"/model = "large-v3-turbo"/' "$VOXTYPE_CONFIG"

# Update language to Portuguese
sed -i 's/^language = "en"/language = "pt"/' "$VOXTYPE_CONFIG"

echo -e "${GREEN}  ✓ Voxtype configured for Portuguese (PT-BR)${NC}"
echo -e "${GREEN}    - Model: large-v3-turbo (multilingual, optimized)${NC}"
echo -e "${GREEN}    - Language: pt (Portuguese)${NC}\n"

# Download the large-v3-turbo model
echo -e "${YELLOW}📥 Downloading large-v3-turbo model (~1.5GB)...${NC}"
echo -e "${BLUE}   This may take a few minutes depending on your connection...${NC}"
voxtype setup --download --no-post-install
echo -e "${GREEN}  ✓ Model downloaded${NC}\n"

# Setup systemd service
echo -e "${YELLOW}🔧 Setting up systemd service...${NC}"
voxtype setup systemd
echo -e "${GREEN}  ✓ Systemd service configured${NC}\n"

# Enable GPU acceleration (Vulkan)
echo -e "${YELLOW}🚀 Enabling GPU acceleration...${NC}"
sudo voxtype setup gpu --enable
echo -e "${GREEN}  ✓ GPU (Vulkan) backend enabled${NC}\n"

# Restart voxtype service to apply GPU settings
echo -e "${YELLOW}🔄 Restarting voxtype service...${NC}"
systemctl --user restart voxtype
echo -e "${GREEN}  ✓ Voxtype service restarted${NC}\n"

# Restart waybar to show voxtype status
omarchy-restart-waybar

echo -e "${GREEN}Installation complete:${NC}"
echo -e "  • Voxtype installed and configured for Portuguese (PT-BR)"
echo -e "  • Model: large-v3-turbo (multilingual, ~1.5GB)"
echo -e "  • Language: Portuguese (pt)"
echo -e "  • GPU acceleration enabled (Vulkan)"
echo -e "  • Systemd service enabled"
echo -e "\n${YELLOW}Usage:${NC}"
echo -e "  Hold ${BLUE}Super + Ctrl + X${NC} to start dictation"
echo -e "  Release to transcribe and type"
echo -e "\n${YELLOW}Config file:${NC} ~/.config/voxtype/config.toml"
echo -e "${YELLOW}Change model:${NC} omarchy-voxtype-model\n"

notify-send "🎤 Voxtype Dictation Ready (PT-BR)" "Hold Super + Ctrl + X to dictate.\nModel: large-v3-turbo (Portuguese)\nGPU acceleration enabled (Vulkan)\nEdit ~/.config/voxtype/config.toml for options." -t 10000
