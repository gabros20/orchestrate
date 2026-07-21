# hierarchical — orchestrator → sub-orchestrators → workers

Purpose: Delegate broad domains to sub-orchestrators that plan and supervise their own workers.

Read when:
- The task exceeds one controller context or contains several independently reasoned domains.

Skip when:
- The work is a small flat set of directly assignable tasks.

Inputs:
- Domain boundaries, budgets, model tiers, reporting contract, and overall acceptance criteria.

Produces:
- Domain plans, delegated task results, domain summaries, and controller synthesis.

Preset: `topology=hierarchical review=dual models=orchestrator:strong,worker:cheap`.
Use when the work spans domains that each need real *thinking* plus their own worker fleet, or
when total context far exceeds one window. Your context is the scarce resource: you hold only
conclusions; sub-orchestrators hold their domain; workers hold one task.

Read with this file: `shared-model-routing.md`, `shared-contracts.md`.
Prompt: `prompt-sub-orchestrator.md`.

## Depth reality (know the runtime before designing the tree)

- Claude Code **subagents cannot spawn subagents**. Depth comes from these mechanisms only:
  1. **Teammates as sub-orchestrators** (agent teams): a teammate is a full session that CAN spawn
     its own *foreground* subagents. Lead → teammates → subagents = 3 levels. Teammates can't
     nest teams or run background subagents.
  2. **Workflow nesting**: a workflow script can call `workflow()` exactly ONE level deep.
  3. **The main conversation as recursion stack** (RLM pattern): you sequentially play each
     sub-orchestrator yourself — fan out workers for domain A, aggregate, then domain B. Cheapest;
     no extra sessions; serializes the thinking layer.
- Anthropic managed-agents (server-side) also caps delegation at depth 1 — flat rosters, max 20
  agents, 25 threads. Same lesson everywhere: **wide and shallow beats deep**.

## Design rules

- Decompose into **3–7 independent partitions** per level; <3 means you didn't need the level,
  >7 means the brief is too vague. Aggregation strategy declared up front: union · synthesis ·
  reduce.
- Each sub-orchestrator brief: domain scope, its worker budget (count + model tier), the typed
  report it must return (verdict + findings + artifact paths, <1500 tokens), and what it must NOT
  do (no cross-domain edits, no scope invention). Briefs follow the priming anatomy + pass
  `scripts/brief-check` (`shared-token-economy.md`); sub-orchestrators apply the same standard to
  their own worker briefs.
- Planners and sub-orchestrators make cross-cutting design decisions THEMSELVES and record them
  with IDs and owners in `decisions.md` (`shared-contracts.md`) — never delegate a cross-cutting
  decision to a worker; no two delegated subtrees may decide the same question.
- **Peek before deep**: have each sub-orchestrator sample structure (cheap greps/reads) before
  committing its worker fan-out.
- Token budget drives shape (it explains ~80% of multi-agent quality variance): give each branch
  an explicit effort tier; simple domain = 1 worker/3–10 tool calls, complex = several workers.
- **Blind parallel counsel** for judgment calls: task two different-lineage agents (e.g. an opus
  reasoner + a codex peer) on the SAME question in parallel, never showing either the other's
  answer; synthesize the best of both yourself.

## Flow

1. Split domains → pick the depth mechanism (teams if domains need long-lived coordination;
   recursion-stack if they're read-heavy analyses; workflow if homogeneous at scale).
2. Dispatch sub-orchestrators with briefs; they run their own worker loops and return typed
   reports + artifacts on disk.
3. Aggregate per the declared strategy; gaps → follow-up partition, not a redo of everything.
4. Review gates apply at the level that produced code (worker output → its sub-orchestrator's
   review; cross-domain integration → yours).
5. Ledger the tree: one line per sub-orchestrator completion with its artifact paths.
