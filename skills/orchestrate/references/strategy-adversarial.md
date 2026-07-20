# adversarial — harden the plan by debate before cheap execution

Purpose: Harden a high-stakes plan through independent proposals, critique, and synthesis before execution.

Read when:
- Failure is costly enough to justify debate or cross-model challenge.

Skip when:
- The task is routine, low risk, or already has an approved plan.

Inputs:
- Problem statement, constraints, independent planner roles, judge, and decision deadline.

Produces:
- Competing plans, explicit attacks, adjudication, and a hardened executable plan.

Preset: `planning=adversarial models=planner:strong,counter:different-lineage,worker:cheap review=dual`.
Use when the cost of a wrong plan dwarfs the cost of arguing about it: architecture choices,
migrations, security-sensitive designs, anything expensive to reverse. The plan gets attacked
BEFORE any code exists — a plan-veto gate made adversarial.

Prompt: `prompt-planner-debate.md`.

## The four-step chain

1. **Interview** (grill-style): relentless one-at-a-time questions to the human until requirements
   stop moving — what's being built, what good looks like, constraints, non-goals. Plan mode on
   steroids; ambiguity caught here is 100x cheaper than in review.
2. **Adversarial planning**: the planner (strong model) drafts the plan; a counter-model of
   DIFFERENT lineage (e.g. Codex via `strategy-xcli.md`, or a separately-prompted skeptic
   subagent) attacks it — wrong assumptions, missing cases, simpler alternatives, hidden risks.
   Planner revises. Iterate to consensus, **≤5 rounds**; unresolved disagreements after 5 become
   pinned OPEN QUESTIONS for the human, not silent compromises. The attack prompt matters: the
   counter must be told to REFUTE ("find the strongest reason this plan fails"), not to review
   politely — default-agreeable counters make the whole chain decorative.
3. **Cheap execution**: the consensus plan runs as `staged` (or `parallel`) with cheap workers.
4. **Premium close**: the strong model reviews the final output against the consensus plan.

## Variants

- **Blind parallel synthesis** (for a decision, not a full plan): task two different-lineage
  agents on the same problem in parallel, neither seeing the other's answer; you synthesize the
  best of both. Prevents anchoring; costs one extra agent.
- **Judge panel / `review=consensus:N`**: N independent attempts from different angles, scored by
  parallel judges; build from the winner, graft the runners-up's best ideas. For wide solution
  spaces (design, naming, API shape).
- **Consensus voting on findings**: N verifiers vote real/not-real per claim; majority rules.
  This is the workflow strategy's adversarial-verify stage, usable anywhere.

## Cost honesty

Debate multiplies planning cost ~(rounds × 2 models). Worth it when execution cost or blast
radius is high; skip for anything a single strong-model plan-review would catch. If the interview
(step 1) reveals the task is actually small — downgrade to `staged` and say so.
