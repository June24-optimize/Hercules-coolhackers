"""Write one dispatch per stage from dispatch-pocketful.md, with this machine's paths.

    python3 tools/make_stage_dispatches.py --workspace ~/hackathon \
        --kickoff ~/hackathon/dark-factory-wearedevs --result ~/hackathon/band-work/result \
        --out ~/hackathon/band-work [--work ~/hackathon/band-work]

Writes dispatch-pocketful-stage-N.local.md (N = 1..4) into --out. Paste one per stage into
the room, addressed to @coordinator, and send nothing else until that stage's report.
"""
import argparse
import pathlib
import re

TEMPLATE = pathlib.Path(__file__).resolve().parent.parent / "dispatch-pocketful.md"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--workspace", required=True)
    ap.add_argument("--kickoff", required=True)
    ap.add_argument("--result", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--work", help="seats' working folder for worktrees, checks and notes "
                    "(default: the result repository's parent folder)")
    a = ap.parse_args()
    ws, kick, res, out = (str(pathlib.Path(p).expanduser()) for p in (a.workspace, a.kickoff, a.result, a.out))
    work = str(pathlib.Path(a.work).expanduser()) if a.work else str(pathlib.Path(res).parent)

    body = TEMPLATE.read_text().split("\n---\n", 1)[1].lstrip("\n")
    body = (body.replace("/Users/wanyubian/hackathon/dark-factory-wearedevs", kick)
                .replace("/Users/wanyubian/hackathon/band-work/checks", str(pathlib.Path(work) / "checks"))
                .replace("/Users/wanyubian/hackathon", ws)
                .replace("WORKDIR", work)
                .replace("RESULT", res))

    for n in range(1, 5):
        text = body
        text = re.sub(r"^@coordinator Build all four stages of the pocketful track, one after the other, following\nyour mandate\.",
                      f"@coordinator Build stage {n} of the pocketful track only, following your\nmandate.", text, flags=re.M)
        text = re.sub(r"^- Stage (\d): .*\n", lambda m: m.group(0) if int(m.group(1)) == n else "", text, flags=re.M)
        text = text.replace("Stage specifications (read each in full; paste it in full into every handoff):",
                            "Stage specification (read it in full; paste it in full into every handoff that assigns work):")
        if n > 1:
            done = "Stage 1 is" if n == 2 else f"Stages 1 to {n - 1} are"
            text = text.replace("Finish and verify each stage before starting the next.",
                                f"{done} already verified in the result repository; carry stage {n - 1} forward.")
        text = re.sub(r"## When you are done\n\n.*", f"## When you are done\n\nWhen stage {n} is verified (or no further progress is possible), post the final\n"
                      f"report for stage {n} in the room: verified revision, last isolated check result, invariant\n"
                      f"evidence, open gaps and the time the stage took. Then stop; the next stage arrives as a\n"
                      f"separate dispatch.\n", text, flags=re.S)
        assert "wanyubian" not in text and "RESULT" not in text and "WORKDIR" not in text, n
        dest = pathlib.Path(out) / f"dispatch-pocketful-stage-{n}.local.md"
        dest.write_text(text)
        print("wrote", dest)


if __name__ == "__main__":
    main()
