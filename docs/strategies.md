# Strategies

Nine orchestration strategies, each a named preset over the [dimensions](usage.md#dimensions) —
nothing in the skill reads a strategy name directly, so treat these as starting points you can
override, not fixed modes. Pick one via `strategy=<name>`, a saved `alias=` (see
[recipes.md](recipes.md#saved-aliases)), or let bare invocation triage for you
(see [usage.md#selection-priority](usage.md#selection-priority)).

Each section: **use when** it's the right fit · **how it runs** (the step flow) · **key mechanics**
worth knowing before you dispatch · **failure handling** · **composition overrides** that change
its behavior.

## staged

*(the default)* — `topology=staged planning=plan-first review=dual isolation=off trigger=once`

**Use when** you have a plan with mostly-independent tasks and sequential execution is fine —
this is the strategy triage falls back to.

**How it runs**: setup once per run (create `.orchestrate/`, read the whole plan in one pass to
batch any contradictions/ambiguities into a single upfront question, resume from `progress.md` if
one exists), then per task: brief → dispatch a **fresh** implementer subagent → (questions get
answered and it's re-dispatched) → implement/test/commit/self-review → spec review → fix loop until
clean → quality review → fix loop until clean → append a ledger line → next task. After all tasks,
one whole-branch review runs on the most capable model over the full diff, with its findings
resolved by a single fix subagent (never one fixer per finding).

**Key mechanics**: the controller never implements — every task gets a brief file and a fresh
context, never session history. The review package is always built from the task's recorded BASE
commit (`git rev-parse HEAD` before the implementer starts), not `HEAD~1`, which would truncate a
multi-commit task. Implementers return under 15 lines (status, commits, one-line test summary,
concerns, report path) — full detail lives in the report file.

**Failure handling**: `DONE` → review. `DONE_WITH_CONCERNS` → read the report; correctness/scope
issues get addressed before review. `NEEDS_CONTEXT` → supply it, re-dispatch the same model.
`BLOCKED` → the escalation ladder: context problem → more context; needs more reasoning → a more
capable model; task too large → split it; plan is wrong → escalate to the human. Never re-dispatch
unchanged.

**Composition overrides**: `engine=codex` turns implementer dispatches into `codex exec` calls while
reviews stay on Claude — cross-model review by construction (see [`xcli`](#xcli)). `review=panel:N`
swaps the quality review for an N-lens panel. `isolation=worktree` moves implementers into worktrees
when tasks touch overlapping areas and serialized merges are preferable to a shared tree.

## parallel

`topology=parallel review=dual isolation=worktree workers=3..5`

**Use when** tasks are genuinely independent and don't share files or mutable state, and speed
matters. Run the gate first: multiple independent problems that share files → that's `staged`
(or repartition until they don't); no shared files → `parallel`.

**How it runs**: partition the work along one axis (layer, component, concern, or — strongest for
writers — exclusive file ownership) and write a task card per worker in `.orchestrate/card-<k>.md`.
Dispatch all workers in one message with parallel tool calls, each with `isolation: worktree`, an
explicit model, and the repo's gitignored `.env*` copied into its fresh worktree (a new worktree has
none — builds fail mysteriously without it). Workers implement/commit in their own tree and return a
branch/PR ref plus a report. Reviews (dual, as in `staged`) run per worker as each finishes — don't
wait on the slowest worker to review the fastest. An integrator then merges gated branches in
dependency order, resolving seam conflicts and running the full suite after each merge.

**Key mechanics**: a card is `Objective · Owned files (exclusive) · Requirements · Interface
contract · Acceptance criteria · Out of scope · MERGE GATE`. Before dispatch, grep the cards' file
lists for overlap — any overlap means the partition is wrong, fix it or add an integrator-owned seam
file both depend on. Merge-readiness is judged by the gate, never by vibes. Cleanup is mandatory:
`git worktree remove` every finished tree and verify `git worktree list` is clean, plus kill any
per-worker dev servers — a leftover worktree pins its branch.

**Failure handling**: same escalation ladder as `staged`. On API overload, never spawn a duplicate
worker for the same card — resume or nudge the one that exists. Overlapping-write conflicts an
integrator can't resolve mechanically go back to the owning worker, never hand-merged by the
controller. Respect review bandwidth — don't open more PRs than the human can review; queue the
rest. A worker that finished with an unchanged tree just auto-removes its worktree; its report (a
no-op) is still information, not a failure.

**Composition overrides**: `workers=N` sets fan-out (3–5 is the sweet spot; scale only when work is
genuinely independent). `review=panel:N`/`consensus:N` swap the per-worker review shape.

## hierarchical

`topology=hierarchical review=dual models=orchestrator:strong,worker:cheap`

**Use when** work spans domains that each need real thinking plus their own worker fleet, or total
context far exceeds one window. Your context is the scarce resource — you hold conclusions;
sub-orchestrators hold their domain; workers hold one task.

**How it runs**: split into 3–7 independent partitions (fewer means you didn't need the level, more
means the brief was too vague), pick a depth mechanism, dispatch sub-orchestrators with a domain
scope, a worker budget (count + model tier), a required typed report (verdict + findings + artifact
paths, under 1500 tokens), and an explicit "must NOT do" list (no cross-domain edits, no scope
invention). Each sub-orchestrator samples structure cheaply before committing its own worker
fan-out. Aggregate per a declared strategy (union / synthesis / reduce) stated up front; gaps get a
follow-up partition, never a redo of everything.

**Key mechanics — the depth reality**: Claude Code subagents cannot spawn subagents, so depth comes
from exactly three mechanisms: (1) **teammates as sub-orchestrators** — a teammate is a full session
that can spawn its own foreground subagents, giving lead → teammates → subagents (3 levels;
teammates can't nest teams or run background subagents); (2) **workflow nesting** — a workflow
script can call `workflow()` exactly one level deep; (3) **the main conversation as recursion
stack** — you sequentially play each sub-orchestrator yourself, fanning out workers for domain A,
aggregating, then domain B (cheapest option, no extra sessions). Anthropic's managed agents cap
delegation at depth 1 too (flat rosters, max 20 agents, 25 threads) — the lesson is universal: wide
and shallow beats deep. For judgment calls, use blind parallel counsel: two different-lineage agents
(e.g. an opus reasoner plus a codex peer) on the same question in parallel, neither seeing the
other's answer, synthesized by you.

**Failure handling**: review gates apply at the level that produced the code — worker output goes
to its own sub-orchestrator's review; cross-domain integration is yours to review. Ledger the tree:
one line per sub-orchestrator completion with its artifact paths.

**Composition overrides**: token budget per branch drives quality more than anything else (it
explains ~80% of multi-agent quality variance) — give each branch an explicit effort tier rather than
a uniform one.

## team

`topology=team review=dual workers=3..5`

**Use when** workers must talk to each other mid-task — competing hypotheses, cross-layer features,
adversarial review debates. Experimental; cost scales roughly linearly per teammate. Requires
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`; without it, no teammates spawn and you fall back to
`parallel` or `hierarchical`.

**How it runs**: pick a preset composition rather than inventing one — `review` (3 reviewers:
security/performance/architecture), `debug` (3 investigators each owning one hypothesis, told to
disprove the others), `feature` (1 lead + 2 implementers, file-ownership split), `fullstack` (lead +
frontend + backend + tests), `research` (3 general-purpose on different angles), `security` (4
lenses: OWASP/auth/deps/secrets), or `migration` (lead + 2 implementers + 1 reviewer). Size to the
smallest team covering all dimensions (3–5 teammates, 5–6 tasks each) — three focused teammates beat
five scattered ones.

**Key mechanics**: teammates get CLAUDE.md/skills but not your conversation history — the spawn
prompt has to carry task specifics, and they're named so you can `SendMessage to:name`. Tasks, not
chat, carry state (shared task list with dependencies; status via `TaskUpdate`, never JSON in chat).
Direct messages beat broadcast (a broadcast is N messages — reserve it for genuine all-hands).
Risky work gets a plan-approval gate: spawn with "require plan approval" and the teammate stays
read-only until you approve, with your approval criteria set up front. Teams don't worktree-isolate
teammates — partition file ownership in the spawn prompts, or give write-heavy teammates their own
worktrees manually. For debug/review teams, each teammate must actively try to disprove the others'
theories; you synthesize and dedup (same file:line → merge; conflicting severity → higher wins).

**Failure handling**: `TeammateIdle`/`TaskCompleted` hooks (exit code 2 = send feedback, keep
working, or block completion) enforce gates mechanically when configured. A deadlocked pair gets one
of them a stub/partial result to unblock — don't let both sit idle.

**Known limits**: no nested teams · teammates can't run background subagents · `/resume` doesn't
restore in-process teammates (re-spawn instead) · task status can lag (nudge or fix manually) · the
lead is fixed · one team per session · shutdown is graceful but slow. Watch from the agent panel;
interrupt with Escape; steer early — an unattended team compounds wasted effort.

## workflow

`topology=workflow review=consensus/adversarial-verify budget=agents`

**Use when** the task outgrows turn-by-turn coordination: 20+ homogeneous items (audit every route,
migrate every component, review every changed file), findings that need cross-verification
(independent verify agents voting on each claim), or an orchestration worth saving and re-running as
a `/command`. Not for work needing mid-run human sign-off between stages — run each stage as its own
workflow instead.

**How it runs**: a JavaScript workflow script holds the plan — loops, fan-out, verification — and
the Claude Code runtime executes it in the background while your context holds only the final
result. Trigger via the Workflow tool, the `ultracode` keyword, or explicit user opt-in — never
launch one on inference. Pilot on a slice first (one directory, not the repo) to gauge tokens before
committing to the full run.

**Key mechanics**: an explicit agent budget capped in the script itself (loop-until-dry with a
dry-round counter, never `while(true)`) — the runtime's own cap (16 concurrent / 1000 total) is
advisory, not a substitute for your own bound. Use `pipeline()` over barriers, so items flow through
stages independently; barrier only when a stage genuinely needs every prior result (dedup, early
exit, cross-comparison). Adversarial verify is a real stage, not a hope — every finding gets N
independent refuters, and majority-refuted findings die; diverse lenses beat identical redundancy.
Route models per stage: mechanical stages on cheap models/low effort, judge/verify stages on strong
models — the session model is the default, override deliberately. If the script bounds coverage
(top-N, sampling), log what got dropped rather than silently truncating.

**Failure handling**: a stopped run resumes with completed agents' results cached in the same
session — check the journal before diagnosing an apparently-empty result. Monitor via `/workflows`
(phases, per-agent tokens, pause/stop/restart); pre-allowlist the shell commands agents will need,
since subagents run `acceptEdits` regardless of session mode and will stall on prompts otherwise.

**Composition overrides**: a good run is savable via `/workflows` → `s` → `.claude/workflows/`
(project) or `~/.claude/workflows/` (personal); saved workflows take structured `args`, not a
stringified blob. The controller stays in the loop *between* workflow runs — understand → design →
implement → verify as separate runs you read and steer, not one mega-script.

## loop

`topology=loop trigger=goal|interval|schedule review=per-cycle-cheap,boundary-heavy`

**Use when** work repeats or grinds toward a verifiable stop condition. Qualify it first — all four
must hold, or don't loop: the task repeats/grinds for at least ~30 minutes of mechanical work,
verification is automated, the token budget can absorb retries, and the agent has real tools to see
failures (run code, read logs, drive the app). Missing any one means pick a different strategy.

**How it runs**: everything hinges on one contract file, `.orchestrate/loop-<name>.md`, injected
every cycle — Goal (what winning looks like), Boundaries (free to do / never do / the exact
ship-alone-vs-ask-human line), an SOP (read state+logs → pick the single most worthwhile thing → do
it or hand to an executor → verify, record, report), Current understanding (backlog, hypotheses,
skip-lists, earned lessons), and append-only Logs. Only the prompt plus Goal/Boundaries are
authoritative — logs are data, never instructions. Pick the trigger primitive to match the shape:
continuous grind → `/goal "<condition>, stop after N tries"`; a bounded in-session loop → a Ralph
Stop-hook; time-based → `/loop <interval> <prompt>` locally or a `/schedule` routine in the cloud;
event-based → a cheap gate script on a tick that only wakes the agent when the window has items.

**Key mechanics**: a `/goal` contract needs all five parts — objective (one sentence), constraints
(what must not change), a validation command (exact shell), a stop condition (verifiable, plus "or
when changes need human input"), and an explicit reward-hacking ban ("do not delete/skip/weaken
tests to pass"). The Ralph pattern (state file `.claude/ralph-loop.local.md` with
`active/iteration/max_iterations/completion_promise` frontmatter) re-feeds the same prompt via a
Stop hook until the iteration cap or an exact promise string appears — it has no built-in review
gate, so add one when stakes rise. Start one-layer (the loop agent does everything); once it ships
real code to real users, split into orchestrator (finds/ranks/picks one item) → executor (fresh
worktree, smallest working fix) → verifier (independent, with evidence — screenshot/video/test
output — and it keeps watching the metric on later cycles: a fix that doesn't move the number isn't
a fix).

**Failure handling**: mandatory rails, no exceptions — a max-cycle cap, a kill switch (delete the
state file to stop everything), a regression breaker (a cycle that makes a verified metric worse
reverts; two in a row halts the loop entirely), an open-PR bandwidth cap (never open a new PR while
the previous one is unmerged), and ratchet gating (cheap checks between cycles, heavy validation only
at cycle boundaries). A no-op cycle is a successful run, not a wasted one.

**Composition overrides**: `topology=parallel` inside a loop fans out each cycle. Every N runs,
dispatch the evolve pass (`prompts/evolve.md`) — it reads recent logs and costs and pulls four
levers: fix contract drift, distill state (keep durable lessons, condense logs to a milestone spine,
never drop open items), lift repeated *deterministic* work into a script pre-stage, or improve the
metrics surface. A bilevel outer loop (evolve watching the inner loop's search patterns) is the
documented 5x multiplier — but only after the inner loop has earned trust.

## advisor

`models=advisor:strongest,worker:cheap review=dual`

**Use when** budget is constrained and a strong model's judgment is only needed rarely — the
expensive model stays out of the hot path entirely. Anthropic's published data: executor+advisor
reaches ~92% of the strong model's SWE-bench Pro score at ~63% of the cost, with the advisor
consulted about once per task.

**How it runs — two variants.** **Variant A (executor calls advisor, runtime steering)**: a cheap
executor runs every turn and does all the work; the advisor (strongest model) is exposed as an
on-demand consult the executor calls at an architecture fork, a debugging wall, or an "is this
approach right?" moment. The advisor thinks thoroughly but returns a concise verdict + rationale +
next step (under 500 tokens) and never edits files. Budget the consults (e.g. ≤2 per task) — an
executor that consults every turn has the roles inverted. **Variant B (planner writes, executor
runs — the plan.md handoff)**: the strong model does the highest-leverage step once, then leaves.
Interview first (what's the project for, what does good look like, what's being optimized for —
don't assume); read everything and review across four lenses (overbuilt/redundant → cut,
fragile/unclear → fix, missing for the goal → add, structure fights the goal → restructure); write
one plan file ranked by leverage (per change: what, why, which files, order, how to verify —
unknowns become pinned open questions answered by the human, never guessed); then a cheap model
executes step-by-step without the planner in the room, verifying each change as it goes — this is
effectively `staged` with `models=worker:cheap`. An optional premium close has the strong model
review the final diff.

**Key mechanics**: "turn count beats token price" is the load-bearing rule here — a too-cheap
executor takes 2–3× the turns and loses the savings the split was chosen for; mid-tier is the
executor floor for anything prose-driven, and the cheapest tier is only right for transcription-grade
work where the plan already contains the code.

**Failure handling**: same as `staged` for Variant B's execution phase. Variant A's advisor is
read-only by contract — a consult that starts editing files has broken the split.

**Composition overrides**: run Variant B before building on top of an existing project, when a
messy project needs simplifying (not extending), or *always* before handing a codebase to a cheaper
model — skip the review step and it just executes your existing mistakes faster.

## adversarial

`planning=adversarial models=planner:strong,counter:different-lineage,worker:cheap review=dual`

**Use when** the cost of a wrong plan dwarfs the cost of arguing about it — architecture choices,
migrations, security-sensitive designs, anything expensive to reverse. The plan gets attacked before
any code exists; a plan-veto gate made adversarial.

**How it runs — the four-step chain**: (1) **interview**, grill-style — relentless one-at-a-time
questions to the human until requirements stop moving (what's being built, what good looks like,
constraints, non-goals; ambiguity caught here is ~100× cheaper than in review); (2) **adversarial
planning** — the planner (strong model) drafts, a counter-model of a genuinely different lineage
(e.g. Codex via [`xcli`](#xcli), or a separately-prompted skeptic subagent) attacks it for wrong
assumptions, missing cases, simpler alternatives, and hidden risks, the planner revises, iterating to
consensus in ≤5 rounds — unresolved disagreements past round 5 become pinned open questions for the
human, never silent compromises; (3) **cheap execution** — the consensus plan runs as `staged` (or
`parallel`) with cheap workers; (4) **premium close** — the strong model reviews the final output
against the consensus plan.

**Key mechanics**: the attack prompt is what makes this work — the counter model must be told to
*refute* ("find the strongest reason this plan fails"), never to review politely; a default-agreeable
counter makes the whole chain decorative.

**Failure handling**: if the interview reveals the task is actually small, downgrade to `staged` and
say so rather than running the full chain on a task that didn't need it.

**Composition overrides / variants**: **blind parallel synthesis** — for a single decision rather
than a full plan, task two different-lineage agents on the same problem in parallel, neither seeing
the other's answer, and synthesize the best of both yourself (prevents anchoring, costs one extra
agent). **Judge panel** (`review=consensus:N`) — N independent attempts from different angles, scored
by parallel judges; build from the winner and graft the runners-up's best ideas — good for wide
solution spaces like design or naming. **Consensus voting on findings** — N verifiers vote
real/not-real per claim, majority rules; this is the same mechanism `workflow`'s adversarial-verify
stage uses, and it's usable standalone anywhere. Debate multiplies planning cost by roughly
`rounds × 2 models` — worth it when execution cost or blast radius is high; skip it for anything a
single strong-model plan review would already catch.

## xcli

`engine=codex|grok|mixed` — usually layered as a dimension on another strategy rather than run
standalone (e.g. `strategy=staged engine=codex`, `strategy=adversarial counter=codex`).

**Use when** you want a genuinely different model lineage — cross-validation, a separate
subscription quota, or a CLI's own sandbox (Codex) — at the cost of serialization overhead and zero
shared context (the prompt has to carry everything; the external CLI sees nothing of your session).

**How it runs**: one task per launch (split big jobs); one git worktree per concurrent run, never two
engines in the same tree, with `.env*` copied in. Runs take minutes with no timeout, so background
them (`run_in_background`) and poll the output file rather than blocking the controller.

**Key mechanics per engine** — verify flags before scripting (`<cli> --help` once per session; CLIs
drift):
- **Codex** (`codex exec`) — the most script-friendly. `codex --version && codex login status` as
  preflight; `--sandbox workspace-write`, `-m <model> -c model_reasoning_effort=low|medium|high|
  xhigh|max|ultra` (medium default; `ultra` fans out Codex-side subagents — a fan-out decision,
  not an effort bump), `-o <file>` for output, `--output-schema` for validated structured output, `--json`
  for JSONL events. `</dev/null` is **mandatory** in scripts — an open stdin makes Codex wait
  forever; for a long prompt, pipe `- < task.md` instead. Approvals via `-a
  untrusted|on-request|never`; network inside the sandbox via
  `-c sandbox_workspace_write.network_access=true`. Never `--dangerously-bypass-approvals-and-sandbox`.
  Follow-up in the same session: `codex exec resume --last "…" </dev/null`. Sessions live under
  `$CODEX_HOME` (default `~/.codex`); Codex is also available as an MCP server (`codex mcp-server`).
- **Grok** (`grok -p`) — `--output-format plain|json|streaming-json`; sessions via `--cwd
  <path> -m <model> -s <uuid>` (the session id must be a UUID on CLI ≥0.2.x); resume via `-r <id>`
  or continue-last via `-c`. Models: the API flagship is `grok-4.5` (500k context, coding/agentic,
  reasoning effort `low|medium|high` with high default), but the CLI ships its own shorter list —
  run `grok models` before pinning (0.2.101 exposes only `grok-composer-2.5-fast` and
  `grok-build`). Approval is all-or-nothing (`--always-approve`) — prefer read-only tasks, or
  babysit it. Sessions on disk at `~/.grok/sessions`; a long-lived JSON-RPC surface exists via
  `grok agent stdio` (ACP). No reasoning-effort flag in the CLI; effort is an API-side knob.
- **Claude Code as a subprocess** (for symmetry or a separate account) — `claude -p --bare
  --output-format stream-json --max-turns N --model <tier> --permission-mode acceptEdits --agents
  '{"worker":{...}}' "task"`. `--bare` disables auto-discovery for scripts/CI (auth via env);
  `--json-schema` validates output. A background fleet is monitored via `claude agents --json`,
  `claude logs <id>`, and `claude attach <id>` to step into a blocked one.

**Failure handling**: review the diff yourself (or via your normal review gate) before accepting —
external engines don't inherit your review discipline. A rate limit hit gets reported to the user,
never retried in a loop against a subscription quota. Auth is always the user's
(`codex login`/grok cookie/`claude` login) — never read or copy credential files.

**Composition overrides**: the division-of-labor heuristic — Claude for reasoning/architecture/
review, Codex (GPT lineage) for heavy implementation and an honest peer counter, Grok for a fast
second opinion or search-adjacent tasks. For cross-validation, send the same review to two engines,
dedup the findings, and keep the union (conflicting severity → the higher one wins).
