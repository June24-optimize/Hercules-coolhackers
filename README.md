# CoolHackers · Pocketful Delivery Line

Our factory for the WeAreDevelopers × BAND "Dark Factory" hackathon, **pocketful** track.
Design by Srilekha ([deck](docs/pocketful-delivery-line.pdf)), with the changes in
[PLAN.md §9](PLAN.md#9-changes-from-the-original-deck-and-why) and the lean factory
in [PLAN.md §10](PLAN.md#10-lean-factory-v2-after-the-toy-rehearsal): four model seats plus a timekeeper
program seat ([PLAN.md §12](PLAN.md#12-judged-run-stage-1-the-stalled-handoff-and-the-timekeeper)).
The judged run verified all four stages; lessons from it are in
[PLAN.md §13](PLAN.md#13-judged-run-stage-4-the-room-message-limit-and-other-lessons).

| Path | What it is |
|---|---|
| [PLAN.md](PLAN.md) | The complete plan: scoring, gates, seats, flow diagrams, service, schedule, checklist |
| [mandates/](mandates/) | Generic standing instructions for the five seats (generated; do not edit by hand) |
| [tools/build_mandates.py](tools/build_mandates.py) | Source of the mandates: shared rules + one role section per seat |
| [tools/scan_mandates.sh](tools/scan_mandates.sh) | The harness's mandate rules (Harness/Model lines, track vocabulary); run after every edit |
| [setup-seats.sh](setup-seats.sh) | Creates the five seats in Band (Claude Code, OpenCode or the timekeeper script, per mandate), live-linked to their mandates |
| [tools/start-stage.sh](tools/start-stage.sh) | Starts one stage: preflight checks, seats, timekeeper ticker, dispatch on the clipboard |
| [tools/timekeeper.sh](tools/timekeeper.sh) | The timekeeper: sends `@coordinator` a clock tick every 15 minutes while a stage runs |
| [tools/make_stage_dispatches.py](tools/make_stage_dispatches.py) | Writes one dispatch per stage from `dispatch-pocketful.md` with your local paths |
| [tools/opencode-featherless](tools/opencode-featherless) | Launcher for the OpenCode seats: hands them the Featherless key from launchd (macOS) |
| [claude-settings.json](claude-settings.json) | Claude Code seats: pre-allowed commands; git push denied; test files and harness source unreadable |
| [opencode-seats.json](opencode-seats.json) | OpenCode seats: the same permission rules, plus tool-output limits and early compaction to keep contexts (and cost) small |
| [dispatch-pocketful.md](dispatch-pocketful.md) | The single task message for the judged run (all track detail lives here) |
| [dispatch-toy.md](dispatch-toy.md) | The toy rehearsal task |
| [docs/setup-notes.md](docs/setup-notes.md) | Step-by-step setup and submission notes |
| [vm/](vm/) | Setup script and guide for hosting the seats on an Ubuntu cloud VM (untested) |
| [seats/](seats/) | Alternative: the OpenCode seats as your own Band SDK programs |

Spec package: https://github.com/band-ai/dark-factory-wearedevs · Earlier tablekeeper plan: branch `tablekeeper-plan`.
