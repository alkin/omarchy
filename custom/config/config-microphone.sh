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

# Create WirePlumber configuration to block Philips monitor microphone
WIREPLUMBER_CONFIG_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
mkdir -p "$WIREPLUMBER_CONFIG_DIR"

echo -e "${YELLOW}Criando regra do WirePlumber para bloquear microfone do monitor...${NC}"

cat > "$WIREPLUMBER_CONFIG_DIR/51-disable-monitor-mic.conf" << 'EOF'
-- Disable Philips 231P4U monitor microphone (INPUT only)
-- This prevents the external monitor microphone from being used
-- But keeps the monitor speakers/outputs working

monitor.alsa.rules = {
  {
    matches = {
      {
        -- Match ONLY Philips monitor INPUT by name
        { "node.name", "matches", "alsa_input.*Philips.*231P4U*" },
      },
    },
    apply_properties = {
      ["device.disabled"] = true,
    },
  },
  {
    matches = {
      {
        -- Match by device description ONLY for inputs (sources)
        { "node.description", "matches", "Philips 231P4U*" },
        { "media.class", "equals", "Audio/Source" },
      },
    },
    apply_properties = {
      ["device.disabled"] = true,
    },
  },
}
EOF

echo -e "${GREEN}✓ Regra do WirePlumber criada${NC}"

# Create additional rule to set AMD-Soundwire as default
echo -e "${YELLOW}Criando regra para priorizar microfone interno AMD-Soundwire...${NC}"

cat > "$WIREPLUMBER_CONFIG_DIR/52-default-amd-mic.conf" << 'EOF'
-- Set AMD-Soundwire internal microphone as default and highest priority

monitor.alsa.rules = {
  {
    matches = {
      {
        -- Match AMD-Soundwire microphone
        { "node.name", "matches", "alsa_input.*amd.*soundwire*" },
      },
    },
    apply_properties = {
      ["priority.session"] = 2000,
      ["node.description"] = "Microfone Interno (AMD-Soundwire)",
    },
  },
}
EOF

echo -e "${GREEN}✓ Regra de prioridade criada${NC}"

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

# Find and disable ONLY Philips monitor microphone inputs (not outputs/speakers)
# We search in the "Sources" section which contains only audio inputs
wpctl status | awk '/Sources:/,/Sinks:/' | grep -i "philips" | grep -i "231p4u" | while read -r line; do
    # Extract device ID
    ID=$(echo "$line" | grep -oP '\d+\.' | tr -d '.')
    if [ -n "$ID" ]; then
        # Mute only the input (microphone), not the entire device
        wpctl set-mute "$ID" 1 2>/dev/null || true
        echo "Muted Philips monitor microphone input (ID: $ID)"
    fi
done

# Set AMD-Soundwire microphone as default
INTERNAL_MIC_ID=$(wpctl status | awk '/Sources:/,/Sinks:/' | grep -i "amd.*soundwire" | grep -v "HDMI\|Monitor" | head -n 1 | grep -oP '\d+\.' | tr -d '.')
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

# Restart WirePlumber to apply new rules
systemctl --user restart wireplumber 2>/dev/null || true
sleep 2

# Run the configuration script
bash "$SYSTEMD_USER_DIR/disable-monitor-mic.sh"

echo ""
echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo ""
echo -e "${YELLOW}O que foi feito:${NC}"
echo -e "  • Criadas regras do WirePlumber para bloquear apenas microfone (input) do monitor Philips"
echo -e "  • As caixas de som (outputs) do monitor continuam funcionando normalmente"
echo -e "  • Configurado microfone AMD-Soundwire interno como padrão com prioridade alta"
echo -e "  • Criado serviço systemd para aplicar configurações automaticamente no boot"
echo -e "  • Configurações aplicadas imediatamente"
echo ""
echo -e "${BLUE}Verificar dispositivos de áudio:${NC}"
echo -e "  ${GREEN}wpctl status${NC}"
echo ""
echo -e "${YELLOW}Nota:${NC} Se conectar/desconectar o monitor, as configurações serão aplicadas automaticamente."
echo ""
