---
name: orchestrate
description: >-
  Coordinate multi-agent work by selecting and running a bounded orchestration strategy. Use for
  implementation plans or multi-step tasks needing staged reviews, parallel worktrees, hierarchical
  fleets, agent teams, workflows, goal loops, advisor/executor splits, adversarial
  planning, or external coding CLIs. Triggers include "orchestrate this", "run this plan with
  subagents", "fan out agents", "goal loop", and "agent swarm". Do not use for small coupled tasks
  one agent can complete efficiently or for choosing a digital-product lifecycle; orchestrate only
  coordinates agents and execution.
---

# Orchestrate

## Mission and boundary

Coordinate, dispatch, review, and gate multi-agent work through one of nine strategy presets. The
invoking agent is the controller: it resolves the execution topology and maintains durable state;
subagents perform the implementation or investigation.

`orchestrate` owns **how work is assigned across agents**. It does not decide which product-lifecycle
domains are required, replace a domain skill, or own product progress. A lifecycle composer such as
`digital-product` may request orchestration, but neither capability depends on the other.

## Invocation grammar

Use the explicit form supported by the client: `$orchestrate` in Codex, `/orchestrate` in
slash-command clients, or the host's equivalent. Documentation uses `/orchestrate` as shorthand.

```text
<plan-file | task description>
  [strategy=auto|staged|parallel|hierarchical|team|workflow|loop|advisor|adversarial|xcli]
  [review=dual|spec|quality|panel:N|consensus:N|off]
  [engine=claude|codex|grok|cursor|agy|opencode|hermes|mixed]
  [models=orchestrator:<tier>,worker:<tier>,advisor:<tier>,reviewer:<tier>]
  [isolation=worktree|branch|off]
  [trigger=once|goal:"<stop condition>"|interval:<t>|schedule:"<cron>"]
  [workers=N] [budget=<cycles|agents|tokens>] [alias=<saved-preset>]
```

Selection priority: explicit `strategy=` > `alias=` from [config.yaml](config.yaml) >
[auto-triage](references/triage.md) > ask. Ask only when triage signals genuinely conflict.

## Route before acting

1. Reject orchestration when the coordination cost exceeds the expected benefit.
2. Resolve the host and its available primitives before choosing a strategy.
3. Select one strategy and record all resolved dimensions in `.orchestrate/run.md`.
4. Read the selected strategy plus only the supporting routes its roles and gates require.
5. Never preload the entire reference library.

### Strategy route

| Strategy | Use when | Read | Contribution |
|---|---|---|---|
| **staged** *(default)* | Mostly independent plan tasks need fresh implementation and ordered dual review | [Staged](references/strategy-staged.md) | Sequential task cycle, fix-wave rules, and merge gate |
| **parallel** | Tasks share no files and can run concurrently in isolated worktrees | [Parallel](references/strategy-parallel.md) | Partition, fan-out, integration, and overload behavior |
| **hierarchical** | Work is too broad for one context and needs domain sub-orchestrators | [Hierarchical](references/strategy-hierarchical.md) | Domain decomposition and delegated controller hierarchy |
| **team** | Workers must message, debate, or coordinate across layers | [Team](references/strategy-team.md) | Shared-context team protocol and host degradation |
| **workflow** | Large deterministic fan-out should be held by a script rather than model memory | [Workflow](references/strategy-workflow.md) | Pilot, budget, batch, verify, and aggregation procedure |
| **loop** | Work repeats until a verifiable goal or scheduled condition is met | [Loop](references/strategy-loop.md) | Bounded cycle, stop condition, kill switch, and evolution pass |
| **advisor** | Expensive reasoning should be separated from cheaper execution | [Advisor](references/strategy-advisor.md) | Consultation cadence and advisor/executor contract |
| **adversarial** | A high-stakes plan deserves independent challenge before execution | [Adversarial](references/strategy-adversarial.md) | Debate roles, synthesis, and hardened plan |
| **xcli** | External coding CLIs act as workers, peers, or second opinions | [External CLIs](references/strategy-xcli.md) | Verified CLI invocation, isolation, monitoring, and result capture |

Strategies compose through dimension overrides: `strategy=staged engine=codex`,
`strategy=loop topology=parallel`, or `strategy=parallel review=panel:3`.

### Shared route

| Condition | Read | Contribution |
|---|---|---|
| Any non-reference host or uncertain primitive | [Hosts](references/shared-hosts.md) | Host detection, primitive binding, and honest degradation |
| Every dispatched task | [Contracts](references/shared-contracts.md) | Brief, status, report, findings, and workspace schemas |
| Any review-enabled run | [Review gates](references/shared-review-gates.md) | Ordered spec/quality gates and panel behavior |
| Any role or engine selection | [Model routing](references/shared-model-routing.md) | Explicit model tiers, cost posture, and drift verification |
| More than one writer | [Isolation](references/shared-isolation.md) | Worktree/branch rules and integration ownership |
| Background, long-running, or external work | [Monitoring](references/shared-monitoring.md) | Polling, liveness, timeout, and recovery rules |
| Every run | [Safety rails](references/shared-safety-rails.md) | Main-branch, overload, loop, budget, and reward-hacking guards |
| Resume, compaction, or controller transfer | [Handoff](references/shared-handoff.md) | Durable state and clean controller handoff |
| Every dispatch and returned report | [Token economy](references/shared-token-economy.md) | Role-scoped communication blocks and priming anatomy |

### Prompt route

| Role | Read | Contribution |
|---|---|---|
| Implementation worker | [Implementer](references/prompt-implementer.md) | Executable task brief and dense report contract |
| Spec reviewer | [Spec reviewer](references/prompt-spec-reviewer.md) | Requirement-compliance review prompt |
| Quality reviewer | [Quality reviewer](references/prompt-quality-reviewer.md) | Maintainability and correctness review prompt |
| Integration owner | [Integrator](references/prompt-integrator.md) | Cross-worktree merge and conflict-resolution prompt |
| Domain sub-orchestrator | [Sub-orchestrator](references/prompt-sub-orchestrator.md) | Delegated planning, dispatch, and summary contract |
| Advisor | [Advisor prompt](references/prompt-advisor.md) | Bounded consultation prompt |
| Triage assessor | [Triage assessor](references/prompt-triage-assessor.md) | Independent strategy-assessment prompt |
| Verification-only worker | [Verifier](references/prompt-verifier.md) | Minimal objective verification prompt |
| Adversarial planner | [Planner debate](references/prompt-planner-debate.md) | Independent proposal and challenge prompt |
| Loop evolution pass | [Evolve](references/prompt-evolve.md) | Periodic pattern extraction and process-improvement prompt |

## Dimensions

| Dimension | Values | Default |
|---|---|---|
| `topology` | solo · staged · parallel · hierarchical · team · workflow · loop | selected strategy |
| `planning` | none · plan-first · interview · adversarial | plan-first |
| `review` | off · spec · quality · dual · panel:N · consensus:N | dual |
| `engine` | claude · codex · grok · cursor · agy · opencode · hermes · mixed | host-appropriate |
| `models` | advisor · orchestrator · reasoner · worker · reviewer · peer tier map | model routing |
| `isolation` | none · worktree · branch | worktree for multiple writers |
| `trigger` | once · goal · interval · schedule | once |
| `budget` | max cycles · agents · tokens · open PRs | selected strategy |

## Universal rules

1. **The controller coordinates; subagents work.** Do not silently implement a failed task in the
   controller. Fix the brief, model, context, or worker and re-dispatch deliberately.
2. **Artifacts on disk are the interface.** Keep briefs, reports, findings, raw logs, and ledgers in
   `.orchestrate/`; do not rely on chat memory.
3. **Pin a model on every dispatch.** An omitted model may inherit an unintended expensive default.
4. **Enforce typed gates.** When dual review is enabled, spec review precedes quality review.
5. **Ledger before memory.** Append progress after every gated unit; on resume, trust the ledger and
   repository state over recollection.
6. **Keep safety rails active.** Never begin on main/master without consent; cap loops and open work;
   on overload resume or nudge the existing agent rather than spawn a duplicate.
7. **Prime with pointers, work silent, report dense.** Preserve required safety and coordination
   messages while eliminating routine narration and raw output dumps.
8. **Do not orchestrate small coupled work.** If one agent can complete the task efficiently within
   one coherent context, use solo execution and optionally one reviewer.

## Core workflow

1. Inspect the task, plan, repository state, host capabilities, and stop condition.
2. Resolve strategy, dimensions, roles, models, budget, isolation, review, and degradation.
3. Initialize `.orchestrate/` with [workspace](scripts/workspace); record the resolved run.
4. Create task briefs with [task-brief](scripts/task-brief) and validate them with
   [brief-check](scripts/brief-check).
5. Dispatch only ready work. Monitor without duplicating agents and integrate through the selected
   strategy's owner.
6. Package review evidence with [review-package](scripts/review-package), enforce configured gates,
   and send failures back to the correct worker or owner.
7. Append durable progress and finish or hand off only when the stop condition is verified.

Use [toolbox](scripts/toolbox) to inventory available tools once and reuse the recorded result.

## Artifact contract

Every run owns `.orchestrate/run.md`, `progress.md`, task briefs, worker reports, review findings,
and any raw evidence required to reproduce a gate. Record resolved dimensions, exact role/model
assignments, budgets, branch/worktree ownership, decisions, failures, and the verified stop
condition.

## Completion and handoff

Complete only when every in-scope task has a terminal status, required reviews passed, integration
is verified, temporary worktrees or processes are accounted for, and the goal or one-shot stop
condition is satisfied. On interruption or controller transfer, emit the durable handoff defined in
[shared handoff](references/shared-handoff.md); never force the next controller to reconstruct state
from chat.
