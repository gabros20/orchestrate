# Triage — picking a strategy when the user didn't

Run this BEFORE dispatching anything. It costs one cheap assessment, not a subagent, unless the
codebase is unknown (then dispatch `prompts/triage-assessor.md` on a mid-tier model).

## Step 0 — should you orchestrate at all?

Estimate total context the work needs (files to read + plan + expected diffs).
- **< 50K tokens AND tasks are coupled → `solo`.** Do the work directly; add a single reviewer
  subagent if the change is risky. Orchestration overhead would exceed its return (measured
  baselines: one tool-using agent ≈ 4× a chat interaction's tokens; multi-agent ≈ 15×).
- A loop earns its cost only when ALL four hold (Karpathy test): the task repeats or grinds;
  verification is automated; the token budget can absorb retries; the agent has real tools to see
  failures. Miss one → don't pick `loop`.

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
3. Only if two strategies fit equally and the cost difference is large → AskUserQuestion with the
   trade-off. Otherwise proceed.

## Re-triage triggers (mid-run)

- Scope expansion (new features/constraints/tech discovered) → STOP, restart triage with the
  integrated requirements. Do not bolt new scope onto a running strategy.
- Repeated BLOCKED from workers on the same theme → the plan is wrong; escalate to the human.
- Budget exhausted → summarize state to the ledger, report, stop. Never silently downgrade review.
