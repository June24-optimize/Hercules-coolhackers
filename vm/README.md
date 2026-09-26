# Hosting the seats on an Ubuntu cloud VM

The seats need a machine running Anthropic's standard Claude Code (`@anthropic-ai/claude-code`),
not the Apple build, and a Docker host for the harness and the ship loop.

## 1. Create the VM

| Setting | Value |
|---|---|
| OS | Ubuntu 24.04 LTS, **x86_64** (Band's Linux package is amd64) |
| Size | **8 vCPU, 32 GB RAM** (9 Claude Code seats + harness browser + service containers at 2 vCPU / 2 GiB each). 4 vCPU / 16 GB works for the toy. |
| Disk | 100 GB SSD (Docker images, Playwright, check outputs) |
| Network | Inbound: SSH (22) only. Outbound: open (model API, Band, package installs). |

Any provider works (AWS, GCP, Azure, Hetzner, DigitalOcean). Stop the VM when you're not
running the factory; you pay per hour.

## 2. Run the setup script

```sh
ssh <user>@<vm-ip>
curl -fsSL https://raw.githubusercontent.com/June24-optimize/Hercules-coolhackers/main/vm/setup-ubuntu.sh -o setup-ubuntu.sh
bash setup-ubuntu.sh
```

It installs Docker, Python 3.12 and the harness, Claude Code, the Band CLI and daemon (as a
user service that keeps running after you log out), clones our repo and the kickoff package,
prepares `~/hackathon/band-work`, and writes the dispatch files with the VM's paths into
`~/hackathon/band-work/`. It ends with the six steps that need your accounts.

## 3. Watching the room

You don't need a desktop on the VM. The seats run headless under the Band daemon; watch the
room from Band Desktop on your laptop or from the Band console (app.band.ai), signed in to
the **same Band account** the VM uses. If you want Band Desktop on the VM itself, rerun with
`INSTALL_DESKTOP=1` and connect over RDP through an SSH tunnel.

## 4. Long runs

Start long harness runs inside `tmux` so they survive a dropped SSH connection:

```sh
tmux new -s factory      # detach: Ctrl-b d · reattach: tmux attach -t factory
```

## Not verified yet

The script was written without a VM to test on. Expect to adjust:
- where the `.deb` puts `band` and `jamd` (the script finds them with `dpkg -L`);
- whether `band init` can sign in without a browser on the VM (fallback: `--user-api-key`);
- the Claude Code login flow over SSH (copy the URL to your laptop's browser).