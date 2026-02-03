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

# Step 0: Install Voxtype if not installed
if ! command -v voxtype &>/dev/null; then
    echo -e "${YELLOW}Voxtype não está instalado. Instalando do AUR...${NC}"
    echo -e "${BLUE}Instalando voxtype do AUR (isso pode demorar alguns minutos)...${NC}"
    if yay -S --noconfirm voxtype 2>&1; then
        echo -e "${GREEN}✓ Voxtype instalado com sucesso${NC}\n"
    else
        echo -e "${RED}✗ Erro ao instalar Voxtype${NC}"
        echo -e "${YELLOW}Você pode tentar instalar manualmente executando:${NC}"
        echo -e "${BLUE}  yay -S voxtype${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Voxtype já está instalado${NC}\n"
fi

# Create config directory if it doesn't exist
VOXTYPE_CONFIG_DIR="$HOME/.config/voxtype"
mkdir -p "$VOXTYPE_CONFIG_DIR"

# Check if config file exists, create if not
VOXTYPE_CONFIG="$VOXTYPE_CONFIG_DIR/config.toml"

# Step 1: Download multilingual Whisper model if not already downloaded
# Using 'small' model for best speed/accuracy balance for Portuguese
MODEL_NAME="small"
echo -e "${YELLOW}Verificando/downloadando modelo multilíngue Whisper (${MODEL_NAME})...${NC}"

# Check if model already exists
MODEL_PATH="$HOME/.local/share/voxtype/models/ggml-${MODEL_NAME}.bin"
if [ -f "$MODEL_PATH" ]; then
    MODEL_SIZE=$(du -h "$MODEL_PATH" | cut -f1)
    echo -e "${GREEN}✓ Modelo ${MODEL_NAME} já está baixado (${MODEL_SIZE})${NC}\n"
else
    echo -e "${YELLOW}Baixando modelo ${MODEL_NAME} (isso pode demorar alguns minutos, ~466 MB)...${NC}"
    echo -e "${BLUE}Por favor, aguarde...${NC}\n"
    
    # Download the model using voxtype setup command
    DOWNLOAD_OUTPUT=$(voxtype setup --download --model ${MODEL_NAME} 2>&1)
    DOWNLOAD_EXIT_CODE=$?
    
    if [ $DOWNLOAD_EXIT_CODE -eq 0 ]; then
        echo -e "\n${GREEN}✓ Modelo baixado com sucesso${NC}\n"
    else
        echo -e "\n${YELLOW}⚠ Aviso: Download do modelo falhou ou foi interrompido${NC}"
        echo -e "${YELLOW}Possíveis causas:${NC}"
        echo -e "  • Sem conexão com a internet"
        echo -e "  • Problema de rede/DNS"
        echo -e "  • Download interrompido"
        echo ""
        echo -e "${BLUE}O modelo será baixado automaticamente quando você iniciar o Voxtype pela primeira vez${NC}"
        echo -e "${BLUE}Ou você pode tentar baixar manualmente depois executando:${NC}"
        echo -e "${BLUE}  voxtype setup --download --model ${MODEL_NAME}${NC}\n"
        echo -e "${YELLOW}Continuando com a configuração do idioma...${NC}\n"
    fi
fi

# Step 2: Configure config.toml with Portuguese language
echo -e "${YELLOW}Configurando idioma Português Brasil...${NC}"

# Backup existing config if it exists
if [ -f "$VOXTYPE_CONFIG" ]; then
    cp "$VOXTYPE_CONFIG" "$VOXTYPE_CONFIG.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
fi

# Check if Portuguese is already configured
NEEDS_UPDATE=false
if [ -f "$VOXTYPE_CONFIG" ] && grep -qiE "language\s*=\s*[\"']?pt[\"']?" "$VOXTYPE_CONFIG" 2>/dev/null; then
    # Check if it's using a multilingual model (not .en models)
    if grep -qiE "model\s*=\s*[\"']?(small|medium|large-v3)" "$VOXTYPE_CONFIG" 2>/dev/null && ! grep -qiE "model\s*=\s*[\"']?.*\.en" "$VOXTYPE_CONFIG" 2>/dev/null; then
        CURRENT_MODEL=$(grep -iE "model\s*=" "$VOXTYPE_CONFIG" 2>/dev/null | head -1 | sed 's/.*=\s*["'\'']*\([^"'\'']*\)["'\'']*/\1/')
        echo -e "${GREEN}✓ Português já está configurado com modelo multilíngue (${CURRENT_MODEL})${NC}\n"
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

if [ "$NEEDS_UPDATE" = true ]; then
    # Use Python if available (more reliable for TOML manipulation)
    if command -v python3 &>/dev/null; then
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
        
        # Append [whisper] section
        cat >> "$VOXTYPE_CONFIG" << 'CONFIG_EOF'
[whisper]
model = "small"
language = "pt"
CONFIG_EOF
        
        echo -e "${GREEN}✓ Configuração atualizada${NC}\n"
    fi
fi

echo ""
echo -e "${GREEN}Instalação e configuração concluídas!${NC}"
echo ""
echo -e "${YELLOW}Resumo:${NC}"
echo -e "  • Voxtype: Instalado"
echo -e "  • Modelo: ${MODEL_NAME} (multilíngue, rápido)"
echo -e "  • Idioma: Português (pt)"
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
echo -e "${YELLOW}Para testar:${NC}"
echo -e "  • Reinicie o serviço: ${BLUE}systemctl --user restart voxtype${NC}"
echo -e "  • Ou verifique o status: ${BLUE}systemctl --user status voxtype${NC}"
echo ""
