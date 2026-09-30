# Contributing

Contributions that improve portability, safety, or agent usefulness are welcome.

1. Create or update `skills/<name>/SKILL.md` with valid YAML frontmatter containing a matching `name` and a non-empty `description`.
2. Add or update its matching entry in `manifest.yaml`.
3. Keep shared policies canonical in `shared-rules/`; add an adapter only when an agent requires one.
4. Write skill and policy content in English. Retain only instructions that change an agent decision; link conditional references rather than duplicating them.
5. Run `./tests/test-install.sh` and include its result in the pull request.

Read [AGENTS.md](AGENTS.md), including its documentation length limit, before changing the repository. Keep each pull request focused and explain the behavior it changes.

When changing installation, uninstall, sync, or manifest validation, reuse shared logic in `lib.sh` and extend `tests/test-install.sh`. Its sync fixture uses `git archive HEAD`; test a committed snapshot to exercise script changes not yet committed in the working checkout. Run uninstall tests only on repository copies.

The installer validates manifest entries and source existence, not skill frontmatter or behavior. Validate those separately; an installer test pass does not prove that an agent can load or correctly execute the skill.

Project-level sync changes (`--scope`, the `lib.sh` project helpers, `import-project.sh`) must extend `test_projects` and `test_projects_sync`. Never commit project content or local paths here: project config belongs in the private projects repository, and the per-machine `local.yaml` stays untracked. Run project-scope `uninstall.sh` tests only against temporary homes.

For agent-authored changes, use `refactor` to delegate rule verification to its read-only `verify` subagent. Keep `.docs/` handoffs and learning notes untracked. Follow the commit approval policy in [AGENTS.md](AGENTS.md).
