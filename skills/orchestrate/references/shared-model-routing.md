# Model routing — tiers, and the rules that keep costs honest

Purpose: Select explicit model tiers for each orchestration role while controlling cost and capability risk.

Read when:
- A run dispatches any worker, reviewer, advisor, peer, or sub-orchestrator.

Skip when:
- No agent dispatch occurs.

Inputs:
- Available models, host pinning support, role complexity, risk, and budget.

Produces:
- Explicit per-role model map, effort settings, and drift verification steps.

## Tier table

| Tier | Job | Default | Never |
|---|---|---|---|
| **advisor** | rare judgment consults, OUT of the hot path | strongest available | executes or edits |
| **orchestrator** | plans, decomposes, assigns, measures | strong (opus-class) | implements |
| **reasoner** | architecture, hard debugging, algorithms | opus-class | mechanical batches |
| **worker** | scoped execution, boilerplate, tests, transforms | sonnet-class / cheap engine | design decisions |
| **reviewer** | spec/quality/verification | sonnet-class floor; panel lenses may go higher | writes |
| **peer** | different-lineage second opinion | codex/grok | seeing the other peer's answer pre-synthesis |

## Rules

1. **Model explicit on EVERY dispatch.** An omitted model silently inherits the session's most
   expensive one. Both a cost bug and a routing bug — make it a required field in every prompt
   template.
2. **"Turn count beats token price."** Too-cheap models take 2–3× the turns and lose the savings.
   Mid-tier is the FLOOR for reviewers and prose-driven implementers; the cheapest tier only for
   transcription-grade work (the plan already contains the code).
3. **Task-class signals**: 1–2 files + complete spec → cheap worker · multi-file integration →
   standard worker · design judgment / whole-branch review → most capable.
4. **Escalation is a model change**: BLOCKED-for-reasoning re-dispatches the SAME task one tier
   up. Never the same model unchanged.
5. **Token budget ≈ quality** (it explains ~80% of multi-agent quality variance): scale effort by
   complexity — simple lookup = 1 agent / 3–10 tool calls; comparison = 2–4 agents; complex =
   more. State the budget in the brief; cap chat returns per `shared-contracts.md`.
6. **Separate maker from checker — always.** Writer cheap+fast, reviewer strict, different
   instance. Self-review never replaces review.
7. **Advisor economics** (published): executor+advisor ≈ 92% of the strong model's quality at
   ~63% cost, advisor consulted ~once per task. When budget-pressed, prefer advisor-shaped
   routing over downgrading the whole run.
8. Effort knobs exist beyond model choice: Claude `--effort low..max`, codex
   `-c model_reasoning_effort=low..ultra` (medium default; `ultra` fans out Codex-side subagents —
   treat as a fan-out decision, not an effort bump), grok-4.5 API `reasoning_effort=low|medium|high`
   (high default; no CLI flag as of grok CLI 0.2.106). Cheap stage = low effort; judge stage = high.
9. Engine tier map — codex (verified 2026-07-13): `gpt-5.6-luna` ≈ cheap worker ·
   `gpt-5.6-terra` ≈ standard worker/reviewer · `gpt-5.6-sol` ≈ reasoner/advisor/peer.
   Grok (verified 2026-07-14): `grok-4.5` = flagship (500k ctx, coding/agentic/reasoning) ≈
   reasoner/advisor/peer; grok CLI (0.2.106, verified 2026-07-20) defaults to `grok-4.5` as its
   sole listed model — lists drift, re-verify with `grok models` before pinning. Kimi (verified
   2026-07-20, live 0.28.0): `k3` = flagship (1M ctx on
   Allegretto+ membership, 256k below; `reasoning_effort: low|high|max`, default `high` — set via
   config.toml or `/effort`, NOT a CLI
   flag) ≈ reasoner/advisor/peer · `kimi-for-coding` ≈ balanced worker/reviewer (256k ctx) ·
   `kimi-for-coding-highspeed` ≈ latency-critical worker (6× speed at 3× quota — budget-relevant,
   not a cheap tier; no cheap tier exists). Switching model or effort mid-session invalidates
   Kimi's prompt cache — pin both per session. Model lists drift — re-verify slugs before pinning
   (`strategy-xcli.md`).
10. Sensitivity to emphasized/literal wording varies by model — re-tune dispatch templates per
    model at a recorded boundary, never mid-run (cache hygiene, `shared-token-economy.md`).
11. **Hybrid preferred when the brief is transcription-grade**: planner spend converts
    prose-driven tasks into transcription-grade ones — buy the conversion, don't upgrade the
    worker. Eligible only if the brief passes `scripts/brief-check`, scope is narrow and declared,
    verification is exact, and no design/cross-task seam is unresolved; otherwise rule 2's floor
    applies unchanged. Judge a planner by the **worker tokens its plans induce**, not its own bill —
    terse plans are not free (Cursor 2026 swarm data: similar quality across mixes, ~8× cost
    spread, workers ≥69–90% of tokens — bounded observation, not a causal law).
12. **Host caveat** (non-Claude-Code hosts): per-dispatch pinning is native on Codex (agents
    TOML), Cursor (`model:` frontmatter), and opencode (agent files) — but Antigravity subagents
    inherit the parent model, Hermes accepts a per-task model then silently ignores it, and there is
    no documented per-dispatch pin on Kimi. On those hosts, tier separation routes
    through xcli engines (one process per tier, `strategy-xcli.md`) or collapses to one model +
    effort knobs — record which in run.md (`shared-hosts.md`).
