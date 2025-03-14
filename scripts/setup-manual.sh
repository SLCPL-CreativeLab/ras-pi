#!/bin/bash

MANUAL_PORT=5090;

echo "Creating a SystemD service file. These are commands (applications) that you can set to start as soon as you turn on the Pi.";
echo "This file is located at `/etc/systemd/system/manual.service`.";
echo "For more information, see raspi.vintagecoding.net#systemd";

echo "[Unit]
Description=Raspberry Pi Manual Mirror
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=$(whoami)
WorkingDirectory=$HOME/ras-pi/man/pages
ExecStartPre=/usr/bin/git pull
ExecStart=/usr/bin/python3 -m http.server $MANUAL_PORT

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/manual.service;

sudo systemctl daemon-reload && sudo systemctl enable manual.service && sudo systemctl start manual.service;

echo "For now, this uses the command `python -m http.server 5090` to serve the man/pages on port 5090.";
echo "For more information, see raspi.vintagecoding.net#web-servers";
