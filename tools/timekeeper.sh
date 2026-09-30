#!/bin/bash
# The timekeeper seat: sends @coordinator a clock tick every INTERVAL seconds, so a stalled
# stage is noticed even when no seat is sending messages (seats act only when woken).
#   tools/timekeeper.sh <room-id> [interval-seconds, default 900]
# Stop it with Ctrl-C (or kill) when the stage report is posted.
set -euo pipefail
ROOM=${1:?usage: tools/timekeeper.sh <room-id> [interval-seconds]}
INTERVAL=${2:-900}
OWNER=${BAND_OWNER:-$(band whoami | sed -n 's/.*@\([^ ]*\) <.*/\1/p')}
BAND=${BAND:-band}
echo "timekeeper: ticking @$OWNER/coordinator in room $ROOM every ${INTERVAL}s (Ctrl-C to stop)"
while :; do
  sleep "$INTERVAL"
  now=$(date '+%Y-%m-%d %H:%M %Z')
  "$BAND" send --as "$OWNER/timekeeper" "$ROOM" \
    "@$OWNER/coordinator tick $now: check the time against every outstanding handoff; whose move is it now, and was that seat sent the request?" \
    >/dev/null && echo "$now tick sent" || echo "$now tick FAILED (will retry next interval)"
done
