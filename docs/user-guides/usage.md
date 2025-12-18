# Usage

Use `./src/bin/okso --help` to see all flags. The CLI walks through planning and tool execution with approvals by default.

## Task-based walkthroughs

### Run with approvals

1. Start with a prompted run so each tool call requires confirmation (default):

   ```bash
   ./src/bin/okso -- "inspect project layout and search notes"
   ```

2. To auto-approve tool calls, pass `--yes` (or `--no-confirm`) for a fully automated pass:

   ```bash
   ./src/bin/okso --yes -- "save reminder"
   ```

3. If your config sets `APPROVE_ALL=true` but you need to restore prompts for a sensitive query, add `--confirm` to override the config.

4. Preview the plan without running anything using `--dry-run`, or emit machine-readable JSON only via `--plan-only`:

   ```bash
   ./src/bin/okso --dry-run -- "draft meeting notes"
   ./src/bin/okso --plan-only -- "catalog data sources"
   ```

5. Increase logging with `--verbose` or silence informational logs with `--quiet` when running unattended scripts.

### Offline or noninteractive feedback collection

The `feedback` tool can run without prompts while still capturing ratings and notes.

1. Disable interactive prompts and pre-fill a rating and note using `FEEDBACK_NONINTERACTIVE_INPUT` (`rating|note`). To bypass llama.cpp entirely for deterministic scoring, set `TESTING_PASSTHROUGH=true`.

   ```bash
   FEEDBACK_NONINTERACTIVE_INPUT="5|Clear summary" \
   TESTING_PASSTHROUGH=true \
   ./src/bin/okso --yes -- "summarize research notes"
   ```

2. When you only need to collect feedback artifacts, call the tool directly with a context payload and an output file:

   ```bash
   TOOL_QUERY='{"plan_item":"Summarize notes","observations":"Draft complete"}' \
     FEEDBACK_NONINTERACTIVE_INPUT="4|Mentioned gaps" \
     FEEDBACK_OUTPUT_PATH="${HOME}/.okso/feedback.jsonl" \
     bash -lc 'source ./src/tools/feedback.sh; tool_feedback'
   ```

3. Turn off prompts entirely for CI runs with `FEEDBACK_ENABLED=false`; set `FEEDBACK_MIN_INTERVAL` or `FEEDBACK_MAX_ENTRIES` to tune churn and storage rotation.

### Initialize config for a custom model

1. Generate a config file without executing any plan using the `init` subcommand. Supply your preferred model and optional branch:

   ```bash
   ./src/bin/okso init --config "${XDG_CONFIG_HOME:-$HOME/.config}/okso/config.env" \
     --model your-org/your-model:custom.gguf \
     --model-branch main
   ```

2. At runtime, override config values with environment variables prefixed by `OKSO_`:

   ```bash
   OKSO_MODEL_SPEC=bartowski/Qwen_Qwen3-4B-GGUF:Qwen_Qwen3-4B-Q4_K_M.gguf \
   OKSO_MODEL_BRANCH=main \
   OKSO_LLAMA_BIN=llama-cli \
   ./src/bin/okso --yes -- "classify support tickets"
   ```

3. To keep the run noninteractive while still respecting a new model, pair the overrides with `--yes` or `--confirm` depending on whether you want automatic approvals.

### macOS clipboard helpers

Call built-in helpers when you need quick transfers without opening other tools:

```bash
./src/bin/okso -- tool clipboard_copy "temporary text"
./src/bin/okso -- tool clipboard_paste
```

Refer to [configuration](../reference/configuration.md) for available settings and [tools](../reference/tools.md) for handler details.
