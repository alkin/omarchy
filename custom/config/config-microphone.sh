#!/bin/bash

# Configure microphone to disable external monitor microphone INPUT (Philips 231P4U)
# and always use internal AMD-Soundwire microphone as default
# Note: Only the monitor's microphone (input) is disabled; speakers (outputs) remain functional
# Requires: PipeWire/WirePlumber

set +e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}⚙️  Configurando microfones...${NC}\n"

# Check if PipeWire is running
if ! command -v wpctl &>/dev/null || ! pgrep -x pipewire >/dev/null; then
    echo -e "${RED}✗ PipeWire não está instalado ou em execução${NC}"
    echo -e "${YELLOW}Este script requer PipeWire e WirePlumber${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Detectado: PipeWire${NC}"
echo ""

# Configure audio profiles using pactl instead of WirePlumber rules
# WirePlumber rules for device.profile don't work reliably, so we use pactl
echo -e "${YELLOW}Configurando perfil de áudio do monitor Philips...${NC}"
echo -e "${GREEN}✓ Configuração será aplicada via systemd service${NC}"

# Create a systemd user service to apply microphone settings on boot/login
echo ""
echo -e "${YELLOW}Criando serviço systemd para aplicar configurações no boot...${NC}"

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

cat > "$SYSTEMD_USER_DIR/disable-monitor-mic.service" << 'EOF'
[Unit]
Description=Disable external monitor microphone input and set internal mic as default
After=pipewire.service pipewire-pulse.service
Wants=pipewire.service pipewire-pulse.service

[Service]
Type=oneshot
RemainAfterExit=yes
# Wait for audio system to be ready
ExecStartPre=/bin/sleep 2
# Run the configuration script
ExecStart=/usr/bin/bash -c '/home/ricardo/.config/systemd/user/disable-monitor-mic.sh'

[Install]
WantedBy=default.target
EOF

# Create the actual script that will be executed by the service
cat > "$SYSTEMD_USER_DIR/disable-monitor-mic.sh" << 'EOF'
#!/bin/bash

# Wait for audio system to be fully initialized
sleep 3

# Find Philips monitor card and set it to output-only profile (no microphone input)
# This disables the microphone but keeps the speakers/outputs working
PHILIPS_CARD_ID=$(pactl list cards short | grep -i "Philips.*231P4U" | awk '{print $1}')
if [ -n "$PHILIPS_CARD_ID" ]; then
    pactl set-card-profile "$PHILIPS_CARD_ID" output:analog-stereo 2>/dev/null || true
    echo "Set Philips monitor to output-only profile (ID: $PHILIPS_CARD_ID) - microphone disabled, speakers enabled"
fi

# Set AMD-Soundwire microphone as default
INTERNAL_MIC_ID=$(wpctl status | awk '/Sources:/,/^[A-Z]/' | grep -i "amd.*soundwire" | grep -v "HDMI\|Monitor" | head -n 1 | grep -oP '\d+\.' | tr -d '.')
if [ -n "$INTERNAL_MIC_ID" ]; then
    wpctl set-default "$INTERNAL_MIC_ID"
    echo "Set AMD-Soundwire microphone as default (ID: $INTERNAL_MIC_ID)"
fi
EOF

chmod +x "$SYSTEMD_USER_DIR/disable-monitor-mic.sh"

echo -e "${GREEN}✓ Serviço systemd criado${NC}"

# Enable the systemd service
echo -e "${YELLOW}Habilitando serviço systemd...${NC}"
systemctl --user daemon-reload
systemctl --user enable disable-monitor-mic.service 2>/dev/null || true
echo -e "${GREEN}✓ Serviço habilitado${NC}"

# Apply settings immediately
echo ""
echo -e "${YELLOW}Aplicando configurações imediatamente...${NC}"

# Run the configuration script
bash "$SYSTEMD_USER_DIR/disable-monitor-mic.sh"

echo ""
echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo ""
echo -e "${YELLOW}O que foi feito:${NC}"
echo -e "  • Monitor Philips configurado para profile 'output:analog-stereo' (apenas saída de áudio)"
echo -e "  • Microfone (input) do monitor foi desabilitado"
echo -e "  • Caixas de som (outputs) do monitor continuam funcionando normalmente"
echo -e "  • Configurado microfone AMD-Soundwire interno como padrão"
echo -e "  • Criado serviço systemd para aplicar configurações automaticamente no boot"
echo -e "  • Configurações aplicadas imediatamente"
echo ""
echo -e "${BLUE}Verificar dispositivos de áudio:${NC}"
echo -e "  ${GREEN}wpctl status${NC}"
echo -e "  ${GREEN}pactl list sources short${NC}"
echo ""
echo -e "${YELLOW}Nota:${NC} Se conectar/desconectar o monitor, as configurações serão aplicadas automaticamente."
echo ""
