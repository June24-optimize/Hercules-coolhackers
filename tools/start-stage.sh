#!/bin/bash
# Start one stage of a judged run: checks everything, creates missing seats (stage 1 only),
# starts the timekeeper ticker and copies that stage's dispatch to the clipboard.
#   tools/start-stage.sh 1 [room-id]   stage 1: creates the seats if missing
#   tools/start-stage.sh N <room-id>   later stages: seats must already exist
#   tools/start-stage.sh all [room-id] one dispatch for all four stages; the coordinator opens a
#                                      fresh room per stage and the timekeeper follows it
# Paths (override with env vars; defaults assume the layout in docs/setup-notes.md):
#   WORKDIR   band-work folder: seats' cwd, result/ repo and the generated dispatches
#   KICKOFF   the hackathon kickoff package (specs + harness)
#   STAGE_ROOMS  optional, "all" mode: the ids of the pre-made rooms for stages 2-4, space-separated;
#             each must already contain all five seats
#   RESULT    the result repository the seats commit to (default: $WORKDIR/result)
#   BAND_OWNER your Band handle (the part before /coordinator); auto-detected by tools/timekeeper.sh
# Generate the per-stage dispatches first with tools/make_stage_dispatches.py.
# macOS only as written (launchctl, pbcopy).
set -euo pipefail
N=${1:?usage: tools/start-stage.sh <stage 1-4 | all> [room-id]}
ROOM=${2:-}
R="$(cd "$(dirname "$0")/.." && pwd)"                 # this team repo
W=${WORKDIR:-$HOME/hackathon/band-work}
K=${KICKOFF:-$HOME/hackathon/dark-factory-wearedevs}
RES=${RESULT:-$W/result}
CLAUDE=${CLAUDE:-$(command -v claude || echo claude)}
[ -d "$W" ] || { echo "WORKDIR $W does not exist (set WORKDIR=...)"; exit 1; }
[ -d "$K" ] || { echo "KICKOFF $K does not exist (set KICKOFF=...)"; exit 1; }
[ -d "$RES/.git" ] || { echo "RESULT $RES is not a git repository (set RESULT=...)"; exit 1; }
if [ "$N" = all ]; then DISPATCH="$W/dispatch-pocketful-all.local.md"; else DISPATCH="$W/dispatch-pocketful-stage-$N.local.md"; fi
ok()   { echo "  ok   $*"; }
fail() { echo "  FAIL $*"; exit 1; }

echo "== Checks for stage $N"
[ -f "$DISPATCH" ] || fail "missing $DISPATCH"; ok "dispatch file"
[ -n "$(launchctl getenv FEATHERLESS_API_KEY)" ] || fail 'Featherless key not in launchd: run  launchctl setenv FEATHERLESS_API_KEY "$FEATHERLESS_API_KEY"'
ok "Featherless key in launchd"
"$CLAUDE" auth status 2>/dev/null | grep -q '"loggedIn": true' || fail "Claude not logged in: run  claude auth login"
ok "Claude login present"
docker info >/dev/null 2>&1 || fail "Docker is not running"; ok "Docker running"
( cd "$R" && bash tools/scan_mandates.sh "$K" >/dev/null ) || fail "mandate scan found problems"; ok "mandates scan clean"
[ -z "$(git -C "$R" status --porcelain -- mandates tools claude-settings.json opencode-seats.json setup-seats.sh)" ] \
  || fail "team repo has uncommitted mandate/tool changes: commit them first"; ok "team repo committed"
[ "$(git -C "$RES" config user.name)" = "unattributed-seat" ] || fail "result repo lacks the neutral git identity"
ok "result repo identity"
if [ "$N" = 1 ] || [ "$N" = all ]; then
  [ -z "$(git -C "$RES" rev-list --all 2>/dev/null)" ] || fail "result repo already has commits: stage 1 needs a fresh repo"
  ok "result repo is fresh"
fi

echo "== Seats"
missing=0
for s in coordinator tester developer reviewer; do band list | grep -q "/$s \[" || missing=1; done
if [ "$missing" = 1 ]; then
  { [ "$N" = 1 ] || [ "$N" = all ]; } || fail "seats are missing mid-run: recreating them now would lose the room's context"
  echo "  creating the four seats (Claude seats in bypassPermissions; the deny list still applies)"
  ( cd "$R" && PERMISSION_MODE=bypassPermissions WORKDIR="$W" ./setup-seats.sh ) | grep -E '^==|created|error'
fi
[ -f "$R/mandates/timekeeper.md" ] || fail "mandates/timekeeper.md missing: regenerate the mandates first"
if ! band list | grep -q "/timekeeper \["; then
  echo "  creating the timekeeper seat (a program seat; never @mentioned, so it runs no model)"
  band agent create --session timekeeper --name timekeeper \
    --description "Program seat: sends the coordinator a clock tick every 15 minutes during a stage." \
    --cwd "$W" --transport opencode --spawn-command "$R/tools/opencode-featherless" --spawn-arg acp \
    --runtime-model "$(sed -n 's/^Model: //p' "$R/mandates/developer.md" | head -1)" \
    --instructions-file "$R/mandates/timekeeper.md" | grep -E 'created|error' || true
fi
for s in coordinator tester developer reviewer timekeeper; do
  band list | grep -q "/$s \[.*Connected" && continue
  # A seat whose worker stopped (band list: "Stopped running=false") cannot be restarted with
  # `band restart`; reattaching a worker to the existing peer brings it back with its context.
  band list | grep -q "/$s \[.*Stopped" \
    && fail "$s is Stopped: run  band attach --as <owner>/$s --host generic  and rerun this script"
  fail "$s not connected"
done
ok "all five seats connected (four model seats + timekeeper)"
if [ "$N" = all ] && [ -n "${STAGE_ROOMS:-}" ]; then
  for r in $ROOM $STAGE_ROOMS; do
    members=$(band room participants "$r" 2>/dev/null) || fail "room $r not found"
    for s in coordinator tester developer reviewer timekeeper; do
      echo "$members" | grep -q "/$s " || fail "room $r is missing seat $s: add it in Band Desktop"
    done
  done
  ok "stage rooms contain all five seats"
fi

# Timekeeper: one background ticker per run
pkill -f "tools/timekeeper.sh" 2>/dev/null || true
if [ -n "$ROOM" ]; then
  { [ "$N" = 1 ] || [ "$N" = all ]; } && rm -f "$W/current-room"   # a fresh run starts in the room given here
  rm -f "$W/handover.md"; WORKDIR="$W" nohup "$R/tools/timekeeper.sh" "$ROOM" > "$W/timekeeper.log" 2>&1 &
  ok "timekeeper ticking @coordinator every 15 min in room $ROOM (pid $!, log $W/timekeeper.log)"
else
  hint=$(band activity list --limit 5 2>/dev/null | head -1 | awk '{print $5}')
  echo "  NOTE no room id given, so the timekeeper is not running yet. After you create the room and"
  echo "       add all five seats, start it with:  $R/tools/timekeeper.sh <room-id> &"
  [ -n "$hint" ] && echo "       (most recently active room: $hint)"
fi

pbcopy < "$DISPATCH"
echo
echo "== Stage $N dispatch is on your clipboard ($(wc -l < "$DISPATCH" | tr -d ' ') lines)."
echo "   Start: $(date '+%Y-%m-%d %H:%M')   Note your Featherless balance now."
echo "   1. Check claude.ai -> Settings -> Usage: start only with plenty of headroom."
echo "   2. Use a NEW room for every stage (one room per stage stays under Band's 10,000-message"
echo "      limit; see PLAN.md §13) with all five seats: coordinator, tester, developer, reviewer, timekeeper."
echo "   3. Paste (Cmd+V), check it starts with @coordinator, send. Post nothing else."
echo "   4. At the stage report: stop the ticker, then download the room (scroll to its first message,"
echo "      then Download full session) and keep it as room-stage-$N.json."
echo "   No Claude use anywhere (chat, Claude Code, IntelliJ) until the stage report."
echo "   When the stage report is posted, stop the timekeeper:  pkill -f tools/timekeeper.sh"
