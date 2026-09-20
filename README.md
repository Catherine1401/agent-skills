# Agent Skills

Portable agent workflows for Linux. `skills/` is the canonical source;
`adapters/` contains agent-specific rule formats.

```sh
./install.sh --agent codex --force
./install.sh --agent all --mode symlink
./tests/test-install.sh
```

`--force` moves an existing target to a timestamped backup. Use `--no-rules`
to install only the skill. Override default config roots with `CODEX_HOME`,
`CLAUDE_CONFIG_DIR`, or `CURSOR_CONFIG_DIR`.
