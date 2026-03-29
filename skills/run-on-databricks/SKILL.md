---
name: run-on-databricks
description: Submit a training job to the Databricks GPU cluster, wait for results, and pull MLflow metrics back locally. Use when the user wants to train on GPU, run a full experiment, or execute code on the Databricks cluster. Triggers on "run on Databricks", "train on GPU", "submit job", "full training run".
context: fork
agent: experiment-runner
allowed-tools: Bash(uv run python scripts/*), Bash(make *), mcp__databricks__*, Read, Write(mlflow_results/**)
---

# Databricks training task

Script and args: $ARGUMENTS

## Steps

1. Read `CLAUDE.md` for cluster ID, experiment name, and environment setup.
2. Run a local smoke test first if the user hasn't confirmed the code runs locally:
   `uv run python scripts/train.py --datasets 1 --epochs 2 2>&1 | head -40`
   If it fails, stop and report the error. Don't submit broken code to the cluster.
3. Submit to Databricks (this builds a wheel, uploads it + scripts/train.py to DBFS, and runs):
   `uv run python scripts/submit_to_databricks.py scripts/train.py $ARGUMENTS`
   The script passes `--wheel-path` and `--experiment` args automatically.
   - To use an ephemeral job cluster (lower DBU rate) instead of the existing cluster, add `--job-cluster`
   - Job clusters have ~5-10min startup overhead but cost less per DBU
4. Pull MLflow results:
   `uv run python scripts/pull_results_on_databricks.py`
5. Read `mlflow_results/latest_run.json` and `mlflow_results/all_runs.csv`.
6. Report:
   - Run status (SUCCESS / FAILED)
   - Key metrics (loss, accuracy, or whatever the primary metric is)
   - Training time and GPU type used
   - Comparison with the previous best run from all_runs.csv
7. If the run failed, read `mlflow_results/job_logs.txt` and diagnose the error.
   Common DBR 15+ issues:
   - `OSError: Operation not supported` on Workspace paths — scripts must be on DBFS
   - `pydantic has no model_validator` — stale system pydantic; check that the bootstrap clears sys.modules
   - `cannot import Sentinel from typing_extensions` — same stale module issue
   - `BAD_REQUEST: For input string: "None"` — MLflow experiment name must be a `/Users/...` workspace path
   - `DBFS library installations are not supported on DBR 15` — wheel must be pip-installed at runtime, not via compute.Library

## Output
Summarize results and propose the next experiment with specific hyperparameter or architecture changes.
ultrathink
