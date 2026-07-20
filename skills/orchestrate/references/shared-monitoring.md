# Monitoring — watching agents you spawned

Purpose: Monitor background agents and external processes without duplicating work or flooding context.

Read when:
- Work continues asynchronously, may stall, or writes output outside the controller session.

Skip when:
- All dispatched work returns synchronously and immediately.

Inputs:
- Worker identifiers, process or session stores, output paths, timeouts, and stop rules.

Produces:
- Liveness checks, bounded polling, recovery action, and terminal status.

Match the surface to the mechanism; don't poll what notifies you.

## In-session (Claude Code)

- Spawned subagents/background work: `/tasks` (list, attach, stop); named background subagents
  show in the @-mention typeahead with status. Harness-tracked work re-invokes you on completion
  — schedule a LONG fallback, never a short poll.
- Workflows: `/workflows` — phases, per-agent tokens, pause `p` / stop `x` / restart `r`; drill
  into any agent's prompt + tool calls. Journal: `<transcriptDir>/journal.jsonl` records each
  agent's actual return — read it before diagnosing an empty result.
- Teams: the agent panel (arrows + Enter to open a teammate, Escape interrupts); idle
  notifications arrive automatically; task list via Ctrl+T.
- Usage: `/usage` (by skills/subagents/MCPs) · bare `/goal` (turns + tokens so far).

## Background sessions (agent fleet on this machine)

```bash
claude agents --json        # id, state(working|blocked|done|failed|stopped), pid, waitingFor, sessionId
claude logs <id>            # recent output (persists ~5min after exit)
claude attach <id>          # step in when one is blocked
```
State files: `~/.claude/daemon/roster.json`, `~/.claude/jobs/<id>/state.json`.

## Session transcripts (deep record, cross-engine)

- Claude: `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl` — tail for live events, mine for
  post-hoc analysis (the evolve pass reads these). Convention, not documented API — verify the
  path exists before scripting against it.
- Codex: `$CODEX_HOME` (default `~/.codex`) — sessions/rollouts/logs. Grok: `~/.grok/sessions`.
  Cursor/agy/opencode/Hermes: stores vary and drift — don't script against them.
- External CLI runs: capture `--json` / `--output-format streaming-json` to a file per run and
  tail THAT — more stable than their internal stores (and the only portable option on hosts
  whose stores aren't documented — `shared-hosts.md`).

## Hooks (mechanical enforcement, not observation)

- `SubagentStop` → append to a progress ledger + run a validator as a hard gate (the
  brease-factory pattern: hooks enforce, orchestrator trusts the ledger).
- `TeammateIdle` / `TaskCompleted` → exit code 2 blocks + sends feedback ("keep working", "task
  isn't done: X missing").
- `Stop` → the Ralph loop re-feed (`strategy-loop.md`).
- Optional heavier rigs (OTel export, hook→HTTP→dashboard) exist; reach for them only when
  running fleets daily — one dashboard is worth less than one good ledger.

## Rules

1. Every long-running dispatch gets `run_in_background` (Claude Code; hosts without background
   shells — codex — use `nohup … &`) + a deliverable FILE path you can check.
2. An idle-without-report agent gets ONE nudge (SendMessage on Claude Code, `send_message` on
   Antigravity; elsewhere resume its session with a nudge prompt) — if it still returns nothing,
   read its transcript; don't respawn blind.
3. Silence is not success: no report + no artifact = failed, treat it as BLOCKED.
