OPEN_WEBUI_PORT=5092
OLLAMA_PORT=11434

echo "Running `curl -fsSL https://ollama.com/install.sh | sh`";
echo "This will take about 5-10 minutes...";
curl -fsSL https://ollama.com/install.sh | sh;
echo "Ollama has been installed!"

read -p "Are you using a Raspberry Pi 5 or newer? (y/N)" PI_VERSION
PI_VERSION=$(echo "$PI_VERSION" | tr '[:upper:]' '[:lower:]')
if [[ -z "$PI_VERSION" || "$PI_VERSION" == "n" ]]; then
	echo "You can still use AI, but it's only available directly on your Raspberry Pi for now.";
	echo "For more information, see raspi.vintagecoding.net#ollama";
	exit;
fi

echo "Running `python -m venv open-webui-env`. This creates a Python virtual environment, where";
echo "we can install applications in an isolated manner from the rest of our Operating System (OS).";
python -m venv open-webui-env;
source open-webui-env/bin/activate

echo "Running `pip install open-webui`. This is Python's package manager.";
pip install open-webui;

echo "Setting up Nginx. For more information, visit raspi.vintagecoding.net#nginx";
echo "server {
listen 80;
server_name localhost;

location / {
	proxy_pass http://localhost:$OPEN_WEBUI_PORT/;
	proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
	proxy_set_header Connection 'upgrade';
	proxy_set_header Host $host;
	proxy_cache_bypass $http_upgrade;
}

location /api/ {
	proxy_pass http://localhost:$OPEN_WEBUI_PORT/api/;
	proxy_http_version 1.1;
	proxy_set_header Upgrade $http_upgrade;
	proxy_set_header Connection 'upgrade';
	proxy_set_header Host $host;
	proxy_cache_bypass $http_upgrade;
}
}" | sudo tee /etc/nginx/sites-available/open-webui;

sudo ln -s /etc/nginx/sites-available/open-webui /etc/nginx/sites-enabled
sudo systemctl enable nginx;

echo "Creating a SystemD service file. These are commands (applications) that you can set to start as soon as you turn on the Pi.";
echo "This file is located at `/etc/systemd/system/open-webui.service`.";
echo "For more information, see raspi.vintagecoding.net#systemd";

echo "[Unit]
Description=Open WebUI
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=$(whoami)
Environment=WEBUI_AUTH=True
Environment=WEBUI_BASE_URL=https://TMP_URL
Environment=OLLAMA_BASE_URL=http://localhost:11434
WorkingDirectory=$HOME
ExecStartPre=/bin/bash -c "source /home/$(whoami)/open-webui-env/bin/activate"
ExecStart=/home/$(whoami)/open-webui/open-webui-env/bin/open-webui serve --port $OLLAMA_PORT

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/open-webui.service;

read -p "Do you want to require login to your AI? (n/Y)" REQUIRE_LOGIN
REQUIRE_LOGIN=$(echo "$REQUIRE_LOGIN" | tr '[:upper:]' '[:lower:]')
if [[ -z "$REQUIRE_LOGIN" || "$REQUIRE_LOGIN" == "n" ]]; then
	sudo sed -i -e 's/WEBUI_AUTH=True/WEBUI_AUTH=False/' /etc/systemd/system/open-webui.service;
fi

sudo systemctl daemon-reload && sudo systemctl enable open-webui.service && sudo systemctl start open-webui.service;
