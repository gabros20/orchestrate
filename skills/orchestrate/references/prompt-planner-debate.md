# Adversarial planning — the two debate prompts

Purpose: Provide an independent proposal or critique prompt for adversarial planning.

Read when:
- The adversarial strategy assigns planner or challenger roles.

Skip when:
- The plan is already approved and execution has begun.

Inputs:
- Problem statement, constraints, assigned stance, evidence, and decision deadline.

Produces:
- Independent proposal or attack with assumptions, failure cases, and recommendation.

## Counter/refuter prompt (the one that decides whether the chain works)

Dispatch to a DIFFERENT-lineage model (codex peer, or an independently-prompted subagent).

```
You are the counter-planner. A plan is attached. Your job is to REFUTE it — find the strongest
reasons it fails. You are not a polite reviewer; a plan you wave through and later breaks is
your failure.

## Plan
[the current plan draft — full text or path]

## Attack surfaces (cover all, report only real hits)
- Assumptions: which stated/unstated assumptions are wrong or unverified?
- Missing: requirements, failure modes, migrations, rollbacks, edge cases it doesn't handle
- Simpler: is there a materially simpler design that meets the same requirements? Sketch it.
- Risk: the single likeliest way this plan fails in production; the most expensive-to-reverse step
- Verification: which steps have no real check — where would bad work pass unnoticed?

## Rules
- Every attack names its evidence (file, requirement, constraint) — no vibes.
- Rank attacks by expected damage. Concede explicitly what the plan gets right (one line).
- If, after genuine effort, you cannot materially attack it: say CONSENSUS and why.

No preamble, no narration: return only your schema. Quote literals verbatim; state
uncertainty explicitly.

## Return
ATTACKS: ranked list, each: claim · evidence · suggested fix
CONSENSUS: yes|no — if no, the one issue that most blocks it
```

## Planner revision prompt

```
The counter-planner's attacks are attached. For EACH: accept (revise the plan, note the change)
or rebut (with evidence — "I considered it" is not evidence). Produce the revised plan with a
CHANGELOG section listing accepted/rebutted per attack. Unresolved after this round → carry as a
pinned OPEN QUESTION, do not silently drop.
```

Controller loop: draft → counter → revise → counter … **≤5 rounds** or CONSENSUS. Surviving open
questions go to the human before execution. Then run the consensus plan via `staged`/`parallel`,
premium final review per `strategy-adversarial.md`.
