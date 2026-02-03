#!/bin/bash

# Script para corrigir o dispositivo de áudio do voxtype
# Use este script se o voxtype não estiver funcionando devido a dispositivo de áudio inválido

set +e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Corrigindo configuração de áudio do Voxtype...${NC}\n"

VOXTYPE_CONFIG="$HOME/.config/voxtype/config.toml"

# Check if config exists
if [ ! -f "$VOXTYPE_CONFIG" ]; then
    echo -e "${RED}✗ Arquivo de configuração não encontrado: $VOXTYPE_CONFIG${NC}"
    exit 1
fi

# Check permissions
if [ ! -w "$VOXTYPE_CONFIG" ]; then
    echo -e "${YELLOW}⚠ Arquivo pertence ao root. Tentando corrigir...${NC}"
    if command -v sudo &>/dev/null; then
        sudo chown "$USER:$USER" "$VOXTYPE_CONFIG" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Permissões corrigidas${NC}\n"
        else
            echo -e "${RED}✗ Não foi possível corrigir permissões${NC}"
            echo -e "${YELLOW}Execute manualmente: sudo chown $USER:$USER $VOXTYPE_CONFIG${NC}"
            exit 1
        fi
    else
        echo -e "${RED}✗ sudo não disponível. Execute manualmente como root${NC}"
        exit 1
    fi
fi

# Stop voxtype if running
if pgrep -x voxtype >/dev/null 2>&1; then
    echo -e "${YELLOW}Parando voxtype...${NC}"
    pkill -x voxtype 2>&1
    sleep 1
fi

# Detect audio system (PipeWire or PulseAudio)
AUDIO_SYSTEM=""
if command -v wpctl &>/dev/null && pgrep -x pipewire >/dev/null; then
    AUDIO_SYSTEM="pipewire"
    echo -e "${GREEN}✓ Detectado: PipeWire${NC}"
elif command -v pactl &>/dev/null && (pgrep -x pulseaudio >/dev/null || pgrep -x pipewire-pulse >/dev/null); then
    AUDIO_SYSTEM="pulseaudio"
    echo -e "${GREEN}✓ Detectado: PulseAudio/PipeWire-Pulse${NC}"
fi

# Check available audio devices
echo -e "${BLUE}Verificando dispositivos de áudio disponíveis...${NC}"
if [ "$AUDIO_SYSTEM" = "pipewire" ]; then
    AVAILABLE_DEVICES=$(wpctl status 2>/dev/null | grep -i "audio" | head -10)
    if [ -n "$AVAILABLE_DEVICES" ]; then
        echo -e "${GREEN}Dispositivos disponíveis (PipeWire):${NC}"
        echo "$AVAILABLE_DEVICES"
        echo ""
    else
        echo -e "${YELLOW}⚠ PipeWire não está rodando ou não há dispositivos disponíveis${NC}"
        echo -e "${BLUE}Usando 'default' como dispositivo${NC}\n"
    fi
elif [ "$AUDIO_SYSTEM" = "pulseaudio" ]; then
    AVAILABLE_DEVICES=$(pactl list sources short 2>/dev/null | head -5)
    if [ -n "$AVAILABLE_DEVICES" ]; then
        echo -e "${GREEN}Dispositivos disponíveis (PulseAudio):${NC}"
        echo "$AVAILABLE_DEVICES"
        echo ""
    else
        echo -e "${YELLOW}⚠ PulseAudio não está rodando ou não há dispositivos disponíveis${NC}"
        echo -e "${BLUE}Usando 'default' como dispositivo${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠ Sistema de áudio não detectado${NC}"
    echo -e "${BLUE}Usando 'default' como dispositivo${NC}\n"
fi

# Backup config
cp "$VOXTYPE_CONFIG" "$VOXTYPE_CONFIG.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true

# Try to find amd-soundwire device
AUDIO_DEVICE="default"
if [ "$AUDIO_SYSTEM" = "pipewire" ]; then
    if wpctl status 2>/dev/null | grep -qiE "amd.*soundwire|soundwire"; then
        AUDIO_DEVICE="amd-soundwire"
        echo -e "${GREEN}✓ Dispositivo amd-soundwire encontrado (PipeWire)${NC}"
    else
        echo -e "${YELLOW}⚠ Dispositivo amd-soundwire não encontrado${NC}"
        echo -e "${BLUE}Usando 'default' como dispositivo${NC}"
    fi
elif [ "$AUDIO_SYSTEM" = "pulseaudio" ]; then
    if pactl list sources short 2>/dev/null | grep -qiE "amd-soundwire|soundwire"; then
        AUDIO_DEVICE="amd-soundwire"
        echo -e "${GREEN}✓ Dispositivo amd-soundwire encontrado (PulseAudio)${NC}"
    else
        echo -e "${YELLOW}⚠ Dispositivo amd-soundwire não encontrado${NC}"
        echo -e "${BLUE}Usando 'default' como dispositivo${NC}"
    fi
fi

# Update config file
if command -v python3 &>/dev/null; then
    python3 << PYTHON_EOF
import re
from pathlib import Path

config_path = Path("$VOXTYPE_CONFIG")
content = config_path.read_text()

# Update or add device in [audio] section
if re.search(r'^\s*\[audio\]', content, re.MULTILINE):
    if re.search(r'^\s*device\s*=', content, re.MULTILINE):
        content = re.sub(
            r'(^\s*\[audio\]\s*\n(?:[^\[]*\n)*?)(device\s*=\s*)[^\n]+',
            r'\1\2"$AUDIO_DEVICE"',
            content,
            flags=re.MULTILINE
        )
    else:
        content = re.sub(
            r'(^\s*\[audio\]\s*\n)',
            r'\1device = "$AUDIO_DEVICE"\n',
            content,
            flags=re.MULTILINE
        )
else:
    # Add [audio] section
    if content and not content.endswith('\n'):
        content += '\n'
    content += '\n[audio]\ndevice = "$AUDIO_DEVICE"\n'

config_path.write_text(content)
print("Configuração atualizada com sucesso")
PYTHON_EOF
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Configuração atualizada usando Python${NC}"
    else
        # Fallback to sed
        sed -i "s/device = \".*\"/device = \"$AUDIO_DEVICE\"/" "$VOXTYPE_CONFIG" 2>/dev/null || \
        sed -i "/^\[audio\]/,/^\[/ s/^device = .*/device = \"$AUDIO_DEVICE\"/" "$VOXTYPE_CONFIG" 2>/dev/null
        echo -e "${GREEN}✓ Configuração atualizada${NC}"
    fi
else
    # Fallback to sed
    sed -i "s/device = \".*\"/device = \"$AUDIO_DEVICE\"/" "$VOXTYPE_CONFIG" 2>/dev/null || \
    sed -i "/^\[audio\]/,/^\[/ s/^device = .*/device = \"$AUDIO_DEVICE\"/" "$VOXTYPE_CONFIG" 2>/dev/null
    echo -e "${GREEN}✓ Configuração atualizada${NC}"
fi

echo ""
echo -e "${GREEN}Configuração corrigida!${NC}"
echo -e "  • Dispositivo de áudio: ${AUDIO_DEVICE}"
echo ""
echo -e "${YELLOW}Para iniciar o voxtype:${NC}"
echo -e "  ${BLUE}voxtype daemon${NC}"
echo -e "  ${BLUE}ou${NC}"
echo -e "  ${BLUE}systemctl --user start voxtype.service${NC}"
echo ""
