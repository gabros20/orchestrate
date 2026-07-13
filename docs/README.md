# Docs index

Four documents cover using `orchestrate`; two more (linked at the bottom) cover why it's built the
way it is. Each doc has one job — read in this order the first time, then jump straight to whichever
one answers your question.

| Doc | Type | Answers |
|---|---|---|
| [installation.md](installation.md) | How-to | How do I get `/orchestrate` running in Claude Code (or Codex)? |
| [usage.md](usage.md) | Reference | What does every flag, dimension, and workspace file actually do? |
| [strategies.md](strategies.md) | Reference / explanation | What does each of the 9 strategies do, and when do I reach for it? |
| [recipes.md](recipes.md) | How-to | What's the exact command for `<scenario>`? |

## Reading order

1. **[installation.md](installation.md)** — install it, confirm `/orchestrate` responds.
2. **[usage.md](usage.md)** — the invocation grammar, the 8 dimensions, and how selection
   (`strategy=` > `alias=` > triage) works. Read this once, fully; everything else builds on it.
3. **[strategies.md](strategies.md)** — one strategy at a time, as you need it. Skip straight to
   the strategy triage already picked for you, or browse to pick one yourself.
4. **[recipes.md](recipes.md)** — copy-paste starting points: the 5 built-in aliases and a set of
   scenario commands. Keep this one open while you work.

If you only read one page, read **usage.md** — it's the full control surface; the others are
elaboration and shortcuts on top of it.

## Background (not needed to use the skill)

Two folders separate *what we learned* from *what we shipped*:

- **[research/](research/)** — research records: the evidence and sources gathered before any
  implementation. Version-agnostic; each doc's header states its status (which release implemented
  it, or "research only — not yet implemented").
  - [research/foundations.md](research/foundations.md) — the original research that fed v1.0.0
    (X posts, official Claude Code docs, prior orchestration skills, CLI docs).
  - [research/token-optimization.md](research/token-optimization.md) — token/context/cost
    optimization for multi-agent orchestration (research only as of v1.0.1).
- **[designs/](designs/)** — implementation designs that shipped, one per release that changed
  behavior. **The filename carries the release version** (`v<version>-<topic>.md`) and the header
  states the version + date; [CHANGELOG.md](../CHANGELOG.md) is the cross-reference.
  - [designs/v1.0.0-initial-architecture.md](designs/v1.0.0-initial-architecture.md) — why
    strategies are presets over dimensions, the file layout, the build decisions.

Lifecycle: research lands in `research/` → when acted on, an implementation design lands in
`designs/` as `v<next-version>-<topic>.md` → the release bumps `version:` in SKILL.md, adds a
CHANGELOG entry, and tags `v<version>`.

Read these if you want to know *why* something works the way it does, or if you're extending the
skill yourself.
