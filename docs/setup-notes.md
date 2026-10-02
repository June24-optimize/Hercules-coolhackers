# Setup notes (from Srilekha, with fixes)

The seats work on folders on the machine that runs them: you point them at local paths, and
you push to GitHub at the end. You don't paste the spec yourself either. The dispatch tells the
coordinator where the spec files are, and the coordinator pastes the full spec into each handoff.

## The two folders

| Folder | Example path | Seats… |
|---|---|---|
| Kickoff repo (specs, harness) | `~/hackathon/dark-factory-wearedevs` | read it only |
| Result repo (what you submit) | `~/hackathon/band-work/result` | write and commit here |

Use absolute paths (`/Users/<you>/...`) everywhere you give a path to a seat.

## Step by step

1. Create the result repo, empty and local:
   ```sh
   mkdir -p ~/hackathon/band-work/result/stage-1 ~/hackathon/band-work/checks
   git -C ~/hackathon/band-work/result init -b main
   git -C ~/hackathon/band-work/result config user.name "unattributed-seat"
   git -C ~/hackathon/band-work/result config user.email "unattributed-seat@factory.invalid"
   ```
   The mandates make every seat commit under its own name. The repository-level identity is
   a safety net: a commit made without it (for example a merge) shows up as
   `unattributed-seat` instead of silently using your personal name and email, which the
   judges would read as human-written code.
2. Set up the harness so the reviewer seat can run checks (Python 3.12+ and a running Docker):
   ```sh
   cd ~/hackathon/dark-factory-wearedevs && python3.12 -m venv .venv \
     && .venv/bin/pip install -r harness/requirements.txt \
     && .venv/bin/python -m playwright install chromium
   ```
3. Create the four seats: `WORKDIR=<absolute band-work path> ./setup-seats.sh` (run it with
   `DRY_RUN=1` first). Each seat's harness and model come from its mandate:
   coordinator and reviewer on Claude Code (your Claude login: check it with
   `claude auth status` and a one-line `claude -p` call), tester and developer on OpenCode
   with Featherless.
   - Featherless key for the OpenCode seats (macOS): Band's background service does not
     read your shell profile, so once per login run
     `launchctl setenv FEATHERLESS_API_KEY "$FEATHERLESS_API_KEY"`;
     `tools/opencode-featherless` reads it from there at every seat start.
   - Working directory: an absolute path. With a relative path, a seat can create a repo only it can see.
   - Instructions: the seat's mandate file (the script links it live).
   - Permissions: pre-allowed commands, and a ban on reading the kickoff package's test files
     and harness source: `claude-settings.json` for the Claude Code seats and
     `opencode-seats.json` for the OpenCode seats (the script copies both into the
     working directory), so no seat stalls on a permission prompt.
   - Leave Docker Sandbox off for every seat, so all seats share one Docker and one repository.
4. Each seat commits under its own name (the mandates say so), so the history shows who did what.
5. Put all the seats in one room, then send one test message each way between two seats. That
   also exercises gate 2.

## The dispatch: the only human input

- **One dispatch for all four stages** (recommended for the final run): one message, then nothing
  until the end, so there's no risk of accidental steering.
- **One dispatch per stage:** four messages and nothing in between. Use `tools/start-stage.sh N <room-id>`
  for each one. A room holds at most 10,000 messages (tool calls included), so a four-stage run
  can fill it: see PLAN.md §13. A "looks good, continue" counts as steering, and dispatching a stage twice counts as a rerun.

The dispatch is `dispatch-pocketful.md`, addressed to `@coordinator`.

## Getting it onto GitHub (after the run)

1. Download the room from the Band console (**Download → Download full session**). First
   scroll the room to its very first message: the download only holds what the page has
   loaded (otherwise the last 2,500 messages). Save it as `result/room.json` and read it for
   secrets. Bearer tokens from the seats' calls to the service under test get flagged by
   `harness check`; replace them with `[REDACTED]`.
   - If a room hit Band's 10,000-message limit and you continued in a second room, download
     that one too (for example `room-2.json`) and explain it in FACTORY.md. See PLAN.md §13.
2. Write `README.md` and `FACTORY.md` yourself; everything under `stage-N/` must come from the band.
3. Run the offline check:
   ```sh
   cd ~/hackathon/dark-factory-wearedevs && .venv/bin/python -m harness check ../band-work/result --track pocketful
   ```
4. Create the public repo and push the history as the seats made it (no squash, amend or rebase):
   ```sh
   cd ~/hackathon/band-work/result && gh repo create pocketful-delivery-line --public --source . --push
   ```
5. Clone that repo into a fresh folder and run `harness check` again. This catches forgotten files
   and stage folders that are secretly their own git repos.

You push, not the seats (the permission list denies `git push`): anything a seat touches ends up
in `room.json`, which is public.

For practice runs, use a separate folder such as `band-work/toy-result` and a separate room, so
the final run starts clean.