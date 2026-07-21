# xcli — external coding CLIs as workers, peers, and second opinions

Purpose: Use external coding-agent CLIs as isolated workers, peers, or second-opinion engines.

Read when:
- A selected engine is external to the current host or portability requires headless CLI processes.

Skip when:
- The host's native subagents satisfy the task without external-engine benefit.

Inputs:
- Verified CLI help, authentication state, working directory, prompt, sandbox, and output path.

Produces:
- Executed CLI command, captured output, repository diff, and engine-specific caveats.

## Contents

- Codex (`codex exec`) — the most script-friendly
- Grok (`grok -p`)
- Claude Code as a subprocess (for symmetry / cross-account)
- Cursor (`cursor-agent`)
- Antigravity CLI (`agy`)
- opencode (`opencode run`)
- Hermes (`hermes -z`)
- Kimi (`kimi -p`)
- Rules (all engines)
- Division-of-labor heuristic

Preset: `engine=codex|grok|cursor|agy|opencode|hermes|kimi|mixed` — usually a dimension on another
strategy rather than a standalone topology (e.g. `staged engine=codex`, `adversarial
counter=codex`). Why: genuinely different capabilities (different model lineages for
cross-validation; separate subscription quotas; codex's sandbox), at the price of serialization
overhead and zero shared context — the prompt must carry EVERYTHING. xcli is also the
**portability floor**: on a host missing a native primitive, these engines recover parallel
fan-out and model pinning as background processes (`shared-hosts.md`).

**Verify flags before trusting them** — CLIs drift; run `<cli> --help` once per session before
scripting against it.

**Task text carries the WORKER communication block** (`shared-token-economy.md`) with
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
- Models (verified 2026-07-14 API / 2026-07-20 CLI): the flagship is **`grok-4.5`** (500k
  context, built for coding/agentic work, reasoning effort `low|medium|high`, high default) — grok
  CLI 0.2.106 now defaults to it as the sole listed model too. Lists drift — run `grok models`
  before pinning.
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

## Cursor (`cursor-agent`)

```bash
cursor-agent -p "task" --model <id> --output-format json
```
- Headless GOTCHA: in `-p` mode the agent's ask-user tool auto-receives "skipped by user" — a
  headless Cursor worker silently skips its own clarification gates. Anything human-gated needs
  ACP (`cursor-agent acp`, JSON-RPC over stdio with real blocking ask/permission requests) or an
  interactive session — never bare `-p`.
- Native `--worktree <name>`; when Cursor is the CONTROLLER, `.cursor/agents/*.md` subagents give
  parallel + background dispatch with per-agent `model:` pinning (depth 1).

## Antigravity CLI (`agy`)

```bash
agy -p "task" --cwd /path/to/repo     # the one vendor-documented headless form
```
- Flag surface beyond `-p`/`--cwd` (output format, approvals, non-interactive auth) is
  under-documented — probe `agy --help` yourself before scripting; treat blog-reported flags as
  rumors. Auth is keyring/OAuth (no confirmed CI path).
- Interactive `agy` is orchestration-strong (async subagents to depth 10, `/agents` panel,
  any-to-any send_message, per-subagent worktrees) but subagents inherit the parent model — for
  tier separation, pin the model per PROCESS instead.

## opencode (`opencode run`)

```bash
opencode run "task" --model <provider/model> --agent <name>
```
- In-session delegation is synchronous — for N-way parallelism run N `opencode run` processes in
  separate worktrees (or drive `opencode serve` + its SDK from the controller).
- `.opencode/agents/*.md` pin model + granular permissions per agent; its `question` tool gives
  structured ask-user in interactive runs.

## Hermes (`hermes -z`)

```bash
hermes -z "task"                      # clean stdout one-shot; also: hermes chat -q --quiet
```
- Its internal per-task model override is accepted then silently ignored (open upstream bugs) —
  pin the model per PROCESS (`hermes -z --model <id>`), one invocation per tier.
- `clarify` (its ask-user) times out after ~120s then proceeds on best judgment, and is blocked
  inside leaf subagents — keep human gates at the controller level. Also ships an
  OpenAI-compatible API server + JSONL batch runner for fleet-style use.

## Kimi (`kimi -p`)

```bash
kimi --version && kimi doctor                 # preflight; not logged in → user runs `kimi login` (device-code OAuth)
cd /path/to/repo && kimi -p "Full task: goal, constraints, files to touch, definition of done." \
  -m k3 --output-format text </dev/null   # no cwd flag — cd first; stdin undocumented, `</dev/null` defensively
```
- `--output-format text|stream-json` (only valid with `-p`) — `text` prefixes thinking/assistant
  lines with `•`; `stream-json` emits one JSON object per line.
- `-p` forces the `auto` permission policy — no approval gating exists headless (rejects
  `--yolo`/`--auto`/`--plan`); worktree + diff review is the ONLY containment.
- Models: `k3` (flagship, up to 1M context, `reasoning_effort: low|high|max`, default `high`) ·
  `kimi-for-coding` (256k, balanced worker) · `kimi-for-coding-highspeed` (6× speed at 3× quota —
  not a cheap tier, none exists). Effort has NO CLI flag — set via `/effort`,
  `[models."<alias>".overrides]` in config.toml, or the `KIMI_MODEL_*` env channel; switching
  model or effort mid-session invalidates the prompt cache.
- No programmatic quota check headless (`/usage` is TUI-only, rejected in `-p` mode) — don't
  dispatch a fleet assuming quota headroom.
- Kimi workers carry their OWN subagents (`Agent`/`AgentSwarm`) — nested orchestration multiplies
  spend like codex `ultra`; instruct workers not to swarm unless intended.
- Poisoned-session landmine: malformed tool-call JSON can wedge a session into permanent HTTP 400
  loops with no self-recovery — kill and restart as a NEW session, never resume a wedged run
  (legacy-tracker provenance; re-verify before trusting it as fixed).
- Resume: `-c` (most recent session, cwd-scoped) · `-S <id>` (specific; bare = picker) — mutually
  exclusive.
- State: `~/.kimi-code` (`KIMI_CODE_HOME` relocates it), sessions cwd-scoped underneath.
- CI env: `KIMI_CODE_NO_AUTO_UPDATE=1` (skip update preflight), `KIMI_DISABLE_TELEMETRY=1`.
- Legacy Python `MoonshotAI/kimi-cli` is a DIFFERENT tool (verified 2026-07-20 against live
  0.28.0) — its flags (`--print`, `--input-format`, `--quiet`, `--final-message-only`) are absent
  from kimi-code 0.28.0; never cite them.

## Rules (all engines)

1. One task per launch; split big jobs. The CLI sees NOTHING of your session — brief files work
   here too: write the brief, reference nothing conversational.
2. One git worktree per concurrent run, never two engines in one tree; copy `.env*` in.
3. Runs take minutes with no timeout — background them (Claude Code `run_in_background`; other
   hosts `nohup … &`) and poll the output file; don't block the controller.
4. **Review the diff yourself** (or via your review gate) before accepting — external engines
   don't inherit your review discipline.
5. Rate limit hit → report to the user; never retry-loop against a subscription quota.
6. Auth is the user's: `codex login` / grok cookie / `claude` login / `kimi login`. Never read or copy
   credential files.

## Division-of-labor heuristic

Claude = reasoning/architecture/review · Codex (GPT lineage) = heavy implementation + honest peer
counter · Grok = fast second opinion / search-adjacent tasks (and with `grok-4.5` on the API, a
frontier-class peer for coding and agentic work) · Kimi (Moonshot lineage, K3 — Artificial Analysis
Intelligence Index 4/189 as of 2026-07-20, behind Fable 5/GPT-5.6 Sol, ahead of Opus 4.8) =
frontier-class independent lineage, the fourth vote in cross-lineage panels, and the pick for
1M-context long-horizon/large-context work · Cursor/agy/opencode/Hermes = alternate workers when
quotas, sandboxing, or lineage diversity matter (agy = Gemini lineage, the third vote in a
cross-lineage panel). Cross-validation: send the same review to two engines, dedup findings, keep
the union (conflicting severity → higher).
