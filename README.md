# CoolHackers · Pocketful Delivery Line

Our factory for the WeAreDevelopers × BAND "Dark Factory" hackathon, **pocketful** track.
Design by Srilekha ([deck](docs/pocketful-delivery-line.pdf)), with the changes in [PLAN.md §9](PLAN.md#9-changes-from-the-original-deck-and-why).

| Path | What it is |
|---|---|
| [PLAN.md](PLAN.md) | The complete plan: scoring, gates, seats, flow diagrams, release pipeline, service, schedule, checklist |
| [mandates/](mandates/) | Generic standing instructions for the ten seats (generated; do not edit by hand) |
| [tools/build_mandates.py](tools/build_mandates.py) | Source of the mandates: shared rules + one role section per seat |
| [tools/scan_mandates.sh](tools/scan_mandates.sh) | The harness's mandate rules (Harness/Model lines, track vocabulary); run after every edit |
| [setup-seats.sh](setup-seats.sh) | Creates the nine model seats in Band, live-linked to their mandates |
| [claude-settings.json](claude-settings.json) | Pre-allowed commands for the seats (git push denied) |
| [dispatch-pocketful.md](dispatch-pocketful.md) | The single task message for the judged run (all track detail lives here) |
| [dispatch-toy.md](dispatch-toy.md) | The toy rehearsal task |
| [docs/setup-notes.md](docs/setup-notes.md) | Step-by-step setup and submission notes |
| [vm/](vm/) | Setup script and guide for hosting the seats on an Ubuntu cloud VM |
| [seats/](seats/) | Seats as Band SDK programs on OpenCode + Featherless; `lite` 3-seat profile for rehearsals |
| [mandates-lite/](mandates-lite/) | Mandates for the 3-seat lite profile (generated) |

Spec package: https://github.com/band-ai/dark-factory-wearedevs · Earlier tablekeeper plan: branch `tablekeeper-plan`.
