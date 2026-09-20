# Contributing

Contributions that improve portability, safety, or agent usefulness are welcome.

1. Create or update `skills/<name>/SKILL.md`.
2. Add or update its matching entry in `manifest.yaml`.
3. Keep shared policies canonical in `shared-rules/`; add an adapter only when an agent requires one.
4. Write instructions for agent execution: retain only text that changes a decision.
5. Run `./tests/test-install.sh` and include its result in the pull request.

Read [AGENTS.md](AGENTS.md) before changing the repository. Keep each pull request focused and explain the behavior it changes.
