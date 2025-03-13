<h1>ras-pi</h1>
A comprehensive, end-to-end guide to the fundamentals of coding, network
protocols, Linux, and the Raspberry Pi.

<h2>Getting Started</h2>
Run the following commands on a fresh installation on a Raspberry Pi:

```
sudo apt install git;
git clone https://github.com/SLCPL-CreativeLab/ras-pi;
cd ras-pi/scripts;
sudo chmod a+x install.sh;
sudo ./install.sh;

# If you want to expose services to the internet, run this command as well.
sudo ./cloudflared.sh;
```

<h3>Expose Services to the Internet</h3>
To enable cloudflared to expose services to the internet, you must:<br>
<ul>
    <li>Make a Cloudflare account & purchase a domain</li>
    <li>Run the command `cloudflared tunnel login`</li>
    <li>Run the command ./cloudflared.sh in ~/ras-pi/scripts</li>
</ul>

To temporarily expose a single service to the internet, use this
command: `cloudflared tunnel --url=http://localhost:PORT`, where
PORT is the service you'd like to expose. The ports used with the
standard services are:<br>
<ul>
  <li>5090 (the manual mirror of raspi.vintagecoding.net)</li>
  <li>5091 (the AI web application)</li>
  <li>5092 (the personal Netflix replacement)</li>
</ul>

See `cloudflared.md` for more information.
