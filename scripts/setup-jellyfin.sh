#!/bin/bash

JELLYFIN_PORT=5091;

# Get the official image of Jellyfin software.
echo "Running `podman pull ghcr.io/jellyfin/jellyfin`";
podman pull ghcr.io/jellyfin/jellyfin &;
echo "`podman` is a container technology that allows for easy distribution of software that is platform-agnostic.";
echo "Please see raspi.vintagecoding.net#podman for more information.";

echo "Running `cd && mkdir media;`. This is changing the current directory and MaKing a DIRectory called media.";
echo "This is where your movies and TV shows should go.";
cd && mkdir media;

echo "Running
`podman run \
	--detach \
	--label "io.containers.autoupdate=registry" \
	--name myjellyfin \
	--publish $JELLYFIN_PORT:8096/tcp \
	--user $(id -u):$(id -g) \
	--volume jellyfin-cache:/cache:Z \
	--volume jellyfin-config:/config:Z \
	--mount type=bind,source=$HOME/media,destination=/media,ro=true,relabel=private \
	--restart always \
ghcr.io/jellyfin/jellyfin;`

Please see raspi.vintagecoding.net#podman for more information about this command.";

podman run \
	--detach \
	--label "io.containers.autoupdate=registry" \
	--name myjellyfin \
	--publish $JELLYFIN_PORT:8096/tcp \
	--user $(id -u):$(id -g) \
	--volume jellyfin-cache:/cache:Z \
	--volume jellyfin-config:/config:Z \
	--mount type=bind,source=$HOME/media,destination=/media,ro=true,relabel=private \
	--restart always \
ghcr.io/jellyfin/jellyfin;

echo "Creating a SystemD service file. These are commands (applications) that you can set to start as soon as you turn on the Pi.";
echo "This file is located at `/etc/systemd/system/jellyfin.service`.";
echo "For more information, see raspi.vintagecoding.net#systemd";

echo "[Unit]
Description=Jellyfin
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=$(whoami)
ExecStart=/usr/bin/podman start myjellyfin

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/jellyfin.service;

sudo systemctl daemon-reload && sudo systemctl enable jellyfin.service && sudo systemctl start jellyfin.service;

echo "For now, please visit jellyfin.org/docs for information about setting up Jellyfin. We'll have a more comprehensive guide soon.";
