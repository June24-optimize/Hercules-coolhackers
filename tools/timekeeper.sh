#!/bin/bash
# The timekeeper seat: wakes @coordinator when a stage has gone quiet, so a stalled stage is
# noticed even when no seat is sending messages (seats act only when woken).
#   tools/timekeeper.sh <room-id> [interval-seconds, default 900]
#
# Every INTERVAL seconds it looks at the newest message in the room (any seat, any kind: a
# tool call counts). It ticks only if that message is older than QUIET seconds (default 600):
#   - the room is active        -> no tick (nothing is stuck, no turn is wasted)
#   - the room is quiet         -> one tick
#   - the newest message is our own unanswered tick (nothing moved since) -> back off: the
#     next tick waits until the room has been quiet for BACKOFF seconds (default 1800), so a
#     long outage (a usage-limit pause, a stopped seat) queues at most one tick per half hour
#   - the check itself fails    -> tick anyway (fail open)
#
# It also follows the coordinator from room to room. When the coordinator moves to the next
# stage's room it writes HANDOVER_FILE (default $WORKDIR/handover.md) and then the room id to
# ROOM_FILE (default $WORKDIR/current-room). The next poll sends @coordinator a message in
# the new room that points to the handover: a seat cannot mention itself, so this message is
# what wakes the coordinator there.
# Stop it with Ctrl-C (or kill) when the final report is posted.
set -euo pipefail
ROOM=${1:?usage: tools/timekeeper.sh <room-id> [interval-seconds]}
INTERVAL=${2:-900}
QUIET=${QUIET:-600}
BACKOFF=${BACKOFF:-1800}
POLL=${POLL:-10}
OWNER=${BAND_OWNER:-$(band whoami | sed -n 's/.*@\([^ ]*\) <.*/\1/p')}
BAND=${BAND:-band}
ROOM_FILE=${ROOM_FILE:-${WORKDIR:-.}/current-room}
HANDOVER_FILE=${HANDOVER_FILE:-${WORKDIR:-.}/handover.md}
echo "timekeeper: watching room $ROOM, waking @$OWNER/coordinator when it has been quiet for ${QUIET}s (checks every ${INTERVAL}s; Ctrl-C to stop)"

send() {  # send <message>; returns band's status
  "$BAND" send --as "$OWNER/timekeeper" "$ROOM" "$1" >/dev/null
}

# prints "<age-seconds> <own|other>" for the newest message in the room; fails if unreadable
newest() {
  "$BAND" room messages "$ROOM" --json 2>/dev/null | python3 -c '
import json, sys, datetime as dt
m = json.load(sys.stdin)["messages"]
if not m:
    print("999999 other"); sys.exit()
n = max(m, key=lambda x: x["inserted_at"])
t = dt.datetime.fromisoformat(n["inserted_at"].replace("Z", "+00:00"))
age = int((dt.datetime.now(dt.timezone.utc) - t).total_seconds())
own = n.get("sender_name") == "timekeeper"
print(age, "own" if own else "other")'
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
  [ "$waited" -ge "$INTERVAL" ] || continue
  waited=0
  if state=$(newest); then
    age=${state%% *}; who=${state##* }
    need=$QUIET; [ "$who" = own ] && need=$BACKOFF
    if [ "$age" -lt "$need" ]; then
      echo "$now no tick: newest message is ${age}s old (${who}), waiting for ${need}s of quiet"
      continue
    fi
  else
    echo "$now could not read the room; ticking anyway"
  fi
  send "@$OWNER/coordinator tick $now: the room has been quiet. Check the time against every outstanding handoff; whose move is it now, and was that seat sent the request?" \
    && echo "$now tick sent" || echo "$now tick FAILED (will retry next interval)"
done
