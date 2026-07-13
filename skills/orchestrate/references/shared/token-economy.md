# Token economy — prime with pointers, work silent, report dense

Goal: **zero wasted tokens, not minimal tokens.** Token spend explains ~80% of multi-agent quality
variance — spending tokens IS the capability. Cut narration, duplication, raw dumps, and
unstructured returns; never cut brief completeness. Underpriming costs more than overpriming: a
worker missing context burns turns exploring or round-trips NEEDS_CONTEXT (a full re-dispatch).

## The communication blocks (role-scoped — paste the ROLE's block into its dispatch, verbatim)

One block does not fit all roles: ~150 tokens of contract on a 4-line verifier is net-negative.
Keep block text byte-stable across a run (cache hygiene); per-task variables go late in the prompt.

### WORKER block — implementer, sub-orchestrator, integrator, loop executor, xcli workers

```
## Communication contract
Routine narration is silence: while working, don't announce tool calls, restate this brief,
or add pleasantries. Write text only when you find something load-bearing, change direction,
or hit a blocker. Required messages are NEVER silenced: task-state updates, approval requests,
integration/teammate coordination, security warnings, irreversible-action confirmations.
Minor choices — local, reversible, not user-visible, semantics-preserving (naming, formatting,
private helpers) — pick one and note it in your report. Defaults affecting security,
compatibility, persistence, or public behavior are NOT minor: resolve per your brief or
escalate.
Tool output: read targeted (grep, line-ranges) over whole files/logs. Redirect noisy commands
to a file at execution time (cmd > .orchestrate/raw/<task>-<what>.log 2>&1), inspect with
grep/tail; cite the minimum sufficient excerpt + the file path.
Blockers are structured, not brief: BLOCKED — what / evidence (excerpt + raw path) / what you
tried / what you need.
Reports: follow the schema, dense full sentences, state uncertainty and assumptions explicitly
— omit only rhetorical hedging, filler, arrow-chains, invented abbreviations.
When quoting literal code, commands, diffs, API names, or error strings: copy verbatim, never
paraphrase. Ordered multi-step instructions stay full prose.
```

### REVIEWER block — spec, quality, panel, consensus roles

A self-contained block (read-only roles don't run noisy commands, so the WORKER redirect line is
deliberately absent):

```
## Communication contract
Read targeted (grep, line-ranges) over whole files; when quoting literal code, commands, or
error strings: copy verbatim, never paraphrase. State uncertainty and confidence explicitly —
omit only rhetorical hedging and filler.
Report EVERY finding with severity + confidence — never self-filter to "important" ones;
triage is the controller's job. Findings go to the findings FILE (path in your inputs); inline
return = verdict + counts by severity + file path. Your repo access is read-only; the findings
file under .orchestrate/ is your one write.
```

### MINIMAL line — advisor, triage assessor, verifier, planner-debate

```
No preamble, no narration: return only your schema. Quote literals verbatim; state
uncertainty explicitly.
```

### Team exemption

Teammates keep the WORKER block **minus silence toward each other** — the team strategy exists
because workers must talk. Silence applies to routine narration, never to coordination.

## Dispatch coverage matrix (every surface, its block)

| Surface | Block |
|---|---|
| prompts/implementer, sub-orchestrator, integrator, evolve | WORKER |
| prompts/spec-reviewer, quality-reviewer (+ panel/consensus dispatches) | REVIEWER |
| prompts/advisor, triage-assessor, verifier, planner-debate | MINIMAL |
| team teammates (spawn prompts) | WORKER + team exemption |
| workflow-script `agent()` prompts | MINIMAL (schema-forced output is already structural) |
| xcli workers (codex/grok task text) | WORKER core (fold in; no Claude-specific mechanics) |
| loop executor (loop contract SOP) | WORKER |

Intentional exemptions: none — a dispatch with no block is a defect, not a default.

## Priming anatomy — "prime, don't dump" (brief quality standard)

A quality brief contains, in order:

1. **Objective** — 1–2 sentences, the definition of done.
2. **Scope** — in / out, explicit. Include **negative constraints** (what must NOT change) and
   **rejected alternatives with reasons** — code can't show these; the brief must.
3. **Pointers, not payloads** — one per line, machine-checkable:
   `read: <path> — <why>` (optional `@ <commit-sha>`; `(will exist)` marks generated artifacts
   brief-check skips). Paths resolve from the repo root stated at the top of the brief.
   **Pin with `@ <sha>`** whenever more than one writer is active or the run uses worktrees — a
   branch name is not a pin. Inline content only when it is *semantically complete, stable, and
   cheaper than rediscovery* (an interface, invariants, a constraint table — verbatim); on high
   fan-out, inline the one canonical payload every worker needs rather than making N workers
   rediscover it.
4. **Interfaces & constraints to honor** — exact values, formats, relationships (verbatim).
5. **Verification** — the command(s)/check(s) that prove done.
6. **Report contract** — schema, cap, file path to write it.
7. **Stop conditions** — when to return BLOCKED / NEEDS_CONTEXT instead of guessing, and which
   decision classes REQUIRE escalation (security, data, public API).

**Brief probe-test (controller gate, pre-dispatch):** the brief must answer — *what exactly is
done? how is it verified? which files, at which revision? what must remain unchanged? can this
worker actually reach every pointer? what requires escalation?* Not answerable → fix the brief
now (and run `scripts/brief-check`); a clarifying round-trip after dispatch costs a full worker
turn.

Anti-patterns: pasting session history · pasting whole files · "explore the codebase and…"
(unbounded reads) · duplicating plan text a path reference covers · unpinned pointers in
parallel/worktree runs.

## Raw-output convention

Noisy commands are **redirected to file at execution time** — the dump never enters the
transcript (saving after emission saves nothing; redirection is the input-side win). Chat carries
exit status + minimum sufficient excerpt + path. `.orchestrate/raw/` is gitignored with the
workspace. In worktree runs the store is per-worktree: anything still needed after merge is cited
(excerpt) in the task report or copied next to it before cleanup.

## Controller diet

- Read **reports by default, not diffs** — reviewers read diffs via `scripts/review-package`.
  Retain targeted inspection: specific hunks/symbols/files when a gate is ambiguous, reviewers
  conflict, or a reviewer returns "cannot verify from diff" (already routed to you).
- Never paste file contents into briefs (priming anatomy); reference artifacts by path; never
  re-read what a path reference covers. Ledger + `git log` on resume.
- Your own narration to the user follows the same discipline: outcome first, no play-by-play.

## Cache hygiene (best-effort, not a measured lever)

Keep shared template text stable across a run; per-task variables late in the prompt; don't churn
worker model/tool configurations mid-run. Claude Code manages provider caching internally —
prefix stability is the part you control. Staggering identical-prefix fan-outs is an OPTION only
(unmeasured through the Agent-tool runtime); the parallel strategy's batch dispatch stays the
default.

## Session hygiene

Long orchestration runs deserve a lean controller session: every unused always-loaded skill/MCP
costs ~1–1.5K input tokens per controller turn. Run `/checkup` (or use a minimal-skill profile)
before big runs.

## Honest numbers

The blocks' own cost (measured, words×1.33): WORKER ≈ 244 tokens/dispatch, REVIEWER ≈ 115,
MINIMAL ≈ 18 — vs the hundreds-to-thousands of narration tokens per worker turn they remove,
and the controller-context bloat every verbose return would re-cost on every later turn.
Expect **10–25% session-level savings** from output discipline — not the 65–75% output-only
headlines. The only trustworthy measure is an A/B on the provider's billing/usage page.
Multipliers for right-sizing *whether* to orchestrate (rule 7): single tool-using agent ≈ 4× a
chat interaction; multi-agent ≈ 15×. Watchlist (not exposed to this skill today): server-side
tool-result clearing (~48% peak-context in Anthropic's cookbook A/B) and Task Budgets
(self-paced token ceilings) — adopt when the runtime surfaces them.
