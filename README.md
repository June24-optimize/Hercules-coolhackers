# CoolHackers · Pocketful Delivery Line

Our factory for the WeAreDevelopers × BAND "Dark Factory" hackathon, **pocketful** track.
Design by Srilekha ([deck](docs/pocketful-delivery-line.pdf)), with the changes in
[PLAN.md §9](PLAN.md#9-changes-from-the-original-deck-and-why) and the lean four-seat factory
in [PLAN.md §10](PLAN.md#10-lean-factory-v2-after-the-toy-rehearsal).

| Path | What it is |
|---|---|
| [PLAN.md](PLAN.md) | The complete plan: scoring, gates, seats, flow diagrams, service, schedule, checklist |
| [mandates/](mandates/) | Generic standing instructions for the four seats (generated; do not edit by hand) |
| [tools/build_mandates.py](tools/build_mandates.py) | Source of the mandates: shared rules + one role section per seat |
| [tools/scan_mandates.sh](tools/scan_mandates.sh) | The harness's mandate rules (Harness/Model lines, track vocabulary); run after every edit |
| [setup-seats.sh](setup-seats.sh) | Creates the four seats in Band (Claude Code or OpenCode, per mandate), live-linked to their mandates |
| [tools/opencode-featherless](tools/opencode-featherless) | Launcher for the OpenCode seats: hands them the Featherless key from launchd (macOS) |
| [claude-settings.json](claude-settings.json) | Claude Code seats: pre-allowed commands; git push denied; test files and harness source unreadable |
| [opencode-permissions.json](opencode-permissions.json) | OpenCode seats: the same rules in OpenCode's format |
| [dispatch-pocketful.md](dispatch-pocketful.md) | The single task message for the judged run (all track detail lives here) |
| [dispatch-toy.md](dispatch-toy.md) | The toy rehearsal task |
| [docs/setup-notes.md](docs/setup-notes.md) | Step-by-step setup and submission notes |
| [vm/](vm/) | Setup script and guide for hosting the seats on an Ubuntu cloud VM (untested) |
| [seats/](seats/) | Alternative: the OpenCode seats as your own Band SDK programs |

Spec package: https://github.com/band-ai/dark-factory-wearedevs · Earlier tablekeeper plan: branch `tablekeeper-plan`.
