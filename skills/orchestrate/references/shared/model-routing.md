# Model routing — tiers, and the rules that keep costs honest

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
   more. State the budget in the brief; cap chat returns per `shared/contracts.md`.
6. **Separate maker from checker — always.** Writer cheap+fast, reviewer strict, different
   instance. Self-review never replaces review.
7. **Advisor economics** (published): executor+advisor ≈ 92% of the strong model's quality at
   ~63% cost, advisor consulted ~once per task. When budget-pressed, prefer advisor-shaped
   routing over downgrading the whole run.
8. Effort knobs exist beyond model choice: Claude `--effort low..max`, codex
   `-c model_reasoning_effort=low..ultra` (medium default; `ultra` fans out Codex-side subagents —
   treat as a fan-out decision, not an effort bump), grok-4.5 API `reasoning_effort=low|medium|high`
   (high default; no CLI flag as of grok CLI 0.2.101). Cheap stage = low effort; judge stage = high.
9. Engine tier map — codex (verified 2026-07-13): `gpt-5.6-luna` ≈ cheap worker ·
   `gpt-5.6-terra` ≈ standard worker/reviewer · `gpt-5.6-sol` ≈ reasoner/advisor/peer.
   Grok (verified 2026-07-14): `grok-4.5` = flagship (500k ctx, coding/agentic/reasoning) ≈
   reasoner/advisor/peer — API-only for now; the grok CLI exposes a separate, shorter list
   (`grok models`). Model lists drift — re-verify slugs before pinning (`strategies/xcli.md`).
