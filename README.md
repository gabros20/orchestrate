# Orchestrate

Select and run bounded multi-agent execution strategies with durable artifacts, explicit model
routing, typed review gates, and safe recovery. Point `orchestrate` at a plan or multi-step task;
it chooses a strategy—or follows one you force—and coordinates the workers without absorbing their
implementation into the controller context.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Visual guide:** [orchestrate-skill.vercel.app](https://orchestrate-skill.vercel.app)

## Boundary

`orchestrate` owns **how work is assigned and coordinated across agents**. It does not decide which
product, design, engineering, marketing, sales, or operations work a digital product requires. A
lifecycle composer such as `digital-product` owns that dependency graph and may optionally request
multi-agent execution; neither skill depends on the other.

Do not orchestrate small, tightly coupled work that one agent can complete efficiently in one
context.

## Strategies

| Strategy | Use when |
|---|---|
| **staged** *(default)* | Mostly independent tasks need fresh implementation and ordered dual review |
| **parallel** | Independent tasks can run concurrently in isolated worktrees |
| **hierarchical** | Several domains need their own sub-orchestrators and workers |
| **team** | Workers must message, debate, or coordinate across layers |
| **workflow** | Large repeated fan-out should be held by a deterministic script |
| **loop** | Work repeats until a verifiable goal or scheduled condition is met |
| **advisor** | Expensive reasoning should be separated from cheaper execution |
| **adversarial** | A high-stakes plan needs independent challenge before execution |
| **xcli** | External coding CLIs act as workers, peers, or second opinions |

Strategies are presets over `topology`, `planning`, `review`, `engine`, `models`, `isolation`,
`trigger`, and `budget`. Explicit dimension overrides win over the selected preset.

## Install

With skills.sh:

```bash
npx skills add gabros20/orchestrate-skill -g
```

Or clone and install for a specific client:

```bash
git clone https://github.com/gabros20/orchestrate-skill.git
cd orchestrate-skill
./install.sh codex
```

| Target | Destination |
|---|---|
| `codex` | `${CODEX_HOME:-$HOME/.codex}/skills/orchestrate` |
| `agents` | `~/.agents/skills/orchestrate` |
| `claude` | `~/.claude/skills/orchestrate` |
| `cursor` | `~/.cursor/skills/orchestrate` |
| `antigravity` | Gemini IDE and Antigravity CLI skill paths |
| `opencode` | `~/.config/opencode/skills/orchestrate` |
| `grok` | `~/.grok/skills/orchestrate` |
| `hermes` | `~/.hermes/skills/orchestrate` |
| `all` | Claude, Codex, and the cross-agent path |

The installer stages a complete runtime copy before replacement and restores the prior
installation if replacement fails.

## Use

Codex explicit invocation uses `$orchestrate`:

```text
Use $orchestrate to execute plan.md with automatic strategy selection.
Use $orchestrate to run plan.md strategy=parallel workers=4.
Use $orchestrate to audit every service strategy=workflow.
Use $orchestrate to keep iterating until tests pass strategy=loop budget=cycles:10.
```

Documentation uses `/orchestrate` as shorthand. Other clients may expose a slash command,
`@orchestrate`, a skill tool, or natural-language activation.

Selection priority is:

```text
explicit strategy > saved alias > auto-triage > ask on genuine conflict
```

Saved aliases live in `skills/orchestrate/config.yaml`; explicit dimensions always override an
alias.

## Supported hosts

Claude Code is the reference host. The skill resolves six abstract primitives—dispatch, parallel,
message, ask-user, worktree, and loop—through the current client's native tools where possible,
then an external CLI, then a named solo degradation.

| Host | Native subagents | Model pinning | Important constraint |
|---|---|---|---|
| Claude Code | Deep, background, teams | Yes | Reference implementation |
| Codex | Parallel agents | Yes | Bind to the current Codex agent tools and limits |
| Cursor | Parallel/background | Yes | Headless ask-user support varies |
| Antigravity | Async agents and messaging | Inherits parent | IDE and CLI paths differ |
| opencode | Synchronous in-session | Agent-file model | External processes recover fan-out |
| Grok Build | Parallel, auto-worktree | Host-dependent | Skills load at session start |
| Hermes | Small flat pool | Host-dependent | Explicit activation may be required |

The runtime [host adapter](skills/orchestrate/references/shared-hosts.md) instructs the controller to
verify current tools and CLI flags rather than trust a static matrix.

## Safety and quality model

- **Controller does not silently implement** failed worker tasks.
- **Artifacts on disk are the interface** under `.orchestrate/`.
- **Every dispatch pins a model** rather than inheriting an accidental default.
- **Dual review is ordered**: spec review, then quality review.
- **Ledger before memory**: durable progress wins over recollection after resume or compaction.
- **No duplicate workers on overload**: resume or nudge the existing worker.
- **Branch and loop rails stay active**: explicit consent, cycle caps, kill switch, and open-work cap.

## Runtime resources

```text
skills/orchestrate/SKILL.md       activation, routing, workflow, and completion
skills/orchestrate/config.yaml    saved strategy/dimension aliases
skills/orchestrate/references/    29 flat strategy, shared, and prompt references
skills/orchestrate/scripts/       workspace, brief, review-package, and toolbox helpers
```

All references are directly linked from `SKILL.md`; no required route depends on directory
discovery or a second-hop index.

## Repository map

```text
.codex-plugin/plugin.json  Codex plugin and release metadata
AGENTS.md / CLAUDE.md      repository and client-specific maintainer guidance
skills/orchestrate/        portable runtime skill and client metadata
evals/                     activation, traversal, output, and compression fixtures
docs/                      installation, usage, strategies, recipes, research, and designs
site/                      optional visual guide
remotion/                  visual-guide animation source
scripts/                   baseline and orchestration-specific release gates
```

## Validate

```bash
scripts/check-sync
scripts/count-skill-tokens
```

The baseline gate validates packaging, flat direct routing, reference headers and contents lists,
plugin/client metadata, runtime scripts, evaluation fixtures, and version alignment. The specialized
gate then checks byte-identical role communication blocks, honest token-cost statements, replicated
invariants, and host-layer limits.

## Documentation

- [Installation](docs/installation.md)
- [Usage](docs/usage.md)
- [Strategies](docs/strategies.md)
- [Recipes](docs/recipes.md)
- [Evaluation fixtures](evals/README.md)

## Versioning and releases

Each release synchronizes `.codex-plugin/plugin.json`, the newest `CHANGELOG.md` release, git tag
`v<version>`, and the matching GitHub Release. Runtime `SKILL.md` intentionally carries no version
or repository metadata.

## Contributing

See [AGENTS.md](AGENTS.md) for repository invariants and [CONTRIBUTING.md](CONTRIBUTING.md) for the
change and release workflow. The repository is independently versioned and remains usable without
`digital-product` or any sibling skill checkout.

## Requirements

- An Agent Skills-compatible client with either native subagents or access to a supported external
  coding CLI.
- `git` for branch/worktree isolation.
- Any selected external engine installed, authenticated, and verified with its current `--help`.

## License

[MIT](LICENSE) · Tamás Gábor ([@gabros20](https://github.com/gabros20))
