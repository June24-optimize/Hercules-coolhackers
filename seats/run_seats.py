"""Run the factory's seats as Band agents backed by one OpenCode server on Featherless.

Each seat is an OpencodeAdapter whose standing instructions are its mandate file. All
seats share one working directory (the parent of every result repository) and one
OpenCode server; each Band room gets its own OpenCode session per seat.

    opencode serve --hostname=127.0.0.1 --port=4096     # terminal 1, from an empty directory
    uv run --project seats python seats/run_seats.py     # terminal 2

This is the alternative to setup-seats.sh's Band-owned OpenCode seats. It runs only the
seats whose mandate says `Harness: OpenCode`.

Environment (all optional):
    SEATS_CONFIG     agent_config.yaml from register_seats.sh
    WORKDIR          absolute directory the seats may change (default ~/hackathon/band-work)
    OPENCODE_URL     OpenCode server (default http://127.0.0.1:4096)
    SEAT_MODEL       overrides every mandate's Model: line (provider/model)
"""

from __future__ import annotations

import asyncio
import contextlib
import logging
import os
import re
from pathlib import Path

from band import Agent, configure_logging
from band.adapters.opencode import OpencodeAdapter, OpencodeAdapterConfig
from band.core.types import Emit

REPO = Path(__file__).resolve().parent.parent
MANDATES = REPO / "mandates"
SEATS_CONFIG = Path(os.getenv("SEATS_CONFIG", "~/hackathon/band-work/seats/agent_config.yaml")).expanduser()
WORKDIR = str(Path(os.getenv("WORKDIR", "~/hackathon/band-work")).expanduser())
OPENCODE_URL = os.getenv("OPENCODE_URL", "http://127.0.0.1:4096")

configure_logging(level=logging.INFO, stream="stdout", root_level=logging.INFO,
                  extra_loggers={"httpx": logging.WARNING})
logger = logging.getLogger("seats")


def seat_names() -> list[str]:
    return sorted(p.stem for p in MANDATES.glob("*.md")
                  if re.search(r"(?m)^Harness:\s*OpenCode\s*$", p.read_text()))


def make_adapter(seat: str) -> OpencodeAdapter:
    mandate = (MANDATES / f"{seat}.md").read_text()
    model = os.getenv("SEAT_MODEL") or re.search(r"(?m)^Model:\s*(\S+)", mandate).group(1)
    provider_id, model_id = model.split("/", 1)
    return OpencodeAdapter(
        config=OpencodeAdapterConfig(
            base_url=OPENCODE_URL,
            directory=WORKDIR,
            provider_id=provider_id,
            model_id=model_id,
            custom_section=mandate,
            # Dark factory: nothing may wait for a human. OpenCode runs commands without
            # asking, and its own clarifying questions are declined, not posted to the room.
            approval_mode="auto_accept",
            question_mode="auto_reject",
            turn_timeout_s=900,   # a single file edit took 16-41 s on these models
        ),
        # Keep execution events on: judges read tool calls in room.json.
        emit=Emit.TOOL_CALLS | Emit.TASK_EVENTS,
    )


async def main() -> None:
    if not os.path.isabs(WORKDIR):
        raise SystemExit("WORKDIR must be absolute")
    if not SEATS_CONFIG.exists():
        raise SystemExit(f"{SEATS_CONFIG} not found; run seats/register_seats.sh first")
    seats = seat_names()
    async with contextlib.AsyncExitStack() as stack:
        agents = []
        for seat in seats:
            agent = await stack.enter_async_context(
                Agent.from_config(seat.replace("-", "_"), adapter=make_adapter(seat),
                                  config_path=SEATS_CONFIG))
            logger.info("seat online: %s", seat)
            agents.append(agent)
        logger.info("%d seats online in %s", len(agents), WORKDIR)
        await asyncio.gather(*(a.run_forever() for a in agents))


if __name__ == "__main__":
    asyncio.run(main())