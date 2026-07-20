# /orchestrate — research record, learnings, and design grounding

> **Status:** implemented — this research fed the **v1.0.0** initial release (design: [../designs/v1.0.0-initial-architecture.md](../designs/v1.0.0-initial-architecture.md) · [CHANGELOG](../../CHANGELOG.md)).

Extracted context for the `orchestrate` skill: every source consulted, what each taught, the
convergent principles, and a traceability map from design decisions back to evidence. Built
2026-07-10. Companion docs: [../designs/v1.0.0-initial-architecture.md](../designs/v1.0.0-initial-architecture.md) (the build plan/design) and the visual guide, now [site/index.html](../../site/index.html) (orchestrate-skill.vercel.app).

**Method note.** The research itself was run as an orchestration: X threads/articles/images pulled
via the x-relay CLI (serialized, rate-limit-respecting), four parallel research subagents (Claude
docs, external-CLI docs, web state-of-the-art, skills-registry mining), a GitHub-mining subagent
for raw source, plus /find-skills registry sweeps. Three subagents died on a 529 overload and were
recovered by nudging the SAME agents to retry (never duplicating) — the incident that hardened the
overload rule in `shared-safety-rails.md`.

---

## 1. Source inventory

### Official — Anthropic / Claude Code
| Source | What it is |
|---|---|
| "Getting started with loops" (X Article by @ClaudeDevs / delba_oliveira, x.com/i/article/2074204645845839872) | The Claude Code team's loop taxonomy |
| code.claude.com/docs/en/agents | Parallel-work landscape: subagents vs agent view vs teams vs workflows |
| code.claude.com/docs/en/workflows | Dynamic workflows (full) |
| code.claude.com/docs/en/agent-teams | Agent teams (full) |
| code.claude.com/docs/en/cli-reference + /headless + /agent-view | Headless flags, session flags, background-fleet monitoring |
| platform.claude.com/docs/en/managed-agents/multi-agent | Server-side coordinator/roster model |
| anthropic.com/engineering/multi-agent-research-system | The orchestrator-worker research system paper |
| ClaudeDevs thread 2074606058128224365 (+2 continuations, + diagrams) | Advisor & orchestrator patterns with SWE-bench Pro data |

### X posts & articles (user-provided + search finds)
| Source | Author |
|---|---|
| 2075258271947210875 "fable 5 subagent swarm" (+diagram) | @shannholmberg |
| 2074817317184397381 "Fable review loop" (+diagram) | @shannholmberg |
| 2075284848022114770 "Meta LOOP" (+diagram) | @Saboo_Shubham_ |
| 2075172031893545079 4-step architect/builder chain | @Psalteric |
| Article "Loop Engineering: The Karpathy Method" (via 2072329149520232639) | @0xCodila |
| Article "What I learnt after running loops for 1 month" (via 2075179471951614381) | @jasonzhou1993 |
| 2072436501263339841 Fable orchestrator + Opus/Sonnet/Codex tiers | @diegocabezas01 |
| 2074875092090470469 Codex plugin inside Claude Code | @cjzafir |
| 2024874219662905676 PRD → issues → Ralph loop pipeline | @mattpocockuk |

### GitHub — skills & repos (raw source)
| Source | What was mined |
|---|---|
| davidondrej/skills: codex-subagent, goal-loop, handoff, fable-safe-prompt | External-CLI subagent recipe, /goal contract, handoff protocol |
| obra/superpowers: subagent-driven-development (+ scripts, writing-plans, requesting-code-review) | The SDD mechanics `staged` is built on |
| anthropics claude-code plugin `ralph-wiggum` | Stop-hook loop implementation |
| superdesigndev/loopany-platform | Scheduled loops, exec/evolve/edit roles, evolve levers |
| AI-Builder-Club/skills (loop-engineer, verifier-setup, new-loop, dev-local-setup) | Evidence-based /verify, file-KB substrate, worktree contract |

### skills.sh registry (12 mined via subagent)
shinpr/claude-code-workflows@subagents-orchestration-guide · wshobson/agents (team-composition,
task-coordination, team-communication, multi-reviewer) · belumume@rlm-orchestrator ·
boshu2/agentops@evolve · bassimeledath@dispatch · aradotso@edict-multi-agent-orchestration ·
affaan-m/ecc@team-agent-orchestration · thebeardedbearsas@parallel-worktrees ·
hjewkes@dispatching-parallel-agents · qodex-ai@multi-agent-orchestration ·
andrelandgraf@ralph-loop

### External CLI docs
docs.x.ai/build/cli/headless-scripting (grok) · learn.chatgpt.com developer-commands + pinned
`codex --help` v0.136.0 (codex) · code.claude.com cli-reference (claude headless)

### Web state-of-the-art (subagent report)
humanlayer.dev "Brief History of Ralph" · ralph-wiggum.ai · re-cinq.com BMAD/Claude-Flow/Gastown
comparison · addyosmani.com "code agent orchestra" · disler/claude-code-hooks-multi-agent-observability
· claudefa.st agent-teams guide · codex.danielvaughan.com three-CLI toolkit

---

## 2. Key learnings by cluster

### 2a. Official Claude Code / Anthropic

- **Loop taxonomy** (loops article): turn-based / goal-based (`/goal` + evaluator model checks the
  stop condition each time Claude tries to stop) / time-based (`/loop`, `/schedule`) / proactive
  (composition + dynamic workflows + auto mode). Manage tokens by: right primitive per job, clear
  stop criteria, pilot before large runs, scripts for deterministic work, `/usage` · `/goal` ·
  `/workflows` for observability.
- **Parallel-work landscape** (agents doc): four surfaces differ by WHO coordinates — subagents
  (Claude, in-conversation), agent view (you, background sessions), teams (a lead agent),
  workflows (a script). Worktrees isolate FILES; that's orthogonal to who coordinates work.
- **Dynamic workflows**: script-holds-the-plan; results live in script variables not context;
  16 concurrent / 1000 agents caps; resumable with cached agent results; save runs as commands;
  25-agent/1.5M-token advisory warning; workflow subagents always run acceptEdits.
- **Agent teams**: experimental, env-gated; shared task list + mailbox + file locking; no nested
  teams; teammates can't run background subagents; plan-approval requests; TeammateIdle /
  TaskCompleted hooks (exit 2 = block + feedback); 3–5 teammates, 5–6 tasks each; teams do NOT
  worktree-isolate — partition file ownership.
- **Managed agents** (server): delegation depth is EXACTLY 1 ("depth > 1 is ignored"), 20 agents,
  25 threads — flat rosters everywhere; escalation = calling a more capable agent, not nesting.
- **Headless claude**: `claude -p --bare` (recommended for scripts; auth via env), `--output-format
  stream-json`, `--json-schema` (validated `structured_output`), `--agents '<json>'` (dynamic
  subagent defs), `--max-turns`, `--max-budget-usd`, `--permission-mode dontAsk` for CI; background
  fleet via `claude --bg` + `claude agents --json` + `claude logs <id>`; session resume is
  cwd-scoped. The `~/.claude/projects/<cwd>/<session>.jsonl` transcript path is a convention, NOT
  documented — verify before scripting against it.
- **Multi-agent research system** (the paper): orchestrator-worker with explicit per-worker
  objective/format/tools/boundaries; effort scaling written into prompts (1 agent/3–10 calls for
  facts → 10+ agents for complex); multi-agent ≈ 15× chat tokens; **token volume explains ~80% of
  quality variance**; Opus-lead + Sonnet-workers beat single Opus by 90.2%; artifact/output
  isolation over funneling through the lead; external memory near 200K.
- **Advisor economics** (ClaudeDevs): Sonnet executor + Fable advisor tool = ~92% of Fable-solo
  SWE-bench Pro at ~63% cost; advisor called ~once per task. Second pattern: strong-model
  orchestrator delegating to cheap workers, most tokens billed at worker rate.

### 2b. X practitioners

- **shannholmberg swarm**: orchestrator "never executes — plans, assigns, measures"; three worker
  tiers routed by task need (judgment / scoped execution / code); results measured against the
  /goal — miss reruns at the same tier, hit ships.
- **shannholmberg review loop / shadcn /improve**: strongest model does review+plan ONCE (four
  lenses: overbuilt→cut, fragile→fix, missing→add, structure-fights-goal→restructure) → one
  plan.md ranked by leverage, open questions pinned top → cheaper model executes alone. Run it
  before building on top of anything, and always before handing a codebase to a cheaper model.
- **Psalteric chain**: interview (grill) → adversarial planning (two models argue ≤5 rounds to
  consensus) → cheap execution → premium review. (His full skill was never posted as of 2026-07-12.)
- **Saboo meta-loop**: chief-operator orchestrator (plan→delegate→verify→synthesize hot path) +
  board advisor consulted OUT of the hot path + cheap parallel labor layer.
- **diegocabezas01**: 4 roles — Fable orchestrator, Opus deep-reasoner, Sonnet fast-worker, Codex
  as PEER not reviewer; high-stakes: task Opus + Codex on the same problem in parallel WITHOUT
  showing either the other's answer, synthesize.
- **cjzafir**: official Codex plugin inside Claude Code (`/plugin marketplace add
  openai/codex-plugin-cc`, `/codex:rescue`); "inspect the result yourself before accepting";
  context rot → clear after ~4 compactions with a /handoff.
- **0xCodila Karpathy article**: a loop = verifier + state + stop condition; no gate = "the agent
  grading its own homework". Karpathy's autoresearch: agent may touch train.py, NEVER the
  evaluator. Four-condition test for whether a loop pays (repeats · automated verification ·
  budget absorbs waste · real tools). Bilevel (outer loop rewrites the inner loop's search) = 5x,
  same LLM — architecture, not intelligence. Costs: comprehension debt, cognitive surrender.
- **Jason Zhou loops article**: the loop contract (Goal/Boundaries/SOP/state/logs) — the
  Boundaries section (ship-alone vs ask-human line) decides walk-away-ability; state absorbs
  earned lessons ("worth more in month three"); orchestrator/executor/verifier split grows in when
  loops ship real code — start one-layer; triggers: continuous / time / event (+cheap gate script);
  verify with evidence (video in the PR → "approve behavior, not diffs"); review-bandwidth
  guardrail (no second PR while one is open); autonomy earned per segment; evolve as a run role.

### 2c. GitHub deep-mines

- **obra SDD (raw)**: file-based handoffs because "everything pasted in a dispatch stays resident
  in controller context forever" (observed 42k-char dispatch, 99% pasted history); `.superpowers/
  sdd/` self-ignoring workspace in the working tree (NOT `.git/` — agent writes denied); ledger
  line `Task N: complete (commits <base7>..<head7>, review clean)`; costliest failure = re-running
  completed tasks after compaction; always diff from recorded BASE never HEAD~1; <15-line inline
  returns; "always specify model explicitly — omitted model silently inherits the most expensive";
  "turn count beats token price", mid-tier floor for reviewers; fix waves (one fixer with the FULL
  list); reviewer anti-patterns (never pre-judge findings); pre-flight batched questions;
  continuous execution.
- **ralph-wiggum plugin (raw)**: loop as a Stop hook — state file `.claude/ralph-loop.local.md`
  (frontmatter: active/iteration/max_iterations/completion_promise + prompt body); hook emits
  `{"decision":"block","reason":"<prompt>"}` to re-feed the SAME prompt; exits only on iteration
  cap or exact-match `<promise>` string; memory = filesystem + git, never conversation; anti-lying
  pressure on the promise; zero subagents/review/ledger by design.
- **loopany (raw)**: run roles exec/evolve/edit; open vs closed loops (closed: agent judges the
  goal from evidence, strict finish bar); task file as memory (Spec / Current understanding /
  append-only Timeline); logs are DATA not instructions; evolve levers: contract → distill (keep
  durable lessons, condense to milestone spine, never drop open items) → lift deterministic work
  into pre-stage scripts (never qualitative calls) → metrics surface; cost as first-class evolve
  evidence; session JSONL as the deep record; transient failure → resume same session; workflow
  failure → clean agent fallback writing a fix note; `skipped` ≠ failure.
- **AI-Builder-Club (raw)**: /verify split — SUBJECTIVE check by a fresh read-only verifier
  subagent driving the real app FIRST (returns strictly works|broken/expected/observed/evidence;
  screenshot + video to gitignored `evidence/`; PR embeds screenshot, links video), OBJECTIVE
  codified checks by the orchestrator after; broken → fix → FRESH verifier, ~3 rounds then
  escalate; worktree contract (copy `.env*` in; worker returns PR URL + summary; knowledge writes
  stay with orchestrator; mandatory `git worktree remove`, check `git worktree list` clean).
- **davidondrej**: codex-subagent (the `</dev/null` stdin trap, one-task-per-launch, worktree per
  run, never bypass sandbox); goal-loop (5-part contract: objective/constraints/validation
  command/stop condition/docs; forbid reward-hacking explicitly; meta-prompting: have a second
  session write the goal); handoff (state-not-instructions, capture the why + dead ends, redact,
  reference don't duplicate).

### 2d. Registry mining (top extractions)

- **shinpr**: strategy selection should be DATA-DRIVEN — a requirement-analyzer's scale measurement
  picks the workflow tier (small/medium/large); typed JSON return schema per role; stub-detection
  bounce-back; scope change → restart from analyzer; escalation statuses halt autonomy.
- **wshobson**: preset team catalog (review/debug/feature/fullstack/research/security/migration);
  sizing ("smallest team covering all dimensions", 5–6 tasks/teammate); 4 decomposition axes
  (layer/component/concern/file-ownership); broadcast cost ∝ team size; finding dedup rules +
  severity calibration (impact × likelihood; externally-exploitable → always Crit/High); deadlock
  break by sending a stub.
- **rlm-orchestrator**: <50K tokens → don't decompose at all; 3–7 partitions; aggregation
  strategies union/synthesis/reduce; peek-before-deep; the main conversation is the recursion
  stack (subagents can't nest).
- **evolve (agentops)**: ratchet gating — cheap checks between cycles, heavy validation at the
  boundary only; dormancy hard-gates (kill switch, max-cycle cap, regression breaker); work-ladder
  re-selection over fixed backlog; "no verdict = not done".
- **edict**: plan-veto gate (a reviewer that can reject the plan pre-execution) + enforced state
  transitions — but buried in Docker/dashboard infra: the anti-example for scope.
- **affaan-m**: kanban cards with per-state EXIT CRITERIA and an explicit MERGE GATE;
  "merge-readiness by gate, not subjective assessment"; integrator for overlapping writes.
- **hjewkes**: the independence decision tree (single vs sequential vs parallel); per-agent
  return-format constraint ("verdict first, <1000 tokens").
- **dispatch**: persistent config with user-defined ALIASES for presets.
- **qodex**: only the strategy names generalize (sequential/parallel/hierarchical/consensus) —
  Python-library implementation rejected.

### 2e. External CLIs (verified)

- **codex**: most script-friendly — `codex exec` w/ stdin piping, `--output-schema` (validated
  JSON), `--json` JSONL events, `-c model_reasoning_effort=minimal..xhigh`, sandbox
  (`read-only|workspace-write|danger-full-access`) × approval (`untrusted|on-request|never`),
  `codex exec resume --last` (cwd-scoped), `$CODEX_HOME`; `</dev/null` mandatory; codex-as-MCP via
  `codex mcp-server`.
- **grok**: `grok -p` + `--output-format plain|json|streaming-json`; sessions `~/.grok/sessions`
  (`-s/-r/-c`); approval all-or-nothing (`--always-approve`); no reasoning-effort flag; richest
  programmatic surface is ACP `grok agent stdio` (JSON-RPC).
- **cross-CLI division of labor** (web): Claude = reasoning/review, Codex = fast sandboxed
  implementation + honest peer, Gemini = huge-context recon; cross-validation by sending the same
  review to multiple engines.

---

## 3. Convergent principles (seen independently ≥3 times each)

1. **Artifact-on-disk is the interface** — obra, Ralph, loopany, AIBC file-KB, Gastown beads,
   Anthropic artifact-isolation, brease-factory itself. Chat handoffs bloat and die.
2. **Fresh context per unit beats accumulated context** — SDD, Ralph (fresh window per iteration),
   orchestrator-worker, verifier-must-be-fresh.
3. **Separate maker from checker; gates enforced not trusted** — SDD dual review, Karpathy's
   untouchable evaluator, AIBC fresh verifier, workflows' adversarial verify, edict veto.
4. **The strong model plans/judges; cheap models execute** — ClaudeDevs (with data), shannholmberg,
   Psalteric, Saboo, diegocabezas01, cjzafir, obra model rules. Corollaries: model explicit per
   dispatch; turn count beats token price.
5. **Loops = verifier + state + stop condition, plus hard rails** — Karpathy, Jason Zhou,
   goal-loop, ralph plugin (its ONLY features are the rails), evolve's dormancy gates.
6. **Isolation (files) × delegation (work) × coordination (comms) are three orthogonal axes** —
   official docs; worktrees vs subagents vs teams/messaging. Compose, don't pick one.
7. **Strategy choice should be measured, not vibed** — shinpr scale-gating, rlm token threshold,
   hjewkes decision tree, Anthropic effort-scaling. And recorded (auditable dimensions).
8. **Human bandwidth is a budget** — Jason Zhou's PR cap, tiered/earned autonomy, batched
   questions (obra), "loops must respect review bandwidth, not just throughput".
9. **Recovery is first-class** — SDD ledger+git, Ralph re-run, loopany session-resume + leases,
   Gastown "git is the persistence layer"; and the 529 lesson: never duplicate a failed agent.
10. **Loop-improves-loop is real but second** — bilevel 5x, loopany evolve, agentops evolve; all
    gate it behind an inner loop that already earns trust.

---

## 4. Design decisions → grounding

| Decision in the skill | Grounded in |
|---|---|
| Strategies are presets over DIMENSIONS | brease-factory mode→dimensions; composability demand (user: "large collection of strategies"); qodex naming |
| 9-strategy catalog | Convergent set across all sources (§2); each strategy has ≥2 independent implementations in the wild |
| Selection: arg > alias > triage > ask | shinpr (data-driven), dispatch (aliases), hjewkes (tree), rlm (<50K veto), Anthropic effort-scaling |
| Thin router + per-strategy references (progressive disclosure) | brease-factory doc layering; obra's "read only what your job requires"; edict as the bloat anti-example |
| `.orchestrate/` self-ignoring workspace | obra sdd-workspace verbatim (incl. the .git/-denial rationale) |
| Brief/report files + <15-line returns | obra file-handoff cost thesis |
| Ledger + resume rules | obra progress.md + "costliest failure" evidence |
| Dual review, spec-then-quality, fix→re-review | The original skill + obra current; order rationale (wasted quality tokens) |
| Plan-veto as a SEPARATE gate kind | edict menxia, teams plan-approval, adversarial planning — all pre-execution |
| panel:N dedup + severity rules | wshobson multi-reviewer |
| consensus:N refuter voting | Workflow tool adversarial-verify pattern; deep-research shape |
| Fresh evidence-producing verifier (works\|broken) | AIBC verifier-setup verbatim |
| Model tier table + "explicit every dispatch" + "turn count beats token price" | obra rules + ClaudeDevs advisor data + Anthropic 80%-variance finding |
| Worktree contract (.env copy, PR-URL return, mandatory removal) | AIBC CLAUDE.template + official worktrees doc |
| Task cards with merge gates | affaan-m kanban |
| Integrator role | affaan-m + wshobson file-ownership axis |
| Hierarchical depth guidance (teams / workflow() / recursion-stack) | Verified runtime limits: no subagent nesting, workflow one level, no nested teams, managed-agents depth 1 |
| Blind parallel counsel | diegocabezas01 |
| Loop contract file template | Jason Zhou verbatim |
| Ralph stop-hook recipe | anthropics ralph-wiggum plugin (raw) |
| /goal 5-part contract + anti-reward-hacking | davidondrej goal-loop + official /goal evaluator behavior |
| Evolve pass (4 levers, no-op valid) | loopany evolve.md + agentops evolve + bilevel paper narrative |
| Loop rails (cap/kill/regression/PR-cap) | evolve dormancy gates + Jason Zhou + Karpathy stop-condition |
| xcli recipes | davidondrej codex-subagent + verified CLI docs (docs-clis subagent) |
| Overload → never duplicate | This project's prior memory (porter incident) + re-confirmed live during this research |
| Data ≠ instructions rail | loopany untrusted-timeline rule + prompt-injection hygiene |
| Handoff template | davidondrej handoff, condensed |
| config.yaml aliases | dispatch skill |

## 5. Considered and rejected

- **Heavy infra** (edict's Docker/daemons/dashboard, qodex's Python broker, observability servers):
  compose native primitives instead; "one dashboard is worth less than one good ledger".
- **Always-spawn-a-worker-even-for-trivial-tasks** (dispatch): contradicts the <50K/solo rule.
- **A `consensus` standalone strategy**: folded into `review=consensus:N` — it's a gate shape, not
  a topology.
- **Auto-launching workflows**: workflows stay opt-in per the tool's own contract.
- **Renaming/rewriting the original skill in place**: user chose a separate skill; original kept
  untouched as reference.

## 6. Open items / watchlist

- @Psalteric's promised adversarial-planning skill never dropped (checked through 2026-07-12) —
  `adversarial.md` is built from his architecture + our own debate-prompt design; compare if it
  ships.
- `~/.claude/projects/.../<session>.jsonl` transcript path is convention, not documented API.
- Agent teams are experimental: re-verify limitations (nesting, resume, background subagents) on
  Claude Code upgrades.
- CLI flags drift — xcli.md mandates a `--help` check per session; the codex facts are pinned to
  v0.136.0.
- The local x-relay install was an older version than its skill doc (no `doctor`/`batch`; media
  schema differs; the shim printed nothing — invoke `dist/cli.js` via node directly). Upgrade
  `x-relay-mcp` when convenient.
