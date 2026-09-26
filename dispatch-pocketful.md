# Dispatch task: pocketful (paste this into the room, addressed to @coordinator)

This file is the track-specific input: the ONLY human message in the judged run.
Before the judged run:
- replace every `/Users/wanyubian/hackathon` with the workspace path on the machine that runs the seats;
- replace RESULT with the fresh result repository path;
- set RELEASE_TOOLING to the release script's path, or to `none` to skip the ship loop.

Then paste the block below as one message and send nothing after it.

---

@coordinator Build all four stages of the pocketful track, one after the other, following
your mandate. Do not ask me anything; I will not reply.

Workspace root: /Users/wanyubian/hackathon
Specification package (read only): /Users/wanyubian/hackathon/dark-factory-wearedevs
Track: pocketful
Result repository (absolute path, initialised, branch main): RESULT
Release tooling: RELEASE_TOOLING
Approval gate: OFF (dark-factory run; nothing may wait for a human)

Stage specifications (read each in full; paste it in full into every handoff):
- Stage 1: /Users/wanyubian/hackathon/dark-factory-wearedevs/pocketful/spec/stage-1.md
- Stage 2: /Users/wanyubian/hackathon/dark-factory-wearedevs/pocketful/spec/stage-2.md
- Stage 3: /Users/wanyubian/hackathon/dark-factory-wearedevs/pocketful/spec/stage-3.md
- Stage 4: /Users/wanyubian/hackathon/dark-factory-wearedevs/pocketful/spec/stage-4.md

Finish and verify each stage before starting the next. Stage N lives in RESULT/stage-N/ with a
Dockerfile, a RUN.md and the source. stage-2/ starts as a copy of the verified stage-1/, and
so on; delete any .git inside a copy. Each folder must satisfy its own stage and all earlier
ones, and must NOT implement later stages' features. Working documents go in
RESULT/specs/stage-N/. Do not create README.md, FACTORY.md, mandates/ or room.json; the humans
write those. Do not push to any remote.

## Checks

    cd /Users/wanyubian/hackathon/dark-factory-wearedevs && . .venv/bin/activate

While iterating (host mode; does NOT block network):

    python -m harness run --track pocketful --repo RESULT --stage N --out /Users/wanyubian/hackathon/band-work/checks/sN-<counter>

Stage verification (isolated: no outbound network, 2 vCPU, 2 GiB, the way judges run it):

    python -m harness run --track pocketful --repo RESULT --stage N --mode isolated --out /Users/wanyubian/hackathon/band-work/checks/sN-final-<counter>

A good result ends with `claimed stage: N`; for stages 1-3 the extra line for the next stage
must read `fail` (the overshoot check). Every --out directory must be new.

IMPORTANT: the shipped checks are only part of the judged tests (about 79%, 35%, 9% and 16%
for stages 1-4). The judged tests are all derived from the spec text; a green run is not
evidence of a finished stage. Code written to the shipped tests disqualifies the entry. Do
not read the test source files to decide behaviour: read the failing log, then the spec.

## Delivery constraints

- One container; starts with `-e PORT=<port>`; healthy within 60 s.
- Network during `docker build` only, none at run time. Bundle every runtime asset (fonts,
  scripts, stylesheets). No CDN links.
- 2 vCPU, 2 GiB, up to 50 requests in flight, 5 s per request (10 s for reset). No 5xx ever.

## Technical direction (decided up front)

- Python 3.12 standard library unless the architect records a better reason in a decision
  record. Server request queue of at least 256.
- All state in memory. Every write runs as one uninterrupted critical section, from claiming
  the idempotency key to commit (one global lock, or a single-threaded event loop). Password
  hashing happens outside that critical section. Export is an atomic snapshot.
- Order for every idempotent write: parse the body, authenticate, resolve the idempotency key,
  then validate. A replay returns the stored response; a different body under a used key is
  refused; a failed request frees the key.
- Amounts are exact integers of minor units; follow the stage-1 rounding rule exactly.
- Keep payments as an append-only ledger whose entries carry both effective and recorded
  times, so one balance function can answer "as of" and "as known at" questions later. Do not
  expose later-stage features early.
- Export carries a version; every stage imports every earlier stage's export.
- Stage 2 UI: server-rendered pages are fine, but pay, refresh, request and split actions must
  run from an in-page script so that: a lost response shows the uncertain state and keeps the
  unchanged form retryable with the same key and body; the key changes only when a field
  changes; the latest refresh wins over delayed earlier responses (sequence numbers); no page
  reload is needed. It must look like a real, trustworthy money app at 375 px and on desktop.

## Ship loop (only when Release tooling is not `none`)

After each stage passes verification: build once, stage, QA, promote blue/green, then watch
for 10 minutes. Probes and thresholds for the watcher and @sre-monitor:
- conservation: the sum of all wallet balances equals the total seeded by the last reset (any difference = breach);
- replay mismatch: an idempotent replay returns a different body (any = breach);
- any 5xx response (any = breach);
- refusal spike: insufficient-funds refusals exceed 3x the previous 5-minute window;
- latency: p99 above 4 s.
Summaries every 5 minutes. A QA finding or incident becomes a task in the CURRENT stage folder.

## When you are done

After stage 4 is reported (or when no further progress is possible): stop the watcher, then
post a final report in the room with each stage's verified revision, last isolated check
result, image digest if shipped, open gaps and the time each stage took.