# Capturing feedback

Use the bundled `feedback` tool to record ratings for each plan item. Feedback events help tune prompts and surface regressions without storing raw transcripts.

## Quick start

Provide a JSON context payload describing the current plan item and any prior observations, then supply the score and optional notes:

```bash
TOOL_QUERY='{"plan_item":"Summarize notes","observations":"Draft complete"}' \
  FEEDBACK_NONINTERACTIVE_INPUT="5|Clear summary" \
  bash -lc 'source ./src/tools/feedback.sh; tool_feedback'
```

Interactive prompts are enabled by default. Set `FEEDBACK_ENABLED=false` to skip prompting entirely. To persist the captured payload within the writable allowlist, set `FEEDBACK_OUTPUT_PATH=${HOME}/.okso/feedback.json`.

## Runtime prompts

When interactive mode is enabled, the tool will:

1. Print the plan item and recent observations.
2. Request a 1-5 numeric rating.
3. Optionally collect a short free-form note.

Use `FEEDBACK_NONINTERACTIVE_INPUT` to pre-fill both fields when running in CI or other unattended environments (`rating|note`).

## Additional controls

- `FEEDBACK_ENABLED`: globally toggles feedback collection.
- `FEEDBACK_OUTPUT_PATH`: path for the JSONL log of captured events.
- `FEEDBACK_MIN_INTERVAL`: minimum seconds between prompts to avoid chatter during rapid tool loops.
- `FEEDBACK_MAX_ENTRIES`: cap the number of stored events before rotation.

The feedback handler is loaded via `src/tools/feedback.sh`; see [tools](tools.md) for broader tool lifecycle details.
