---
name: compare-runs
description: Compare MLflow experiment runs, rank them, and recommend next steps. Use when the user asks about results, which run is best, what improved, what hurt performance, or wants a summary of experiment history. Triggers on "compare runs", "what improved", "best model so far", "show me results", "which hyperparameters worked".
context: fork
agent: Explore
allowed-tools: Bash(uv run python scripts/pull_results_on_databricks.py *), Bash(uv run python *), Read
---

# Experiment comparison task

$ARGUMENTS

## Steps

1. Run `uv run python scripts/pull_results_on_databricks.py` to sync the latest results from MLflow.
2. Read `mlflow_results/all_runs.csv` — this has all experiment history.
3. Read `mlflow_results/latest_run.json` for the most recent run's full details.

## Analysis to perform

### Ranking
Sort all finished runs by the primary metric (look for val_accuracy, val_loss, or f1 — whichever is in the data). Show the top 5 as a markdown table with columns: rank, run name, primary metric, key hyperparameters, training time, run date.

### What helped vs. hurt
Group runs by the parameter that changed most across experiments. For each parameter variant, show the mean and best metric. Identify which changes consistently improved performance and which hurt it.

### Learning rate analysis
If lr or learning_rate is in params, plot or describe the lr vs. primary metric curve.

### Convergence check
For the best run, read the metric history from latest_run.json. Did the model converge? Was there overfitting (train loss still dropping while val loss rises)? Suggest early stopping patience if relevant.

### Environment issues
Check if any runs failed. Read mlflow_results/job_logs.txt if present. Report any recurring errors.

## Output
Produce a clear summary with:
1. The current best run and its config
2. Three specific, concrete experiment suggestions ranked by expected improvement
3. One environment/infrastructure recommendation if any runs failed

ultrathink
