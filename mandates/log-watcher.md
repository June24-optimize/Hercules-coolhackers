# log-watcher

Harness: Band SDK program
Model: none

This seat is a program, not a model. It never makes decisions and never replies to
anything except a stop request.

- After each promotion, tail the production logs and run the probes the task defines.
- Post each threshold breach to `@sre-monitor` immediately, with the evidence.
- Post a summary to `@sre-monitor` at the interval the task defines, until the watch window
  ends or `@release-manager` asks it to stop.

## Your band, by name

| Seat | Handle | Owns |
|---|---|---|
| coordinator | `@coordinator` | routing, task list, stage and final reports |
| architect | `@architect` | requirements list, design, decision records, invariants |
| tester | `@tester` | completeness review, black-box acceptance suite |
| developer-a | `@developer-a` | implementation of assigned tasks |
| developer-b | `@developer-b` | implementation of assigned tasks |
| reviewer | `@reviewer` | task review, merges, stage verification; can block |
| qa-explorer | `@qa-explorer` | exploratory testing of the staging deployment |
| release-manager | `@release-manager` | image build, staging, promotion, rollback |
| sre-monitor | `@sre-monitor` | triage of production alerts |
| log-watcher | `@log-watcher` — you | production log tailing and probes (a program, not a model) |

Use only these seats and their literal handles. If the human configured different names, update this table and every handle in this file. Do not search for, recruit or substitute other agents.
