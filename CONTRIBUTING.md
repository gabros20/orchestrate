# Contributing

Improve strategy selection, dispatch contracts, host bindings, safety, review gates, or measurable
coordination efficiency without absorbing domain workflows or digital-product lifecycle logic.

## Pull-request checklist

1. Update the smallest owning runtime file and every deliberately replicated invariant.
2. Preserve byte-identical communication blocks in the prompt templates assigned to each role.
3. Add or update activation, traversal, output, and regression fixtures affected by the change.
4. Execute representative runtime scripts when their behavior changes.
5. Run:

   ```bash
   scripts/check-sync
   scripts/count-skill-tokens
   ```

6. Update README/user docs when the public workflow changes and `AGENTS.md`/`CLAUDE.md` when
   repository invariants change.
7. Record user-visible behavior in `CHANGELOG.md`.

Use semantic versioning. Synchronize `.codex-plugin/plugin.json`, the newest changelog release,
tag `v<version>`, and the matching GitHub Release. Runtime `SKILL.md` contains no version metadata.
