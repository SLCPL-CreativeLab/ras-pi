#!/bin/bash

DOMAIN=""
MANUAL_PORT=5090
JELLYFIN_PORT=5091
OLLAMA_PORT=5092

# This function initializes cloudflared.
# TODO: This needs to dynamically insert based upon what the user has entered.
init_cloudflared() {
	read -p "What is your domain name? e.g., vintagecoding.net: " DOMAIN;

	echo "export TUNNEL_ORIGIN_CERT=$HOME/.cloudflared/cert.pem" >> $HOME/.bashrc;
	source $HOME/.bashrc;

	cloudflared tunnel create raspi;
	TUNNEL_ID=$(cloudflared tunnel list | awk '/raspi/ {print $1}');

	cd;
	echo "tunnel: $TUNNEL_ID
credentials-file: $(pwd)/.cloudflared/$TUNNEL_ID.json
ingress:
  - hostname: raspi.$DOMAIN
    service: http://localhost:$MANUAL_PORT
  - hostname: media.$DOMAIN
    service: http://localhost:$JELLYFIN_PORT
  - hostname: ai.$DOMAIN
    service: http://localhost:$OLLAMA_PORT
  - service: http_status:404" > $(pwd)/.cloudflared/config.yaml;

	cloudflared tunnel route dns $TUNNEL_ID raspi.$DOMAIN;
	cloudflared tunnel route dns $TUNNEL_ID media.$DOMAIN;
	cloudflared tunnel route dns $TUNNEL_ID ai.$DOMAIN;
	
	ACTUAL_USER=$(whoami)

	echo "[Unit]
Description=Cloudflare Tunnel Daemon
After=network.target

[Service]
Type=simple
User=$ACTUAL_USER
ExecStart=/usr/bin/cloudflared tunnel run raspi
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/cloudflared.service;

	sudo systemctl enable cloudflared.service;
	sudo systemctl start cloudflared.service;

	source ~/.bashrc;

	sudo sed -i -e 's/server_name localhost/servername ai.$DOMAIN/' /etc/nginx/sites-available/open-webui;

	kill -9 $(pgrep open-webui);
	cd;
	source open-webui-env/bin/activate;

	read -p "Do you want to require login to your AI? (n/Y)" REQUIRE_LOGIN
	REQUIRE_LOGIN=$(echo "$REQUIRE_LOGIN" | tr '[:upper:]' '[:lower:]')
	if [[ -z "$REQUIRE_LOGIN" || "$REQUIRE_LOGIN" == "n" ]]; then
		export WEBUI_AUTH=False;
	fi

	export OLLAMA_BASE_URL=http://localhost:11434;
	export WEBUI_BASE_URL=ai.$DOMAIN;
	open-webui serve --port $OLLAMA_PORT &
}

read -p "Has the command 'cloudflared tunnel login' been executed? (y/N): " LOGGED_IN
LOGGED_IN=$(echo "$LOGGED_IN" | tr '[:upper:]' '[:lower:]')
if [[ -z "$LOGGED_IN" || "$LOGGED_IN" == "y" ]]; then
	init_cloudflared;
else
	echo "You can still use Cloudflare for free, by generating random URLs."
	echo "Enter the following into a terminal:";
	echo "    cloudflared tunnel --url=http://localhost:PORT";
	echo "to get a URL a process, for example. Replace PORT with one of the following:";
	echo "    $MANUAL_PORT (The manual mirror's port.)";
	echo "    $JELLYFIN_PORT (The Jellyfin port.)";
	echo "    $OLLAMA_PORT (The Ollama & Open Web-UI port.)";
fi
