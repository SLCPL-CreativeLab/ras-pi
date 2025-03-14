#!/bin/bash

# This script gets a Raspberry Pi setup with essential tools.
# For explanations of commands, please visit raspi.vintagecoding.net

# Update repositories and upgrade installed packages.
sudo apt update && sudo apt upgrade;

# Install requisite packages for cloudflared.
sudo apt install curl lsb-release;

# Add cloudflare gpg key
sudo mkdir -p --mode=0755 /usr/share/keyrings;
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null;

# Add this repo to your apt repositories
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list;

echo "Installing nginx, cloudflared, podman, golang, tldr, and neovim to get you started. Run `sudo apt install package` to install other applications. Please see";
echo "raspi.vintagecoding.net#package-manager for more information.";
sudo apt update && sudo apt install nginx cloudflared podman golang tldr neovim;
