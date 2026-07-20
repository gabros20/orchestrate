# team — coordinated peer sessions with shared tasks and messaging

Purpose: Coordinate agents that must exchange messages, debate, or adapt to one another's findings.

Read when:
- The task requires live inter-agent communication or competing hypotheses.

Skip when:
- Independent workers can communicate solely through artifacts and controller integration.

Inputs:
- Host team capabilities, roles, shared objective, communication rules, and approval points.

Produces:
- Team discussion artifacts, coordinated decisions, and integrated result.

Preset: `topology=team review=dual workers=3..5`.
Use when workers must TALK to each other mid-task: competing hypotheses, cross-layer features,
adversarial review debates. Teams are experimental; costs scale ~linearly per teammate.

**Host availability**: Claude Code (experimental flag below) or Antigravity (`invoke_subagent` +
any-to-any `send_message` approximate the topology — no shared task list, so carry state in
`.orchestrate/` files). Every other host: degrade to `hierarchical` with file-based handoff and
say so (`shared-hosts.md`).

Requires (Claude Code): `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (settings.json `env` or shell).
Without it, no teammates spawn — fall back to `parallel` or `hierarchical`.

## Preset team compositions (pick, don't invent)

| Team | Composition | For |
|---|---|---|
| review | 3 reviewers: security / performance / architecture | PR or branch review |
| debug | 3 investigators, each owning ONE hypothesis, told to disprove the others | unclear root cause |
| feature | 1 lead + 2 implementers (file-ownership split) | mid-size feature |
| fullstack | lead + frontend + backend + tests | cross-layer change |
| research | 3 general-purpose on different angles | investigation |
| security | 4 lenses: OWASP / auth / deps / secrets | audit |
| migration | lead + 2 implementers + 1 reviewer | mechanical at scale |

Sizing: start with the smallest team covering all dimensions (3–5); 5–6 tasks per teammate; three
focused teammates beat five scattered ones. Never assign implementation to read-only agent types.

## Rules of engagement

- **Spawn with full context**: teammates get CLAUDE.md/skills but NOT your history — the spawn
  prompt carries task specifics, named so you can address them (`SendMessage to:name`). Spawn
  prompts embed the WORKER communication block with the team exemption: silence covers routine
  narration, never teammate/integration coordination (`shared-token-economy.md`).
- **Tasks, not chat, carry state**: shared task list with dependencies; teammates claim work.
  Status goes in TaskUpdate, never as JSON chat messages. Card-shaped task briefs follow the
  priming anatomy and pass `scripts/brief-check` (`shared-token-economy.md`).
- **Direct messages > broadcast** (broadcast = N messages; use for genuine all-hands only).
  Message at integration points; don't micromanage mid-task.
- **Plan-approval gate for risky work**: spawn with "require plan approval"; the teammate stays
  read-only until you approve its plan — give yourself explicit approval criteria up front.
- **File conflicts**: teams do NOT worktree-isolate teammates. Partition file ownership in the
  spawn prompts, or give write-heavy teammates their own worktrees manually.
- **Quality hooks**: TeammateIdle / TaskCompleted hooks (exit 2 = send feedback, keep working /
  block completion) enforce gates mechanically when available.
- **Debate protocol** (debug/review teams): each teammate must try to DISPROVE the others'
  theories; consensus goes in a findings doc; you synthesize, dedup (same file:line → merge;
  conflicting severity → higher wins).
- Deadlocked pair → send one of them a stub/partial result to unblock; don't let both idle.

## Known limits (design around, don't fight)

No nested teams · teammates can't run background subagents · /resume doesn't restore in-process
teammates (re-spawn instead) · task status can lag (nudge or fix manually) · lead is fixed · one
team per session · shutdown is graceful-but-slow (ask by name). Watch teammates from the agent
panel; interrupt with Escape; steer early — an unattended team compounds wasted effort.
