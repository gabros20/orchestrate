# xcli — external coding CLIs as workers, peers, and second opinions

Preset: `engine=codex|grok|mixed` — usually a dimension on another strategy rather than a
standalone topology (e.g. `staged engine=codex`, `adversarial counter=codex`).
Why: genuinely different capabilities (different model lineages for cross-validation; separate
subscription quotas; codex's sandbox), at the price of serialization overhead and zero shared
context — the prompt must carry EVERYTHING.

**Verify flags before trusting them** — CLIs drift; run `<cli> --help` once per session before
scripting against it.

**Task text carries the WORKER communication block** (`shared/token-economy.md`) with
`.orchestrate/raw/` paths made absolute for the CLI's cwd — external workers narrate by default
and their stdout lands in YOUR context; the contract is the filter.

## Codex (`codex exec`) — the most script-friendly

```bash
codex --version && codex login status          # preflight; not logged in → user runs `codex login`
OUT=$(mktemp)
codex exec --cd /path/to/repo \
  -m gpt-5.6-terra -c model_reasoning_effort=high \
  --sandbox workspace-write \
  -o "$OUT" \
  "Full task: goal, constraints, files to touch, definition of done." </dev/null
cat "$OUT"; git -C /path/to/repo status --short   # read result; inspect what it actually changed
```
- `</dev/null` is MANDATORY in scripts — open stdin makes codex wait forever. Long prompt →
  `codex exec [flags] - < task.md`.
- Structured output: `--output-schema schema.json` (validated) · events: `--json` (JSONL:
  `thread.started/turn.completed/item.completed/error`).
- Models (verified 2026-07-13): `gpt-5.6-sol` (flagship — reasoner/advisor/peer tier),
  `gpt-5.6-terra` (balanced — standard worker/reviewer), `gpt-5.6-luna` (cheap — mechanical
  worker); `gpt-5.5`/`gpt-5.4[-mini]` remain available. Re-verify before pinning: model lists
  drift (`codex exec -m <slug>` errors loudly on an unknown slug).
- Reasoning effort: `-c model_reasoning_effort=low|medium|high|xhigh|max|ultra` (medium default).
  `ultra` fans out Codex-side subagents — nested orchestration that multiplies spend like any
  fan-out; use only when you'd have approved a fleet anyway.
- Approvals: `-a untrusted|on-request|never`; network inside sandbox:
  `-c sandbox_workspace_write.network_access=true`. NEVER `--dangerously-bypass-approvals-and-sandbox`.
- Follow-up same session: `codex exec resume --last "…" </dev/null` (cwd-scoped).
- Monitor/session store: `$CODEX_HOME` (default `~/.codex`). Codex-as-MCP: `codex mcp-server`.

## Grok (`grok -p`)

```bash
grok -p "task" --output-format json          # plain|json|streaming-json
grok --cwd /path -m <model> -s "$(uuidgen)" -p "task"   # session id MUST be a UUID (CLI ≥0.2.x)
grok -r <id> -p "follow-up"                  # resume; -c = continue last
```
- Models (verified 2026-07-14): the API flagship is **`grok-4.5`** (500k context, built for
  coding/agentic work, reasoning effort `low|medium|high`, high default) — but the CLI ships its
  own shorter list; 0.2.101 exposes only `grok-composer-2.5-fast` (default) and `grok-build`, and
  `-m grok-4.5` errors until the CLI catches up. Run `grok models` before pinning.
- Approval is all-or-nothing (`--always-approve`) — prefer read-only tasks, or babysit.
- Sessions on disk: `~/.grok/sessions`. Long-lived JSON-RPC: `grok agent stdio` (ACP).
- No reasoning-effort flag in the CLI; effort is an API-side knob.

## Claude Code as a subprocess (for symmetry / cross-account)

```bash
claude -p --bare --output-format stream-json --max-turns 30 \
  --model sonnet --permission-mode acceptEdits \
  --agents '{"worker":{"description":"…","prompt":"…"}}' "task"
```
- `--bare` for scripts/CI (no auto-discovery; auth via env). `--json-schema` for validated output.
- Background fleet: `claude --bg "task"` → monitor `claude agents --json`, `claude logs <id>`,
  attach with `claude attach <id>`. Session lookup is cwd-scoped for `--resume`.

## Rules (all engines)

1. One task per launch; split big jobs. The CLI sees NOTHING of your session — brief files work
   here too: write the brief, reference nothing conversational.
2. One git worktree per concurrent run, never two engines in one tree; copy `.env*` in.
3. Runs take minutes with no timeout — background them (`run_in_background`) and poll the output
   file; don't block the controller.
4. **Review the diff yourself** (or via your review gate) before accepting — external engines
   don't inherit your review discipline.
5. Rate limit hit → report to the user; never retry-loop against a subscription quota.
6. Auth is the user's: `codex login` / grok cookie / `claude` login. Never read or copy
   credential files.

## Division-of-labor heuristic

Claude = reasoning/architecture/review · Codex (GPT lineage) = heavy implementation + honest peer
counter · Grok = fast second opinion / search-adjacent tasks (and with `grok-4.5` on the API, a
frontier-class peer for coding and agentic work). Cross-validation: send the same
review to two engines, dedup findings, keep the union (conflicting severity → higher).
