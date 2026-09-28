#!/usr/bin/env bash
# Create the factory's four seats in Band as persistent agents, each live-linked to its
# mandate file (edit tools/build_mandates.py, rerun it, and the agents follow).
#
# Each seat's runtime comes from its mandate's Harness/Model lines:
#   Harness: Claude Code -> claude-code-cli transport, your Claude subscription
#   Harness: OpenCode    -> opencode transport, Featherless via tools/opencode-featherless
#
# Usage:
#   DRY_RUN=1 ./setup-seats.sh      # probe each runtime configuration, create nothing
#   ./setup-seats.sh                # create all four seats
#
# Before the OpenCode seats can start (macOS), once per login or reboot:
#   launchctl setenv FEATHERLESS_API_KEY "$FEATHERLESS_API_KEY"
#
# Seat names must be free: delete any existing Band agents with the same names first.
set -euo pipefail

BAND=${BAND:-band}
FACTORY_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR=${WORKDIR:-$HOME/hackathon/band-work}          # parent of every result repo
# Pre-allowed commands (claude-settings.json) instead of skipping every permission check.
PERMISSION_MODE=${PERMISSION_MODE:-acceptEdits}
LAUNCHER="$FACTORY_DIR/tools/opencode-featherless"
DRY=${DRY_RUN:+--dry-run}

# Permissions for both harnesses live in the seats' shared working directory.
mkdir -p "$WORKDIR/.claude"
cp "$FACTORY_DIR/claude-settings.json" "$WORKDIR/.claude/settings.json"
cp "$FACTORY_DIR/opencode-permissions.json" "$WORKDIR/opencode.json"
chmod 755 "$LAUNCHER"

create() {
  local name=$1 description=$2
  local mandate="$FACTORY_DIR/mandates/$name.md"
  local harness model
  harness=$(sed -n 's/^Harness: //p' "$mandate" | head -1)   # the mandate is the source of truth
  model=$(sed -n 's/^Model: //p' "$mandate" | head -1)
  # band rejects --instructions-file together with --dry-run, so a dry run probes the
  # runtime only; the real run links the mandate.
  local instructions=(--instructions-file "$mandate")
  [ -n "$DRY" ] && instructions=()
  local runtime
  case "$harness" in
    "Claude Code")
      runtime=(--transport claude-code-cli --runtime-auth subscription
               --claude-permission-mode "$PERMISSION_MODE" --claude-context-mode local_config) ;;
    "OpenCode")
      runtime=(--transport opencode --spawn-command "$LAUNCHER" --spawn-arg acp) ;;
    *) echo "$name: unsupported harness '$harness' in $mandate" >&2; exit 1 ;;
  esac
  echo "== $name ($harness, $model)"
  "$BAND" agent create \
    --session "$name" \
    --name "$name" \
    --description "$description" \
    --cwd "$WORKDIR" \
    "${runtime[@]}" \
    --runtime-model "$model" \
    ${instructions[@]+"${instructions[@]}"} \
    $DRY
}

create coordinator "Specifies and designs each stage, routes handoffs, keeps the task list, writes the reports."
create tester      "Completeness review and black-box acceptance tests, including user-interface checks."
create developer   "Coding agent: implements assigned tasks with unit tests."
create reviewer    "Independent review from a clean copy; merges; verifies stages; can block."

echo "Done. Next: create a room, add the four seats, and dispatch the task to @coordinator."
