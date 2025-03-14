# Raspberry Pi, Linux, and Coding Introduction
A guide to the fundamentals of the Raspberry Pi through the exploration of coding, networking, and Linux. See the full guide at [vintagecoding.net](https://raspi.vintagecoding.net), or follow **Getting Started** to host a mirror of the manual directly on your Raspberry Pi.

The possibilities are endless, and support for more projects is coming soon!

## Getting Started
Run the commands below in the terminal application on a fresh installation on a Raspberry Pi. To paste into a terminal, use Control+Shift+v. If you need help with installing the Operating System (OS) on your Pi, please see the [manual](https://raspi.vintagecoding.net#install-os).

```bash
sudo apt install git;
git clone https://github.com/SLCPL-CreativeLab/ras-pi;
cd ras-pi/scripts;
./setup.sh;

# Optionally:
./setup-ai.sh # Installs Ollama (all supported Pi's) and Open WebUI (only on Pi 5 and higher).
./setup-manual.sh # Installs the manual.
./setup-jellyfin.sh # Installs Jellyfin.
```

## Expose Services to the Internet
To use `cloudflared` to expose services to the internet, you must:

- Make a Cloudflare account & purchase a domain
- Run the command `cloudflared tunnel login`
- Run the command `./setup-cloudflared.sh` in ~/ras-pi/scripts

or:

- `cloudflared tunnel --url=http://localhost:PORT`

to alternatively temporarily expose a single service to the internet. PORT is the service you'd like to expose. The ports used with the standard services are below.

|        PORT        |      SERVICE                                 |
|--------------------|----------------------------------------------|
|        5090        | Mirror of raspi.vintagecoding.net            |
|        5091        | Jellyfin                                     |
|        5092        | Open WebUI                                   |

For more information about `cloudflared`, particularly regarding the security of connecting a service to the internet, please read their [docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/).

## Contributions & Support
Feel free to contribute to the project! Please see **CONTRIBUTIONS.md** to start.

If you need any help with getting started, please email [me](mailto:jashton@slcpl.org).

## Projects/Software Used

- [ollama](https://github.com/ollama/ollama)
- [open-webui](https://github.com/open-webui/open-webui)
- [jellyfin](https://github.com/jellyfin/jellyfin)
- [cloudflared](https://github.com/cloudflare/cloudflared)
- [podman](https://github.com/containers/podman)
