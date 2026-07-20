# Isolation — worktrees for parallel writers

Purpose: Assign writers to safe branches or worktrees and define integration ownership.

Read when:
- More than one agent may write or the task needs branch-level isolation.

Skip when:
- The run has one writer and no branch separation requirement.

Inputs:
- Repository state, task ownership, base revision, writers, and integration order.

Produces:
- Isolation plan, worktree or branch paths, merge sequence, and cleanup.

Worktree = separate working dir + branch over one shared object store. It prevents PHYSICAL
conflicts (two agents editing one tree), not LOGICAL ones (incompatible assumptions still break
the merge) — partitioning and merge gates handle those (`shared-contracts.md`).

## Mechanisms

- **Subagents**: `isolation: "worktree"` on the Agent dispatch (or frontmatter in a custom agent
  def). Each parallel invocation gets its own temporary worktree, auto-removed if it finishes
  unchanged. ~200–500ms + disk per agent — use only for parallel WRITERS.
- **Sessions you run**: `claude --worktree <name>` (`-w`) → `.claude/worktrees/<name>/` on branch
  `worktree-<name>`; EnterWorktree/ExitWorktree switch mid-session. Other hosts' accelerators:
  Cursor `--worktree` · Grok subagents auto-worktree · Antigravity per-subagent worktree option.
- **Plain git (canonical — works on every host)**: `git worktree add /tmp/wt-taskA -b
  agent/task-a` then `--cd`/`--cwd` the CLI into it. One engine per tree, never two.

## Contract per worktree

1. **Copy the repo's gitignored `.env*` in** — a fresh worktree has none; builds fail
   mysteriously without it. (`.worktreeinclude` automates this for Claude-managed trees.)
2. Own deps: run the install step; don't share `node_modules` across trees.
3. Base: default clean `origin/HEAD`; set `worktree.baseRef: "head"` to carry unpushed work in.
4. One task per tree; the worker commits there and returns a branch/PR ref.
5. **Removal is mandatory**: `git worktree remove <path>` when merged/abandoned (a leftover pins
   its branch); controller ends the run by checking `git worktree list` is clean. Claude-managed
   trees are locked while live and swept by `cleanupPeriodDays`; manual ones are yours to remove.
6. Nav/dev servers started inside a tree die with the run — kill them in cleanup (lingering
   localhost servers are the classic parallel-batch leak).

## When NOT to isolate

Single writer (staged) — a shared tree with recorded BASEs is simpler and cheaper. Read-only
fan-out — readers can't conflict; skip the overhead entirely.
