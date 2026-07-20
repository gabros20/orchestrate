# Token & context optimization for multi-agent orchestration — research record

> **Status:** implemented — this research fed the **v1.1.0** release (design: [../designs/v1.1.0-token-optimization.md](../designs/v1.1.0-token-optimization.md)). O7/O12 partially (session/cache hygiene as guidance); O14 as a doc note; server-side clearing + Task Budgets on the watchlist. Research date: 2026-07-13.

*Method: X/Twitter sweep (13 queries, 9 full-thread reads via x-relay), web research agent,
skills-ecosystem survey agent, primary-source reads (repos, SKILL.md files, benchmark docs).*

**Question:** How do we cut token spend and context-window usage in `/orchestrate` runs — without
degrading reasoning, code, or output quality? Specifically: when should subagents be "cavemen"
(terse while working) and when detailed (final reports)?

---

## TL;DR — the economics that decide everything

1. **Output-style compression (caveman) only touches output tokens.** The caveman repo's own
   honest-numbers doc: 65% average *output* reduction (range 22–87%), **0% input reduction**, and
   the skill itself *adds* ~1–1.5K input tokens per turn. Independent session-level measurements:
   **14–21% total savings** on output-heavy work, **net-negative** on terse work; one independent
   field test measured only **15–25%** real savings. Discount the 75% headline.
2. **In agentic coding, input dwarfs output.** System prompt + tool schemas + skills + file reads +
   tool results dominate. The biggest single levers are input-side: filtering tool output before it
   hits context, reading symbols not files, trimming always-loaded rules.
3. **But in *orchestration* output-discipline compounds twice:** a subagent's chat return becomes
   the *controller's input*, is re-read on every controller turn thereafter, and survives
   compaction summaries. A 2K-token status ramble costs the controller for the rest of the run.
   That's why "quiet while working, structured when reporting" is the right contract — not caveman
   everywhere.
4. **Terse ≠ dumber — probably.** The caveman repo cites a March 2026 paper across 31 models where
   brevity constraints *improved* accuracy ~26 points ([arXiv:2604.00025](https://arxiv.org/abs/2604.00025)
   — **unverified**: our web pass could not locate it independently; treat as claimed, not fact).
   Context rot, however, is well attested: retrieval quality collapses as context grows (GPT-5.5:
   80% at 256K → 36% at 1M — Prime Intellect talk). Shorter contexts are *more* correct, not less.
5. **Never compress:** code, diffs, commands, error strings, API names (byte-for-byte exact),
   security warnings, irreversible-action confirmations, and ordered multi-step instructions where
   dropped conjunctions create ambiguity. Every serious terse-mode implementation carves these out.

---

## Part 1 — The caveman phenomenon (X + primary source)

**Origin:** [@om_patel5's viral thread](https://x.com/om_patel5/status/2040279104885314001)
(23.4K likes) — "I taught Claude to talk like a caveman to use 75% less tokens… caveman claude
doesn't explain itself. it does its task first. gives the result. then stops."
Follow-up ([2041035711063732460](https://x.com/om_patel5/status/2041035711063732460)): someone
turned it into an installable skill with API-measured benchmarks.

**The skill:** [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — **88.8K stars**,
works across 30+ agents. What its SKILL.md actually does (worth reading as prompt engineering):

- **Drop:** articles, filler (just/really/basically), pleasantries, hedging, tool-call narration,
  decorative tables/emoji, raw error-log dumps (quote the shortest decisive line instead).
- **Keep byte-for-byte:** code blocks, commands, API names, exact error strings, commit keywords.
- **Anti-lever it measured and rejected:** invented abbreviations (`cfg`/`impl`/`req`) and arrows
  (`→`) save **zero** tokens — the tokenizer splits them the same — while costing clarity.
- **Intensity levels** (lite / full / ultra + wenyan classical-Chinese variants) — a dial, not a
  switch.
- **Auto-Clarity escape hatch:** drops caveman for security warnings, irreversible-action
  confirmations, ambiguous multi-step sequences, and when the user repeats a question — then
  resumes. This is the quality-protection half most copycats miss.
- **Boundaries:** code/commits/PRs are always written normal.

**Measured numbers** ([benchmarks](https://github.com/JuliusBrussee/caveman/tree/main/benchmarks),
[docs/HONEST-NUMBERS.md](https://github.com/JuliusBrussee/caveman/blob/main/docs/HONEST-NUMBERS.md)):

| Metric | Number |
|---|---|
| Output reduction vs default verbose replies | **65% avg** (22–87% by task), real Claude API counts |
| Input reduction | **0%** |
| Input cost the skill adds | **~1–1.5K tokens/turn** (SKILL.md injected) |
| Session-level total savings (output-heavy work) | **14–21%** |
| Terse Q&A workloads | **net-negative** (issue #145, measured) |
| Per-request-billed agents (Copilot) | zero savings by construction (#506) |
| `/caveman-compress` on memory/CLAUDE.md files | **46% avg input reduction, recurring every session** |

**Rule of thumb from the repo:** normal reply >1.5–2K output tokens → caveman saves money; shorter
than that (or per-request billing) → it costs money. Readability/speed win either way.

**When it loses hard:** one Cursor A/B showed 4.3M tokens *with* caveman vs 1M without (rule
re-injection + retries + cache accounting swamped output savings). Lesson: **A/B on your own
workload; provider billing page outranks any repo's claims.**

Related: [caveman-code](https://github.com/JuliusBrussee/caveman-code) — a full terse-by-design
coding agent claiming ~2× fewer tokens than Codex on identical tasks.

## Part 2 — Other proven techniques from X (ranked by evidence quality)

### Input-side (the bigger pot)

| Technique | Source | Claim |
|---|---|---|
| **Filter terminal/tool output before it hits context** | [RTK — Rust Token Killer](https://github.com/rtk-ai/rtk) (via [@DeRonin_](https://x.com/DeRonin_/status/2045420155434320270), [@DataChaz](https://x.com/DataChaz/status/2045784379155226971)) | 60–90% reduction on common dev commands; proxy binary |
| **Sandbox raw tool output to SQLite, return summaries** | [context-mode](https://github.com/mksglu/context-mode) | 98% context reduction on Playwright/GitHub/log dumps |
| **Navigate code by symbols, not whole files** | [token-savior](https://github.com/Mibayy/token-savior) (MCP) | 97% reduction on code navigation |
| **Tree-sitter code graph — read only what matters** | [code-review-graph](https://github.com/tirth8205/code-review-graph) | 49× reduction on monorepo reviews, 6.8× average |
| **Hybrid code search (BM25+dense) instead of file reads** | [zilliztech/claude-context](https://github.com/zilliztech/claude-context) | ~40% reduction at equivalent retrieval quality |
| **Strip system-prompt bloat** | [@mattpocockuk](https://x.com/mattpocockuk/status/2074464823232888987) + [aihero.dev article](https://www.aihero.dev/how-to-kill-the-bloat-in-claude-codes-system-prompt) | proxy-inspect what's actually sent; settings.json trims to ~13K start-of-session |
| **Prune unused skills/MCPs/plugins** | Claude Code `/checkup` ([@bcherny](https://x.com/bcherny/status/2074997570317779038)) | official: cleans unused skills/MCPs, dedups CLAUDE.md, nests CLAUDE.md, disables slow hooks |
| **Compress always-loaded memory files** | caveman-compress | 46% avg on CLAUDE.md-class files, recurring |

Skill-count caveat cuts both ways: **every installed skill costs ~1–1.5K input tokens per turn**
whether used or not. An orchestration controller loaded with 20 skills pays ~25K/turn of standing
overhead. (`/context` in a fresh session shows the pre-typed burn.)

### Structure-side

- **Big-model-plans / cheap-model-executes** — [@cjzafir](https://x.com/cjzafir/status/2065104422762684745):
  Fable-high plans → Codex executes → Fable-max reviews = **"50% less weekly Claude Code limits"**.
  Same economics as orchestrate's `advisor` strategy (SWE-bench Pro: Sonnet executor + Fable
  advisor ≈ 92% of quality at 63% of cost — already in RESEARCH.md).
- **Context rot is a quality argument for orchestration itself** —
  [Prime Intellect via @0xCarnagee](https://x.com/0xCarnagee/status/2075983721841225885): GPT-5.5
  retrieval 80% @256K → 36% @1M. Fresh-context-per-task (orchestrate rule #1) isn't just hygiene,
  it's measurably higher reasoning quality than one long accumulating session.
- **Narration is pure cost** — [@k1rallik](https://x.com/k1rallik/status/2043724669644116149):
  "Claude explaining itself costs more than the answer… 180 tokens of politeness. Every Single
  Call." Codex users disable plan narration (`Process_narration=false`) for the same reason.

## Part 3 — Web research findings (first-party Anthropic data + verified benchmarks)

Delivered by a dedicated web-research agent; **[M]** = measured, **[V]** = vendor/qualitative,
**[U]** = unverified community claim.

### 3.1 The multipliers (Anthropic first-party, [multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)) [M]

- Single tool-using agent ≈ **4×** the tokens of a chat interaction; **multi-agent ≈ 15×**.
- **Token usage alone explained 80% of performance variance** on BrowseComp; model choice + tool-call
  count together only ~15%. (Spending tokens *is* the capability — the goal is not fewer tokens, but
  no *wasted* tokens.)
- Anthropic's economic rule: multi-agent only when task value pays for it — parallelizable work,
  info exceeding one context window, complex tool surfaces. Otherwise don't spawn agents at all.
- Orchestration overhead in one study: planning ≈ **9.8%** of tokens, workers ≈ **70.6%** — the
  workers' style, not the controller's, is where output discipline pays.
- Naive agent loops grow quadratically: a 10-step file-reading loop cost **43.3×** a single-pass
  equivalent (472K vs 9K input tokens) in a third-party benchmark (augmentcode.com).

### 3.2 Verbosity control that Anthropic itself ships [M/V]

- **Silence-default pattern** (from Opus 4.8 migration guidance): *"Default to silence between tool
  calls. Only write text when you find something, change direction, or hit a blocker — one sentence
  each. Do not narrate routine actions."* Companion autonomy pattern (pick-and-note instead of
  asking on minor choices) measured **~12pp ask-rate reduction with no quality loss** in Claude
  Code testing.
- **The coverage-vs-filtering trap (critical for review gates):** telling a reviewer "only report
  high-severity issues / be conservative" measurably **lowers recall** — newer models self-filter
  literally. Fix is structural: the reviewer reports *everything* with confidence+severity; a
  downstream step filters. Never bolt verbosity suppression onto a judgment/filtering task.
- Vague "be concise" regresses after a few turns; **explicit scope bounds** ("≤200 words", "N
  sentences", a fixed report schema) hold.
- **Report size norm:** Anthropic's context-engineering post recommends subagents return a
  **condensed 1,000–2,000-token summary** to the coordinator, never the raw work product.

### 3.3 Context-management mechanics [M — Anthropic cookbook A/B, ~328K-token research task]

| Strategy | Peak context | Reduction |
|---|---|---|
| Baseline | 335K | — |
| Compaction (trigger 180K) | 169K | ~50% |
| Tool-result clearing (keep last 4) | 173K | ~48%, free (no inference) |
| Memory file reused in session 2 | ~45K | skips re-discovery entirely |

They compose. Clearing needs re-fetchable tools + notes; compaction costs one summarization call;
memory is the only one that survives sessions.

Also first-party: **Task Budgets** (beta; Fable 5 / Sonnet 5 / Opus 4.7+) — a token ceiling for a
whole agentic loop that the model is *aware of*, so it self-paces and wraps up gracefully instead
of hard-truncating like `max_tokens`. Minimum 20K. A direct lever for bounding a worker's total
spend without any brevity prompting — relevant to orchestrate's `budget=` dimension (O6).

**Prompt-caching mechanics that matter to an orchestrator** (first-party pricing/behavior):
cache reads ≈ 0.1× input price, writes 1.25× (5-min TTL) / 2× (1-hr); strict prefix match
(`tools → system → messages`) — one changed byte upstream invalidates everything after;
breakpoints look back only 20 content blocks (long tool-heavy turns silently miss cache);
N parallel identical-prefix requests all pay full price unless you fire 1, await first token,
then fan out. For dispatch design: **keep worker system prompts stable across a run; vary only
the tail** (task brief), and stagger simultaneous spawns of identically-prefixed workers.

### 3.4 Advisor tool (first-party, GA 2026-04) [M]

Server-side inversion of big-plans/small-executes: cheap executor drives the whole task, consults
a stronger advisor only at hard decisions (advisor emits just **400–700 tokens per consult**).
Measured: Sonnet-executor + Opus-advisor **74.8% vs 72.1%** (Sonnet alone) on SWE-bench
Multilingual at **11.9% lower cost** — the only technique in this record with simultaneous
measured cost *and* accuracy wins. Haiku+Opus on BrowseComp: 19.7% → **41.2%**. Worst fit:
uniformly-hard tasks (executor consults constantly).

### 3.5 Structured output as compression [M/V]

- MCP/tool field-filtering (50 fields → 3–5 relevant) cuts **80–90%** of tool-result payload —
  usually a bigger lever than compressing the model's own prose.
- JSON-schema-forced output bounds length mechanically (no prompting fragility); token-lean
  formats (TOON) cut tokens while *improving* extraction accuracy on tabular data.
- File-based handoffs over chat returns is also Anthropic's first-party pattern (Managed Agents):
  the orchestrator fetches only what it needs.

## Part 4 — Skills-ecosystem survey (what's borrowable)

Delivered by a dedicated skills-survey agent (`npx skills find` + raw SKILL.md reads).

### 4.1 cavecrew (juliusbrussee/caveman family, ~344K installs) — **the direct answer to "quiet workers"**

Three subagent presets (investigator / builder / reviewer) that replace prose returns with
**fixed per-role output contracts**, because "subagent tool results get injected into main context
verbatim":

- investigator: `path:line — \`symbol\` — short note` + `totals: <counts>` (or `No match.`)
- builder: `<path:line-range> — <change ≤10 words>` + `verified: <re-read OK | mismatch @ path:line>`,
  or one terminal token (`too-big.` / `needs-confirm.` / `ambiguous.` / `regressed.`)
- reviewer: `path:line: <severity>: <problem>. <fix>.` + totals by severity

Claims ~60–70% smaller tool-results vs vanilla agents; auto-reverts to normal English for security
warnings/irreversible actions. **Key idea to borrow: make the terse return format structurally
guaranteed (a contract with a grammar), not a "be brief" vibe.**

### 4.2 context-compression (sickn33/antigravity-awesome-skills) — best conceptual framing

- Optimize **tokens-per-task, not tokens-per-request** — over-aggressive compression that forces
  re-fetching costs more overall.
- Names the worst failure mode of compression: the **artifact-trail problem** (post-compression,
  agents forget which files were modified/read — scored worst across all methods studied).
- Prescribes **anchored iterative summarization**: fixed mandatory sections (Session Intent /
  Files Modified / Decisions Made / Current State / Next Steps) so each must be explicitly
  populated; subsequent compressions merge into sections rather than regenerate.
- **Probe-based evaluation**: after compressing, ask "what was the original error?" / "which files
  did we change?" — if the summary can't answer, the compression failed. (Measured: anchored
  98.6% ratio at 3.70 quality vs opaque 99.3% at 3.35 — the extra 0.7% of kept tokens buys real
  quality.)

### 4.3 caveman + caveman-compress — one non-obvious rule worth lifting verbatim

"No invented abbreviations (`cfg`/`impl`/`req`), no arrows (`→`) — the tokenizer splits them the
same as full words: **zero tokens saved, clarity lost**." Also: compress prose in memory files,
treat fenced code blocks as read-only regions, back up before overwriting.

### 4.4 efficient-fable (builderio/skills) — delegation doctrine

Reserve the expensive model for decomposition, conflict resolution between subagent reports, and
final synthesis; push token-heavy research/coding/log-reduction to cheap subagents. Handoff packets
assume zero context (path, exact objective, in/out of scope, required evidence format, stop
conditions). **Treat subagent reports as leads, not facts** — re-verify before acting on
high-impact findings. (Validates orchestrate's existing structure; good vocabulary.)

### 4.5 Not worth borrowing

`cost-compact-context` (wrapper around an unavailable package, self-admitted heuristic numbers),
`token-optimization` (generic MCP-call hygiene), `context-window-management` /
`context-manager` (textbook/persona filler).

## Part 5 — What this means for /orchestrate (opportunity list — NOT yet implemented)

The controller/worker split changes where each lever pays:

| # | Opportunity | Mechanism | Where it would land |
|---|---|---|---|
| O1 | **Verbosity contract per role** — workers run caveman-style *while working* (no narration, no politeness, terse thinking-out-loud), but final reports stay structured and complete per the existing report schemas | The subagent's chat return is controller input, re-read every turn; working chatter inside the subagent is its own context bloat | `shared-contracts.md` + every prompt template gets a standard "Communication" block |
| O2 | **Report budgets already exist — enforce the working-style half** | We have "<15-line returns"; we don't yet forbid progress narration, restating the brief, or preamble inside the worker | `references/prompts/*.md` |
| O3 | **Never-compress carve-outs** — copy caveman's Auto-Clarity list into the verbosity contract: code/diffs/errors byte-exact; security warnings, irreversible-action asks, ordered steps stay full prose | Prevents the quality degradation failure mode | `shared-contracts.md`, `shared-safety-rails.md` |
| O4 | **Tool-output hygiene rule for workers** — quote the shortest decisive line of an error/log, never paste raw dumps into reports; grep/filter before reading big command output | Input-side, biggest pot | universal rules in SKILL.md |
| O5 | **File-based handoff already wins — say why** — briefs/reports as files (not chat) keep the controller's window flat; document the token rationale so users don't "improve" it away | Already orchestrate rule #2 | docs |
| O6 | **`budget=` dimension could take tokens seriously** — per-worker output caps, alias like `terse` (verbosity=caveman-lite for workers) | Dial, not switch — mirror caveman's intensity levels | `config.yaml` alias + dimensions table |
| O7 | **Controller skill-load audit** — recommend `/checkup` / minimal-skill sessions for long orchestration runs; each idle skill ≈ 1–1.5K/turn | Standing overhead × every controller turn | docs/recipes |
| O8 | **A/B before believing** — add an honest-numbers note: output-style savings are 14–21% session-level at best; measure with provider billing, not vibes | Keeps us from cargo-culting the 75% headline | this doc + docs |
| O9 | **Grammar-guaranteed return contracts (cavecrew-style)** — per-role return formats with a fixed line grammar and terminal tokens (`too-big.`, `needs-confirm.`, …), not "be brief" | Structural guarantee beats stylistic instruction; ~60–70% smaller returns claimed | `shared-contracts.md` chat-return schemas |
| O10 | **Coverage-vs-filtering split in review gates** — reviewers report *everything* with confidence+severity; the controller (or a filter step) triages. Never tell a reviewer to self-filter to "important" findings | Verbosity suppression on judgment tasks silently drops recall (Anthropic-documented) | `shared-review-gates.md`, reviewer prompts |
| O11 | **1–2K-token report norm + tokens-per-task framing** — size the report budget to Anthropic's recommended condensed-summary band; over-compression that forces the controller to re-fetch costs more than it saves | First-party norm + tokens-per-task > tokens-per-request | `shared-contracts.md` |
| O12 | **Cache-friendly dispatch** — keep worker system prompts/templates byte-stable across a run, vary only the task-brief tail; stagger simultaneous identical-prefix spawns | Cache reads are ~0.1× price; prefix instability and parallel cache races silently pay full price | dispatch templates, `shared-model-routing.md` |
| O13 | **Probe-test handoffs** — when compacting or writing a handoff doc, verify it can answer "which files changed?" / "what was the original error?" before trusting it | Artifact-trail loss is the measured worst failure of compression | `shared-handoff.md` |
| O14 | **Advisor tool (server-side) as an engine option** — the API-native advisor (`advisor_20260301`) does the advisor strategy in one call with 400–700-token consults; measured +accuracy at −11.9% cost | Only technique with dual measured wins | `strategy-advisor.md` (as an alternative path) |

**The core design answer to "when caveman, when detailed":**

- **Caveman (terse):** worker *working* style — tool-call narration, self-talk, progress chatter,
  politeness. Also: controller→worker briefs (no filler; but never ambiguous ordering).
- **Detailed (structured, not verbose):** final reports, review verdicts, failure escalations,
  anything that crosses an agent boundary and will be *re-read* — complete per schema, zero fluff.
  Detail = information density, not length.
- **Never compressed:** code, diffs, commands, exact errors, security/irreversible-action language.

## Sources

### X threads (full reads)
- https://x.com/om_patel5/status/2040279104885314001 — caveman origin (23.4K likes)
- https://x.com/om_patel5/status/2041035711063732460 — caveman-as-skill + benchmarks
- https://x.com/DeRonin_/status/2045420155434320270 — 10 repos, 60–90% less tokens
- https://x.com/DataChaz/status/2045784379155226971 — 10 context-rescue tools
- https://x.com/k1rallik/status/2043724669644116149 — narration cost
- https://x.com/mattpocockuk/status/2074464823232888987 — system-prompt bloat
- https://x.com/cjzafir/status/2065104422762684745 — Fable-plans/Codex-executes, −50% limits
- https://x.com/0xCarnagee/status/2075983721841225885 — context rot (256K→1M retrieval collapse)
- https://x.com/bcherny/status/2074997570317779038 — Claude Code /checkup

### Primary sources
- https://github.com/JuliusBrussee/caveman — SKILL.md + benchmarks + docs/HONEST-NUMBERS.md (88.8K★)
- https://github.com/JuliusBrussee/caveman-code
- https://github.com/rtk-ai/rtk · https://github.com/mksglu/context-mode ·
  https://github.com/Mibayy/token-savior · https://github.com/tirth8205/code-review-graph ·
  https://github.com/zilliztech/claude-context · https://github.com/ooples/token-optimizer-mcp ·
  https://github.com/nadimtuhin/claude-token-optimizer · https://github.com/alexgreensh/token-optimizer ·
  https://github.com/drona23/claude-token-efficient
- https://arxiv.org/abs/2604.00025 — brevity constraints ↑ accuracy ~26 pts (31 models)
- https://www.aihero.dev/how-to-kill-the-bloat-in-claude-codes-system-prompt

### Web-agent sources (first-party unless noted)
- https://www.anthropic.com/engineering/multi-agent-research-system — 4×/15×/80%-variance/90%/40%
- https://www.anthropic.com/engineering/building-effective-agents — simplest-first, pattern costs
- https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents — 1–2K report norm
- https://platform.claude.com/cookbook/tool-use-context-engineering-context-engineering-tools — compaction/clearing/memory A/B
- https://www.buildfastwithai.com/blogs/anthropic-advisor-strategy-claude-api — advisor tool numbers (third-party writeup of first-party feature)
- https://www.augmentcode.com/guides/ai-agent-loop-token-cost-context-constraints — 43.3× naive-loop benchmark (third-party)
- https://www.mindstudio.ai/blog/reduce-token-usage-ai-agents-mcp-optimization — MCP field filtering (third-party)
- https://medium.com/data-science-at-microsoft/token-efficiency-with-structured-output-from-language-models-be2e51d3d9d5 · https://www.tensorlake.ai/blog/toon-vs-json — structured-output efficiency
- https://www.newline.co/@Dipen/claude-skills-and-subagents-reduce-prompt-bloat--f2920804 · https://community.openai.com/t/how-to-get-chatgpt-to-be-less-verbose-shut-up/824589 — verbosity-prompt fragility (community)

### Skills-agent sources
- `cavecrew` — juliusbrussee/caveman `skills/cavecrew` (~344K installs, caveman family)
- `context-compression`, `context-guardian`, `context-agent` — sickn33/antigravity-awesome-skills
- `efficient-fable` — builderio/skills
- Surveyed and rejected: `cost-compact-context` (ruvnet/ruflo), `token-optimization`
  (claude-dev-suite), `context-window-management`, `context-manager` (antigravity)

### Verification notes
- Caveman's 88.8K-star count verified directly via the GitHub API on 2026-07-13
  (`stargazers_count: 88849`). The arXiv brevity paper it cites could **not** be independently
  located — treated as claimed throughout. Independent field measurement of caveman's real-world
  savings (15–25%) conflicts with the repo's 65% output-only headline; both are reported with
  their scopes above.
