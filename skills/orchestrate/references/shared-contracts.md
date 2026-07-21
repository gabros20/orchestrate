# Contracts — typed returns, ledger, cards

Purpose: Define the durable brief, status, report, findings, and workspace contracts used between controller and workers.

Read when:
- Any orchestration run creates or consumes task artifacts.

Skip when:
- The task is not being orchestrated.

Inputs:
- Objective, scope, files, constraints, acceptance criteria, report paths, and ownership.

Produces:
- Validated task briefs, typed statuses, dense reports, and reproducible evidence paths.

The interface between any two agents is an artifact on disk, never the conversation. Everything
pasted into a dispatch or printed back stays resident in the controller's context forever — so
briefs and reports are FILES, and chat returns are capped summaries.

## Status enum (every worker, every strategy)

`DONE` · `DONE_WITH_CONCERNS` · `NEEDS_CONTEXT` · `BLOCKED`
Never silently produce unsure work — that's what DONE_WITH_CONCERNS and BLOCKED are for.
Controller handling: DONE → gate. CONCERNS → read report; correctness/scope → address first.
NEEDS_CONTEXT → supply + re-dispatch same model. BLOCKED → ladder (context → stronger model →
split task → human). Never re-dispatch unchanged.

## Chat-return schemas (what comes back INLINE — keep it tiny)

Inline returns are CAPPED (≈1–2K tokens max, per this table); report FILES carry the depth and
are read on demand. Terseness is a grammar, not a vibe — line shapes below are contracts.

| Role | Returns (max) |
|---|---|
| implementer | <15 lines: Status · commits · 1-line tests · concerns · report path · optional `surprise:` line |
| reviewer | verdict first (✅/❌/⚠️) · counts by severity · findings FILE path (see below) |
| verifier | `works|broken` · expected · observed · evidence path |
| sub-orchestrator | <1500 tokens: verdict · findings summary · artifact paths · optional `surprise:` line |
| parallel worker | verdict first, <1000 tokens: branch/PR ref · report path · optional `surprise:` line |
| triage assessor | scale · independence · verifiability · recommended strategy + why |
| search/explore worker | `path:line — symbol — ≤10-word note` per hit + `totals: <n> files` (or `No match.`) |

Failure returns are single structured lines, never essays:
`BLOCKED — what / evidence (excerpt + raw path) / what you tried / what you need`.

**Reviewer findings go to a FILE**, collision-proof name
`review-task<N>-<spec|quality|lens-<k>>-r<round>.md` — inline caps can never truncate findings.
Reviewer "read-only" means the REPO; `.orchestrate/` is the one place a reviewer writes.

## Workspace files (`.orchestrate/`, via `scripts/workspace`)

- `run.md` — resolved dimensions, budget, task, timestamp (written at kickoff)
- `task-N-brief.md` / `task-N-report.md` — per-task handoffs (report named off brief); briefs
  follow the priming anatomy and pass `scripts/brief-check` (`shared-token-economy.md`)
- `decisions.md` — cross-cutting decisions, one line each: ID + owner (small runs: keep in
  `run.md`). Briefs CITE IDs, never restate.
  Contradictions reconcile in the record FIRST, by the owner (integrator only when explicitly
  designated, never invents design intent), then propagate outward.
- `field-guide.md` — optional, created only on the first controller-accepted surprise (any
  WORKER-role report may append one `surprise:` line; controller curates), per-run scope, hard
  ≤40-line cap; entry criteria in `shared-token-economy.md`.
- `card-<k>.md` — parallel task cards
- `review-<b7>..<h7>.diff` — review packages
- `review-task<N>-<kind>-r<round>.md` — reviewer findings files
- `raw/` — full command/tool output, redirected at execution time (`shared-token-economy.md`)
- `toolbox.md` — this repo's probed orientation recipes (`scripts/toolbox`; read, don't re-probe)
- `progress.md` — THE LEDGER (below)
- `loop-<name>.md` — loop contracts

## The ledger (`progress.md`)

One line per gated unit, appended only after the gate passes:
```
Task 3: complete (commits a1b2c3d..e4f5a6b, review clean)
Card api: merged (gate: contract tests green)
Cycle 7: shipped PR #142 (verifier: works, evidence/run7.png)
```
Resume rule: on any restart/compaction, `cat progress.md` + `git log` are the truth; recollection
is not. The single most expensive observed failure is re-dispatching completed work. `git clean
-fdx` destroys the workspace → reconstruct from `git log`.

## Task cards (parallel/team writers)

```
Objective · Owned files (exclusive) · Requirements · Interface contract ·
Acceptance criteria · Out of scope · MERGE GATE: <exact integration precondition>
```
State advances only when the exit artifact exists; merge-readiness is judged by the gate, not by
anyone's assessment. Blocked cards carry an owner + next action or they're not "blocked", they're
abandoned.
