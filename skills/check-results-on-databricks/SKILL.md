---
name: check-results-on-databricks
description: Analyze MLflow experiment results. Use when the user asks about model performance or experiment history.
allowed-tools: Bash, Read
---

# Check MLflow Results

1. Run `uv run python scripts/pull_results_on_databricks.py` to fetch latest results
2. Read `mlflow_results/latest_run.json` for the most recent run
3. Read `mlflow_results/all_runs.csv` for experiment history
4. If the run failed or metrics look wrong, also read `mlflow_results/job_logs.txt` for the full Databricks output
5. Create a comparison table of the top runs by primary metric
6. Identify trends across runs and suggest improvements
