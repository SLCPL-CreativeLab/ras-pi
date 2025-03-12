# This script gets a Raspberry Pi setup with essential applications.
#
# For explanations of commands, visit raspi.vintagecoding.net or use Google.

# GLOBAL VARIABLES

DOMAIN=""
MANUAL_PORT=5090
JELLYFIN_PORT=5091
OLLAMA_PORT=5092

help() {
	echo "This script gets a Raspberry Pi setup with essential applications.";
	echo "By default, everything will be installed. But, there are some flags";
	echo "available for the end user. Multiple flags can be used together.";
	echo "";
	echo "";
	echo "";
	echo "If you're new to the command line, the structure of these help";
	echo "pages is often like this:";
	echo "    command { --full-name-of-flag | -f }";
	echo "Where, the curly braces indicates a grouping of options, typically";
	echo "the full name of a flag, | (or) the short flag.";
	echo "Therefore, either of the following commands are valid:";
	echo "    command --full-name-of-flag";
	echo "or";
	echo "    command -f";
	echo "Furthermore, different flags can be chained together. e.g.,";
	echo "    command --flag-1 --flag-2";
	echo "";
	echo "";
	echo "";
	echo "If you're new, checkout the Raspberry Pi manual available at";
	echo "raspi.vintagecoding.net.";
	echo "";
	echo "";
	echo "";
	echo "NOTE: This script CANNOT be copied to /usr/local/bin, or anywhere on";
	echo "the PATH environment variable. That interferes with the system-level";
	echo "install command.";
	echo "";
	echo "";
	echo "";
	echo "Usage:";
	echo "    ./install.sh { --help | -h }";
	echo "";
	echo "";
	echo "";
	echo "The user will be prompted for each feature beyond the the barebones";
	echo "system utilities installation.";
}

# This function initializes core services and packages for getting started.
init() {
	# Update repositories and upgrade installed packages.
	sudo apt update && sudo apt upgrade;

	# Install requisite packages for cloudflared.
	sudo apt install curl lsb-release;

	# Downloads the GPG key (a package integrity technology).
	curl -L https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee \
		/usr/share/keyrings/cloudflare-archive-keyring.gpg > /dev/null;

	# Add the GPG key to the allowed repositories to download packages from.
	echo "deb [signed-by=/usr/share/keyrings/cloudflare-archive.keyring.gpg] \
		https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" \
		| sudo tee /etc/apt/sources.list.d/cloudflared.list;

	# Install cloudflared.
	# Install podman, a container technology for easily deploying projects.
	# Install golang, a server-side programming language.
	# Install tools for the user
	sudo apt update && sudo apt install nginx cloudflared podman golang tldr neovim;

}

# This function initializes the manual mirror of raspi.vintagecoding.net
init_manual() {
	cd ~/ras-pi/man/pages;
	sudo echo "
		[Unit]
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
		WantedBy=multi-user.target
	" > /etc/systemd/system/manual.service;

	sudo systemctl enable manual.service;
	sudo systemctl start manual.service;
	sudo systemctl daemon-reload;
}

# This function initializes Jellyfin.
init_jellyfin() {
	# Get the official image of Jellyfin software
	podman pull jellyfin/jellyfin;

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
		--userns keep-id \
		--volume jellyfin-cache:/cache:Z \
		--volume jellyfin-config:/config:Z \
		--mount type=bind,source=/$(pwd)/media,destination=/media,ro=true,relabel=private \
		--restart always \
	jellyfin

	echo "Finished creating the Jellyfin container! It is now live on";
	echo "http://localhost:$JELLYFIN_PORT. If you enabled it, it'll also be";
	echo "available at media.yourdomain.com.";
}

# This function initializes Ollama.
init_ollama() {
	echo "This will take a while...";

	cd;
	python -m venv open-webui-env;
	source open-webui-env/bin/activate
	pip install open-webui;
	echo "
		export OLLAMA_BASE_URL=http://localhost:11434;
		export WEBUI_BASE_URL=ai.$DOMAIN;
		export WEBUI_AUTH=False;
	" >> $(pwd)/.bashrc;
	open-webui serve --port $OLLAMA_PORT &;

	curl -fsSL https://ollama.com/install.sh | sh;
}

# This function initializes cloudflared.
# TODO: This needs to dynamically insert based upon what the user has entered.
init_cloudflared() {
	cloudflared tunnel login;
	cloudflared tunnel create raspi;
	TUNNEL_ID=$(cloudflared tunnel list | awk '/raspi/ {print $1}');
	read "?What is your domain name? e.g., vintagecoding.net" $DOMAIN;

	cd;
	echo "
	tunnel: $TUNNEL_ID
	credentials-file: $(pwd)/.cloudflared/$TUNNEL_ID.json
	ingress:
		- hostname: raspi.$DOMAIN
			service: http://localhost:$MANUAL_PORT
		- hostname: media.$DOMAIN
			service: http://localhost:$JELLYFIN_PORT
		- hostname: ai.$DOMAIN
			service: http://localhost:$OLLAMA_PORT
		- service: http_status:404

		" > $(pwd)/.cloudflared/config.yaml;

	cloudflared tunnel route dns $TUNNEL_ID raspi.$DOMAIN;
	cloudflared tunnel route dns $TUNNEL_ID media.$DOMAIN;
	cloudflared tunnel route dns $TUNNEL_ID ai.$DOMAIN;

	echo "
		[Unit]
		Description=Cloudflare Tunnel Daemon
		After=network.target

		[Service]
		Type=simple
		User=$(whoami)
		ExecStart=/usr/bin/cloudflared tunnel run raspi
		Restart=always

		[Install]
		WantedBy=multi-user.target
	" > /etc/systemd/system/cloudflared.service;

	sudo systemctl enable cloudflared.service;
	sudo systemctl start cloudflared.service;

	sudo echo "
	server {
    listen 80; #or whatever port your open-webui backend is running on.
    server_name ai.$DOMAIN;

    location /api/ {
        proxy_pass http://localhost:$OLLAMA_PORT/api/; # Ensure the trailing slash is present
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    location / {
        proxy_pass http://localhost:$OLLAMA_PORT/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

}
	" > /etc/nginx/sites-available/open-webui;
	sudo ln -s /etc/nginx/sites-available/open-webui /etc/nginx/sites-enabled
	sudo systemctl enable nginx;
	sudo systemctl start nginx;
}

# Display help if the user requests it.
if [[ $# == 1 && ($1 == "--help" || $1 == "-h") ]]; then
	help;
	exit;
fi

# Get user input for some default applications to get started.
read "?Do you have a Cloudflare account and own a domain? (y/N)" CLOUDFLARE;
read "?Do you want a mirror of the manual from raspi.vintagecoding.net\
	on this device? (y/N)" MANUAL;
read "?Do you want to setup Jellyfin, a personal Netflix alternative? (y/N)" JELLYFIN;
read "?Do you want to setup Ollama, a personal ChatGPT alternative? (y/N)" OLLAMA;

init;

if [[ $MANUAL == "y" ]]; then
	init_manual;
fi

if [[ $JELLYFIN == "y" ]]; then
	init_jellyfin;
fi

if [[ $CLOUDFLARE == "y" ]]; then
	init_cloudflare;
else
	echo "You can still use Cloudflare for free, by generating random URLs."
	echo "Enter the following into a terminal:";
	echo "    cloudflared tunnel --url=http://localhost:PORT";
	echo "to get a URL a process, for example. Replace PORT with one of the following:";
	echo "    $MANUAL_PORT (The manual mirror's port.)";
	echo "    $JELLYFIN_PORT (The Jellyfin port.)";
	echo "    $OLLAMA_PORT (The Ollama & Open Web-UI port.)";
fi

if [[ $OLLAMA == "y" ]]; then
	init_ollama;
fi
