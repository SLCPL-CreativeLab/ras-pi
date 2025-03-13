#!/bin/bash

# This script gets a Raspberry Pi setup with essential applications.
#
# For explanations of commands, visit raspi.vintagecoding.net or use Google.

# GLOBAL VARIABLES

DOMAIN=""
MANUAL_PORT=5090
JELLYFIN_PORT=5091
OLLAMA_PORT=5092

# This function initializes core services and packages for getting started.
init() {
	# Update repositories and upgrade installed packages.
	sudo apt update && sudo apt upgrade;

	# Install requisite packages for cloudflared.
	sudo apt install curl lsb-release;

		# Add cloudflare gpg key
	sudo mkdir -p --mode=0755 /usr/share/keyrings
	curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

	# Add this repo to your apt repositories
	echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list

	# install cloudflared
	sudo apt-get update && sudo apt-get install cloudflared

	# Install cloudflared.
	# Install podman, a container technology for easily deploying projects.
	# Install golang, a server-side programming language.
	# Install tools for the user
	sudo apt update;
	sudo apt install cloudflared podman golang tldr neovim;

	# Get user input for some default applications to get started.
	read -p "Do you want a mirror of the manual from raspi.vintagecoding.net on this device? (y/N): " MANUAL;
	MANUAL=$(echo "$MANUAL" | tr '[:upper:]' '[:lower:]')
	if [[ -z "$MANUAL" || "$MANUAL" == "n" ]]; then
			MANUAL="n"
	else
		init_manual;
	fi

	read -p "Do you want to setup Jellyfin, a personal Netflix alternative? (y/N): " JELLYFIN;
	JELLYFIN=$(echo "$JELLYFIN" | tr '[:upper:]' '[:lower:]')
	if [[ -z "$JELLYFIN" || "$JELLYFIN" == "n" ]]; then
		JELLYFIN="n"
	else
		init_jellyfin;
	fi

	read -p "Do you want to setup Ollama, a personal ChatGPT alternative? (y/N): " OLLAMA;
	OLLAMA=$(echo "$OLLAMA" | tr '[:upper:]' '[:lower:]')
	if [[ -z "$OLLAMA" || "$OLLAMA" == "n" ]]; then
		OLLAMA="n"
	else
		init_ollama;
	fi

}

# This function initializes the manual mirror of raspi.vintagecoding.net
init_manual() {
	cd ~/ras-pi/man/pages;
	echo "[Unit]
Description=Raspberry Pi Manual Mirror
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=$(whoami)
WorkingDirectory=$(pwd)
ExecStartPre=/usr/bin/git pull
ExecStart=/usr/bin/python3 -m http.server $MANUAL_PORT

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/manual.service;

	sudo systemctl enable manual.service;
	sudo systemctl start manual.service;
	sudo systemctl daemon-reload;
}

# This function initializes Jellyfin.
init_jellyfin() {
	# Get the official image of Jellyfin software
	podman pull ghcr.io/jellyfin/jellyfin;

	echo "Making media directories where Jellyfin will retrieve content.";
	echo "It is up to you to provide supported files and build a library.";

	cd;
	mkdir media;

	podman run \
		--detach \
		--label "io.containers.autoupdate=registry" \
		--name myjellyfin \
		--publish $JELLYFIN_PORT:8096/tcp \
		--user $(id -u):$(id -g) \
		--volume jellyfin-cache:/cache:Z \
		--volume jellyfin-config:/config:Z \
		--mount type=bind,source=/$(pwd)/media,destination=/media,ro=true,relabel=private \
		--restart always \
	ghcr.io/jellyfin/jellyfin;

	echo "Finished creating the Jellyfin container! It is now live on";
	echo "http://localhost:$JELLYFIN_PORT. If you enabled it, it'll also be";
	echo "available at media.yourdomain.com.";
}

# This function initializes Ollama.
init_ollama() {
	echo "This will take a while...";
	cd;
	curl -fsSL https://ollama.com/install.sh | sh;
	echo "export OLLAMA_BASE_URL=http://localhost:11434;
export WEBUI_AUTH=False;" >> $HOME/.bashrc;
	source $HOME/.bashrc

	# TODO: Write a script so this can be daemonized.
	python -m venv open-webui-env;
	source open-webui-env/bin/activate
	pip install open-webui;

	echo "server {
	listen 80; #or whatever port your open-webui backend is running on.
	server_name localhost;

	location / {
		proxy_pass http://localhost:$OLLAMA_PORT/;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection 'upgrade';
		proxy_set_header Host $host;
		proxy_cache_bypass $http_upgrade;
	}

	location /api/ {
		proxy_pass http://localhost:$OLLAMA_PORT/api/; # Ensure the trailing slash is present
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection 'upgrade';
		proxy_set_header Host $host;
		proxy_cache_bypass $http_upgrade;
	}
}" | sudo tee/etc/nginx/sites-available/open-webui;
	sudo ln -s /etc/nginx/sites-available/open-webui /etc/nginx/sites-enabled
	sudo systemctl enable nginx;
	sudo systemctl start nginx;

	open-webui serve --port $OLLAMA_PORT &
}

init;
