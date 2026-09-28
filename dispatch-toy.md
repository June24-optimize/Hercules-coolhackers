# Dispatch task: toy rehearsal (paste as one message to @coordinator)

Unscored practice. Prepare the repo first:

    cd ~/hackathon/dark-factory-wearedevs
    mkdir -p ../band-work/toy-result/stage-1 ../band-work/checks
    cp scaffold/* ../band-work/toy-result/stage-1/
    git -C ../band-work/toy-result init -b main
    git -C ../band-work/toy-result add -A
    git -C ../band-work/toy-result -c user.name=human -c user.email=human@factory.invalid commit -m "scaffold"

Replace every `/Users/wanyubian/hackathon` below with the workspace path on the machine that
runs the seats. For a short confirmation run, change "all four stages of the toy track, one
after the other" to "stage 1 of the toy track only" and list only the stage-1 spec.

---

@coordinator Build all four stages of the toy track, one after the other,
following your mandate. Do not ask me anything; I will not reply.

Specification package: /Users/wanyubian/hackathon/dark-factory-wearedevs
Track: toy
Result repository (absolute path, branch main, scaffold already in stage-1/): /Users/wanyubian/hackathon/band-work/toy-result

Stage specifications (read each in full and paste it in full into every handoff):
- /Users/wanyubian/hackathon/dark-factory-wearedevs/toy/spec/stage-1.md
- /Users/wanyubian/hackathon/dark-factory-wearedevs/toy/spec/stage-2.md
- /Users/wanyubian/hackathon/dark-factory-wearedevs/toy/spec/stage-3.md
- /Users/wanyubian/hackathon/dark-factory-wearedevs/toy/spec/stage-4.md

Stage N lives in stage-N/ with a Dockerfile, RUN.md and source; stage-2/ starts as a copy of
the verified stage-1/, and so on (delete any .git in a copy). Documents go in specs/stage-N/.

Release tooling: none

Never open the test files under the specification package's toy/test/ folder or the harness
source code; the seats' permissions block it. Run the checks, read the failing log, then the
spec.

Checks (the reviewer runs these):

    cd /Users/wanyubian/hackathon/dark-factory-wearedevs && . .venv/bin/activate
    python -m harness run --track toy --repo /Users/wanyubian/hackathon/band-work/toy-result --stage N --out /Users/wanyubian/hackathon/band-work/checks/toy-sN-<counter>

A good result ends with `claimed stage: N`. Post a final report when stage 4 is verified.
