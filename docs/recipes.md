# Recipes

Copy-paste starting points. Start with a saved alias if one fits; otherwise compose dimensions
directly on any strategy — every recipe below is one invocation, no code involved. Explicit
`strategy=`/dimension flags always override an alias on the same invocation; `alias=` always
overrides auto-triage. For what each dimension value means, see
[usage.md#dimensions](usage.md#dimensions); for how each strategy actually runs, see
[strategies.md](strategies.md).

The examples use `/orchestrate` as shorthand. Use `$orchestrate` in Codex or the invocation form
provided by your client.

## Saved aliases

Five built-in presets, each a named bundle of dimensions, defined in `config.yaml`:

### `red-team` — careful build

```
/orchestrate plan.md alias=red-team
```
Expands to `strategy=adversarial review=panel:3 models={planner:strongest,worker:sonnet}`.
**What happens**: the plan gets attacked by a different-lineage counter-model before any code
exists (see [strategies.md#adversarial](strategies.md#adversarial)), then the consensus plan
executes with cheap workers under a 3-lens review panel instead of the usual dual gate.
**Reach for it when**: the plan is high-stakes or expensive to reverse and you want both the
plan *and* the output hardened — architecture decisions, migrations, security-sensitive designs.

### `codex-grind` — cheap bulk execution, cross-model review

```
/orchestrate plan.md alias=codex-grind
```
Expands to `strategy=staged engine=codex review=dual models={reviewer:sonnet}`.
**What happens**: `staged`'s per-task cycle runs, but each implementer dispatch becomes a `codex
exec` call (see [strategies.md#xcli](strategies.md#xcli)) while spec/quality review stay on Claude
— cross-model review by construction, not an afterthought.
**Reach for it when**: you want Codex's throughput on implementation but don't want to give up an
independent-lineage review of its output.

### `swarm` — fast independent fan-out

```
/orchestrate plan.md alias=swarm
```
Expands to `strategy=parallel workers=4 review=spec isolation=worktree`.
**What happens**: the plan is partitioned into 4 worker cards, each isolated in its own git
worktree, reviewed for spec compliance only (no quality pass), then integrated.
**Reach for it when**: tasks are genuinely independent, don't touch shared files, and speed matters
more than a full review — minimal ceremony by design.

### `afk` — walk-away grind with hard rails

```
/orchestrate "<goal description>" alias=afk
```
Expands to `strategy=loop trigger=goal budget={cycles:20,open_prs:1} review=dual`.
**What happens**: a Ralph/goal loop runs cycle after cycle against a verifiable stop condition, capped
at 20 cycles and one unmerged PR at a time, with a dual review gate on each cycle's diff.
**Reach for it when**: the work grinds toward something checkable (tests green, a metric hit) and
you want to walk away and come back to either a finished result or an honest stop with state
recorded — see [strategies.md#loop](strategies.md#loop) for the mandatory rails this alias is
built on.

### `architect` — big-model thinking, small-model doing

```
/orchestrate "<task>" alias=architect
```
Expands to `strategy=advisor models={advisor:strongest,worker:sonnet}`.
**What happens**: a cheap worker does all the execution; the strongest available model is consulted
only at decision points, never runs in the hot path (see
[strategies.md#advisor](strategies.md#advisor) — Anthropic's published number is ~92% of the strong
model's quality at ~63% of the cost).
**Reach for it when**: budget is the binding constraint and most of the task is mechanical, with
just a few moments that need real judgment.

## Scenario recipes

Copy-paste commands for specific situations that don't map to a saved alias.

**Panel of experts debating a question**
```
/orchestrate "should we adopt <X>?" strategy=team workers=3
```
Spins up a small team (pick a preset composition like `research` or `debug` — see
[strategies.md#team](strategies.md#team)) that argues the question out loud via shared tasks and
direct messages, rather than one agent reasoning alone.

**Adversarial plan review**
```
/orchestrate plan.md strategy=adversarial
```
Runs the full four-step chain — interview, adversarial planning with a different-lineage counter,
cheap execution, premium close — before a line of code is written. Use when a wrong plan would cost
far more than the debate.

**Multi-lens review of anything**
```
/orchestrate <plan-or-task> review=panel:3
```
Add `review=panel:3` (or any N) to **any** strategy to replace its default review gate with N
reviewers, each assigned one lens (security/performance/architecture/testing/a11y/…), deduped by
file:line with conflicting severities resolved to the higher one.

**Research with evaluated claims**
```
/orchestrate "research <topic>" strategy=hierarchical review=consensus:3
```
`hierarchical` fans domain-level research out to sub-orchestrators; `consensus:3` has three
independent verifiers vote real/refuted on each claim before it's trusted, so findings survive
scrutiny rather than being taken on the first agent's word.

**Mass migration or audit**
```
/orchestrate plan.md strategy=workflow
```
For 20+ homogeneous items (every route, every component, every changed file). **Pilot on one
directory first** to gauge token cost before committing the script to the full repo — see
[strategies.md#workflow](strategies.md#workflow).

**Cheap bulk implementation with cross-model review**
```
/orchestrate plan.md strategy=staged engine=codex
```
The unaliased form of `codex-grind` above — useful when you want `staged`'s default dual review
(not `codex-grind`'s reviewer-pinned-to-sonnet variant) alongside Codex doing the implementation.

**Walk-away goal loop with rails**
```
/orchestrate plan.md strategy=loop trigger=goal:"tests green" budget=cycles:15
```
A bounded grind: the loop repeats until the stated condition holds or 15 cycles pass, whichever
comes first. Always pair a `goal:` trigger with the mandatory loop rails (max-cycle cap, kill
switch, regression breaker, open-PR cap) — `strategy=loop` sets these up by default; don't disable
them to save a step.

**Second opinion from another CLI**
```
/orchestrate "<task>" strategy=xcli engine=grok
```
or, layered on an existing strategy instead of standalone:
```
/orchestrate plan.md strategy=adversarial counter=codex
```
Routes a task (or one role within another strategy) to an external CLI for a genuinely
different-lineage read. See [strategies.md#xcli](strategies.md#xcli) for the per-CLI flags — `codex
exec` is the most script-friendly, `grok -p` is the fastest for a quick second look.

## Input-side tooling (optional, pairs well)

Heavy-terminal-output or huge-repo workflows benefit from external input-side tooling the skill
deliberately doesn't bundle (keeping itself dependency-free): output-filtering proxies (RTK),
tool-result sandboxes (context-mode), and symbol-navigation/code-search MCPs (token-savior,
claude-context). See `docs/research/token-optimization.md` for what each measured.

## Defining your own alias

Aliases live in `skills/orchestrate/config.yaml` as named dimension bundles — any dimension valid
in [usage.md#dimensions](usage.md#dimensions) is valid under an alias:

```yaml
aliases:
  # ... existing aliases ...

  my-alias:
    strategy: staged
    engine: codex
    review: panel:3
    models: { reviewer: opus }
```

Invoke it the same way as a built-in: `/orchestrate plan.md alias=my-alias`. Explicit
`strategy=`/dimension flags on the invocation still override the alias's value for that one field,
so an alias is a baseline, not a lock. There's no registration step beyond adding the YAML entry —
`config.yaml` is read at invocation time.
