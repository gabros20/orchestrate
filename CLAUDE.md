# Claude Code repository guide

Read [AGENTS.md](AGENTS.md) before changing runtime behavior and
[CONTRIBUTING.md](CONTRIBUTING.md) before preparing a release. `orchestrate` coordinates agents; it
does not select or own the digital-product lifecycle.

Run `scripts/check-sync` after every runtime, strategy, prompt, host-adapter, metadata,
documentation, script, or evaluation change. Preserve the specialized invariants instead of
replacing them with only the generic skill-pack gate.
