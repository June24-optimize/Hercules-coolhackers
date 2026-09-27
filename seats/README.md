# Seats on OpenCode + Featherless (no Band Desktop runtime needed)

Each seat is a small Band SDK program (an `OpencodeAdapter`) whose standing instructions are
its mandate file. All seats share one OpenCode server, whose model is served by Featherless.
Nothing here goes through Claude Code, so it runs from any normal terminal.

| Profile | Seats | Mandates |
|---|---|---|
| `lite` (default) | coordinator, developer-a, reviewer | `mandates-lite/` |
| `full` | the nine model seats | `mandates/` |

## One-time setup

```sh
brew install sst/tap/opencode                                  # or: npm install -g opencode-ai
mkdir -p ~/.config/opencode && cp seats/opencode.json ~/.config/opencode/opencode.json
opencode models | grep featherless                             # FEATHERLESS_API_KEY must be exported
uv sync --project seats

# register the seats on Band (a band_u_ user key; read without echo, never stored)
read -s "BAND_USER_API_KEY?Band user API key: " && export BAND_USER_API_KEY && echo
seats/register_seats.sh                                        # writes ~/hackathon/band-work/seats/agent_config.yaml
unset BAND_USER_API_KEY
```

## Run

```sh
# terminal 1 — OpenCode server, from an empty directory, bound to localhost only
cd "$(mktemp -d)" && opencode serve --hostname=127.0.0.1 --port=4096

# terminal 2 — all seats
cd ~/hackathon/factory && uv run --project seats python seats/run_seats.py
```

Then in the Band console (app.band.ai): new chat → add the seats → paste the dispatch
(`dispatch-toy.md`) to `@coordinator`.

## Safety

`approval_mode="auto_accept"`: seats run shell commands and edit files **without asking**,
inside `WORKDIR` (default `~/hackathon/band-work`) but not sandboxed. Run them on a machine
or VM you're comfortable handing to an unattended agent. `question_mode="auto_reject"` keeps
OpenCode from posting questions to the human.
