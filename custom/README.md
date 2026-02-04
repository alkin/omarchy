# README

```bash
# Install Omarchy from bootable ISO.

# Connect to Wi-Fi and update Omarchy / System.

# Authenticate with GitHub and clone the repository:

gh auth login
gh repo clone alkin/omarchy

# Run the custom setup script:

./omarchy/custom/install.sh

# Sign in to Google Chrome and set up your default pages.

# Sign in to Cursor; refresh your profile if needed.

# Sign in to OpenCode

# Log in to cloud services:

gcloud auth login
az login
pulumi login

# Setup Work Projects Comunitive and Peepi.
```

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

# Cloud
cd cloud/app

npm install

pulumi stack select comunitive/production

gcloud config set project comunitive-staging
gcloud container clusters get-credentials comunitive-cluster --location us-east4
kubectx comunitive-staging=gke_comunitive-staging_us-east4_comunitive-cluster

gcloud config set project comunitive
gcloud container clusters get-credentials comunitive-cluster --location us-east4
kubectx comunitive-production=gke_comunitive_us-east4_comunitive-cluster

# Deploy
cd cloud/app
pulumi whoami
k get po

pulumi up
k rollout restart deployment -l app=comunitive
k rollout status deployment -l app=comunitive
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

# Cloud
az aks get-credentials -a -n peepi-production -g peepi-production
kubectx peepi-production=peepi-production-admin

# Deploy
az account show
peepi secrets download production
peepi deploy production
peepi tinker
```

# TODO

- zsh plugins nao abrindo nas janelas iniciais
- cursor profile
- opencode
- test deploy

# Aprender

- zsh plugins and usage review
- steam
- Chrome profiles
- Terminal
    - nano / vim ?
    - starship info -> Remove unused (bun version etc)
- Usage
    - snapshots ?
    - printscreen

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
    - Theme sync: Configurado para recarregar automaticamente após mudança de tema (ver `custom/config/config-theme-cursor.sh`)
- Terminal
    - Keybindings
    - Ghostty, zsh, prompt, aliases
    - TUI, CLI tools
    - neovim
- Apps
    - Keybindings
    - Steam

# Ricing
