---
name: train-local
description: Run a quick training experiment locally (CPU or MPS). Use when the user wants to test a model change, debug training code, run a smoke test, or validate a new architecture before submitting to Databricks. Fast iteration, small data, short epochs.
allowed-tools: Bash(uv run python *), Bash(uv run pytest *), Read, Write(src/**), Write(configs/**)
---

# Local training task

$ARGUMENTS

## Steps

1. Read `CLAUDE.md` for the project structure and current experiment config.
2. If not specified, default to: 2 epochs, 10% of training data, CPU/MPS device, batch size 16.
3. Add `--dry-run` or `--fast-dev-run` flag if the training script supports it.
4. Run: `uv run python scripts/train.py <args> 2>&1 | tee mlflow_results/local_run.log`
5. Watch for: import errors, shape mismatches, CUDA/MPS device errors, NaN losses, OOM errors.
6. If the run succeeds, report: final train loss, validation metric, time per epoch.
7. If it fails, diagnose the error and propose a fix before suggesting a Databricks run.

## Output
Tell the user whether the code is ready to submit to Databricks, or what to fix first.
Always suggest using `/run-on-databricks` after a successful local smoke test.
