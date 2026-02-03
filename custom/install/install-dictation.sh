#!/bin/bash

# Install and configure Voxtype dictation to use Portuguese Brazil language
# Voxtype uses Whisper models. For Portuguese support, we need:
# 1. A multilingual model (small, medium, or large-v3, NOT .en models)
# 2. Language set to "pt" in the [whisper] section
# 
# Model recommendation: 'small' offers the best speed/accuracy balance for Portuguese
# - small: ~466 MB, fast, good accuracy (WER ~0.28)
# - medium: ~1.5 GB, slower, slightly better accuracy (WER ~0.28)
# - large-v3: ~3.1 GB, slowest, best accuracy (WER ~0.25) but often not worth the speed trade-off

set +e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Instalando e configurando Voxtype para usar Português Brasil...${NC}\n"

# Ensure Omarchy scripts are in PATH
if [ -n "$OMARCHY_PATH" ]; then
    export PATH="$OMARCHY_PATH/bin:$PATH"
elif [ -d "$HOME/.local/share/omarchy/bin" ]; then
    export OMARCHY_PATH="$HOME/.local/share/omarchy"
    export PATH="$OMARCHY_PATH/bin:$PATH"
fi

# Step 1: Install Voxtype if not installed using omarchy commands
if ! command -v voxtype &>/dev/null; then
    echo -e "${YELLOW}Voxtype não está instalado. Instalando...${NC}"
    echo -e "${BLUE}Instalando Voxtype + modelo AI (~150MB)...${NC}"
    
    # Install packages using omarchy-pkg-add (following omarchy-voxtype-install pattern)
    if omarchy-pkg-add wtype voxtype-bin 2>&1; then
        echo -e "${GREEN}✓ Pacotes instalados${NC}"
    else
        echo -e "${RED}✗ Erro ao instalar pacotes${NC}"
        echo -e "${YELLOW}Tente executar manualmente: ${BLUE}omarchy-voxtype-install${NC}"
        exit 1
    fi
    
    # Setup voxtype (same as omarchy-voxtype-install)
    mkdir -p ~/.config/voxtype
    if [ -n "$OMARCHY_PATH" ] && [ -f "$OMARCHY_PATH/default/voxtype/config.toml" ]; then
        cp "$OMARCHY_PATH/default/voxtype/config.toml" ~/.config/voxtype/ 2>/dev/null || true
    fi
    
    # Setup systemd service
    voxtype setup systemd 2>&1 || echo -e "${YELLOW}⚠ Configuração do systemd pode ter falhado${NC}"
    
    echo -e "${GREEN}✓ Voxtype instalado e configurado${NC}\n"
else
    echo -e "${GREEN}✓ Voxtype já está instalado${NC}\n"
    
    # Ensure systemd service is set up even if voxtype is already installed
    if ! systemctl --user list-unit-files 2>/dev/null | grep -q voxtype.service; then
        echo -e "${YELLOW}Configurando serviço systemd do Voxtype...${NC}"
        voxtype setup systemd 2>&1 || echo -e "${YELLOW}⚠ Configuração do systemd pode ter falhado${NC}"
    fi
    
    # Check if voxtype is running and stop it if needed (to apply new config)
    if pgrep -x voxtype >/dev/null 2>&1; then
        echo -e "${YELLOW}Voxtype está rodando. Parando para aplicar novas configurações...${NC}"
        # Try to stop via systemd first
        if systemctl --user is-active voxtype.service >/dev/null 2>&1; then
            systemctl --user stop voxtype.service 2>&1 || true
            echo -e "${GREEN}✓ Serviço voxtype parado${NC}"
        else
            # If not running as service, kill the process
            pkill -x voxtype 2>&1 || true
            echo -e "${GREEN}✓ Processo voxtype parado${NC}"
        fi
        sleep 1
    fi
fi

# Create config directory if it doesn't exist
VOXTYPE_CONFIG_DIR="$HOME/.config/voxtype"
mkdir -p "$VOXTYPE_CONFIG_DIR"

# Check if config file exists, create if not
VOXTYPE_CONFIG="$VOXTYPE_CONFIG_DIR/config.toml"

# Step 2: Download multilingual Whisper model for Portuguese (pt-br)
# Using 'small' model for best speed/accuracy balance for Portuguese
MODEL_NAME="small"
echo -e "${YELLOW}Verificando/downloadando modelo multilíngue Whisper (${MODEL_NAME}) para Português Brasil...${NC}"

# Check if model already exists
MODEL_PATH="$HOME/.local/share/voxtype/models/ggml-${MODEL_NAME}.bin"
if [ -f "$MODEL_PATH" ]; then
    MODEL_SIZE=$(du -h "$MODEL_PATH" | cut -f1)
    echo -e "${GREEN}✓ Modelo ${MODEL_NAME} já está baixado (${MODEL_SIZE})${NC}\n"
else
    echo -e "${YELLOW}Baixando modelo ${MODEL_NAME} (isso pode demorar alguns minutos, ~466 MB)...${NC}"
    echo -e "${BLUE}Por favor, aguarde...${NC}\n"
    
    # Download the model using voxtype setup command
    # Use --no-post-install to avoid interactive prompts
    if voxtype setup --download --model ${MODEL_NAME} --no-post-install 2>&1; then
        echo -e "${GREEN}✓ Modelo baixado com sucesso${NC}\n"
    else
        echo -e "${YELLOW}⚠ Aviso: Download do modelo falhou ou foi interrompido${NC}"
        echo -e "${YELLOW}Possíveis causas:${NC}"
        echo -e "  • Sem conexão com a internet"
        echo -e "  • Problema de rede/DNS"
        echo -e "  • Download interrompido"
        echo ""
        echo -e "${BLUE}O modelo será baixado automaticamente quando você iniciar o Voxtype pela primeira vez${NC}"
        if command -v omarchy-voxtype-model &>/dev/null; then
            echo -e "${BLUE}Ou você pode usar: ${BLUE}omarchy-voxtype-model${NC} para selecionar o modelo${NC}"
        else
            echo -e "${BLUE}Ou você pode tentar baixar manualmente depois executando:${NC}"
            echo -e "${BLUE}  voxtype setup --download --model ${MODEL_NAME}${NC}"
        fi
        echo -e "${YELLOW}Continuando com a configuração do idioma...${NC}\n"
    fi
fi

# Step 3: Configure config.toml with Portuguese Brazil language, audio device, and set as default
echo -e "${YELLOW}Configurando idioma Português Brasil e microfone amd-soundwire como padrão...${NC}"

# Fix permissions if config file is owned by root (can happen if voxtype was run as root)
if [ -f "$VOXTYPE_CONFIG" ] && [ ! -w "$VOXTYPE_CONFIG" ]; then
    echo -e "${YELLOW}⚠ Arquivo de configuração não tem permissão de escrita${NC}"
    echo -e "${BLUE}Tentando corrigir permissões...${NC}"
    if command -v sudo &>/dev/null; then
        sudo chown "$USER:$USER" "$VOXTYPE_CONFIG" 2>/dev/null || true
    fi
    # If still not writable, create a new one
    if [ ! -w "$VOXTYPE_CONFIG" ]; then
        echo -e "${YELLOW}⚠ Não foi possível corrigir permissões. Criando backup e novo arquivo...${NC}"
        mv "$VOXTYPE_CONFIG" "$VOXTYPE_CONFIG.root.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    fi
fi

# Backup existing config if it exists
if [ -f "$VOXTYPE_CONFIG" ] && [ -w "$VOXTYPE_CONFIG" ]; then
    cp "$VOXTYPE_CONFIG" "$VOXTYPE_CONFIG.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
fi

# Check if audio device exists
AUDIO_DEVICE="amd-soundwire"
AUDIO_DEVICE_FOUND=false

# Check if PipeWire is running
if ! command -v wpctl &>/dev/null || ! pgrep -x pipewire >/dev/null; then
    echo -e "${RED}✗ PipeWire não está instalado ou em execução${NC}"
    echo -e "${YELLOW}Este script requer PipeWire${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Detectado: PipeWire${NC}"

# Check if device exists using wpctl
if wpctl status 2>/dev/null | grep -qiE "amd.*soundwire|soundwire"; then
    AUDIO_DEVICE_FOUND=true
    echo -e "${GREEN}✓ Dispositivo de áudio amd-soundwire encontrado${NC}"
else
    echo -e "${YELLOW}⚠ Dispositivo amd-soundwire não encontrado na lista de dispositivos${NC}"
    echo -e "${BLUE}Tentando usar 'default' como fallback...${NC}"
    AUDIO_DEVICE="default"
    echo -e "${YELLOW}Usando dispositivo padrão do sistema${NC}"
fi

# Check if Portuguese and audio device are already configured
NEEDS_UPDATE=false
NEEDS_AUDIO_UPDATE=false

# Check audio device configuration
if [ -f "$VOXTYPE_CONFIG" ] && grep -qiE "device\s*=\s*[\"']?${AUDIO_DEVICE}[\"']?" "$VOXTYPE_CONFIG" 2>/dev/null; then
    echo -e "${GREEN}✓ Microfone ${AUDIO_DEVICE} já está configurado${NC}"
    NEEDS_AUDIO_UPDATE=false
else
    echo -e "${YELLOW}⚠ Microfone não configurado ou usando dispositivo diferente, atualizando para ${AUDIO_DEVICE}...${NC}"
    NEEDS_AUDIO_UPDATE=true
fi

# Check language configuration
if [ -f "$VOXTYPE_CONFIG" ] && grep -qiE "language\s*=\s*[\"']?pt[\"']?" "$VOXTYPE_CONFIG" 2>/dev/null; then
    # Check if it's using a multilingual model (not .en models)
    if grep -qiE "model\s*=\s*[\"']?(small|medium|large-v3)" "$VOXTYPE_CONFIG" 2>/dev/null && ! grep -qiE "model\s*=\s*[\"']?.*\.en" "$VOXTYPE_CONFIG" 2>/dev/null; then
        CURRENT_MODEL=$(grep -iE "model\s*=" "$VOXTYPE_CONFIG" 2>/dev/null | head -1 | sed 's/.*=\s*["'\'']*\([^"'\'']*\)["'\'']*/\1/')
        echo -e "${GREEN}✓ Português já está configurado com modelo multilíngue (${CURRENT_MODEL})${NC}"
        # Still update if using a slower model
        if echo "$CURRENT_MODEL" | grep -qiE "(large-v3|large-v3-turbo)"; then
            echo -e "${YELLOW}⚠ Modelo atual é lento. Atualizando para modelo mais rápido...${NC}"
            NEEDS_UPDATE=true
        else
            NEEDS_UPDATE=false
        fi
    else
        echo -e "${YELLOW}⚠ Idioma configurado mas modelo pode não ser multilíngue, atualizando...${NC}"
        NEEDS_UPDATE=true
    fi
else
    NEEDS_UPDATE=true
fi

# Update if either needs updating
if [ "$NEEDS_UPDATE" = true ] || [ "$NEEDS_AUDIO_UPDATE" = true ]; then
    NEEDS_UPDATE=true
fi

echo ""

if [ "$NEEDS_UPDATE" = true ]; then
    # Use Python if available (more reliable for TOML manipulation)
    if command -v python3 &>/dev/null; then
        export VOXTYPE_AUDIO_DEVICE="$AUDIO_DEVICE"
        python3 << 'PYTHON_EOF'
import os
import re
from pathlib import Path

config_path = Path.home() / ".config" / "voxtype" / "config.toml"
config_path.parent.mkdir(parents=True, exist_ok=True)

# Read existing config or create empty
if config_path.exists():
    content = config_path.read_text()
else:
    content = ""

# Check if [audio] section exists and configure device
has_audio_section = re.search(r'^\s*\[audio\]', content, re.MULTILINE)

# Get audio device from environment or use default
audio_device = os.environ.get('VOXTYPE_AUDIO_DEVICE', 'amd-soundwire')

if has_audio_section:
    # Update existing [audio] section device
    if re.search(r'^\s*device\s*=', content, re.MULTILINE):
        # Update existing device
        content = re.sub(
            r'(^\s*\[audio\]\s*\n(?:[^\[]*\n)*?)(device\s*=\s*)[^\n]+',
            r'\1\2"' + audio_device + '"',
            content,
            flags=re.MULTILINE
        )
    else:
        # Add device after [audio] section
        content = re.sub(
            r'(^\s*\[audio\]\s*\n)',
            r'\1device = "' + audio_device + '"\n',
            content,
            flags=re.MULTILINE
        )
else:
    # Add [audio] section before [whisper] if it exists, otherwise at the end
    if content and not content.endswith('\n'):
        content += '\n'
    audio_section = '\n[audio]\ndevice = "' + audio_device + '"\n'
    if re.search(r'^\s*\[whisper\]', content, re.MULTILINE):
        # Insert before [whisper] section
        content = re.sub(
            r'(^\s*\[whisper\])',
            audio_section + r'\1',
            content,
            flags=re.MULTILINE
        )
    else:
        content += audio_section

# Check if [whisper] section exists
has_whisper_section = re.search(r'^\s*\[whisper\]', content, re.MULTILINE)

if has_whisper_section:
    # Update existing [whisper] section
    # Update model to 'small' for better speed/accuracy balance
    content = re.sub(
        r'(^\s*\[whisper\]\s*\n(?:[^\[]*\n)*?)(model\s*=\s*)[^\n]+',
        r'\1\2"small"',
        content,
        flags=re.MULTILINE
    )
    # Add or update language
    if re.search(r'^\s*language\s*=', content, re.MULTILINE):
        # Update existing language
        content = re.sub(
            r'(^\s*language\s*=\s*)[^\n]+',
            r'\1"pt"',
            content,
            flags=re.MULTILINE
        )
    else:
        # Add language after model in [whisper] section
        content = re.sub(
            r'(^\s*\[whisper\]\s*\n(?:[^\[]*\n)*?)(model\s*=\s*[^\n]+)',
            r'\1\2\nlanguage = "pt"',
            content,
            flags=re.MULTILINE
        )
else:
    # Add [whisper] section at the end
    if content and not content.endswith('\n'):
        content += '\n'
    content += '\n[whisper]\n'
    content += 'model = "small"\n'
    content += 'language = "pt"\n'

config_path.write_text(content)
print("Configuração atualizada com sucesso")
PYTHON_EOF
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Configuração atualizada usando Python${NC}\n"
        else
            echo -e "${RED}✗ Erro ao atualizar configuração com Python${NC}\n"
        fi
    else
        # Fallback: Use a simpler approach - recreate the [whisper] section
        TEMP_CONFIG=$(mktemp)
        
        if [ -f "$VOXTYPE_CONFIG" ]; then
            # Remove existing [whisper] section if present
            awk '
                /^\[whisper\]/ { in_whisper=1; next }
                in_whisper && /^\[/ { in_whisper=0 }
                !in_whisper { print }
            ' "$VOXTYPE_CONFIG" > "$TEMP_CONFIG"
            mv "$TEMP_CONFIG" "$VOXTYPE_CONFIG"
        fi
        
        # Add [whisper] section at the end
        if [ -f "$VOXTYPE_CONFIG" ] && [ -s "$VOXTYPE_CONFIG" ]; then
            # File exists and is not empty, add newline if needed
            if [ "$(tail -c 1 "$VOXTYPE_CONFIG")" != "" ]; then
                echo "" >> "$VOXTYPE_CONFIG"
            fi
        fi
        
        # Append [audio] and [whisper] sections
        cat >> "$VOXTYPE_CONFIG" << CONFIG_EOF
[audio]
device = "${AUDIO_DEVICE}"

[whisper]
model = "small"
language = "pt"
CONFIG_EOF
        
        echo -e "${GREEN}✓ Configuração atualizada${NC}\n"
    fi
fi

# Step 4: Configure GPU/iGPU acceleration (optional but recommended for better performance)
echo -e "${YELLOW}Configurando aceleração por GPU/iGPU...${NC}"

# Check current GPU status
GPU_STATUS=$(voxtype setup gpu --status 2>&1)
if echo "$GPU_STATUS" | grep -qi "GPU: not detected"; then
    echo -e "${YELLOW}⚠ GPU não detectada ou não disponível${NC}"
    echo -e "${BLUE}O Voxtype usará CPU para processamento${NC}"
    echo -e "${BLUE}Para habilitar GPU depois (se disponível), execute:${NC}"
    echo -e "${BLUE}  sudo voxtype setup gpu --enable${NC}\n"
else
    # Check if GPU backend is already active
    if echo "$GPU_STATUS" | grep -qiE "Active backend:.*GPU"; then
        CURRENT_BACKEND=$(echo "$GPU_STATUS" | grep -i "Active backend:" | sed 's/.*Active backend: //')
        echo -e "${GREEN}✓ GPU já está configurada e ativa (${CURRENT_BACKEND})${NC}\n"
    else
        # Check if GPU backend is available but not active
        if echo "$GPU_STATUS" | grep -qiE "GPU.*installed|Vulkan.*installed"; then
            echo -e "${YELLOW}Backend GPU disponível mas não está ativo${NC}"
            echo -e "${BLUE}Tentando habilitar aceleração por GPU/iGPU...${NC}"
            
            # Try to enable GPU (requires sudo)
            if sudo voxtype setup gpu --enable 2>&1; then
                echo -e "${GREEN}✓ Aceleração por GPU/iGPU habilitada com sucesso${NC}\n"
            else
                echo -e "${YELLOW}⚠ Não foi possível habilitar GPU automaticamente${NC}"
                echo -e "${BLUE}Você pode tentar habilitar manualmente executando:${NC}"
                echo -e "${BLUE}  sudo voxtype setup gpu --enable${NC}"
                echo -e "${BLUE}O Voxtype continuará usando CPU${NC}\n"
            fi
        else
            echo -e "${YELLOW}⚠ Backend GPU não está instalado${NC}"
            echo -e "${BLUE}O Voxtype usará CPU para processamento${NC}"
            echo -e "${BLUE}Para instalar suporte GPU depois, execute:${NC}"
            echo -e "${BLUE}  sudo voxtype setup gpu --enable${NC}\n"
        fi
    fi
fi

# Step 5: Restart voxtype service to apply new configuration
echo -e "${YELLOW}Reiniciando serviço voxtype para aplicar configurações...${NC}"

# Try to restart via systemd if service exists
if systemctl --user list-unit-files 2>/dev/null | grep -q voxtype.service; then
    if systemctl --user restart voxtype.service 2>&1; then
        echo -e "${GREEN}✓ Serviço voxtype reiniciado${NC}\n"
    else
        echo -e "${YELLOW}⚠ Não foi possível reiniciar o serviço via systemd${NC}"
        echo -e "${BLUE}Você pode reiniciar manualmente com: ${BLUE}systemctl --user restart voxtype${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠ Serviço systemd não encontrado${NC}"
    echo -e "${BLUE}Você pode iniciar o voxtype manualmente com: ${BLUE}voxtype daemon${NC}\n"
fi

echo ""
echo -e "${GREEN}Instalação e configuração concluídas!${NC}"
echo ""
echo -e "${YELLOW}Resumo:${NC}"
echo -e "  • Voxtype: Instalado usando comandos do Omarchy"
echo -e "  • Modelo: ${MODEL_NAME} (multilíngue, rápido)"
echo -e "  • Idioma: Português Brasil (pt) - definido como padrão"
echo -e "  • Microfone: ${AUDIO_DEVICE} - definido como padrão"
if [ "$AUDIO_DEVICE" != "amd-soundwire" ]; then
    echo -e "    ${YELLOW}⚠ Nota: amd-soundwire não foi encontrado, usando ${AUDIO_DEVICE}${NC}"
    echo -e "    ${BLUE}Para usar amd-soundwire quando disponível, edite: $VOXTYPE_CONFIG${NC}"
fi
echo -e "  • Configuração salva em: $VOXTYPE_CONFIG"

# Check if model needs to be downloaded
if [ ! -f "$MODEL_PATH" ]; then
    echo ""
    echo -e "${YELLOW}⚠ Atenção: O modelo ainda não foi baixado${NC}"
    echo -e "${BLUE}Para baixar o modelo agora, execute:${NC}"
    echo -e "${BLUE}  voxtype setup --download --model ${MODEL_NAME}${NC}"
    echo ""
    echo -e "${YELLOW}Ou o modelo será baixado automaticamente quando você iniciar o Voxtype${NC}"
fi

echo ""
echo -e "${YELLOW}Notas importantes:${NC}"
echo -e "  • Modelos .en (tiny.en, base.en, etc.) são apenas para inglês"
echo -e "  • Para português, você precisa de modelos multilíngues:"
echo -e "    - small (recomendado, ~466 MB, rápido e preciso)"
echo -e "    - medium (~1.5 GB, mais lento, ligeiramente melhor precisão)"
echo -e "    - large-v3 (~3.1 GB, muito lento, melhor precisão mas geralmente não vale a pena)"
echo ""
echo -e "${YELLOW}Aceleração por GPU/iGPU:${NC}"
echo -e "  • O Voxtype suporta aceleração por GPU usando Vulkan (para Whisper)"
echo -e "  • Funciona com iGPU Intel e AMD, além de GPUs dedicadas NVIDIA/AMD"
echo -e "  • GPU acelera significativamente a transcrição (especialmente modelos maiores)"
echo -e "  • Para verificar status: ${BLUE}voxtype setup gpu --status${NC}"
echo -e "  • Para habilitar: ${BLUE}sudo voxtype setup gpu --enable${NC}"
echo -e "  • Para desabilitar: ${BLUE}sudo voxtype setup gpu --disable${NC}"
echo ""
echo -e "${YELLOW}Para testar:${NC}"
if command -v omarchy-voxtype-status &>/dev/null; then
    echo -e "  • Verifique o status: ${BLUE}omarchy-voxtype-status${NC}"
else
    echo -e "  • Verifique o status: ${BLUE}systemctl --user status voxtype${NC}"
fi
echo -e "  • Reinicie o serviço: ${BLUE}systemctl --user restart voxtype${NC}"
if command -v omarchy-voxtype-config &>/dev/null; then
    echo -e "  • Editar configuração: ${BLUE}omarchy-voxtype-config${NC}"
fi
if command -v omarchy-voxtype-model &>/dev/null; then
    echo -e "  • Alterar modelo: ${BLUE}omarchy-voxtype-model${NC}"
fi
echo ""
