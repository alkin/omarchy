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

- [OK] Ignorar completamente o microfone do monitor - config-microphone.sh configurado

- Microfone do notebook - Audio output do monitor

- Dictation
    - Usar GPU / NPU ?
    - Usar microfone do notebook ?

- Opencode with gemini token

- Cursor theme
- zsh plugins and usage review
- steam
- Workspaces
    - 1 -> Chrome
    - 2 -> Cursor
    - Scratchpag - 3 terminals
    - 9 -> Spotify-9 laptop
- Chrome profiles
- Ghostty - Scroll speed

- [OK] rep mirrors
- Terminal
    - [OK] Scroll speed - config-ghostty-scroll.sh configurado (mouse-scroll-multiplier = 1.5)
    - home / del button on shell ?
    - nano / vim ?
    - starship info -> Remove unused (bun version etc)
- Usage
    - [OK] dictation - Voxtype configured with Portuguese Brazil model
    - snapshots ?
    - printscreen

- [OK] Disable opacity on all windows - config-opacity.sh configurado (opacity 1.0 1.0 para todas as janelas)

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
