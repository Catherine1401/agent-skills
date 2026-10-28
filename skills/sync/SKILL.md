---
name: sync
description: Two-way sync the current Git branch with its upstream using merge (pull with merge, then push). Use when asked to sync the branch or codebase; not for rebasing or syncing other branches.
---

# Sync

- Work only on the current branch and its upstream; stop if HEAD is detached or no upstream is set.
- Stop if the working tree has uncommitted or untracked changes; never stash, commit, or discard them.
- Run `git fetch`, then `git merge --no-edit @{u}`; never rebase, force, or reset.
- On merge conflicts, resolve every conflicted file by preserving the intent of both sides, verified against each side's commits; run the project's build or tests when available, then commit the merge. If a conflict's correct resolution cannot be determined, run `git merge --abort` and report that file.
- Report each resolved file and how it was resolved.
- Run `git push` only when the branch is ahead of its upstream; never force-push. If the push is rejected, report it and stop; do not retry.
- Report incoming and outgoing commit counts and the final `git status -sb`.
