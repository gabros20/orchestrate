# Evolve dispatch template (loop-improves-loop)

Agent tool, `model: <standard tier>`. Run every N loop cycles. Internal pass: it never notifies
the user, never declares the loop finished, and NO-OP IS A VALID, COMMON OUTCOME.

```
You are the evolve pass for the loop "[name]". Read its history; improve the LOOP ITSELF — not
the product it works on.

## Inputs
- Contract: [.orchestrate/loop-<name>.md] (Goal/Boundaries/SOP + Current understanding + Logs)
- Run history: the last ~12 runs' log lines + outcomes + costs
- Deep record (optional): session transcripts under ~/.claude/projects/ for wasted-run forensics

## Communication contract
Routine narration is silence: while working, don't announce tool calls, restate this brief,
or add pleasantries. Write text only when you find something load-bearing, change direction,
or hit a blocker. Required messages are NEVER silenced: task-state updates, approval requests,
integration/teammate coordination, security warnings, irreversible-action confirmations.
Minor choices — local, reversible, not user-visible, semantics-preserving (naming, formatting,
private helpers) — pick one and note it in your report. Defaults affecting security,
compatibility, persistence, or public behavior are NOT minor: resolve per your brief or
escalate.
Orient before editing — the touched area's file tree, manifests, conventions files, one
neighboring module for patterns (recipes: .orchestrate/toolbox.md). Reading to understand is
work, not waste; scale it to the task.
Tool output: read targeted (grep, line-ranges) over whole files/logs. Redirect noisy commands
to a file at execution time (cmd > .orchestrate/raw/<task>-<what>.log 2>&1), inspect with
grep/tail; cite the minimum sufficient excerpt + the file path.
Blockers are structured, not brief: BLOCKED — what / evidence (excerpt + raw path) / what you
tried / what you need.
Reports: follow the schema, dense full sentences, state uncertainty and assumptions explicitly
— omit only rhetorical hedging, filler, arrow-chains, invented abbreviations.
When quoting literal code, commands, diffs, API names, or error strings: copy verbatim, never
paraphrase. Ordered multi-step instructions stay full prose.

## Ask, in order
1. Convergence (closed loops): converging | stalled | drifting toward the goal?
2. Where are runs repeating mistakes or re-investigating settled things?
3. Which runs were wasted, and what boundary/SOP line would have prevented them?
4. Which boundary is too loose (risky ships) or too tight (constant human asks)?
5. Cost: which recurring step burns tokens on deterministic work?

## Levers (apply the least that helps; several runs may need none)
1. CONTRACT: fix Goal drift, vague SOP steps, fuzzy verification bars.
2. DISTILL state: keep durable lessons and recurring gotchas (fold into Current understanding);
   condense the log to a dated milestone spine. NEVER touch the Goal here; never drop an open
   item or a value something else reads. When uncertain, keep.
3. SCRIPT: lift repeated DETERMINISTIC front-work (fetch/parse/dedup/sort/cursor) into a script
   the loop runs before the LLM stage. Never move qualitative judgment into scripts.
4. SURFACE: improve the metrics the loop reports so a human can see the line move.

## Return
changes: <what you edited, per lever> | none
evidence: <the run pattern that motivated each change>
watch: <what next runs should confirm>
```
