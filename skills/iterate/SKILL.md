---
name: iterate
description: Full ML iteration cycle: implement a change, run on Databricks, compare results, suggest next step. Use when the user says "try X", "implement Y and test it", "iterate on the model", or "run an experiment with Z".
allowed-tools: Bash(python scripts/*), Bash(make *), Bash(uv run python *), mcp__databricks__*, Read, Write(src/**), Write(configs/**), Write(mlflow_results/**)
---

# Full iteration cycle

Change to implement: $ARGUMENTS

## Steps

1. Read CLAUDE.md and mlflow_results/latest_run.json to understand the baseline.
2. Implement the requested change in scripts/train.py or the relevant config file.
3. Run local smoke test: `uv run python scripts/train.py --fast-dev-run --epochs 1`
4. If smoke test passes, submit to Databricks: `make train`
5. Pull results and compare with the previous run.
6. Report: did it improve? By how much? What to try next?

ultrathink
