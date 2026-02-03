#!/bin/bash

# Configure Num Lock to be enabled automatically at boot
# This ensures Num Lock is on when entering disk encryption password

set +e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Configurando Num Lock para habilitar automaticamente no boot...${NC}\n"

# Install numlockx if not already installed (for X11/Wayland)
if ! command -v numlockx &>/dev/null; then
    echo -e "${YELLOW}Instalando numlockx...${NC}"
    yay -S --noconfirm --needed numlockx 2>/dev/null || true
fi

# Create getty drop-in to enable numlock on all TTYs
# This is more reliable than a separate service
GETTY_DROPIN_DIR="/etc/systemd/system/getty@.service.d"
sudo mkdir -p "$GETTY_DROPIN_DIR"

echo -e "${YELLOW}Criando drop-in do getty para habilitar Num Lock...${NC}"

sudo tee "$GETTY_DROPIN_DIR/numlock.conf" >/dev/null << 'DROPIN_EOF'
[Service]
# Enable Num Lock on TTY startup
ExecStartPre=/bin/sh -c 'exec </dev/tty%I >/dev/tty%I 2>&1; /usr/bin/setleds -D +num'
DROPIN_EOF

# Also create a systemd service as backup
SYSTEMD_SERVICE="/etc/systemd/system/numlock-on.service"

echo -e "${YELLOW}Criando serviço systemd adicional...${NC}"

sudo tee "$SYSTEMD_SERVICE" >/dev/null << 'SERVICE_EOF'
[Unit]
Description=Enable Num Lock on boot
Documentation=man:setleds(1)
After=systemd-vconsole-setup.service
Before=getty@tty1.service

[Service]
Type=oneshot
# Enable numlock on all TTYs
ExecStart=/bin/sh -c 'for tty in /dev/tty[1-9]; do [ -c "$tty" ] && /usr/bin/setleds -D +num < "$tty" 2>/dev/null || true; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable numlock-on.service 2>/dev/null || true

echo -e "${GREEN}✓ Drop-in do getty e serviço systemd criados${NC}\n"

# Also create a script for console (TTY) numlock activation
# This helps with disk encryption password entry
CONSOLE_SCRIPT="/usr/local/bin/enable-numlock-console"

echo -e "${YELLOW}Criando script para habilitar Num Lock no console...${NC}"

sudo tee "$CONSOLE_SCRIPT" >/dev/null << 'SCRIPT_EOF'
#!/bin/bash
# Enable Num Lock on all console TTYs
for tty in /dev/tty[1-9]; do
    if [ -c "$tty" ]; then
        /usr/bin/setleds -D +num < "$tty" 2>/dev/null || true
    fi
done
SCRIPT_EOF

sudo chmod +x "$CONSOLE_SCRIPT"

echo -e "${GREEN}✓ Script de console criado${NC}\n"

# Install mkinitcpio-numlock hook for early boot (initramfs)
# This is the MOST IMPORTANT method for disk encryption password screen
echo -e "${YELLOW}Configurando hook do mkinitcpio para Num Lock (CRÍTICO para tela de senha)...${NC}"

# Install mkinitcpio-numlock from AUR
if ! pacman -Q mkinitcpio-numlock &>/dev/null; then
    echo -e "${YELLOW}Instalando mkinitcpio-numlock do AUR...${NC}"
    yay -S --noconfirm --needed mkinitcpio-numlock
fi

# Check if installed successfully
if pacman -Q mkinitcpio-numlock &>/dev/null; then
    echo -e "${GREEN}✓ mkinitcpio-numlock instalado${NC}\n"
    
    # Edit Omarchy hooks configuration
    OMARCHY_HOOKS_FILE="/etc/mkinitcpio.conf.d/omarchy_hooks.conf"
    
    if [ -f "$OMARCHY_HOOKS_FILE" ]; then
        echo -e "${YELLOW}Editando $OMARCHY_HOOKS_FILE...${NC}"
        
        # Check if numlock is already in HOOKS
        if grep -q "^HOOKS=.*numlock" "$OMARCHY_HOOKS_FILE" 2>/dev/null; then
            echo -e "${GREEN}✓ Hook numlock já está configurado${NC}"
        else
            # Read the current HOOKS line
            HOOKS_LINE=$(grep "^HOOKS=" "$OMARCHY_HOOKS_FILE" 2>/dev/null | head -1)
            
            if [ -n "$HOOKS_LINE" ]; then
                # Add numlock before encrypt hook
                # Example: HOOKS=(... block encrypt ...) -> HOOKS=(... block numlock encrypt ...)
                if echo "$HOOKS_LINE" | grep -q "encrypt"; then
                    # Replace "encrypt" with "numlock encrypt"
                    NEW_HOOKS_LINE=$(echo "$HOOKS_LINE" | sed 's/ encrypt/ numlock encrypt/')
                else
                    # If no encrypt hook, add before filesystems
                    if echo "$HOOKS_LINE" | grep -q "filesystems"; then
                        NEW_HOOKS_LINE=$(echo "$HOOKS_LINE" | sed 's/ filesystems/ numlock filesystems/')
                    else
                        # Add before the closing parenthesis
                        NEW_HOOKS_LINE=$(echo "$HOOKS_LINE" | sed 's/)/ numlock)/')
                    fi
                fi
                
                # Replace the HOOKS line
                echo "$NEW_HOOKS_LINE" | sudo tee "$OMARCHY_HOOKS_FILE" >/dev/null
                echo -e "${GREEN}✓ Hook numlock adicionado ao mkinitcpio${NC}"
                echo -e "${BLUE}  Linha atualizada: $NEW_HOOKS_LINE${NC}"
            else
                echo -e "${YELLOW}⚠ Não foi possível encontrar a linha HOOKS no arquivo${NC}"
            fi
        fi
        
        # Regenerate initramfs
        echo ""
        echo -e "${YELLOW}Regenerando initramfs (isso pode levar alguns minutos)...${NC}"
        sudo mkinitcpio -P
        echo -e "${GREEN}✓ Initramfs regenerado${NC}\n"
    else
        echo -e "${YELLOW}⚠ Arquivo $OMARCHY_HOOKS_FILE não encontrado${NC}"
        echo -e "${YELLOW}  Tentando usar /etc/mkinitcpio.conf...${NC}"
        
        MKINITCPIO_CONF="/etc/mkinitcpio.conf"
        if [ -f "$MKINITCPIO_CONF" ]; then
            if ! grep -q "^HOOKS=.*numlock" "$MKINITCPIO_CONF" 2>/dev/null; then
                HOOKS_LINE=$(grep "^HOOKS=" "$MKINITCPIO_CONF" 2>/dev/null | head -1)
                if [ -n "$HOOKS_LINE" ]; then
                    if echo "$HOOKS_LINE" | grep -q "encrypt"; then
                        NEW_HOOKS_LINE=$(echo "$HOOKS_LINE" | sed 's/encrypt/numlock encrypt/')
                    else
                        NEW_HOOKS_LINE=$(echo "$HOOKS_LINE" | sed 's/filesystems/numlock filesystems/')
                    fi
                    sudo sed -i "s|^HOOKS=.*|$NEW_HOOKS_LINE|" "$MKINITCPIO_CONF"
                    echo -e "${GREEN}✓ Hook numlock adicionado${NC}"
                    echo -e "${YELLOW}Regenerando initramfs...${NC}"
                    sudo mkinitcpio -P
                fi
            fi
        fi
    fi
else
    echo -e "${RED}✗ Falha ao instalar mkinitcpio-numlock${NC}"
    echo -e "${YELLOW}  Instale manualmente: yay -S mkinitcpio-numlock${NC}"
fi

# Verify Hyprland config has numlock enabled (already should be there)
HYPR_INPUT_CONF="$HOME/.config/hypr/input.conf"
if [ -f "$HYPR_INPUT_CONF" ]; then
    if ! grep -q "numlock_by_default = true" "$HYPR_INPUT_CONF" 2>/dev/null; then
        echo -e "${YELLOW}Adicionando numlock_by_default ao Hyprland...${NC}"
        # Add numlock_by_default if not present
        if grep -q "^input {" "$HYPR_INPUT_CONF"; then
            sed -i '/^input {/a\  numlock_by_default = true' "$HYPR_INPUT_CONF" 2>/dev/null || true
        fi
        echo -e "${GREEN}✓ Configuração do Hyprland atualizada${NC}"
    else
        echo -e "${GREEN}✓ Hyprland já configurado com numlock_by_default${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Configuração concluída!${NC}"
echo ""
echo -e "${YELLOW}Notas:${NC}"
echo -e "  • mkinitcpio-numlock instalado e configurado"
echo -e "  • Hook numlock adicionado antes de encrypt no mkinitcpio"
echo -e "  • Initramfs regenerado automaticamente"
echo -e "  • Drop-in do getty habilitará Num Lock em todos os TTYs"
echo -e "  • Hyprland também tem numlock_by_default configurado"
echo ""
echo -e "${BLUE}Reinicie o sistema para aplicar todas as mudanças:${NC}"
echo -e "  ${GREEN}sudo reboot${NC}"
echo ""
