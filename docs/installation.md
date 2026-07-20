# Installation

Install the `orchestrate` runtime skill, verify that the client discovers it, and keep repository
documentation and evaluation assets outside the runtime context.

## Prerequisites

- `git`
- An Agent Skills-compatible coding client
- Optional external worker CLIs only when using `engine=codex|grok|cursor|agy|opencode|hermes`

The runtime detects the active client at kickoff. Read
[host adapters](../skills/orchestrate/references/shared-hosts.md) when a primitive or invocation
form differs from the documentation shorthand.

## Install with skills.sh

```bash
npx skills add gabros20/orchestrate-skill -g
```

Omit `-g` for a project-local installation.

## Install from a clone

```bash
git clone https://github.com/gabros20/orchestrate-skill.git
cd orchestrate-skill
./install.sh codex
```

The installer accepts one target and transactionally replaces only the installed runtime skill:

| Target | Destination |
|---|---|
| `codex` | `${CODEX_HOME:-$HOME/.codex}/skills/orchestrate` |
| `agents` | `~/.agents/skills/orchestrate` |
| `claude` | `~/.claude/skills/orchestrate` |
| `cursor` | `~/.cursor/skills/orchestrate` |
| `antigravity` | Gemini configuration and Antigravity CLI skill directories |
| `opencode` | `~/.config/opencode/skills/orchestrate` |
| `grok` | `~/.grok/skills/orchestrate` |
| `hermes` | `~/.hermes/skills/orchestrate` |
| `all` | Claude, Codex, and cross-agent standard directories |

Repository-only docs, evals, release metadata, and site assets are not installed.

## Verify discovery

Start a new client session, then invoke the client-native skill form:

```text
$orchestrate execute this plan with the smallest effective agent topology
```

Codex uses `$orchestrate`. Slash-command clients may expose `/orchestrate`; other clients may use
an @-mention, skill tool, or natural-language activation. Documentation uses `/orchestrate` as a
portable shorthand after making this distinction.

If discovery fails, confirm the installed file and frontmatter:

```bash
head -5 "${CODEX_HOME:-$HOME/.codex}/skills/orchestrate/SKILL.md"
```

It must contain `name: orchestrate` and a valid `description`.

## Update

```bash
cd orchestrate-skill
git pull --ff-only
./install.sh codex
```

Or rerun the `npx skills add` command if installed through skills.sh. The transactional installer
stages the new runtime first and restores the previous installation if replacement fails.

## Uninstall

Remove only the installed skill directory for the client you used. For Codex:

```bash
rm -rf "${CODEX_HOME:-$HOME/.codex}/skills/orchestrate"
```

This does not remove a project's `.orchestrate/` run ledger or work artifacts.

## Optional external engines

External engines are additive; in-client orchestration does not require them. Before dispatching to
one, install and authenticate that CLI, inspect its current `--help`, and use the verified command
form in [external CLI strategy](../skills/orchestrate/references/strategy-xcli.md). Credentials stay
outside this skill and CLI flags must be treated as version-sensitive.
