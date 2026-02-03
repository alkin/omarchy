Z# README

## Quick Start Setup

- **Install Omarchy from bootable ISO.**
- **Connect to Wi-Fi and update Omarchy / System.**
- **Authenticate with GitHub and clone the repository:**  
    gh auth login  
    gh repo clone alkin/omarchy
- **Run the custom setup script:**  
    ./omarchy/custom/install.sh
- **Sign in to Google Chrome** and set up your default pages.
- **Log in to cloud services:**  
    gcloud auth login
    az login
    pulumi login
- **Initialize and rename your Kubernetes contexts.**
- **Sign in to Cursor; refresh your profile if needed.**
- **Setup Work Projects Comunitive and Peepi.**


# Work

## Comunitive

```bash
# Setup
gh repo clone comunitive/comunitive
cd comunitive
bash scripts/setup.sh

# Dev Env
sail up -d
sail artisan migrate:refresh
sail down

cd frontend/tenant
bun dev

# Deploy
cd cloud/app
pulumi whoami
k get po

pulumi up
k rollout restart deployment -l app=comunitive
```

## Peepi

```bash
# Setup
gh repo clone peepi-com-br/peepi
cd peepi
bash ./scripts/setup.sh
sudo chmod -R 0777 storage bootstrap

# Dev Env
peepi up
peepi seed
peepi down

cd vite
bun dev

# Deploy
az account show
peepi secrets download production
peepi deploy production
peepi tinker
```

# TODO

- Notebook Config
    - [OK] Invert the vertical scroll on trackpad
    - [OK] F9 -> play pause
    - [OK] Aumentar waybar no monitor externo
    - [OK] Remove CTRL F1 keybinding
    - [OK] Num Lock enabled automatically at boot (including disk encryption screen)

- Cursor theme
- zsh plugins and usage review
- steam
- config desktop
- Chrome profiles
- [OK] rep mirrors
- Terminal
    - Scroll speed
    - home / del button on shell ?
    - nano / vim ?
    - starship info -> Remove unused (bun version etc)
- Usage
    - [OK] dictation - Voxtype configured with Portuguese Brazil model
    - snapshots ?
    - printscreen

- Disable opacity on all windows

# Usage

- Omarchy
    - Keybindings
    - Waybar
    - Printscreen, Screen Capture, Dictation
- Hyprland
    - Keybindings
    - Workspaces + Scratchpad
- Chrome
    - Keybindings
    - Profiles, Default Tabs, Favorite bar
- Cursor
    - Keybindings
    - Profile, Extensions, Keybindings
- Terminal
    - Keybindings
    - Ghostty, zsh, prompt, aliases
    - TUI, CLI tools
    - neovim
- Apps
    - Keybindings
    - Steam

# Ricing
