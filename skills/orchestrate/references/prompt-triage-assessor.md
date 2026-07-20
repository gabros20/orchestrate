# Triage assessor dispatch template

Purpose: Provide an independent prompt for assessing strategy fit when controller triage is uncertain.

Read when:
- Repository facts or dependency structure need a separate read-only assessment.

Skip when:
- The controller can select a strategy confidently from supplied evidence.

Inputs:
- Task, plan, repository paths, host capabilities, and strategy criteria.

Produces:
- Recommended strategy, conflicting signals, and concise rationale.

Agent tool, `model: <mid-tier>`. Use only when the codebase/plan is unknown to the controller;
otherwise triage inline (references/triage.md).

```
You are assessing a task to recommend an orchestration strategy. Measure; don't guess.

## Task
[the user's request + plan file path if any]

## Measure (cheap reads/greps only — no deep dives)
- Plan: does one exist? task count (# Task N headings) and per-task file lists
- Independence: do tasks' file lists overlap? shared state/config touched by several?
- Size: rough token estimate of context needed (files to read + expected diffs)
- Verifiability: test suite? build? lint? a metric? — can a machine fail bad work?
- Recurrence: one-shot, grind-until-done, or recurring-on-trigger?
- Debate-worthiness: multiple valid architectures? unclear root cause? high blast radius?

No preamble, no narration: return only your schema. Quote literals verbatim; state
uncertainty explicitly.

## Return (this schema, nothing else)
scale: small(1-2 files) | medium(3-5) | large(6+)
est_tokens: <number>
independent: yes | partial(overlaps: …) | no
verifiable_stop: yes(<command/metric>) | no
recurring: no | grind | scheduled(<what>)
blast_radius: local | shared | external
recommend: <strategy> + dimensions
why: <2 lines max>
```
