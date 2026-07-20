# Triage — picking a strategy when the user didn't

Purpose: Select the lowest-cost orchestration strategy that satisfies the task's dependency, coordination, and review needs.

Read when:
- No explicit strategy or saved alias was supplied.

Skip when:
- The user forced a valid strategy and host compatibility is already resolved.

Inputs:
- Task or plan, repository shape, host capabilities, dependencies, risk, and budget.

Produces:
- Selected strategy, resolved degradations, and a one-line rationale.

Run this BEFORE dispatching anything. It costs one cheap assessment, not a subagent, unless the
codebase is unknown (then dispatch `prompt-triage-assessor.md` on a mid-tier model).

## Step 0 — should you orchestrate at all?

Estimate total context the work needs (files to read + plan + expected diffs).
- **< 50K tokens AND tasks are coupled → `solo`.** Do the work directly; add a single reviewer
  subagent if the change is risky. Orchestration overhead would exceed its return (measured
  baselines: one tool-using agent ≈ 4× a chat interaction's tokens; multi-agent ≈ 15×).
- A loop earns its cost only when ALL four hold (Karpathy test): the task repeats or grinds;
  verification is automated; the token budget can absorb retries; the agent has real tools to see
  failures. Miss one → don't pick `loop`.
- **Host gate** (non-Claude-Code hosts only): resolve the host first (`shared-hosts.md`). `team`
  needs Claude Code or Antigravity; `workflow` needs Claude Code; in-session parallel fan-out is
  missing on opencode/Hermes. An unsupported pick maps to its degradation (team→hierarchical,
  workflow→scripted xcli fan-out, parallel→headless engines in worktrees) — name the downgrade in
  the one-line pick.

## Step 1 — measure the shape

| Signal | How to read it |
|---|---|
| Plan exists? | plan file / PRD / issue list present → planning=none (already planned) |
| Task count + size | count `# Task N` headings or enumerable units |
| Independence | do tasks share files/state? (grep the plan's file lists for overlap) |
| Verifiable stop? | tests/build/metric that can fail the work without a human |
| Recurring? | same task, new inputs each run (schedule/queue/tracker) |
| Needs debate? | unclear root cause, multiple valid architectures, high-stakes plan |
| Blast radius | prod/customers/external sends → human gates ON regardless of strategy |
| Scale | items to process: ≤5 · 6–20 · 20+ |

## Step 2 — map shape → strategy

```
coupled tasks, <50K ................................. solo
plan + mostly-independent tasks, sequential OK ...... staged            (the default)
independent tasks + no shared files + speed matters . parallel
one repo question spanning huge context ............. hierarchical (read-only fan-out)
domains each needing real thinking + own workers .... hierarchical
workers must argue/coordinate mid-task .............. team
20+ homogeneous items, or verify-each-finding ....... workflow
grind-until-green OR recurring on trigger ........... loop
budget-constrained + strong model only for judgment . advisor
high-stakes plan, wrong-plan cost >> debate cost .... adversarial
task fits another CLI's specialty / second opinion .. xcli (usually as engine= on another strategy)
```

Scale-gating (task count refines within a strategy): 1–2 files w/ complete spec → cheapest worker
tier; 3–5 → standard flow; 6+ → require a written plan first (planning=plan-first) and consider
parallel/workflow.

## Step 3 — resolve and record

1. State the pick in one line: `strategy=X because <signals>`. Apply user dimension overrides.
2. Write `.orchestrate/run.md`: task, resolved dimensions, budget, timestamp.
3. Only if two strategies fit equally and the cost difference is large → ask the user
   (AskUserQuestion on Claude Code; host equivalent per `shared-hosts.md`) with the trade-off.
   Otherwise proceed.

## Re-triage triggers (mid-run)

- Scope expansion (new features/constraints/tech discovered) → STOP, restart triage with the
  integrated requirements. Do not bolt new scope onto a running strategy.
- Repeated BLOCKED from workers on the same theme → the plan is wrong; escalate to the human.
- Budget exhausted → summarize state to the ledger, report, stop. Never silently downgrade review.
