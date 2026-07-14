# /orchestrate

**One entry point, nine subagent-orchestration strategies, for any agent that reads SKILL.md.**

`/orchestrate` turns "run this plan with subagents" into a controlled process instead of an
improvised one. You point it at a plan or a task; it picks (or you force) a strategy —
sequential staged cycles, parallel worktree fan-out, hierarchical sub-orchestrator fleets, agent
teams, deterministic workflows, goal/Ralph loops, advisor/executor cost splits, adversarial
planning, or external CLIs (Codex/Grok) as workers — then coordinates, dispatches, and gates
subagent work through it. Built for Claude Code first; the skill is plain agent-skills format, so
any agent that reads a `SKILL.md` can use it.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Visual guide:** [orchestrate.vercel.app](https://orchestrate-skill.vercel.app) — every strategy, dimension,
and alias on one page.

## Install

**skills.sh ecosystem:**
```bash
npx skills add gabros20/orchestrate@orchestrate -g
```

**Clone + installer** (targets Claude Code, Codex, or both):
```bash
git clone https://github.com/gabros20/orchestrate && cd orchestrate
./install.sh claude   # or: codex | all
```

**Manual:**
```bash
cp -R skills/orchestrate ~/.claude/skills/orchestrate
```

## Quick start

Bare invocation — triage reads the plan, picks a strategy, tells you why, and proceeds:
```
/orchestrate plan.md
```

Force a strategy and tune it with dimensions:
```
/orchestrate plan.md strategy=parallel workers=4
/orchestrate "audit every service for the new auth flow" strategy=workflow
/orchestrate plan.md strategy=loop trigger=goal:"tests green" budget=cycles:15
```

## Composition presets & recipes

A strategy is a **preset over dimensions** (`review`, `engine`, `models`, `isolation`, `trigger`,
`budget`) — everything below is one invocation, no code. Start with a saved alias, or compose
dimensions directly.

### Saved aliases (`config.yaml`)

| Alias | Expands to | Use when |
|---|---|---|
| `red-team` | `strategy=adversarial review=panel:3 models={planner:strongest,worker:sonnet}` | High-stakes plan — harden it by debate, then execute under a 3-reviewer panel |
| `codex-grind` | `strategy=staged engine=codex review=dual models={reviewer:sonnet}` | Cheap bulk implementation, Claude reviews Codex's output |
| `swarm` | `strategy=parallel workers=4 review=spec isolation=worktree` | Independent tasks, no shared files, minimal ceremony |
| `afk` | `strategy=loop trigger=goal budget={cycles:20,open_prs:1} review=dual` | Walk-away grind with hard rails and a stop condition |
| `architect` | `strategy=advisor models={advisor:strongest,worker:sonnet}` | Big-model thinking, small-model doing — minimize expensive-model calls |

```
/orchestrate plan.md alias=red-team
```

### Common recipes

| Goal | Command |
|---|---|
| Panel of experts on a question | `/orchestrate "should we adopt X?" strategy=team workers=3` |
| Review a plan adversarially | `/orchestrate plan.md strategy=adversarial` |
| Multi-lens review of anything | add `review=panel:3` to any strategy |
| Research + evaluated claims | `/orchestrate "research X" strategy=hierarchical review=consensus:3` |
| Mass migration/audit | `/orchestrate plan.md strategy=workflow` (pilot a slice first) |
| Cheap bulk with cross-model review | `/orchestrate plan.md strategy=staged engine=codex` |
| Walk-away grind | `/orchestrate plan.md strategy=loop trigger=goal:"tests green" budget=cycles:15` |

Explicit `strategy=`/dimension flags always override an alias; `alias=` always overrides auto-triage.

## The 9 strategies

| Strategy | Use when |
|---|---|
| **staged** *(default)* | A plan with mostly-independent tasks — fresh implementer per task, dual review gate |
| **parallel** | Independent tasks, no shared files — N workers at once in worktrees |
| **hierarchical** | Work too broad for one context — sub-orchestrators think per-domain, workers execute |
| **team** | Workers must talk to each other — debate, competing hypotheses, cross-layer coordination |
| **workflow** | 10–1000 agents, deterministic fan-out/verify — a script holds the plan, not the model |
| **loop** | Recurring or grind-until-done work with a verifiable stop condition |
| **advisor** | Cost split — cheap executor runs, expensive model consulted rarely (or plans up front) |
| **adversarial** | High-stakes plan worth hardening by debate before cheap execution |
| **xcli** | Route work to external CLIs (Codex/Grok) as workers, peers, or second opinions |

Strategies compose: `strategy=staged engine=codex` (Codex implements, Claude reviews) ·
`strategy=loop topology=parallel` (each cycle fans out) · `strategy=parallel review=panel:3`.

## Dimensions

Every strategy is a preset over these; you can override any of them on top of a strategy or alias.

| Dimension | Values | Default |
|---|---|---|
| `topology` | solo · staged · parallel · hierarchical · team · workflow · loop | from strategy |
| `planning` | none · plan-first · interview · adversarial | plan-first |
| `review` | off · spec · quality · dual · panel:N · consensus:N | dual |
| `engine` | claude · codex · grok · mixed | claude |
| `models` | tier map (advisor/orchestrator/reasoner/worker/reviewer/peer) | see model-routing |
| `isolation` | none · worktree · branch | worktree when >1 writer |
| `trigger` | once · goal · interval · schedule | once |
| `budget` | max cycles / agents / tokens / open-PR cap | per strategy |

## How it stays safe

- **Branch-first** — never starts on `main`/`master` without consent.
- **Typed review gates** — enforced, not trusted; fixed order (spec, then quality).
- **Ledger before memory** — progress is appended to `.orchestrate/progress.md`; on resume, the
  ledger and `git log` win over recollection.
- **Loop rails** — hard cycle caps, a kill switch, and an open-PR bandwidth cap.
- **No duplicate agents on overload** — an API overload resumes/nudges the same agent, never
  forks a second one doing the same work.
- **Controller never implements** — the invoking agent coordinates and gates; every unit of work
  runs in a fresh subagent context.

## Repo map

```
skills/orchestrate/   the skill: SKILL.md (router), config.yaml (aliases), references/, scripts/
docs/                 research/ (research records), designs/ (versioned implementation designs)
site/                 the visual guide, deploys to orchestrate-skill.vercel.app
install.sh            installer (claude | codex | all)
```

More docs: [docs/research/](docs/research/) · [docs/designs/](docs/designs/) ·
[docs/installation.md](docs/installation.md) · [docs/usage.md](docs/usage.md) ·
[docs/strategies.md](docs/strategies.md) · [docs/recipes.md](docs/recipes.md)

## Requirements

- [Claude Code](https://claude.com/product/claude-code) (primary target).
- `git`, for worktree/branch isolation.
- Optional: `codex` and/or `grok` CLIs installed and on `PATH` for `engine=xcli` workers.

## License

[MIT](LICENSE) · Tamás Gábor ([@gabros20](https://github.com/gabros20))
