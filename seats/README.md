# OpenCode + Featherless seats as Band SDK programs (alternative path)

The default path is `setup-seats.sh`, which creates Band-owned seats: the OpenCode seats run
through `tools/opencode-featherless` with no extra terminals. Use this folder only if you
want to run the OpenCode seats as your own Band SDK programs instead.

It runs every seat whose mandate says `Harness: OpenCode` (in lean factory v2: `tester` and
`developer`). Each seat is an `OpencodeAdapter` whose standing instructions are its mandate
file; all of them share one OpenCode server whose model is served by Featherless. Do not
also create those seats with `setup-seats.sh`: the names would collide.

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

# terminal 2 — the OpenCode seats
cd ~/hackathon/factory && uv run --project seats python seats/run_seats.py
```

Then in the Band console (app.band.ai): new chat → add the seats → paste the dispatch
(`dispatch-toy.md`) to `@coordinator`.

## Safety

`approval_mode="auto_accept"`: seats run shell commands and edit files **without asking**,
inside `WORKDIR` (default `~/hackathon/band-work`) but not sandboxed. Run them on a machine
or VM you're comfortable handing to an unattended agent. `question_mode="auto_reject"` keeps
OpenCode from posting questions to the human. The permission rules in
`opencode-seats.json` apply only when that file is the working directory's
`opencode.json` (`setup-seats.sh` copies it there).
