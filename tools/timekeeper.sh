#!/bin/bash
# The timekeeper seat: sends @coordinator a clock tick every INTERVAL seconds, so a stalled
# stage is noticed even when no seat is sending messages (seats act only when woken).
#   tools/timekeeper.sh <room-id> [interval-seconds, default 900]
# If ROOM_FILE (default: $WORKDIR/current-room) holds a room id, that room wins: the
# coordinator writes it when it opens a fresh room for the next stage, so the ticks follow it.
# Stop it with Ctrl-C (or kill) when the stage report is posted.
set -euo pipefail
ROOM=${1:?usage: tools/timekeeper.sh <room-id> [interval-seconds]}
INTERVAL=${2:-900}
OWNER=${BAND_OWNER:-$(band whoami | sed -n 's/.*@\([^ ]*\) <.*/\1/p')}
BAND=${BAND:-band}
ROOM_FILE=${ROOM_FILE:-${WORKDIR:-.}/current-room}
echo "timekeeper: ticking @$OWNER/coordinator in room $ROOM every ${INTERVAL}s (Ctrl-C to stop)"
while :; do
  sleep "$INTERVAL"
  now=$(date '+%Y-%m-%d %H:%M %Z')
  if [ -s "$ROOM_FILE" ]; then
    next=$(head -1 "$ROOM_FILE" | tr -d '[:space:]')
    if [[ "$next" =~ ^[0-9a-f-]{36}$ ]] && [ "$next" != "$ROOM" ]; then
      echo "$now following the coordinator to room $next"; ROOM=$next
    fi
  fi
  "$BAND" send --as "$OWNER/timekeeper" "$ROOM" \
    "@$OWNER/coordinator tick $now: check the time against every outstanding handoff; whose move is it now, and was that seat sent the request?" \
    >/dev/null && echo "$now tick sent" || echo "$now tick FAILED (will retry next interval)"
done
