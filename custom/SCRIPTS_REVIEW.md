# Revisão de Scripts Config e Install

## Scripts Utilizados

### Em `install.sh`:
- ✅ `config-mirrors.sh`
- ✅ `install/install-desktop.sh`
- ✅ `install/install-dev.sh`
- ✅ `install/install-utils.sh`
- ✅ `install/install-terminal.sh`
- ✅ `uninstall.sh`
- ❌ `config-desktop.sh` (comentado - linha 44-46)

### Em `config-laptop.sh`:
- ✅ `config/config-trackpad.sh`
- ✅ `config/config-f9-playpause.sh`
- ✅ `config/config-remove-ctrl-f1.sh`
- ✅ `config/config-waybar-monitor.sh`
- ✅ `install/install-dictation.sh`
- ✅ `config/config-numlock.sh`
- ✅ `config/config-zsh-keybindings.sh`

## Scripts NÃO Utilizados (ANTES DA REVISÃO)

### Scripts de Configuração:
1. ❌ `config/config-ghostty-scroll.sh` - Configura velocidade do scroll do Ghostty
   - **Status no README**: [OK] configurado
   - **Status**: ✅ **ADICIONADO ao `config-laptop.sh`**

2. ❌ `config/config-microphone.sh` - Configura microfone (desabilita microfone do monitor)
   - **Status no README**: [OK] configurado
   - **Status**: ✅ **ADICIONADO ao `config-laptop.sh`**

3. ❌ `config/config-opacity.sh` - Remove opacidade de todas as janelas
   - **Status no README**: [OK] configurado
   - **Status**: ✅ **ADICIONADO ao `config-laptop.sh`**

4. ❌ `config-desktop.sh` - Configura workspaces do desktop
   - **Status**: Comentado no `install.sh`
   - **Recomendação**: Descomentar se necessário ou criar script separado para desktop

## Mudanças Realizadas

✅ **Adicionados ao `config-laptop.sh`**:
- `config-ghostty-scroll.sh` - Configura velocidade do scroll do Ghostty
- `config-opacity.sh` - Remove opacidade de todas as janelas
- `config-microphone.sh` - Configura microfone (desabilita microfone do monitor)

## Recomendações Pendentes

1. **Decidir sobre `config-desktop.sh`**:
   - Se for necessário, descomentar no `install.sh`
   - Ou criar um script separado `run-config-desktop.sh`

2. **Considerar criar um script `run.sh`**:
   - Como mencionado no AGENTS.md, um script `run.sh` poderia orquestrar todos os scripts
   - Facilitaria a execução de todos os scripts de uma vez
