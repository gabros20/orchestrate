# Review gates — plan-veto before, output review after

Purpose: Define ordered spec, quality, panel, and consensus gates with durable findings.

Read when:
- A run enables review or needs objective acceptance before integration.

Skip when:
- Review is explicitly off and the task's risk permits it.

Inputs:
- Task brief, diff or artifact, acceptance criteria, reviewer roles, and findings path.

Produces:
- Typed review findings, pass/fail result, fix instructions, and re-review state.

Two DISTINCT gate kinds; don't conflate them. Gates are enforced, not trusted: a gate that can't
fail the work isn't a gate.

## 1. Plan-veto (before any execution)

A dedicated reviewer that can REJECT the plan and force rework — cheaper than rejecting code.
Forms, by rising cost: controller self-check against the four lenses (overbuilt/fragile/missing/
structure-fights-goal) → independent plan-review subagent → adversarial debate
(`strategy-adversarial.md`) → team plan-approval (teammate stays read-only until the lead
approves). Rejected plans go back with REASONS; cap the cycles (default 3), then escalate.

## 2. Output review (after execution)

**Order is law: spec compliance FIRST, quality SECOND.** Spec answers "did they build what was
asked — nothing missing, nothing extra"; quality answers "is it well-built". Quality-reviewing
non-compliant code is wasted tokens.

- Reviewers are **read-only** and get: the brief, the implementer's report, the diff package, and
  the plan's Global Constraints VERBATIM (exact values, formats, relationships).
- **Do-not-trust-the-report**: reviewers verify by reading code, never by believing claims.
  Implementer rationale never downgrades a severity.
- **Never pre-judge findings** in a reviewer prompt ("don't flag X", "at most Minor", "the plan
  chose this") — if you're typing that, you're dodging a review loop you need.
- **The coverage rule — never instruct a reviewer to self-filter** ("only flag high-severity",
  "be conservative", "at most N issues"): measured to silently drop recall. Reviewers report
  EVERYTHING found, each with severity + confidence; filtering/triage is the CONTROLLER's job at
  the dedup/merge step. Terseness rules apply to a reviewer's prose, never its finding count.
  Findings go to the findings file (`shared-contracts.md`) so inline caps can't truncate them.
- Findings loop: Critical/Important → fix subagent → RE-REVIEW (no skipping); Minor → ledger,
  batch to final review. ⚠️ "cannot verify from diff" → the CONTROLLER resolves (it holds
  cross-task context), never auto-pass.

## Panels (`review=panel:N`) and consensus (`review=consensus:N`)

- Panel: N reviewers, each ONE lens (security / performance / architecture / testing / a11y…).
  Diverse lenses catch what redundant copies can't.
- Lenses may also decorrelate by INPUT — diff-only · codebase-only (still brief + constraints, no
  diff) · diff+report+brief (standard) — or by ENGINE LINEAGE (xcli peers/peer tier); worker
  transcripts are post-mortem forensics only (`shared-monitoring.md` paths), referenced, never
  pasted into a dispatch.
- Review compute is high-return — cheaper than the work it audits; decorrelated lenses stack, no
  single lens catches everything (Cursor 2026, bounded observation).
- Dedup rules: same file:line + same issue → merge, credit all finders; conflicting severity →
  take the HIGHER; conflicting recommendations → keep both, attributed.
- Severity calibration: impact × likelihood; externally exploitable → always Critical/High.
- Consensus: N independent verifiers vote real/refuted per finding; majority rules; prompt them
  to REFUTE (default-skeptic), or the vote is decorative.

## Verification with evidence (the /verify split)

For anything user-facing or high-stakes, split verification:
1. **Subjective first — a FRESH read-only verifier subagent** drives the real running app (dev
   server + browser/CLI driver): exercises the change like a user, captures screenshot AND video
   to a gitignored `evidence/` dir, returns strictly `works|broken / expected / observed /
   evidence`. Fresh = independence; the model that wrote the code grades its own homework too
   generously.
2. **Objective second — the controller** runs the codified checks (typecheck/lint/unit/e2e) as a
   regression sweep.
Broken → fix → a NEW fresh verifier; cap ~3 rounds, then escalate. PRs ship with the evidence:
screenshot embedded inline, video linked — reviewers approve behavior, not vibes. A fix that
doesn't move the real metric isn't a fix — keep watching it next cycle.
