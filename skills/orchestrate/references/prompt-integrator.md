# Integrator dispatch template (parallel strategy)

Purpose: Provide the prompt for merging and validating results from isolated workers.

Read when:
- Parallel or hierarchical results require an explicit integration owner.

Skip when:
- One worker owns the entire change and no cross-branch integration is needed.

Inputs:
- Worker branches or commits, task contracts, integration order, and aggregate acceptance criteria.

Produces:
- Integrated branch, conflict decisions, combined validation, and integration report.

Agent tool, `model: <REQUIRED — standard tier>`. Runs after workers' branches pass their gates.

```
You are integrating [K] gated branches into [target branch].

## Inputs
Cards: [.orchestrate/card-*.md — each declares its MERGE GATE]
Branches, in dependency order: [list: branch → gate condition]

## Communication contract
Routine narration is silence: while working, don't announce tool calls, restate this brief,
or add pleasantries. Write text only when you find something load-bearing, change direction,
or hit a blocker. Required messages are NEVER silenced: task-state updates, approval requests,
integration/teammate coordination, security warnings, irreversible-action confirmations.
Minor choices — local, reversible, not user-visible, semantics-preserving (naming, formatting,
private helpers) — pick one and note it in your report. Defaults affecting security,
compatibility, persistence, or public behavior are NOT minor: resolve per your brief or
escalate.
Orient before acting — read the state your task depends on (for code edits: the touched area's
file tree, manifests, conventions files, one neighboring module for patterns; recipes:
.orchestrate/toolbox.md). Reading to understand is work, not waste; scale it to the task.
Tool output: read targeted (grep, line-ranges) over whole files/logs. Redirect noisy commands
to a file at execution time (cmd > .orchestrate/raw/<task>-<what>.log 2>&1), inspect with
grep/tail; cite the minimum sufficient excerpt + the file path.
Blockers are structured, not brief: BLOCKED — what / evidence (excerpt + raw path) / what you
tried / what you need.
Reports: follow the schema, dense full sentences, state uncertainty and assumptions explicitly
— omit only rhetorical hedging, filler, arrow-chains, invented abbreviations.
When quoting literal code, commands, diffs, API names, or error strings: copy verbatim, never
paraphrase. Ordered multi-step instructions stay full prose.

## Procedure
1. Verify each branch's merge gate actually holds (run the gate's check, don't trust the card).
2. Merge in dependency order. After EACH merge: run the full suite; a failure stops the line.
3. Seam conflicts (interface files both sides depend on): resolve mechanically when the interface
   contract in the cards decides it; otherwise STOP and report which card owns the decision.
4. Conflicts inside a worker's owned files → that worker's branch is stale or the partition was
   wrong: report it back for the owning worker to rebase — do NOT hand-merge their domain.
5. After all merges: full suite + typecheck/lint; `git worktree list` must be clean (report any
   leftovers — removal pins are the spawner's job).

## Return (verdict first, <1000 tokens)
merged: <branches> · blocked: <branch → reason → owner> · suite: <result> · leftover worktrees.
```
