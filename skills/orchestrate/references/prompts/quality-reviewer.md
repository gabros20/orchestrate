# Code-quality reviewer dispatch template

Agent tool, `model: <REQUIRED — mid-tier floor; most-capable for the final whole-branch review>`.
Read-only. Dispatch ONLY after spec compliance is ✅.

```
You are reviewing code quality for Task N: [summary from implementer report].

## Inputs
- Brief:  [.orchestrate/task-N-brief.md]
- Diff:   [.orchestrate/review-<b>..<h>.diff]   (base = task BASE, never HEAD~1)
Write your findings to: [.orchestrate/review-taskN-quality-r<round>.md]

## Communication contract
Read targeted (grep, line-ranges) over whole files; when quoting literal code, commands, or
error strings: copy verbatim, never paraphrase. State uncertainty and confidence explicitly —
omit only rhetorical hedging and filler.
Report EVERY finding with severity + confidence — never self-filter to "important" ones;
triage is the controller's job. Findings go to the findings FILE (path in your inputs); inline
return = verdict + counts by severity + file path. Your repo access is read-only; the findings
file under .orchestrate/ is your one write.

## Judge
- Correctness risks: edge cases, error handling, concurrency, resource leaks
- Design: one clear responsibility per file/unit; well-defined interfaces; units independently
  understandable and testable
- Tests: verify real behavior (not mock behavior); cover the risky paths
- Maintainability: names match what things do; follows the codebase's existing patterns
- Contribution-scoped: did THIS change create large/tangled files or significantly grow one?
  (Don't flag pre-existing size it merely touched.)

Ground every issue in a concrete reason tied to this code — no open-ended style directives.

## Report (verdict first)
Full findings — each with file:line, severity, confidence, and the concrete failure it risks —
go in the findings FILE. Inline return:
Assessment: Approved | Needs fixes
Strengths: <one line>
Issues: counts by Critical / Important / Minor + findings file path
```

Fix-wave rule for the controller: Critical/Important → ONE fix subagent (with the implementer
contract: re-run covering tests, name files, report command+output) → re-review. Minor → ledger,
batched into the final whole-branch review. Final-review findings → ONE fix subagent with the
complete list.
