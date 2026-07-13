# staged — fresh implementer per task, dual review gate (default strategy)

Preset: `topology=staged planning=plan-first review=dual isolation=off trigger=once`.
Sequential per-task cycles. The controller never implements; every task gets a FRESH subagent with
a curated brief; two ordered reviews gate every task. Descends from superpowers SDD.

Read with this file: `shared/contracts.md`, `shared/review-gates.md`, `shared/model-routing.md`,
`shared/token-economy.md` (communication blocks + priming anatomy).
Prompts: `prompts/implementer.md`, `prompts/spec-reviewer.md`, `prompts/quality-reviewer.md`.

## Setup (once per run)

1. `scripts/workspace` → `.orchestrate/` (self-ignoring; survives compaction, invisible to git).
2. **Pre-flight plan scan**: read the whole plan ONCE. Collect contradictions, ambiguities, and
   plan-mandated defects into ONE batched question to the human. Then no more between-task
   check-ins — continuous execution until BLOCKED, genuine ambiguity, or done.
3. Read `.orchestrate/progress.md` if it exists (resume): tasks with a `complete` line are DONE —
   resume at the first task without one. Trust the ledger + `git log` over recollection; the most
   expensive observed failure mode is re-dispatching completed task sequences after compaction.
4. Write `.orchestrate/run.md` with resolved dimensions.

## Per-task cycle

```
brief → dispatch implementer → (questions? answer, re-dispatch) → implement/test/commit/self-review
  → spec review → (fix → re-review)* → quality review → (fix → re-review)* → ledger line → next
```

1. **Brief**: `scripts/task-brief PLAN_FILE N` extracts the plan section; COMPOSE the brief
   around it per the priming anatomy (`shared/token-economy.md`) and gate it with
   `scripts/brief-check` before dispatch. Dispatch the implementer (prompt template) with: brief
   path, report path (`task-N-report.md`), scene-setting (where this fits, interfaces from prior
   tasks, resolved ambiguities), and an EXPLICIT model. A dispatch is ONE task — never session
   history.
2. **Record BASE** (`git rev-parse HEAD`) before the implementer starts.
3. Implementer returns **<15 lines**: Status · commits · one-line test summary · concerns · report
   path. Full detail goes in the report file, not chat.
4. **Status protocol** (`shared/contracts.md`): `DONE` → review. `DONE_WITH_CONCERNS` → read the
   report; correctness/scope concerns are addressed before review, observations are noted.
   `NEEDS_CONTEXT` → supply it, re-dispatch same model. `BLOCKED` → the ladder: context problem →
   more context, same model · needs reasoning → more capable model · too large → split the task ·
   plan wrong → escalate to human. NEVER re-dispatch unchanged.
5. **Review package**: `scripts/review-package BASE HEAD` (always the recorded BASE — `HEAD~1`
   truncates multi-commit tasks). Dispatch spec reviewer with brief + report + diff paths and the
   plan's Global Constraints copied VERBATIM. Then, only after spec ✅, the quality reviewer.
   Reviewers are read-only. Never pre-judge findings in a reviewer prompt ("don't flag X", "at
   most Minor") — that's you sparing yourself a review loop.
6. **Fix waves**: Critical/Important → ONE fix subagent carrying the full implementer contract
   (re-run covering tests, name files, report command+output) → re-review. Minor → ledger, batched
   for the final review. Implementer rationale never downgrades a severity. ⚠️ "cannot verify from
   diff" items are YOURS to resolve — you hold cross-task context.
7. **Ledger**: append `Task N: complete (commits <base7>..<head7>, review clean)`.

## Finish

After all tasks: ONE whole-branch review (most capable model) over
`review-package $(git merge-base main HEAD) HEAD`. Its findings → ONE fix subagent with the
complete list (never one fixer per finding — that costs more than all the tasks combined). Then
hand off to the repo's branch-finishing flow (merge/PR per project convention).

## Dimension overrides that change this file's behavior

- `engine=codex` — implementer dispatches become `codex exec` calls (`strategies/xcli.md`);
  reviews stay on Claude. Cross-model review is a feature, not an accident.
- `review=panel:N` — replace the quality review with an N-lens panel (`shared/review-gates.md`).
- `isolation=worktree` — implementers work in worktrees; use when tasks touch overlapping areas
  and you want serialized merges instead of a shared tree (`shared/isolation.md`).

## Red flags (inherited from the original skill — still law)

Never: skip either review or run them out of order · proceed with unfixed Critical/Important ·
run parallel implementers in this strategy (that's `parallel`) · make a subagent read the plan
file (brief it) · ignore subagent questions · let self-review replace review · move on while a
review has open issues · implement in the controller.
