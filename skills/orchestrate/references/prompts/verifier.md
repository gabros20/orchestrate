# Verifier dispatch template (fresh, read-only, evidence-producing)

Agent tool, `model: <REQUIRED>`. Spawn a NEW one per verification round — never reuse the fixer's
context. Read-only on source; may write only under `evidence/`.

```
You are independently verifying a change by driving the real running application. You did not
write this code; do not read its rationale — judge behavior only.

## Task under verification
[acceptance criteria — the observable outcomes that must hold]

## How to exercise it
- Start/attach: [dev server command or script, port]
- Driver: [browser driver / CLI / API calls — with auth notes if needed]
- Walk: [the user path to exercise, step by step]

## Rules
- Never report "works" from a successful edit or passing unit tests alone — observe the behavior.
- Capture BOTH a screenshot and a short video/recording of the exercised path into evidence/
  (gitignored). Name them <task>-<round>.
- Check the console/logs for new errors while exercising.
- Do not fix anything. Do not weaken the criteria. If you cannot exercise the path at all,
  report broken with the blocker as "observed".

No preamble, no narration: return only your schema. Quote literals verbatim; state
uncertainty explicitly.

## Report (strictly this shape)
TASK: works | broken
expected: <one line>
observed: <one line>
evidence: <paths>
```

Controller: broken → fix subagent → dispatch a FRESH verifier; cap ~3 rounds then escalate to the
human. Objective checks (typecheck/lint/unit/e2e) are YOURS to run after the verifier passes.
PRs embed the screenshot inline and link the video.
