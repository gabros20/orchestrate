# advisor — expensive judgment, cheap execution

Purpose: Separate expensive reasoning or review from cheaper repeated execution.

Read when:
- A strong model should plan or advise occasionally while a cheaper worker executes most steps.

Skip when:
- Every step needs the strongest model or consultation overhead exceeds the saving.

Inputs:
- Advisor question, executor state, consultation cadence, budget, and escalation rules.

Produces:
- Bounded advice, executor decisions, and consultation ledger.

Preset: `models=advisor:strongest,worker:cheap review=dual`.
Two verified variants. Both keep the strong model OUT of the hot path — it plans or advises;
cheap models burn the tokens. Anthropic's published data: executor+advisor ≈ 92% of the strong
model's SWE-bench Pro score at ~63% of the cost; the advisor is consulted ~once per task.

Prompt: `prompt-advisor.md`.

## Variant A — executor calls advisor (runtime steering)

- The **executor** (cheap/mid model) runs every turn and does all the work.
- The **advisor** (strongest model) is exposed as an on-demand consult: the executor calls it
  when it hits an architecture fork, a debugging wall, or a "is this approach right?" moment.
- Advisor contract: think thoroughly, return a CONCISE conclusion the executor can act on
  (verdict + rationale + next step, <500 tokens). It never edits files.
- Budget the consults (e.g. ≤2 per task); an executor that consults every turn has the roles
  inverted. In Claude Code: a pinned-model subagent ("deep-reasoner") the main session delegates
  to — or the inverse, where the cheap session is the main loop.

## Variant B — planner writes, executor runs (plan.md handoff)

The strong model does the highest-leverage step once — review + plan — then leaves the room:
1. **Interview first**: ask what the project is for, what good looks like, what's being optimized
   for. Don't assume.
2. **Read everything**, then review across four lenses: overbuilt/redundant → cut · fragile/
   unclear → fix · missing for the goal → add · structure fights the goal → restructure.
3. **Write ONE plan file** ranked by leverage: per change — what, why, which files, order, how to
   verify. Unknowns become OPEN QUESTIONS pinned at the top, answered by the human, never guessed.
4. **Cheap model executes** step-by-step without the planner in the room, verifying each change
   as it goes (this is `staged` with `models=worker:cheap`).
5. Optional premium close: the strong model reviews the final diff (quality gate stays premium).

When to run B: before building on top of an existing project · when it grew messy and needs
simplifying, not extending · ALWAYS before handing a codebase to a cheaper model (skip the review
and it executes your existing mistakes faster).

## Server-side alternative (API pipelines)

When building *programmatic* pipelines directly against the API, the native advisor tool
(`advisor_20260301`, beta header `advisor-tool-2026-03-01`) runs Variant A server-side in ONE
call: the executor consults the advisor mid-task with shared context, no client orchestration
(published: +2.7pp SWE-bench Multilingual at −11.9% cost vs Sonnet-alone; consults are 400–700
tokens). Inside Claude Code, the subagent shape on this page remains the path.

## Model routing note

"Turn count beats token price" — a too-cheap executor takes 2–3× the turns and loses the savings.
Mid-tier is the executor floor for anything prose-driven; the cheapest tier only transcribes
plans that already contain the code. See `shared-model-routing.md`.
