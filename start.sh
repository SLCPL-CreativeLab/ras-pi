apt-get update
apt-get install go
apt-get install cloudflared
./services/install.sh
serve_page --path ./man/pages --destination / --port 8888
echo "Visit http://localhost:8888 to get started!"
echo "To temporarily expose a webpage to the internet, use:\n    `cloudflared tunnel --url http://localhost:8888"
