# Usage

The CLI guides you through planning and executing tool calls. Use `--help` to see all options, pass `--verbose` for debug-level logs, or `--quiet` to silence informational messages.

All runtime output is produced as structured JSON logs so it can be piped to `jq` or collected by log shippers. INFO-level events trace suggested tools, plan outlines, and dry-run previews, while ERROR entries flag fallbacks such as deterministic responses when llama.cpp is unavailable. Final answers are pretty-printed for readability without sacrificing structure.

Model defaults live in `${XDG_CONFIG_HOME:-~/.config}/okso/config.env`. Override them per-run with `--model` and `--model-branch` (default: `bartowski/Qwen_Qwen3-4B-GGUF:Qwen_Qwen3-4B-Q4_K_M.gguf` on `main`).

## Approval and preview modes

- **Default**: prompts before executing each tool. Declining a tool logs a skip and continues through the ranked list.
- `--yes` / `--no-confirm`: executes ranked tools without prompts.
- `--confirm`: forces prompts even if the config opts into auto-approval.
- `--dry-run`: prints the planned calls without running any tool handlers.
- `--plan-only`: emits the machine-readable plan JSON and exits.

## Examples

Prompted run (default):

```bash
./src/main.sh -- "inspect project layout and search notes"
```

Auto-approval with a specific model selection:

```bash
./src/main.sh --yes --model your-org/your-model:custom.gguf -- "save reminder"
```

Write a config file without running a plan to persist model overrides:

```bash
./src/main.sh init --config ~/.config/okso/config.env --model your-org/your-model:custom.gguf --model-branch beta
```

Tool helpers for macOS clipboard access:

```bash
./src/main.sh -- tool clipboard_copy "temporary text"
./src/main.sh -- tool clipboard_paste
```

Refer to [configuration](configuration.md) for tuning defaults and [tools](tools.md) for supported handlers.
