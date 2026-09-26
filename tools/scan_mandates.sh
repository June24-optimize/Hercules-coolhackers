#!/usr/bin/env bash
# Run the harness's own mandate rules (Harness:/Model: lines + track vocabulary, both tracks)
# against mandates/. Usage: tools/scan_mandates.sh [path/to/dark-factory-wearedevs]
set -euo pipefail
KICKOFF=${1:-$HOME/hackathon/dark-factory-wearedevs}
MANDATES="$(cd "$(dirname "$0")/.." && pwd)/mandates"
cd "$KICKOFF"
python3 - "$MANDATES" <<'PY'
import pathlib, re, sys
sys.path.insert(0, ".")
from harness.vocabulary import terms_in, for_track
banned = set(for_track("tablekeeper")) | set(for_track("pocketful"))
problems = 0
files = sorted(pathlib.Path(sys.argv[1]).glob("*.md"))
for f in files:
    text = f.read_text()
    for field in ("Harness", "Model"):
        if not re.search(rf"(?im)^[-*_ \t]*{field}[*_ \t]*:[*_ \t]*[^*_\s]", text):
            problems += 1; print(f"{f.name}: missing `{field}:` line")
    for n, line in enumerate(text.splitlines(), 1):
        hits = sorted({t for _, t in terms_in(line) if t in banned})
        if hits:
            problems += 1; print(f"{f.name}:{n}: track vocabulary {hits}")
print(f"{len(files)} mandates scanned, {problems} problem(s)")
sys.exit(1 if problems else 0)
PY
