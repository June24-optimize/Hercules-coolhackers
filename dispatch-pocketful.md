# Dispatch task: pocketful (paste this into the room, addressed to @coordinator)

This file is the track-specific input: the ONLY human message in the judged run.
Before the judged run:
- replace every `/Users/wanyubian/hackathon` with the workspace path on the machine that runs the seats;
- replace RESULT with the fresh result repository path.

Lean factory v2 (PLAN.md §10): the ship-and-watch loop is not part of the run, so there is
no release tooling to fill in.

One dispatch per stage (recommended when seats share a usage-limited subscription). The
guide allows dispatching each stage separately, with nothing sent between dispatches. For
stage N, change the first line to "Build stage N of the pocketful track only, following
your mandate", list only stage N's specification, add "Stages 1 to N-1 are already verified
in the result repository; carry stage N-1 forward.", and end with "When stage N is reported,
post the final report and stop; the next stage arrives as a separate dispatch." Check the
subscription's usage before each dispatch and wait for a reset if it is nearly used up.
`tools/make_stage_dispatches.py` writes all four from this file.

Then paste the block below as one message and send nothing after it.

---

@coordinator Build all four stages of the pocketful track, one after the other, following
your mandate. Do not ask me anything; I will not reply.

Workspace root: /Users/wanyubian/hackathon
Specification package (read only): /Users/wanyubian/hackathon/dark-factory-wearedevs
Track: pocketful
Result repository (absolute path, initialised, branch main): RESULT
Release tooling: none (no staging, promotion or watch loop in this run)

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
evidence of a finished stage. Code written to the shipped tests disqualifies the entry.
Never open the test files under the specification package's pocketful/test/ folder or the
harness source code; the seats' permissions block it. Run the checks, read the failing log,
then the spec.

## Delivery constraints

- One container; starts with `-e PORT=<port>`; healthy within 60 s.
- Network during `docker build` only, none at run time. Bundle every runtime asset (fonts,
  scripts, stylesheets). No CDN links.
- 2 vCPU, 2 GiB, up to 50 requests in flight, 5 s per request (10 s for reset). No 5xx ever.

## Technical direction (decided up front)

- Python 3.12 standard library unless the coordinator records a better reason in a decision
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
- Export carries a version; every stage imports every earlier stage's export. The export
  includes every stored idempotency record (key, caller, method, path, body, original
  response) and every session token, so a retry after an upgrade replays the original
  response and never moves money a second time.
- Stage 2 UI: server-rendered pages are fine, but pay, refresh, request and split actions must
  run from an in-page script so that: a lost response shows the uncertain state and keeps the
  unchanged form retryable with the same key and body; the key changes only when a field
  changes; the latest refresh wins over delayed earlier responses (sequence numbers); no page
  reload is needed. It must look like a real, trustworthy money app at 375 px and on desktop.

## Money invariants (the hard part of this track)

Money must never be created, destroyed or spent twice, under concurrent transfers, retries
and rounding. Every stage's requirements list states these invariants, and both the
tester's acceptance suite and the reviewer's stage verification must prove them, by
driving the running service over HTTP with up to 50 requests in flight:

- Conservation: after any mix of operations, the sum of all wallet balances (read the way
  the spec allows) equals the total seeded by the last reset. From stage 2 this is the sum
  of `total`; in stage 3, also in every historical view.
- No negative money, ever, including transiently: no balance below zero; from stage 2,
  `available` never below zero and held funds never spent by other operations.
- Exactly once: concurrent identical idempotent requests give one 201 and identical 200
  replays, and move money once. A replay after the resource changed, or after an
  export/import upgrade, returns the original body and moves nothing. A request is paid at
  most once; each capture, correction and refund moves money once.
- All or nothing: a rejected settlement, batch or multi-part operation leaves every balance,
  record and idempotency key unchanged.
- Rounding: split shares are whole minor units, sum exactly to the amount and follow the
  stage-1 table exactly (e.g. 1000 over 3 is 334, 333, 333).
- No 5xx under concurrent load.

The tester runs randomised, concurrent and retried operations of every kind the stage
allows and asserts every invariant after each run; it also covers the stage-1 rounding table
and, in stages 3 and 4, the stated error precedence. The reviewer repeats an independent
stress run of its own at stage verification. A stage whose invariants are not proven is not
verified, whatever the shipped checks say.

## When you are done

After stage 4 is reported (or when no further progress is possible), post a final report in
the room with each stage's verified revision, last isolated check result, invariant evidence,
open gaps and the time each stage took.