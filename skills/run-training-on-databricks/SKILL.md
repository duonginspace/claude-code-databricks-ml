---
name: run-training-on-databricks
description: Submit ML training to Databricks and pull results. Use when the user wants to run, train, or execute a model on Databricks.
allowed-tools: Bash, Read, Write, mcp__databricks__run_job
---

# Run Training on Databricks

1. The submit script builds a wheel of the project, uploads it + the training script to DBFS, and submits a Spark Python task:
   `uv run python scripts/submit_to_databricks.py scripts/train.py <args>`
   The training script pip-installs the wheel at startup (DBR 15+ does not support DBFS library installs).
   - Add `--job-cluster` to use an ephemeral job cluster (lower DBU rate, ~5-10min startup) instead of the existing cluster
   - Default uses the existing cluster from `DATABRICKS_CLUSTER_ID`
2. Wait for the run to complete (the script handles polling and log capture)
3. If the run failed, read `mlflow_results/job_logs.txt` for the full output and error trace. Common issues:
   - Stale pydantic/typing_extensions from the Databricks runtime (the bootstrap should handle this, but check logs)
   - Missing HF_TOKEN for gated models (TabPFN)
   - MLflow experiment name must be a `/Users/...` workspace path, not a bare name
4. If the run succeeded, pull results: `uv run python scripts/pull_results_on_databricks.py`
5. Read `mlflow_results/latest_run.json` for metrics
6. Summarize key metrics: loss, accuracy, training time
7. Compare with previous runs in `mlflow_results/all_runs.csv`
8. Suggest concrete next steps (hyperparameter changes, architecture modifications)
