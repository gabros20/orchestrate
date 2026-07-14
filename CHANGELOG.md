# Changelog

All notable changes to the **orchestrate** skill are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ·
Versioning: [SemVer](https://semver.org/) — **MAJOR** = invocation grammar or strategy-contract
breaks, **MINOR** = new strategies/dimensions/aliases or new reference material that changes
behavior, **PATCH** = fixes, doc corrections, prompt tuning with unchanged behavior.

The skill's current version lives in `skills/orchestrate/SKILL.md` frontmatter (`version:`) and is
tagged in git as `v<version>`. Every release PR updates **both** plus this file, and must pass
`scripts/check-sync` (block byte-identity, honest numbers, replicated invariants — CI-enforced on
every PR).

## [Unreleased]

### Site & visual guide
- Hero "runs on" line upgraded from plain wrapped text (dangling `·` separators at narrow widths)
  to a chip row: small-caps RUNS ON label + hairline mono chips per host, Claude Code accented as
  the reference; flex-wrap keeps every width tidy.
- Hero row disambiguation: the host chips lost their border (filled `--code-bg` tokens, same
  language as inline code — data, not buttons) and the section-nav pills gained a `#` anchor
  prefix, so metadata tags and in-page links no longer look like the same component.

## [1.4.0] — 2026-07-14

### Added
- **Multi-CLI (coding-agent-agnostic) support** — the skill now runs on any Agent Skills host,
  with Claude Code as the reference implementation. Design: `docs/designs/v1.4.0-multi-cli-support.md`
  (built on eight sourced research reports covering the agentskills.io standard, skills.sh, and
  each target CLI).
  - New `references/shared/hosts.md` — host detection (from the agent's own toolset), a
    capability matrix across Claude Code / Codex / Cursor / Antigravity / opencode / Grok Build /
    Hermes, bindings for six abstract primitives (dispatch, parallel, message, ask-user,
    worktree, loop), a stated-never-silent degradation ladder (native → xcli shell-out → solo
    with a warning), per-host state paths and quirks.
  - SKILL.md: new "Host" section; `engine` dimension widened to
    `claude|codex|grok|cursor|agy|opencode|hermes|mixed`; frontmatter gains `license: MIT` +
    `metadata` (source/guide URLs) per the open spec.
  - `xcli` strategy: four new engine blocks (Cursor `cursor-agent -p` + the headless-ask-user
    trap and ACP alternative; Antigravity `agy -p` with its under-documented flag caveat;
    `opencode run`; `hermes -z` with per-process model pinning) — xcli is now documented as the
    portability floor for hosts missing native primitives.
  - Triage: host gate in step 0 (unsupported strategy → named degradation).
  - `team`/`workflow`: explicit **Host availability** headers (team = Claude Code or Antigravity;
    workflow = Claude Code only) with degradation paths; `loop`: native variants (Antigravity
    Stop-hook continue + `/schedule`, Grok `/goal`/`/loop`) and the universal external-driver
    form; model-routing rule 10 (hosts where per-dispatch pinning is absent or broken);
    monitoring/isolation/token-economy/evolve generalized (host state paths, plain-git worktrees
    as the canonical form, CLAUDE.md/AGENTS.md/GEMINI.md conventions).
- `install.sh`: per-host targets (`claude|codex|cursor|antigravity|opencode|grok|hermes|agents|all`);
  `agents` = the cross-agent `~/.agents/skills` standard path. README gains a **Supported agents**
  matrix; docs/installation.md covers every host's paths, quirks, and engine table.
- `scripts/check-sync`: host-layer invariants (hosts.md present, team/workflow availability notes
  present, SKILL.md ≤120 lines, hosts.md ≤200 lines).
- docs/usage.md + docs/strategies.md: `engine` values widened everywhere; four new per-engine
  mechanics bullets in the xcli section; division-of-labor heuristic extended.

### Site & visual guide
- The site now states multi-agent support: hero eyebrow generalized to "An agent skill", a muted
  mono "runs on Claude Code · Codex · Cursor · Antigravity · opencode · Grok Build · Hermes" line
  under the hero terminal, and a "supported agents — who runs what" disclosure in Start here (host
  / native subagents / model pin / worth-knowing table + the team/workflow availability note),
  matching the page's existing panel/table language. llms.txt updated to match.
- Strategy decision strip restructured: six free-wrapping mini-cards became one bordered panel —
  a 2×3 grid of aligned "question → strategy" rows with internal hairlines (single column <720px).
- The five-step run pipe and four-step gate pipe (cramped joined cells + floating ▸ arrows)
  replaced by a numbered vertical stepper (`.steps`, same family as the token timeline): circled
  numbers on a connector rail, icon+name titles, full-width text; gate steps keep amber/green
  marker colors. One layout at every viewport.
- Fixed the `loop` glyph (arrowhead floated off the ring; now sits on the arc) and redrew the
  `advisor` glyph (executor ⇄ boxed advisor with two dashed consult arrows).

## [1.3.1] — 2026-07-14

### Changed
- `xcli` strategy + model routing updated for **grok 4.5** (verified against docs.x.ai
  2026-07-14): API flagship `grok-4.5` — 500k context, built for coding/agentic work, reasoning
  effort `low|medium|high` (high default) — documented as reasoner/advisor/peer tier. Explicitly
  noted the CLI/API split: grok CLI 0.2.101 exposes only `grok-composer-2.5-fast`/`grok-build`
  and rejects `-m grok-4.5`; run `grok models` before pinning.
- grok CLI drift fixed (hit live): `-s` now requires a **UUID** session id, not a name;
  examples updated in xcli.md and docs/strategies.md.

### Site & visual guide
- "The idea" section: the planned V1 **"Life of a task" Remotion animation** shipped as a
  progressive enhancement — a 15s themed loop (light + dark renders from one parameterized
  composition in `remotion/`) showing the problem (one agent's context filling), the split
  (controller writes a brief, a fresh worker takes it), the discard (worker fades, files remain),
  the gates (spec ✓ then quality ✓), and the ledger. Desktop ≥720px only; the static poster
  remains for mobile, `prefers-reduced-motion`, no-JS, and the claude.ai guide artifact.
- Site readability redesign (expert-panel run: codex gpt-5.6-sol high · grok-build · fable 5, two
  rounds + synthesis — plan in the run workspace): the page now teaches before it references.
  New narrative order (hero → "The idea" mental-model poster → run spine → preset-over-dimensions
  override figure → triage decision strip + two-sentence strategy cards → gates → tokens → start);
  first-read prose cut to ~1,100 words with a strict term-introduction order; two-register icon
  system (existing topology glyphs for strategies + 27 inlined lucide icons for concepts/steps/
  rails); grammar, model tiers, and the files tree collapsed into `<details>`; install command
  added; nav cut 11 → 5 question-shaped anchors. Same palette/type/components throughout.

## [1.3.0] — 2026-07-14

### Changed
- Built-in aliases renamed to community-recognizable AI-engineering terms (`config.yaml`, README,
  recipes, site): `fortress` → **`red-team`** (adversarial plan + panel review), `blitz` →
  **`swarm`** (parallel fan-out), `overnight` → **`afk`** (unattended goal loop), `penny-wise` →
  **`architect`** (aider-style strong-model-plans / cheap-model-executes). `codex-grind` unchanged.
  **Breaking for saved invocations of the old names** — aliases are user-editable config, so this
  ships as MINOR this early; re-add old names locally in `config.yaml` if you need them.

### Added
- CI: `scripts/check-sync` now runs on every PR and push to main
  (`.github/workflows/check-sync.yml`) — the release gate is enforced, not remembered.

### Fixed
- Human docs re-synced to the current skill (drift audit): usage.md's workspace table gains the
  v1.1.0/v1.2.0 files (`review-task<N>-<kind>-r<round>.md` findings files, `raw/`, `toolbox.md`);
  strategies.md's codex effort list corrected to `low..ultra` (was the pre-2026-07-13
  `minimal..xhigh`); docs/README.md marks token-optimization research as implemented (v1.1.0),
  lists the v1.1.0/v1.2.0 design docs, and adds check-sync to the release lifecycle.

## [1.2.1] — 2026-07-14

Audit fixes — a full walk of the skill package (post-v1.2.0 sanity check) confirmed the design
holds and surfaced three nits, all addressed here.

### Fixed
- `scripts/brief-check`: the report-path check now scans only the brief's Report section. Since
  v1.2.0 mandates `read: .orchestrate/toolbox.md` in every brief, the old whole-file grep matched
  that pointer first and the check passed vacuously — a brief with no report path went undetected.
- WORKER block: orientation sentence reworded role-agnostic ("Orient before acting — read the
  state your task depends on (for code edits: …)"), so integrator/evolve dispatches are no longer
  told to read neighboring modules their roles don't touch. Byte-identity across token-economy.md
  and all four WORKER templates preserved — no per-role variants introduced.
- Honest numbers re-measured after the rewording: WORKER ≈300, REVIEWER ≈140, MINIMAL ≈19
  (was 285/139/18); the stale "~150 tokens of contract" example in the blocks intro corrected to
  ~300; site + guide block-cost badges updated to match.

### Added
- `scripts/check-sync` (repo root — maintenance tooling, NOT shipped with the skill): mechanizes
  the release-time checks — block byte-identity per the dispatch coverage matrix, stated block
  costs vs measured (words×1.33, ±15), and presence of deliberately-replicated invariants
  (fix-wave rule, escalation ladder, overload rule, HEAD~1 warning, 80%-variance stat,
  reward-hacking ban) in every home. Its registry doubles as the sync map for prose the skill
  intentionally restates across files.

## [1.2.0] — 2026-07-13

Worker orientation licensed and tooled — a fresh subagent is EXPECTED to fill its context
(tree, manifests, conventions, neighboring patterns); v1.1.0's discipline governs how findings
enter chat, never whether the worker may learn the repo. Design:
`docs/designs/v1.2.0-orientation.md`.

### Added
- `scripts/toolbox [--refresh]` — zero-token shell probe of the repo's orientation tooling into
  `.orchestrate/toolbox.md` (structure/outline/search recipes with graceful degradation to
  `git ls-files`/grep, manifests, package manager, conventions files); auto-generated by
  `scripts/workspace`; every worker/reviewer brief points at it.
- "Orientation" section in `token-economy.md`: pointers are entry points not fences; the 5-step
  graded ritual (map → shape → rules → one neighboring pattern → symbols before bodies) with
  task-scaled budgets; per-role grading (reviewers targeted, loop cached, integrator git-state).

### Changed
- WORKER block: +"Orient before editing… reading to understand is work, not waste" (≈285 tok,
  honest numbers updated). REVIEWER block: licenses reading surrounding code to judge the diff
  in context, outline-first (≈139 tok).
- Misreadable phrasings fixed: the "explore the codebase and…" anti-pattern now explicitly
  targets vague BRIEFS, not worker orientation; "burns turns exploring" → "blind-searching".

### Site & visual guide (shipped between v1.1.0 and this release)
- New "Token economy" section — role-scoped block cards with honest per-dispatch costs, and a
  **life-of-a-dispatch timeline** (actor-coded steps with token-effect badges: spent / saved /
  quality-guarded; expandable example brief); disk map and run pipeline updated for
  `brief-check`, `token-economy.md`, findings files, and `.orchestrate/raw/`.
- The "Gates & safety rails" gate strip replaced with the numbered workflow pipeline
  (plan-veto → execute → spec → quality → evidence verify, gate-colored) plus an explicit
  fix→re-review loop strip; old pill-row markup and CSS removed.
- Orientation parity with v1.2.0: block-cost badges updated (≈285 / ≈139), "Orients first"
  clause in the timeline's work step, `toolbox` in the scripts map, `toolbox.md` in the
  workspace map.

## [1.1.0] — 2026-07-13

Token & context optimization across every strategy — cut narration, duplication, raw dumps, and
unstructured returns without degrading the context workers receive. Design (twice reviewed by an
external gpt-5.6-sol advisor): `docs/designs/v1.1.0-token-optimization.md`.

### Added
- `references/shared/token-economy.md` — role-scoped communication blocks (WORKER / REVIEWER /
  MINIMAL + team exemption), the priming anatomy ("prime with pointers, not payloads", pinned
  `read: <path> [@ <sha>]` pointer grammar, brief probe-test), raw-output
  redirect-at-execution convention (`.orchestrate/raw/`), controller diet, cache/session
  hygiene, honest numbers, and a dispatch coverage matrix.
- `scripts/brief-check` — executable brief validator (required sections, pointer resolution,
  unpinned-pointer warning under multiple worktrees, report-path check); wired into the staged,
  parallel, hierarchical, and team strategies.
- SKILL.md universal rule 8: *prime with pointers, work silent, report dense*.
- `docs/designs/v1.1.0-token-optimization.md` — the implementation design (advisor-reviewed,
  "ship with amendments" → all amendments adopted).
- docs: "Token economy" section in `usage.md`; optional input-side tooling note in `recipes.md`.

### Changed
- All 10 dispatch prompt templates embed their role's communication block; the implementer's
  clarify-first rule explicitly outranks pick-and-note.
- Reviewer returns restructured: full findings go to a collision-proof findings FILE
  (`review-task<N>-<kind>-r<round>.md`); inline = verdict + counts + path — inline caps can no
  longer truncate findings. Reviewer read-only scope clarified (repo read-only; `.orchestrate/`
  writable).
- `review-gates.md`: the coverage rule — never instruct a reviewer to self-filter findings;
  filtering is the controller's job (measured recall protection).
- `contracts.md`: inline-cap vs report-file norm, line grammars (search/explore returns,
  structured BLOCKED), workspace map gains `raw/` + findings files.
- `handoff.md`: probe-test before trusting any handoff/compaction summary.
- `advisor.md` strategy: server-side advisor tool (`advisor_20260301`) noted for API pipelines.
- `triage.md`: 4×/15× multiplier grounding on the don't-orchestrate rule.

## [1.0.2] — 2026-07-13

### Changed
- `xcli` strategy + model routing updated for the new Codex model family (verified against the
  official model docs): `gpt-5.6-sol` / `gpt-5.6-terra` / `gpt-5.6-luna` with the new reasoning
  effort ladder `low…ultra` (`ultra` fans out Codex-side subagents — documented as a fan-out
  decision, not an effort bump). Engine tier map added to `shared/model-routing.md`.

## [1.0.1] — 2026-07-13

### Added
- `docs/research/token-optimization.md` — research record on token/context/cost optimization for
  multi-agent orchestration (caveman-style output compression, report-only verbosity contracts,
  context-window economics, proven ecosystem techniques). Research only; no strategy behavior
  changed.
- `CHANGELOG.md` + `version:` frontmatter field — release/versioning machinery for the skill.
- Current version stated in the SKILL.md body so an installed agent can answer "which orchestrate
  version do I have?".

### Changed
- Docs reorganized: research records live in `docs/research/` (status header says which release
  implemented them, if any); implementation designs live in `docs/designs/` named
  `v<version>-<topic>.md` (`RESEARCH.md` → `research/foundations.md`, `DESIGN.md` →
  `designs/v1.0.0-initial-architecture.md`). System documented in `docs/README.md`.

## [1.0.0] — 2026-07-13

### Added
- Initial public release: 9 strategies (staged, parallel, hierarchical, team, workflow, loop,
  advisor, adversarial, xcli) as presets over 8 dimensions, auto-triage, dual review gates,
  file-based handoffs (`.orchestrate/` workspace), model routing, safety rails, saved aliases.
- `skills/orchestrate/` skill tree (SKILL.md router + references + prompts + scripts + config.yaml).
- Docs (`docs/`), visual guide (`site/` → orchestrate-skill.vercel.app), skills.sh-standard
  install (`install.sh`, `npx skills add gabros20/orchestrate`).

[Unreleased]: https://github.com/gabros20/orchestrate/compare/v1.3.1...HEAD
[1.3.1]: https://github.com/gabros20/orchestrate/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/gabros20/orchestrate/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/gabros20/orchestrate/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/gabros20/orchestrate/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/gabros20/orchestrate/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/gabros20/orchestrate/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/gabros20/orchestrate/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/gabros20/orchestrate/releases/tag/v1.0.0
