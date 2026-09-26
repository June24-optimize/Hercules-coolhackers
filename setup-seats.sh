#!/usr/bin/env bash
# Create the four factory seats in Band as persistent agents, each live-linked to its
# mandate file (edit the .md, and the agent's instructions follow).
#
# Usage:
#   DRY_RUN=1 ./setup-seats.sh      # probe the runtime configuration, create nothing
#   ./setup-seats.sh                # create lead, coder-a, coder-b, reviewer
#
# Override any default with an environment variable, e.g.
#   MODEL_CODER=claude-sonnet-5 WORKDIR=$HOME/hackathon/band-work ./setup-seats.sh
set -euo pipefail

BAND=${BAND:-band}
FACTORY_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR=${WORKDIR:-$HOME/hackathon/band-work}          # parent of every result repo
MODEL_LEAD=${MODEL_LEAD:-claude-opus-5-5}
MODEL_CODER=${MODEL_CODER:-claude-sonnet-5}
MODEL_REVIEWER=${MODEL_REVIEWER:-claude-opus-5-5}
# Unattended runs stall on permission prompts. This lets the seat run commands without
# asking, so only use it on a machine or sandbox you are willing to let it change.
PERMISSION_MODE=${PERMISSION_MODE:-bypassPermissions}
DRY=${DRY_RUN:+--dry-run}

mkdir -p "$WORKDIR"

create() {
  local name=$1 model=$2 description=$3
  local mandate="$FACTORY_DIR/mandates/$name.md"
  if ! grep -q "^Model: $model\$" "$mandate"; then
    echo "WARNING: $mandate does not say 'Model: $model' — update it so the mandate matches the seat." >&2
  fi
  echo "== $name ($model)"
  "$BAND" agent create \
    --name "$name" \
    --description "$description" \
    --cwd "$WORKDIR" \
    --transport claude-code-cli \
    --runtime-auth subscription \
    --runtime-model "$model" \
    --claude-permission-mode "$PERMISSION_MODE" \
    --instructions-file "$mandate" \
    $DRY
}

create lead     "$MODEL_LEAD"     "Specifies, plans and splits the work; integrates; reports. Writes no product code."
create coder-a  "$MODEL_CODER"    "Coding agent: implements assigned tasks with tests and hands them to review."
create coder-b  "$MODEL_CODER"    "Coding agent: implements assigned tasks with tests and hands them to review."
create reviewer "$MODEL_REVIEWER" "Independent reviewer: verifies against the requirements from a clean copy; can block."

echo "Done. Next: in Band Desktop, create a new room, add these four agents, and dispatch the task to @lead."