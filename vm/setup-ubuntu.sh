#!/usr/bin/env bash
# Set up an Ubuntu 24.04 (x86_64) cloud VM to host the factory's seats.
#
# Installs Docker, Python 3.12 + the harness, Claude Code (Anthropic's standard build),
# the Band CLI + daemon (from the Band Desktop .deb), clones our repos, prepares
# ~/hackathon/band-work, and writes dispatch files with this machine's paths.
#
# Run as a normal user with sudo rights (not root):
#   curl -fsSL https://raw.githubusercontent.com/June24-optimize/Hercules-coolhackers/main/vm/setup-ubuntu.sh -o setup-ubuntu.sh
#   bash setup-ubuntu.sh
# Optional: INSTALL_DESKTOP=1 bash setup-ubuntu.sh   # also installs XFCE + xrdp for the Band Desktop GUI
#
# Safe to re-run: every step checks before it installs.
set -euo pipefail

WS="$HOME/hackathon"
FACTORY_REPO=${FACTORY_REPO:-https://github.com/June24-optimize/Hercules-coolhackers.git}
KICKOFF_REPO=${KICKOFF_REPO:-https://github.com/band-ai/dark-factory-wearedevs.git}
BAND_DEB_URL=${BAND_DEB_URL:-https://downloads.band.ai/desktop/latest/linux/jam-amd64.deb}

log()  { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mWARNING: %s\033[0m\n' "$*" >&2; }

[ "$(id -u)" -ne 0 ] || { echo "Run as a normal user with sudo, not as root." >&2; exit 1; }
[ "$(uname -m)" = "x86_64" ] || warn "Band's Linux package is amd64; this VM is $(uname -m)."
. /etc/os-release
[ "${VERSION_ID:-}" = "24.04" ] || warn "Tested for Ubuntu 24.04; this is ${PRETTY_NAME:-unknown}."

log "Base packages"
sudo apt-get update -y
sudo apt-get install -y git curl ca-certificates jq unzip build-essential tmux \
  python3.12 python3.12-venv python3-pip

log "Docker Engine"
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sudo sh
fi
sudo usermod -aG docker "$USER"
sudo systemctl enable --now docker

log "Claude Code (Anthropic's standard build)"
export PATH="$HOME/.local/bin:$PATH"
if ! command -v claude >/dev/null; then
  if ! curl -fsSL https://claude.ai/install.sh | bash; then
    warn "Native installer failed; falling back to npm."
    sudo apt-get install -y nodejs npm
    sudo npm install -g @anthropic-ai/claude-code
  fi
fi
claude --version || warn "claude is not on PATH yet; open a new shell."
if claude --version 2>/dev/null | grep -qi apple; then
  warn "This claude is an Apple build. The seats need @anthropic-ai/claude-code."
fi

log "Band CLI + daemon (from the Band Desktop package)"
if ! command -v band >/dev/null; then
  tmpdeb=$(mktemp --suffix=.deb)
  curl -fL "$BAND_DEB_URL" -o "$tmpdeb"
  sudo apt-get install -y "$tmpdeb"          # pulls in the GUI libraries the package needs
  pkg=$(dpkg-deb -f "$tmpdeb" Package)
  rm -f "$tmpdeb"
  mkdir -p "$HOME/.local/bin"
  # Link band AND jamd next to each other on PATH: band looks for jamd beside itself.
  for bin in band jamd; do
    src=$(dpkg -L "$pkg" | grep -E "/$bin\$" | head -1 || true)
    if [ -n "$src" ]; then ln -sf "$src" "$HOME/.local/bin/$bin"; else warn "no $bin in package $pkg"; fi
  done
fi
grep -q '.local/bin' "$HOME/.bashrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
band --version 2>/dev/null || band --help >/dev/null 2>&1 || warn "band CLI not working yet"

log "Band daemon as a user service (keeps running after you log out)"
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/jamd.service" <<EOF
[Unit]
Description=Band daemon (jamd)
After=network-online.target

[Service]
ExecStart=$HOME/.local/bin/band daemon run
Restart=on-failure
Environment=PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=default.target
EOF
sudo loginctl enable-linger "$USER"
systemctl --user daemon-reload || warn "systemd user bus not ready; run: systemctl --user daemon-reload (after re-login)"
# Enabled now, started after `band init` (it has no account until then).
systemctl --user enable jamd.service || warn "run later: systemctl --user enable jamd.service"

log "Repositories"
mkdir -p "$WS"
[ -d "$WS/factory/.git" ] || git clone "$FACTORY_REPO" "$WS/factory"
[ -d "$WS/dark-factory-wearedevs/.git" ] || git clone "$KICKOFF_REPO" "$WS/dark-factory-wearedevs"
git -C "$WS/factory" pull --ff-only || true
git -C "$WS/dark-factory-wearedevs" pull --ff-only || true

log "Harness (Python 3.12 venv + Playwright Chromium)"
cd "$WS/dark-factory-wearedevs"
[ -x .venv/bin/python ] || python3.12 -m venv .venv
.venv/bin/pip install -q -r harness/requirements.txt
.venv/bin/python -m playwright install --with-deps chromium

log "Workspace: ~/hackathon/band-work"
BW="$WS/band-work"
mkdir -p "$BW/checks" "$BW/toy-result/stage-1"
if [ ! -d "$BW/toy-result/.git" ]; then
  cp scaffold/* "$BW/toy-result/stage-1/"
  git -C "$BW/toy-result" init -q -b main
  git -C "$BW/toy-result" add -A
  git -C "$BW/toy-result" -c user.name=human -c user.email=human@factory.invalid commit -q -m "scaffold"
fi
# Dispatch files with this machine's paths (the repo copies use the author's paths).
for f in dispatch-pocketful.md dispatch-toy.md; do
  sed "s#/Users/wanyubian/hackathon#$WS#g" "$WS/factory/$f" > "$BW/$f"
done

if [ "${INSTALL_DESKTOP:-0}" = "1" ]; then
  log "Optional desktop (XFCE + xrdp) for the Band Desktop GUI"
  sudo apt-get install -y xfce4 xfce4-goodies xrdp
  echo xfce4-session > "$HOME/.xsession"
  sudo systemctl enable --now xrdp
  echo "Connect with an RDP client through an SSH tunnel:  ssh -L 3389:localhost:3389 <vm>"
fi

cat <<EOF

$(printf '\033[1;32m')Setup finished.$(printf '\033[0m') Finish these by hand (they need your accounts):

 1. Log out and back in (or run: newgrp docker) so Docker works without sudo.
    Check:  docker run --rm hello-world

 2. Sign in to Claude Code with the team's Claude subscription:
       claude            # then /login; copy the URL into your laptop's browser; paste the code back
    Check:  claude --version   (must NOT mention apple)

 3. Sign in to Band, then start the daemon:
       band init         # prints/opens a sign-in link; or: band init --user-api-key <key from app.band.ai>
       systemctl --user start jamd.service
       band preflight    # every row should be ok

 4. Create the seats (delete Band's preset agents first; free tier = 10 agents):
       cd ~/hackathon/factory
       DRY_RUN=1 ./setup-seats.sh     # the MCP relay checks should now pass
       ./setup-seats.sh

 5. Create a room in the Band console (app.band.ai) or Band Desktop, add the seats,
    and test one @handle exchange each way.

 6. Toy rehearsal: paste the block in ~/hackathon/band-work/dispatch-toy.md to @coordinator.
    Harness check:
       cd ~/hackathon/dark-factory-wearedevs && . .venv/bin/activate
       python -m harness run --track toy --repo ../band-work/toy-result --stage 1 --out ../band-work/checks/toy-s1

Keep SSH as the only open inbound port; staging/production ports stay on localhost.
EOF
