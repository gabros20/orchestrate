# Agent guide — orchestrate-skill

This repository packages one independently versioned runtime skill: `orchestrate`. The GitHub and
plugin package name is `orchestrate-skill`; the runtime identifier and Codex invocation remain
`orchestrate` and `$orchestrate`.

## Ownership boundary

`orchestrate` owns how work is assigned across agents: topology selection, dispatch, isolation,
monitoring, review gates, durable state, recovery, and handoff. It does not decide which digital-
product lifecycle domains are required and does not replace design, frontend, backend, growth, or
other domain skills. A lifecycle composer may request orchestration, but the two capabilities stay
independent.

## Repository contract

- `skills/orchestrate/SKILL.md` is the activation-time strategy router and universal contract.
- `skills/orchestrate/references/` is one flat layer of directly routed `strategy-*`, `shared-*`,
  `prompt-*`, and triage references.
- `skills/orchestrate/scripts/` provides deterministic workspace, brief, review, and orientation
  mechanics.
- `skills/orchestrate/agents/openai.yaml` contains Codex-facing discovery metadata.
- `.codex-plugin/plugin.json` contains package, storefront, and release metadata.
- `evals/` tests activation, traversal, output quality, and compression separately.

## Change rules

1. Preserve the ownership boundary above; do not turn this into the `digital-product` composer.
2. Keep `SKILL.md` as a thin router. Every reference must be directly linked, flat, and prefixed
   with its loading condition, required inputs, and contribution.
3. Preserve role-scoped communication blocks byte-for-byte wherever the specialized gate requires
   replication. Update stated token measurements only from the measuring script.
4. Keep host detection and honest degradation intact. Never imply a primitive exists on a client
   where it does not.
5. Preserve durable `.orchestrate/` artifacts, explicit model assignment, ordered review gates,
   bounded loops, and the no-duplicate-agent overload rule.
6. Keep runtime frontmatter to `name` and `description`; release metadata stays outside the runtime.
7. Update affected activation, traversal, output, or compression fixtures when behavior changes.
8. Link to one source of truth instead of copying strategy or contract prose into public docs.

## Validation and release

Run before handoff:

```bash
scripts/check-sync
scripts/count-skill-tokens
```

The first command runs the universal package/navigation gate and the orchestrate-specific
byte-identity, honest-number, invariant, and host-layer checks. Release by synchronizing
`.codex-plugin/plugin.json`, `CHANGELOG.md`, tag `v<version>`, and the GitHub Release. Never add the
version to runtime `SKILL.md`.
