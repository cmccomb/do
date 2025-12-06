# do Assistant Entrypoint

A lightweight MCP-inspired planner that wraps a local `llama.cpp` binary, ranks
registered tools via ToolRAG, and executes them in either supervised (human
confirmation) or unsupervised mode.

## Installation

The project ships with an idempotent macOS-only installer that bootstraps
dependencies and installs the CLI binary without running global Homebrew
upgrades:

```bash
./scripts/install [--prefix /custom/path] [--upgrade | --uninstall]
```

What the installer does:

1. Verifies Homebrew is present (installing it if missing) without running
   `brew upgrade`.
2. Ensures pinned CLI dependencies: `llama.cpp` binaries, `llama-tokenize`,
   `tesseract`, `pandoc`, `poppler` (`pdftotext`), `yq`, `bash`, `coreutils`,
   and `jq`.
3. Copies the `src/` contents into `/usr/local/do` (override with `--prefix`),
   and symlinks `do` into your `PATH` (default: `/usr/local/bin`).
4. Downloads a configurable Qwen3 GGUF for `llama.cpp` into `~/.do/models`
   unless `DO_MODEL_PATH` already points to an existing file.
5. Offers `--upgrade` (refresh files/model) and `--uninstall` flows, refusing
   to run on non-macOS hosts.

Key environment variables:

- `DO_MODEL_URL`: Override the default Qwen3 model URL
  (`qwen3-1.5b-instruct-q4_k_m.gguf`).
- `DO_MODEL_PATH`: Destination path for the GGUF (default:
  `~/.do/models/qwen3-1.5b-instruct-q4_k_m.gguf`).
- `DO_LINK_DIR`: Directory for the CLI symlink (default: `/usr/local/bin`).
- `DO_INSTALLER_ASSUME_OFFLINE=true`: Skip network calls; installation fails if
  downloads are required while offline.
- `HF_TOKEN`: Optional Hugging Face token for gated model downloads.

For manual setups, ensure `bash` 5+, `llama.cpp` (optional for heuristic mode),
`fd`, and `rg` are on your `PATH`, then run the script directly with `./src/main.sh`.

## Configuration

Environment variables control runtime behavior and can be stored in an env file
(such as `tests/fixtures/sample.env`):

- `DO_MODEL_PATH`: Path to the llama.cpp model (default: `./models/llama.gguf`).
- `DO_SUPERVISED`: `true`/`false` to toggle confirmation prompts (default:
  `true`).
- `DO_VERBOSITY`: `0` (quiet), `1` (info), `2` (debug). Overrides `-v`/`-q`.
- `DO_LOG_DIR`: Directory where transcripts are persisted (default:
  `~/.do/logs`).
- `DO_LOG_VERBOSITY`: `0` (errors only), `1` (info, default), `2` (debug) for
  the persisted JSONL logs.
- `LLAMA_BIN`: llama.cpp binary to use (default: `llama`; can point to the mock
  `tests/fixtures/mock_llama.sh` during testing).

The included `tests/fixtures/sample.env` demonstrates a debug-friendly,
unsupervised configuration that prefers the notes tool for reminder queries.
Running with that config and a reminder request will emit a tool prompt where
`notes` is scored highest, followed by a summary beginning with
`[notes executed]`. Each run also writes a transcript to `~/.do/logs` (or
`DO_LOG_DIR`), capturing the ranked proposals, approvals, and execution
outcomes with the configured `DO_LOG_VERBOSITY`.

## Modes

- **Supervised** (default): shows a numbered proposal list and prompts once per
  plan. Choose `all` to run every proposed tool, provide comma-separated
  indices (for example `1,3`), or `skip` to run none. A persisted transcript
  records the proposal list, selection, and results.
- **Unsupervised**: executes ranked tools without prompts; enable with
  `--unsupervised` or `DO_SUPERVISED=false`. Proposals and execution summaries
  are still logged to the transcript directory.

## Tooling registry

The planner registers the following tools:

- `os_nav`: inspect the working directory (read-only).
- `file_search`: search for files and contents using `fd`/`rg` fallbacks.
- `notes`: append reminders under `~/.do/notes.txt`.
- `mail_stub`: capture a mail draft without sending.
- `applescript`: execute AppleScript snippets on macOS (no-op elsewhere).

Ranking prefers llama.cpp scoring when `LLAMA_BIN` is available; otherwise a
heuristic keyword overlap is used.

## Usage examples

Supervised run (default):

```bash
./src/main.sh -- "inspect project layout and search notes"
```

Unsupervised run with a specific model:

```bash
DO_SUPERVISED=false ./src/main.sh --model ./models/llama.gguf -- "save reminder"
```

Using the sample configuration:

```bash
set -a
. tests/fixtures/sample.env
set +a
./src/main.sh -- "capture reminder for tomorrow"
```

Use `--help` to view all options. Pass `--verbose` for debug-level logs or
`--quiet` to silence informational messages.

### Logging

All runs write structured JSON logs to `~/.do/logs` (overridable via
`DO_LOG_DIR`). The console verbosity follows `-v`/`-q` or `DO_VERBOSITY`, while
persisted logs follow `DO_LOG_VERBOSITY`. Each entry includes the timestamp,
level, message, and detail (such as tool proposals, approval selections, and
execution summaries).

## Testing and linting

Run the formatting and lint targets before executing the Bats suite:

```bash
shfmt -w src/main.sh tests/test_all.sh tests/test_main.bats
shellcheck src/main.sh tests/test_all.sh tests/test_main.bats
shfmt -w scripts/install tests/test_install.bats
shellcheck scripts/install tests/test_install.bats
bats tests/test_all.sh tests/test_install.bats
```

The Bats suite covers CLI help/version output, supervised prompts, deterministic
mock scoring via `tests/fixtures/mock_llama.sh`, and graceful handling when
`LLAMA_BIN` is missing.
