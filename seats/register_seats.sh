#!/usr/bin/env bash
# Register one Band agent per seat and write their credentials to a private
# agent_config.yaml OUTSIDE this repository.
#
# Usage (the user key is read from the environment, never from argv):
#   read -s "BAND_USER_API_KEY?Band user API key: " && export BAND_USER_API_KEY   # zsh
#   seats/register_seats.sh                       # lite profile: coordinator developer-a reviewer
#   PROFILE=full seats/register_seats.sh          # all nine model seats
set -euo pipefail

: "${BAND_USER_API_KEY:?export BAND_USER_API_KEY (a band_u_ key) first}"
export BAND_BASE_URL=${BAND_BASE_URL:-https://app.band.ai}
PROFILE=${PROFILE:-lite}
OUT=${SEATS_CONFIG:-$HOME/hackathon/band-work/seats/agent_config.yaml}
REGISTER_URL="https://raw.githubusercontent.com/band-ai/add-band/main/scripts/register-agent.sh"

case "$PROFILE" in
  lite) SEATS=(coordinator developer-a reviewer) ;;
  full) SEATS=(coordinator architect tester developer-a developer-b reviewer qa-explorer release-manager sre-monitor) ;;
  *) echo "PROFILE must be lite or full" >&2; exit 1 ;;
esac

mkdir -p "$(dirname "$OUT")"
umask 077
touch "$OUT"
script=$(mktemp); trap 'rm -f "$script"' EXIT
curl -fsSL "$REGISTER_URL" -o "$script"

for seat in "${SEATS[@]}"; do
  key="${seat//-/_}"
  if grep -q "^$key:" "$OUT"; then echo "$seat: already in $OUT, skipped"; continue; fi
  export BAND_AGENT_NAME="$seat"
  export BAND_AGENT_DESCRIPTION="Factory seat: $seat"
  if ! out=$(bash "$script"); then
    echo "$seat: registration FAILED (see the error above). Seats registered so far are in $OUT." >&2
    exit 1
  fi
  eval "$out"
  printf '%s:\n  agent_id: "%s"\n  api_key: "%s"\n\n' "$key" "$BAND_AGENT_ID" "$BAND_AGENT_API_KEY" >> "$OUT"
  echo "$seat: registered ($BAND_AGENT_ID)"
  unset BAND_AGENT_ID BAND_AGENT_API_KEY
done
echo "Credentials: $OUT (private; never commit it)"