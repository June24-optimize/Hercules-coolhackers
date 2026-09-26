# Dispatch task: tablekeeper (paste this into the room, addressed to @lead)

This file is the track-specific input. It is the ONLY human message in the judged run.
Before the judged run: replace RESULT with the fresh repository path, then paste the whole
block below as one message to @lead. Send nothing after it.

---

@lead You are the lead seat. Build all four stages of the tablekeeper track, one after the
other, following your mandate. Do not ask me anything; I will not reply.

Workspace root: /Users/wanyubian/hackathon
Specification package: /Users/wanyubian/hackathon/dark-factory-wearedevs
Track: tablekeeper
Result repository (absolute path, already initialised, branch main): RESULT

Stage specifications (read each in full and paste it in full into every handoff):
- Stage 1: /Users/wanyubian/hackathon/dark-factory-wearedevs/tablekeeper/spec/stage-1.md
- Stage 2: /Users/wanyubian/hackathon/dark-factory-wearedevs/tablekeeper/spec/stage-2.md
- Stage 3: /Users/wanyubian/hackathon/dark-factory-wearedevs/tablekeeper/spec/stage-3.md
- Stage 4: /Users/wanyubian/hackathon/dark-factory-wearedevs/tablekeeper/spec/stage-4.md

Finish and verify each stage before starting the next. Stage N lives in RESULT/stage-N/ and
must hold a Dockerfile, a RUN.md and the source. stage-2/ starts as a copy of the verified
stage-1/, and so on; delete any .git inside a copied folder. Each folder must satisfy its own
stage and all earlier ones, and must NOT implement later stages' features. Your requirement,
plan, task and verification documents go in RESULT/specs/stage-N/. Do not create README.md,
FACTORY.md, mandates/ or room.json; the humans write those.

## How to check (the reviewer runs these; coders may run the host-mode one)

Set up once per shell:

    cd /Users/wanyubian/hackathon/dark-factory-wearedevs && . .venv/bin/activate

While iterating (host mode, fast, does NOT block network):

    python -m harness run --track tablekeeper --repo RESULT --stage N --out /Users/wanyubian/hackathon/band-work/checks/sN-<counter>

Stage verification (isolated: no outbound network, 2 vCPU, 2 GiB — this is how judges run it):

    python -m harness run --track tablekeeper --repo RESULT --stage N --mode isolated --out /Users/wanyubian/hackathon/band-work/checks/sN-final-<counter>

A good stage-N result ends with `claimed stage: N`. For stages 1 and 3 the extra line for the
next stage must read `fail` (that is the overshoot check). Every --out directory must be new.

IMPORTANT: the shipped checks are only part of the judged tests (about 83%, 41%, 11% and 21%
for stages 1-4). The judged tests are all derived from the spec text. A green run is not
evidence of a finished stage. Code written to the shipped tests disqualifies the entry: build
to the spec, and never special-case a test input, fixture id or test name. Do not read the
test source files to decide behaviour; read the failing log, then the spec.

## Delivery constraints (from the spec, restated so nobody misses them)

- One container. It must start with `-e PORT=<port>` and answer the health check within 60 s.
- Network is available during `docker build`, and NONE at run time. Bundle every runtime
  asset in the image: fonts, scripts, stylesheets. No CDN links.
- 2 vCPU, 2 GiB memory, up to 50 requests in flight, 5 s per request (10 s for reset).
- No 5xx under concurrent load.

## Technical direction (decided up front so the band does not have to guess)

- Python 3.12 standard library HTTP server (the kickoff scaffold at
  /Users/wanyubian/hackathon/dark-factory-wearedevs/scaffold may be used as a starting
  point). Set the server's request queue size to at least 256.
- Keep all state in memory behind one process-wide lock, and hold that lock for every write
  and every read that must see a consistent state. This makes every request behave as if run
  one at a time, which the spec requires, and makes export an atomic snapshot.
- Time zones: install the `tzdata` Python package during the image build and use `zoneinfo`.
  Handle the skipped and repeated hours exactly as the spec says; test both listed zones.
- Passwords: scrypt from the standard library (as in the scaffold's passwords.py).
- Export format: include a version number and design it so later stages can import every
  earlier stage's export. Each stage's plan must describe the upgrade path.
- Stage 2 UI: plain HTML, CSS and JavaScript served by the same process, no build step, all
  assets local. It must look like a real, warm restaurant product and work at 375 px wide
  and on desktop, as the stage 2 spec describes.

## When you are done

After stage 4 is verified (or when no further progress is possible), post a final report in
the room: the verified revision of each stage, the last isolated check result per stage,
open gaps, and the time each stage took.
