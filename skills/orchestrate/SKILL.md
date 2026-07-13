---
name: orchestrate
version: 1.1.0
description: Strategy-selectable subagent orchestration. Use when executing an implementation plan or any multi-step task with subagents — sequential staged cycles, parallel worktree fan-out, hierarchical sub-orchestrator fleets, agent teams, dynamic workflows, goal/Ralph loops, advisor/executor cost splits, adversarial planning, or external CLI engines (codex/grok) as workers. Triggers - /orchestrate, "orchestrate this", "run this plan with subagents", "fan out agents", "goal loop", "agent swarm". The user can force a strategy with strategy=<name>; otherwise a triage pass picks one and says why.
---

# Orchestrate

**Version 1.1.0** — if asked which version of orchestrate is installed, answer from this line.
(History: `CHANGELOG.md` in the source repo, github.com/gabros20/orchestrate.)

One entry point, nine orchestration strategies. **A strategy is a preset over dimensions**; every
rule reads the dimensions, not the strategy name. You (the invoking agent) are the **controller**:
you coordinate, dispatch, and gate — you do not implement.

## Invocation grammar

```
/orchestrate [plan-file | task description]
    [strategy=auto|staged|parallel|hierarchical|team|workflow|loop|advisor|adversarial|xcli]
    [review=dual|spec|quality|panel:N|consensus:N|off]
    [engine=claude|codex|grok|mixed]
    [models=orchestrator:opus,worker:sonnet,advisor:<strongest>,...]
    [isolation=worktree|branch|off]
    [trigger=once|goal:"<stop condition>"|interval:<t>|schedule:"<cron>"]
    [workers=N] [budget=<cycles|agents|tokens>] [alias=<saved-preset>]
```

Selection priority: **explicit `strategy=` > `alias=` (config.yaml) > auto-triage > ask**.
Bare invocation → run the triage in `references/triage.md`, state the pick + one-line why, proceed.
Ask (AskUserQuestion) only when triage signals genuinely conflict.

## Dimensions (the knobs every strategy is a preset over)

| Dimension | Values | Default |
|---|---|---|
| `topology` | solo · staged · parallel · hierarchical · team · workflow · loop | from strategy |
| `planning` | none · plan-first · interview · adversarial | plan-first |
| `review` | off · spec · quality · dual (spec→quality, ordered) · panel:N · consensus:N | dual |
| `engine` | claude · codex · grok · mixed | claude |
| `models` | tier map (advisor/orchestrator/reasoner/worker/reviewer/peer) | `shared/model-routing.md` |
| `isolation` | none · worktree · branch | worktree when >1 writer |
| `trigger` | once · goal · interval · schedule | once |
| `budget` | max cycles / agents / tokens / open-PR cap | per strategy |

Record resolved dimensions in `.orchestrate/run.md` at kickoff (auditable, resumable).

## Strategy catalog

| Strategy | Use when | Read |
|---|---|---|
| **staged** *(default)* | A plan with mostly-independent tasks; quality via per-task fresh implementer + dual review | `references/strategies/staged.md` |
| **parallel** | Independent tasks, no shared files; N workers at once in worktrees | `references/strategies/parallel.md` |
| **hierarchical** | Work too broad for one context; sub-orchestrators think per-domain, workers execute | `references/strategies/hierarchical.md` |
| **team** | Workers must talk to each other: debate, competing hypotheses, cross-layer coordination | `references/strategies/team.md` |
| **workflow** | 10–1000 agents, deterministic fan-out/verify; script holds the plan, not you | `references/strategies/workflow.md` |
| **loop** | Recurring or grind-until-done work with a verifiable stop condition | `references/strategies/loop.md` |
| **advisor** | Cost split: cheap executor runs, expensive model consulted rarely (or plans up front) | `references/strategies/advisor.md` |
| **adversarial** | High-stakes plan worth hardening by debate before cheap execution | `references/strategies/adversarial.md` |
| **xcli** | Route work to external CLIs (codex/grok) as workers, peers, or second opinions | `references/strategies/xcli.md` |

Strategies compose via dimension overrides: `strategy=staged engine=codex` (Codex implements,
Claude reviews) · `strategy=loop topology=parallel` (each cycle fans out) · `strategy=parallel
review=panel:3`.

## Universal rules (all strategies)

1. **You coordinate; subagents work.** Never implement in the controller — fresh context per task
   beats accumulated context. Failed task → fix subagent, not manual fixing (context pollution).
2. **Artifacts on disk are the interface, never chat.** Briefs, reports, ledgers, diffs — files.
   Workspace: `.orchestrate/` in the repo root, self-ignoring (`scripts/workspace` creates it).
3. **Model explicit on EVERY dispatch** — an omitted model silently inherits the session's most
   expensive one. Tiers: `references/shared/model-routing.md`.
4. **Gate with typed checks, enforced not trusted.** Review order is fixed: spec THEN quality.
   Contracts + report schemas: `references/shared/contracts.md`; gates: `references/shared/review-gates.md`.
5. **Ledger before memory.** Append progress to `.orchestrate/progress.md` after each gated unit;
   on resume/compaction trust ledger + `git log` over recollection.
6. **Safety rails always on** — never start on main/master without consent; loop caps + kill
   switch; on API overload NEVER spawn a duplicate agent (resume/nudge the same one); respect the
   open-PR bandwidth cap. Full list: `references/shared/safety-rails.md`.
7. **When NOT to orchestrate:** <50K tokens of coupled work → `solo` (just do it, optionally one
   reviewer). A strategy that costs more than it returns is a bug.
8. **Token economy: prime with pointers, work silent, report dense.** Briefs follow the priming
   anatomy and pass `scripts/brief-check`; every dispatch embeds its ROLE's communication block
   (`references/shared/token-economy.md`). Quote literals verbatim; never compress safety
   language. Reviewers report everything — filtering is the controller's job.

## Files

- `references/triage.md` — auto-selection decision procedure
- `references/strategies/*.md` — one per strategy: roles, step flow, failure handling, example
- `references/shared/*.md` — contracts · review-gates · model-routing · isolation · monitoring · safety-rails · handoff · token-economy
- `references/prompts/*.md` — dispatch templates (implementer, reviewers, verifier, sub-orchestrator, …)
- `scripts/` — `workspace` · `task-brief PLAN N` · `review-package BASE HEAD` · `brief-check BRIEF`
- `config.yaml` — saved aliases (named dimension presets)

Read ONLY the strategy file you selected plus the shared files it names. Do not preload everything.
