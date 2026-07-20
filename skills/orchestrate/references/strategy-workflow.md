# workflow — script-orchestrated agent fleets (10–1000 agents, without going loose)

Purpose: Drive large deterministic fan-out through a script-held workflow with bounded agent calls.

Read when:
- The task contains many repeated items whose dispatch, verification, and aggregation can be scripted.

Skip when:
- The task is small, highly coupled, or depends on evolving conversational judgment.

Inputs:
- Input set, pilot slice, workflow script, budgets, verifier, and aggregation schema.

Produces:
- Pilot evidence, batched results, verification records, and deterministic aggregate.

Preset: `topology=workflow review=consensus/adversarial-verify budget=agents`.
A JavaScript workflow script holds the plan — loops, fan-out, verification — and the runtime
executes it in the background; your context holds only the final result. Use when the task
outgrows what you can coordinate turn-by-turn, or when the orchestration itself should be
repeatable/re-runnable.

**Host availability**: the Workflow tool is Claude Code-only. On other hosts, keep the
script-holds-the-plan shape with a controller-held driver — a shell/JS script fanning out
headless engines per item (`strategy-xcli.md`); the discipline below (pilot, budget, pipeline,
adversarial verify, no silent caps) applies unchanged — or downshift to `parallel`/`hierarchical`
(`shared-hosts.md`).

## When script-holds-the-plan beats you-holding-it

- 20+ homogeneous items (audit every route, migrate every component, review every changed file)
- findings need cross-verification (independent verify agents voting on each claim)
- the same orchestration will run again (save it as a `/command`)
Not for: work needing mid-run human sign-off between stages (run each stage as its own workflow).

## Discipline that keeps a fleet from going loose

1. **Pilot on a slice first** — one directory, not the repo; gauge tokens before committing.
   Workflows can spawn hundreds of agents; the 25-agent / 1.5M-token warning is advisory only.
2. **Explicit budget in the script** — cap agents; use loop-until-dry with a dry-round counter,
   never `while(true)`; the runtime caps 16 concurrent / 1000 total, but your budget should bind
   far earlier.
3. **pipeline() over barriers** — items flow through stages independently; barrier only when a
   stage truly needs ALL prior results (dedup, early-exit, cross-comparison).
4. **Adversarial verify as a stage, not a hope** — every finding gets N independent refuters;
   majority-refuted findings die. Diverse lenses beat identical redundancy.
5. **Model routing per stage** — mechanical stages on cheap models/low effort; judge/verify stages
   on strong models. Default = session model; override deliberately.
6. **No silent caps** — if the script bounds coverage (top-N, sampling), log() what was dropped.
7. **Resume, don't re-run** — a stopped run resumes with completed agents' results cached (same
   session). Check the journal before diagnosing an empty result.

## Mechanics (Claude Code)

- Trigger: the Workflow tool / `ultracode` keyword / "use a workflow" in your words — workflows
  need the user's explicit opt-in; don't launch one on inference.
- Monitor: `/workflows` (phases, per-agent tokens, pause/stop/restart); task panel shows a live
  progress line. Subagents run acceptEdits regardless of session mode — pre-allowlist the shell
  commands agents will need, or the run stalls on prompts.
- Save a good run: `/workflows` → `s` → `.claude/workflows/` (project) or `~/.claude/workflows/`
  (personal). Saved workflows take `args` (structured, not stringified).
- The controller stays in the loop BETWEEN workflows: understand → design → implement → verify as
  separate runs you read and steer, not one mega-script.
- `agent()` prompts end with the MINIMAL communication line (`shared-token-economy.md`) — with
  `schema:` the output shape is already structural; the line kills preamble/narration on the way
  there.
