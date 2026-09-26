#!/usr/bin/env bash
# Create the factory's nine model seats in Band as persistent agents, each live-linked to its
# mandate file (edit the .md, rerun tools/build_mandates.py, and the agent follows).
# The tenth seat, log-watcher, is a Band SDK program and is started separately.
#
# Usage:
#   DRY_RUN=1 ./setup-seats.sh      # probe the runtime configuration, create nothing
#   ./setup-seats.sh                # create all nine seats
#
# Free tier: 10 agents. Delete Band's preset agents first.
set -euo pipefail

BAND=${BAND:-band}
FACTORY_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR=${WORKDIR:-$HOME/hackathon/band-work}          # parent of every result repo
# Pre-allowed commands (claude-settings.json) instead of skipping every permission check.
# If a seat still stalls on a prompt in the toy run, add that command to the allow list;
# PERMISSION_MODE=bypassPermissions is the blunt fallback for a machine you can throw away.
PERMISSION_MODE=${PERMISSION_MODE:-acceptEdits}
DRY=${DRY_RUN:+--dry-run}

mkdir -p "$WORKDIR/.claude"
cp "$FACTORY_DIR/claude-settings.json" "$WORKDIR/.claude/settings.json"

create() {
  local name=$1 description=$2
  local mandate="$FACTORY_DIR/mandates/$name.md"
  local model
  model=$(sed -n 's/^Model: //p' "$mandate" | head -1)   # the mandate is the source of truth
  # band rejects --instructions-file together with --dry-run, so a dry run probes the
  # runtime only; the real run links the mandate.
  local instructions=(--instructions-file "$mandate")
  [ -n "$DRY" ] && instructions=()
  echo "== $name ($model)"
  "$BAND" agent create \
    --session "$name" \
    --name "$name" \
    --description "$description" \
    --cwd "$WORKDIR" \
    --transport claude-code-cli \
    --runtime-auth subscription \
    --runtime-model "$model" \
    --claude-permission-mode "$PERMISSION_MODE" \
    --claude-context-mode local_config \
    ${instructions[@]+"${instructions[@]}"} \
    $DRY
}

create coordinator     "Plans each stage, routes handoffs, keeps the task list, writes the reports."
create architect       "Requirements list, design, decision records and invariants."
create tester          "Completeness review and black-box acceptance tests from the requirements."
create developer-a     "Coding agent: implements assigned tasks with unit tests."
create developer-b     "Coding agent: implements assigned tasks with unit tests."
create reviewer        "Independent review from a clean copy; merges; verifies stages; can block."
create qa-explorer     "Explores the staging deployment like a user and tries to break it."
create release-manager "Builds release images; runs staging, promotion and rollback."
create sre-monitor     "Triages production alerts: rollback or incident."

echo "Done. Next: start log-watcher (Band SDK program), create a room, add all ten seats,"
echo "and dispatch the task to @coordinator."