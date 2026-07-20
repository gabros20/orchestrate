# parallel — worktree-isolated fan-out with an integrator

Purpose: Fan independent tasks out to isolated workers and integrate their results safely.

Read when:
- Tasks share no files or can be partitioned into non-overlapping ownership.

Skip when:
- Workers need shared mutable state or unresolved contracts between their tasks.

Inputs:
- Partitioned task cards, worker count, isolation mode, integration owner, and review mode.

Produces:
- Concurrent worker results, integration sequence, conflicts, and gated merge.

Preset: `topology=parallel review=dual isolation=worktree workers=3..5`.
N workers execute independent tasks simultaneously, each in its own git worktree; an integrator
merges. Physical isolation prevents file conflicts, NOT logical ones — partitioning does that.

Read with this file: `shared-isolation.md`, `shared-contracts.md`, `shared-review-gates.md`.
Prompts: `prompt-implementer.md` (per worker), `prompt-integrator.md`.

## Gate: is parallel actually right?

Decision tree (run it, don't skip it):
```
multiple independent problems?
  no  → one agent sees everything (solo/staged)
  yes → do they share files or mutable state?
          yes → sequential (staged) — or repartition until they don't
          no  → parallel
```
Then partition along ONE axis — by layer, by component, by concern, or **by file ownership**
(strongest for writers: each worker owns an exclusive file set, written into its brief).

## Task cards (narrow contracts)

Each worker gets a card in `.orchestrate/card-<k>.md`:
```
Objective · Owned files (exclusive) · Requirements · Interface contract (what other tasks expect)
Acceptance criteria · Out of scope · MERGE GATE: <the exact condition allowing integration>
```
A card cannot advance without its artifact existing; merge-readiness is judged **by the gate, not
vibes**. Return contract per worker: verdict first, <1000 tokens, branch/PR ref + report path.

## Flow

1. Partition → write cards (priming anatomy applies; pin `read:` pointers with `@ <sha>` — every
   worker gets its own worktree; run `scripts/brief-check` per card) → check no two cards own the
   same file (grep the lists; overlap → fix the partition or add an integrator-owned seam file
   both depend on).
2. Dispatch workers (single message, parallel tool calls), each with `isolation: worktree`, an
   explicit model, its card path, and the repo's gitignored `.env*` copied into the fresh worktree
   (a fresh worktree has none — builds fail mysteriously without it).
3. Workers implement/test/commit in their tree and return: PR-or-branch ref + summary. Ledger and
   knowledge writes stay with YOU, not the workers.
4. **Review per worker** (dual, as staged) — reviews can run as each worker finishes; don't barrier
   on the slowest worker before reviewing the fastest.
5. **Integrate**: dispatch the integrator to merge gated branches in dependency order, resolve
   seam conflicts, run the full suite after each merge. Overlapping-write conflicts an integrator
   can't resolve mechanically → back to the owning worker, never hand-merged by the controller.
6. **Cleanup is mandatory**: `git worktree remove` each finished tree (a leftover pins its branch);
   verify `git worktree list` is clean; kill any per-worker dev servers. Before removal, anything
   still needed from a worktree's `.orchestrate/raw/` is cited (excerpt) in the task report or
   copied next to it (`shared-token-economy.md`).

## Limits & failure handling

- 3–5 workers is the sweet spot; scale only when work is genuinely independent.
- Worker BLOCKED → same escalation ladder as staged. On API overload NEVER spawn a duplicate
  worker for the same card — resume/nudge the one that exists (`shared-safety-rails.md`).
- Respect review bandwidth: don't open more PRs than the human can review; queue the rest.
- A worker that finished with an unchanged tree = its worktree auto-removes; still collect its
  report (a no-op result is information).
