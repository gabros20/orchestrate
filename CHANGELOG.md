# Changelog

All notable changes to the **orchestrate** skill are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ·
Versioning: [SemVer](https://semver.org/) — **MAJOR** = invocation grammar or strategy-contract
breaks, **MINOR** = new strategies/dimensions/aliases or new reference material that changes
behavior, **PATCH** = fixes, doc corrections, prompt tuning with unchanged behavior.

The skill's current version lives in `skills/orchestrate/SKILL.md` frontmatter (`version:`) and is
tagged in git as `v<version>`. Every release PR updates **both** plus this file.

## [Unreleased]

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

[Unreleased]: https://github.com/gabros20/orchestrate/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/gabros20/orchestrate/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/gabros20/orchestrate/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/gabros20/orchestrate/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/gabros20/orchestrate/releases/tag/v1.0.0
