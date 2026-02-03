#!/bin/bash

# Configure audio to only allow internal microphone (SoundWire)
# All external microphones (monitors, Bluetooth headsets, USB devices) are muted
# Only the internal SoundWire microphone is enabled and set as default
# Note: External audio OUTPUTS (speakers, headphones) remain functional
# Requires: PipeWire/WirePlumber

set +e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}⚙️  Configurando áudio...${NC}\n"

# Check if PipeWire is running
if ! command -v wpctl &>/dev/null || ! pgrep -x pipewire >/dev/null; then
    echo -e "${RED}✗ PipeWire não está instalado ou em execução${NC}"
    echo -e "${YELLOW}Este script requer PipeWire e WirePlumber${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Detectado: PipeWire${NC}"
echo ""

# Create a systemd user service to apply microphone settings on boot/login
echo -e "${YELLOW}Criando serviço systemd para aplicar configurações no boot...${NC}"

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

cat > "$SYSTEMD_USER_DIR/audio-mic-control.service" << 'EOF'
[Unit]
Description=Configure audio: only internal microphone enabled, all external mics muted
After=pipewire.service pipewire-pulse.service
Wants=pipewire.service pipewire-pulse.service

[Service]
Type=oneshot
RemainAfterExit=yes
# Wait for audio system to be ready
ExecStartPre=/bin/sleep 2
# Run the configuration script
ExecStart=/usr/bin/bash -c '/home/ricardo/.config/systemd/user/audio-mic-control.sh'

[Install]
WantedBy=default.target
EOF

# Create the actual script that will be executed by the service
cat > "$SYSTEMD_USER_DIR/audio-mic-control.sh" << 'EOF'
#!/bin/bash

# Wait for audio system to be fully initialized
sleep 3

# Get all audio sources (microphones/inputs)
# Parse wpctl status to find source IDs
# Format: "  123. device-name [vol: 1.00]" where * indicates default

# Find the internal SoundWire microphone ID (Audio Coprocessor SoundWire microphones)
INTERNAL_MIC_ID=$(wpctl status | awk '/Audio/,/Video/' | awk '/Sources:/,/Filters:/' | grep -i "SoundWire microphones" | head -n 1 | grep -oP '\d+\.' | tr -d '.')

if [ -z "$INTERNAL_MIC_ID" ]; then
    echo "Warning: Internal SoundWire microphone not found"
    exit 0
fi

echo "Internal microphone ID: $INTERNAL_MIC_ID"

# Set internal microphone as default
wpctl set-default "$INTERNAL_MIC_ID"
echo "Set internal microphone as default"

# Unmute and set volume for internal microphone
wpctl set-mute "$INTERNAL_MIC_ID" 0
wpctl set-volume "$INTERNAL_MIC_ID" 1.0
echo "Internal microphone unmuted and volume set to 100%"

# Get all audio input sources (microphones) from pactl and mute all except internal SoundWire
# pactl list sources short gives us all sources including Bluetooth
pactl list sources short | while read -r LINE; do
    SOURCE_NAME=$(echo "$LINE" | awk '{print $2}')
    
    # Skip monitor sources (output monitors, not actual microphones)
    if echo "$SOURCE_NAME" | grep -q "\.monitor$"; then
        continue
    fi
    
    # Check if this is the internal SoundWire microphone
    if echo "$SOURCE_NAME" | grep -qi "amd_sdw.*Mic"; then
        echo "Keeping internal microphone unmuted: $SOURCE_NAME"
        pactl set-source-mute "$SOURCE_NAME" 0
    else
        # Mute all other microphones (Bluetooth, USB, external monitors, etc.)
        pactl set-source-mute "$SOURCE_NAME" 1
        echo "Muted external microphone: $SOURCE_NAME"
    fi
done

echo "Audio configuration complete: only internal microphone active"
EOF

chmod +x "$SYSTEMD_USER_DIR/audio-mic-control.sh"

echo -e "${GREEN}✓ Serviço systemd criado${NC}"

# Remove old service if exists
if [ -f "$SYSTEMD_USER_DIR/disable-monitor-mic.service" ]; then
    systemctl --user stop disable-monitor-mic.service 2>/dev/null || true
    systemctl --user disable disable-monitor-mic.service 2>/dev/null || true
    rm -f "$SYSTEMD_USER_DIR/disable-monitor-mic.service"
    rm -f "$SYSTEMD_USER_DIR/disable-monitor-mic.sh"
    echo -e "${YELLOW}Serviço antigo removido${NC}"
fi

# Enable the systemd service
echo -e "${YELLOW}Habilitando serviço systemd...${NC}"
systemctl --user daemon-reload
systemctl --user enable audio-mic-control.service 2>/dev/null || true
echo -e "${GREEN}✓ Serviço habilitado${NC}"

# Apply settings immediately
echo ""
echo -e "${YELLOW}Aplicando configurações imediatamente...${NC}"

# Run the configuration script
bash "$SYSTEMD_USER_DIR/audio-mic-control.sh"

echo ""
echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo ""
echo -e "${YELLOW}O que foi feito:${NC}"
echo -e "  • Microfone interno SoundWire configurado como padrão"
echo -e "  • Todos os microfones externos foram mutados (monitor, Bluetooth, USB, etc.)"
echo -e "  • Saídas de áudio externas (caixas, fones) continuam funcionando normalmente"
echo -e "  • Criado serviço systemd para aplicar configurações automaticamente no boot"
echo -e "  • Configurações aplicadas imediatamente"
echo ""
echo -e "${BLUE}Verificar dispositivos de áudio:${NC}"
echo -e "  ${GREEN}wpctl status${NC}"
echo -e "  ${GREEN}pactl list sources short${NC}"
echo ""
echo -e "${YELLOW}Nota:${NC} Novos dispositivos conectados terão seus microfones mutados automaticamente no próximo boot."
echo ""
