#!/bin/bash
# The timekeeper seat: sends @coordinator a clock tick every INTERVAL seconds, so a stalled
# stage is noticed even when no seat is sending messages (seats act only when woken).
#   tools/timekeeper.sh <room-id> [interval-seconds, default 900]
# It also follows the coordinator from room to room. When the coordinator opens a fresh room
# for the next stage it writes the room id to ROOM_FILE (default $WORKDIR/current-room) after
# writing HANDOVER_FILE (default $WORKDIR/handover.md). The next poll sends @coordinator a
# message in the new room that points to the handover: a seat cannot mention itself, so this
# message is what wakes the coordinator there. Ticks then continue in the new room.
# Stop it with Ctrl-C (or kill) when the final report is posted.
set -euo pipefail
ROOM=${1:?usage: tools/timekeeper.sh <room-id> [interval-seconds]}
INTERVAL=${2:-900}
POLL=${POLL:-10}
OWNER=${BAND_OWNER:-$(band whoami | sed -n 's/.*@\([^ ]*\) <.*/\1/p')}
BAND=${BAND:-band}
ROOM_FILE=${ROOM_FILE:-${WORKDIR:-.}/current-room}
HANDOVER_FILE=${HANDOVER_FILE:-${WORKDIR:-.}/handover.md}
echo "timekeeper: ticking @$OWNER/coordinator in room $ROOM every ${INTERVAL}s (Ctrl-C to stop)"

send() {  # send <message>; returns band's status
  "$BAND" send --as "$OWNER/timekeeper" "$ROOM" "$1" >/dev/null
}

waited=0
wake_pending=0
while :; do
  sleep "$POLL"
  waited=$((waited + POLL))
  now=$(date '+%Y-%m-%d %H:%M %Z')
  if [ -s "$ROOM_FILE" ]; then
    next=$(head -1 "$ROOM_FILE" | tr -d '[:space:]')
    if [[ "$next" =~ ^[0-9a-f-]{36}$ ]] && [ "$next" != "$ROOM" ]; then
      echo "$now following the coordinator to room $next"
      ROOM=$next; wake_pending=1
    fi
  fi
  if [ "$wake_pending" = 1 ]; then
    if send "@$OWNER/coordinator stage handover: this is the new room for the next stage. Your task and the state of the work are in $HANDOVER_FILE. Read it in full, then continue under your mandate."; then
      echo "$now handover wake sent"; wake_pending=0; waited=0
    else
      echo "$now handover wake FAILED (will retry in ${POLL}s)"
    fi
    continue
  fi
  if [ "$waited" -ge "$INTERVAL" ]; then
    waited=0
    send "@$OWNER/coordinator tick $now: check the time against every outstanding handoff; whose move is it now, and was that seat sent the request?" \
      && echo "$now tick sent" || echo "$now tick FAILED (will retry next interval)"
  fi
done
