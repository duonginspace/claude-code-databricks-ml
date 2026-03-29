---
name: init-databricks-ml
description: Initialize or update a project with Databricks ML workflow scaffolding, skills, and agents. Use when starting a new ML project or adding missing Databricks integration to an existing project.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Initialize / Update Databricks ML Project

Set up or update the current project with Databricks + MLflow + Claude Code integration.
For each item below, CHECK if it already exists before creating. If it exists, skip it or merge missing parts. Only create/update what is missing.

## Checklist

### 1. .gitignore
Check if `.gitignore` exists. If missing, create it with:
```gitignore
# Python-generated files
__pycache__/
*.py[oc]
*.py[cod]
build/
dist/
wheels/
*.egg-info
*.whl

# Virtual environments
.venv/
venv/

# Environment
.env*
!.env.example

# MLflow
mlflow_results/

# EDA / Research
eda_results/
research/

# OS
.DS_Store

# Claude
.claude/

# uv
uv.lock

# misc
std.out
```

If it exists, check that `.env*`, `!.env.example`, `mlflow_results/`, `.venv/`, `eda_results/`, `research/`, `.claude/`, `uv.lock`, and `std.out` are listed. Append missing entries.

### 1b. .claudeignore
Check if `.claudeignore` exists. If missing, create it. This file prevents Claude Code from indexing large data files, model artifacts, and binary files that are irrelevant to code understanding.
```
# Data files — large binary/tabular data that Claude doesn't need to read
*.csv
*.tsv
*.parquet
*.feather
*.arrow
*.h5
*.hdf5
*.pkl
*.pickle
*.npy
*.npz
*.zarr
*.tfrecord
*.avro
*.orc

# Data directories
data/
datasets/

# Model artifacts
*.pt
*.pth
*.onnx
*.safetensors
*.bin
*.ckpt
models/

# Images / media
*.png
*.jpg
*.jpeg
*.gif
*.bmp
*.svg
*.mp4
*.mp3
*.wav

# Archives
*.zip
*.tar
*.tar.gz
*.tgz
*.gz
*.bz2
*.7z
*.rar

# Virtual environments
.venv/
venv/

# Build artifacts
build/
dist/
wheels/
*.egg-info/
*.whl

# MLflow local results
mlflow_results/

# EDA / Research outputs
eda_results/
research/

# Misc
__pycache__/
*.pyc
.DS_Store
std.out
uv.lock
```
If it exists, check that the data file extensions (`*.csv`, `*.parquet`, `*.h5`, `*.pkl`, `*.npy`), data directories (`data/`, `datasets/`), model artifact extensions (`*.pt`, `*.pth`, `*.onnx`, `*.safetensors`), and build/output directories (`mlflow_results/`, `eda_results/`, `research/`) are listed. Append missing entries.

### 2. .env.example
Check if `.env.example` exists. Ensure it contains these variables (add missing ones):
```
DATABRICKS_HOST=https://your-workspace.cloud.databricks.com
DATABRICKS_TOKEN=dapi_xxxxxxxxxxxxxxxxxx
DATABRICKS_CLUSTER_ID=0123-456789-abcdef
MLFLOW_TRACKING_URI=databricks
MLFLOW_EXPERIMENT_NAME=/Users/you@company.com/my-ml-experiment

# Job cluster overrides (used with --job-cluster / CLUSTER=job)
# DATABRICKS_NODE_TYPE=Standard_NV36ads_A10_v5
# DATABRICKS_SPARK_VERSION=16.4.x-scala2.13
```
Do NOT create or modify `.env` itself.

### 3. .mcp.json
Check if `.mcp.json` exists. If missing, create:
```json
{
  "mcpServers": {
    "databricks": {
      "type": "stdio",
      "command": "databricks-mcp"
    }
  }
}
```
If it exists, check that the `databricks` server entry is present. Add it if missing.

### 4. pyproject.toml
Check if `pyproject.toml` exists. Ensure these are present:
- `mlflow>=2.10.0` and `python-dotenv>=1.0.0` in main dependencies
- `databricks-sdk>=0.102.0` in a `databricks` dependency group
- `pytest`, `ruff`, `ipykernel` in a `dev` dependency group

Do NOT remove or modify existing dependencies. Only add missing ones.

### 5. scripts/submit_to_databricks.py
Check if this file exists. If missing, create it.

**Key design decisions (learned from DBR 15+ compatibility testing):**
- Upload files to **DBFS** (not Workspace) — Workspace paths cause `OSError: Operation not supported` when `spark_python_task` tries to `open()` the script.
- **Build a wheel** of the project package and upload it to `/mnt/dev-raw/<project-name>/` on DBFS. The training script pip-installs it at startup (via `--wheel-path` arg) because DBR 15+ does not support DBFS library installs via `compute.Library`.
- **Data/artifact files** (wheels, CSVs, models, datasets) must go to `/mnt/dev-raw/<project-name>/` on DBFS. **Script files** (`.py`, `.ipynb`) can be uploaded to any DBFS path (e.g., `/Users/{username}/`).
- Pass `--experiment` to the training script so MLflow uses the correct workspace path (experiment names on Databricks must be `/Users/...` paths, not bare names).
- Gracefully handle run failures: catch the exception from `waiter.result()` and still fetch logs/error output.
- Use `"SUCCESS" in str(run.state.result_state)` for status check (the enum string representation is `RunResultState.SUCCESS`, not bare `"SUCCESS"`).

```python
#!/usr/bin/env python3
"""Upload training script + project wheel to Databricks and run on a GPU cluster.

On DBR 15+, DBFS library installs are unsupported. Instead we upload the wheel
to DBFS and pip-install it at the start of the training script via subprocess.

Supports two cluster modes:
  - Existing cluster (default): uses DATABRICKS_CLUSTER_ID, cheaper if already running
  - Job cluster (--job-cluster): spins up an ephemeral cluster per run, lower DBU rate
"""

import argparse, os, subprocess, sys, time
from pathlib import Path

from dotenv import load_dotenv
from databricks.sdk import WorkspaceClient
from databricks.sdk.service import jobs
from databricks.sdk.service.compute import (
    AzureAttributes,
    AzureAvailability,
    DataSecurityMode,
    RuntimeEngine,
)

load_dotenv()
w = WorkspaceClient()
CLUSTER_ID = os.environ.get("DATABRICKS_CLUSTER_ID")
USERNAME = w.current_user.me().user_name
DBFS_DIR = f"/Users/{USERNAME}/{os.path.basename(os.getcwd())}"
DBFS_DATA_DIR = f"/mnt/dev-raw/{os.path.basename(os.getcwd())}"
PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Job cluster defaults (override via env vars)
JOB_CLUSTER_NODE_TYPE = os.environ.get("DATABRICKS_NODE_TYPE", "Standard_NV36ads_A10_v5")
JOB_CLUSTER_SPARK_VERSION = os.environ.get("DATABRICKS_SPARK_VERSION", "16.4.x-scala2.13")


def _build_wheel() -> Path:
    """Build a wheel of the project package and return its path."""
    dist_dir = PROJECT_ROOT / "dist"
    subprocess.check_call(
        ["uv", "build", "--wheel", "--out-dir", str(dist_dir)],
        cwd=str(PROJECT_ROOT),
    )
    wheels = sorted(dist_dir.glob("*.whl"))
    if not wheels:
        raise FileNotFoundError("No wheel found after build")
    return wheels[-1]


def _upload_dbfs(local_path: str | Path, remote_path: str):
    """Upload a file to DBFS."""
    with open(local_path, "rb") as f:
        w.dbfs.upload(remote_path, f, overwrite=True)
    print(f"  Uploaded {Path(local_path).name} -> dbfs:{remote_path}")


def _new_cluster_spec() -> jobs.compute.ClusterSpec:
    """Return a job cluster spec matching the project's GPU setup."""
    return jobs.compute.ClusterSpec(
        spark_version=JOB_CLUSTER_SPARK_VERSION,
        node_type_id=JOB_CLUSTER_NODE_TYPE,
        num_workers=0,
        spark_conf={
            "spark.databricks.delta.preview.enabled": "true",
            "spark.master": "local[*, 4]",
            "spark.databricks.cluster.profile": "singleNode",
        },
        custom_tags={"ResourceClass": "SingleNode"},
        azure_attributes=AzureAttributes(
            first_on_demand=1,
            availability=AzureAvailability.ON_DEMAND_AZURE,
            spot_bid_max_price=-1.0,
        ),
        data_security_mode=DataSecurityMode.SINGLE_USER,
        runtime_engine=RuntimeEngine.STANDARD,
        use_ml_runtime=True,
        single_user_name=USERNAME,
    )


def submit(script: str, args: list[str] = None, use_job_cluster: bool = False):
    # Build and upload the wheel
    print("Building wheel...")
    wheel_path = _build_wheel()
    remote_wheel_dbfs = f"{DBFS_DATA_DIR}/{wheel_path.name}"
    _upload_dbfs(wheel_path, remote_wheel_dbfs)

    # Upload the training script
    remote_script = f"{DBFS_DIR}/{os.path.basename(script)}"
    _upload_dbfs(script, remote_script)

    # Pass the DBFS wheel path and experiment name so the training script can use them
    experiment = os.environ.get("MLFLOW_EXPERIMENT_NAME", f"/Users/{USERNAME}/default-experiment")
    extra_args = [
        "--wheel-path", f"/dbfs{remote_wheel_dbfs}",
        "--experiment", experiment,
    ]

    cluster_kwargs = (
        {"new_cluster": _new_cluster_spec()}
        if use_job_cluster
        else {"existing_cluster_id": CLUSTER_ID}
    )
    waiter = w.jobs.submit(
        run_name=f"train-{int(time.time())}",
        tasks=[jobs.SubmitTask(
            task_key="train",
            **cluster_kwargs,
            spark_python_task=jobs.SparkPythonTask(
                python_file=f"dbfs:{remote_script}",
                parameters=extra_args + (args or []),
            ),
        )],
    )
    print(f"Run {waiter.run_id} submitted")

    try:
        run = waiter.result(
            callback=lambda r: print(
                f"  {r.state.life_cycle_state}" if r.state else "  ..."
            )
        )
    except Exception:
        # Fetch the run even on failure so we can grab logs
        run = w.jobs.get_run(waiter.run_id)

    status = "OK" if "SUCCESS" in str(run.state.result_state) else "FAILED"
    print(f"{status}: {run.state.result_state}")

    for task in run.tasks:
        output = w.jobs.get_run_output(run_id=task.run_id)
        if output.logs:
            log_path = "mlflow_results/job_logs.txt"
            os.makedirs("mlflow_results", exist_ok=True)
            with open(log_path, "w") as f:
                f.write(output.logs)
            print(f"Logs saved -> {log_path}")
        if output.error:
            print(f"Error: {output.error}")
        if output.error_trace:
            print(f"Trace:\n{output.error_trace}")

    if status == "FAILED":
        sys.exit(1)
    return run


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Submit training to Databricks")
    parser.add_argument("script", nargs="?", default="scripts/train.py",
                        help="Script (.py) or notebook (.ipynb) to run")
    parser.add_argument("--job-cluster", action="store_true",
                        help="Use an ephemeral job cluster instead of the existing cluster (lower DBU rate)")
    parsed, extra = parser.parse_known_args()

    if not parsed.job_cluster and not CLUSTER_ID:
        parser.error("DATABRICKS_CLUSTER_ID is required unless --job-cluster is used")

    mode = "job cluster" if parsed.job_cluster else f"existing cluster {CLUSTER_ID}"
    print(f"Cluster mode: {mode}")

    submit(parsed.script, extra or None, use_job_cluster=parsed.job_cluster)
```

### 6. scripts/pull_results_on_databricks.py
Check if this file exists. If missing, create it:
```python
#!/usr/bin/env python3
"""Pull latest MLflow results from Databricks into local JSON/CSV files."""

import json, os, sys
from datetime import datetime
from dotenv import load_dotenv
import mlflow
from mlflow import MlflowClient

load_dotenv()
mlflow.set_tracking_uri("databricks")

EXPERIMENT = os.environ.get(
    "MLFLOW_EXPERIMENT_NAME", "/Users/you@company.com/my-ml-experiment"
)
OUTPUT_DIR = "mlflow_results"


def pull_latest(experiment_name: str):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    client = MlflowClient()

    experiment = client.get_experiment_by_name(experiment_name)
    if not experiment:
        print(f"Experiment '{experiment_name}' not found")
        sys.exit(1)

    runs_df = mlflow.search_runs(
        experiment_ids=[experiment.experiment_id],
        filter_string="status = 'FINISHED'",
        order_by=["start_time DESC"],
        max_results=1,
    )
    if runs_df.empty:
        print("No finished runs found")
        sys.exit(1)

    run_id = runs_df.iloc[0]["run_id"]
    run = client.get_run(run_id)

    result = {
        "run_id": run_id,
        "status": run.info.status,
        "start_time": datetime.fromtimestamp(
            run.info.start_time / 1000
        ).isoformat(),
        "duration_seconds": (
            (run.info.end_time - run.info.start_time) / 1000
            if run.info.end_time else None
        ),
        "parameters": dict(run.data.params),
        "metrics": dict(run.data.metrics),
    }

    for name in ["train_loss", "val_loss", "val_accuracy"]:
        try:
            history = client.get_metric_history(run_id, name)
            result.setdefault("metric_history", {})[name] = [
                {"step": m.step, "value": m.value} for m in history
            ]
        except Exception:
            pass

    with open(f"{OUTPUT_DIR}/latest_run.json", "w") as f:
        json.dump(result, f, indent=2)

    all_runs = mlflow.search_runs(
        experiment_ids=[experiment.experiment_id],
        order_by=["start_time DESC"],
        max_results=50,
    )
    all_runs.to_csv(f"{OUTPUT_DIR}/all_runs.csv", index=False)

    print(f"Results -> {OUTPUT_DIR}/latest_run.json")
    print(json.dumps(result["metrics"], indent=2))


if __name__ == "__main__":
    pull_latest(sys.argv[1] if len(sys.argv) > 1 else EXPERIMENT)
```

### 6b. DBR 15+ compatibility: training script bootstrap

Any training script uploaded to Databricks (e.g. `scripts/train.py`) must handle installing the project wheel at startup since DBR 15+ does not support DBFS library installs. The script should:

1. Accept `--wheel-path <path>` and `--experiment <name>` CLI args (passed by `submit_to_databricks.py`)
2. Pip-install the wheel at the top of the script, **before** importing project modules:
```python
import subprocess, sys

def _install_wheel():
    """Install the project wheel passed via --wheel-path."""
    for i, arg in enumerate(sys.argv):
        if arg == "--wheel-path" and i + 1 < len(sys.argv):
            wheel = sys.argv[i + 1]
            print(f"Installing {wheel} (with dependency upgrades)...")
            subprocess.check_call([
                sys.executable, "-m", "pip", "install", wheel,
                "--upgrade", "--upgrade-strategy", "eager", "-q",
            ])
            # Force-clear stale modules cached from the Databricks runtime
            # so newly installed versions are picked up (pydantic, typing_extensions, etc.)
            stale_prefixes = ("pydantic", "typing_extensions")
            for mod_name in list(sys.modules.keys()):
                if any(mod_name == p or mod_name.startswith(p + ".") for p in stale_prefixes):
                    del sys.modules[mod_name]
            import site
            site.main()
            return

_install_wheel()
# Now safe to import project modules
```
3. Use the `--experiment` arg for `mlflow.set_experiment()` (experiment names on Databricks must be `/Users/...` workspace paths, not bare names like `"my-experiment"`)

**Why this is necessary:** Databricks runtimes pre-load system packages (e.g. old pydantic v1, old typing_extensions) that shadow pip-installed versions. The module cache clearing ensures the freshly installed versions are used. The `--upgrade --upgrade-strategy eager` flag ensures transitive dependencies (like pydantic) are also upgraded.

### 7. Makefile
Check if `Makefile` exists. If missing, create it with these targets:
```makefile
PYTHON := uv run python
EXPERIMENT ?= /Users/you@company.com/my-ml-experiment

.PHONY: train pull results check requirements

# Use CLUSTER=job for ephemeral job cluster (lower DBU rate, ~5-10min startup)
# Default uses existing cluster from DATABRICKS_CLUSTER_ID
CLUSTER_FLAG := $(if $(filter job,$(CLUSTER)),--job-cluster,)

train:
	$(PYTHON) scripts/submit_to_databricks.py scripts/train.py $(CLUSTER_FLAG) $(ARGS)
	$(PYTHON) scripts/pull_results_on_databricks.py $(EXPERIMENT)
	@echo "\nResults ready in mlflow_results/"

pull:
	$(PYTHON) scripts/pull_results_on_databricks.py $(EXPERIMENT)

results:
	@cat mlflow_results/latest_run.json | python -m json.tool

check:
	databricks current-user me
	$(PYTHON) -c "import mlflow; mlflow.set_tracking_uri('databricks'); print('MLflow OK')"

requirements:
	uv export --format requirements-txt --no-hashes --no-dev --no-emit-project \
		-o requirements-databricks.txt
```
If it exists, check that `train`, `pull`, `results`, `check`, `requirements` targets are present. Add missing targets. Ensure `CLUSTER_FLAG` variable and the `--job-cluster` comment are present.

### 8. Skills, Agents, and Commands — copy from user-level to project-level

The canonical skill, agent, and command definitions live at the **user level** (`~/.claude/skills/`, `~/.claude/agents/`, `~/.claude/commands/`).
For each item below, copy it from user-level to project-level. If the user-level source doesn't exist, write the file inline as a fallback.

**Skills to copy** (source → destination):
- `~/.claude/skills/explore-data/SKILL.md` → `.claude/skills/explore-data/SKILL.md`
- `~/.claude/skills/train-local/SKILL.md` → `.claude/skills/train-local/SKILL.md`
- `~/.claude/skills/run-on-databricks/SKILL.md` → `.claude/skills/run-on-databricks/SKILL.md`
- `~/.claude/skills/compare-runs/SKILL.md` → `.claude/skills/compare-runs/SKILL.md`
- `~/.claude/skills/research-papers/SKILL.md` → `.claude/skills/research-papers/SKILL.md`
- `~/.claude/skills/iterate/SKILL.md` → `.claude/skills/iterate/SKILL.md`
- `~/.claude/skills/run-training-on-databricks/SKILL.md` → `.claude/skills/run-training-on-databricks/SKILL.md`
- `~/.claude/skills/check-results-on-databricks/SKILL.md` → `.claude/skills/check-results-on-databricks/SKILL.md`

**Agents to copy** (source → destination):
- `~/.claude/agents/data-analyst.md` → `.claude/agents/data-analyst.md`
- `~/.claude/agents/experiment-runner.md` → `.claude/agents/experiment-runner.md`
- `~/.claude/agents/research-agent.md` → `.claude/agents/research-agent.md`

**Commands to copy** (source → destination):
- `~/.claude/commands/commit.md` → `.claude/commands/commit.md` — Conventional Commits 1.0.0 commit command

**Procedure for each file:**
1. Check if the project-level destination already exists. If yes, skip it.
2. Check if the user-level source exists. If yes, read it and write its contents to the project-level destination.
3. If the user-level source does NOT exist, report it as missing and skip (do not write a fallback — the user-level files are the source of truth).

### 10. .claude/settings.local.json
Check if it exists. Ensure these permissions are present (add missing ones):
```json
{
  "permissions": {
    "allow": [
      "Read",
      "Edit",
      "Write(src/**)",
      "Write(configs/**)",
      "Write(scripts/**)",
      "Write(eda_results/**)",
      "Write(research/**)",
      "Write(mlflow_results/**)",
      "Bash(python *)",
      "Bash(uv *)",
      "Bash(pytest *)",
      "Bash(databricks *)",
      "Bash(mlflow *)",
      "Bash(make *)",
      "mcp__databricks__*"
    ],
    "deny": [
      "Read(.env*{!.example})",
      "Write(.env*{!.example})",
      "Bash(rm -rf *)",
      "Bash(databricks clusters delete*)"
    ]
  }
}
```
If it exists, merge missing entries into the existing allow/deny arrays. Do NOT remove existing entries.

### 11. CLAUDE.md — Databricks workflow section
Check if `CLAUDE.md` contains a Databricks workflow section. If missing, append one covering:
- Environment info (workspace, cluster, MLflow experiment — reference `.env`)
- Make commands (`make train`, `make train CLUSTER=job`, `make pull`, `make results`, `make check`)
- Development workflow (edit locally -> submit -> pull results -> iterate)
- Rules (training runs on Databricks Linux/CUDA, local is CPU only, always use MLflow, never hardcode credentials, data/artifact files must use `/dbfs/mnt/dev-raw/<project-name>/` — scripts are exempt)
- DBR 15+ notes: DBFS library installs unsupported — the submit script builds a wheel and pip-installs it at runtime; training scripts must clear stale module caches for pydantic/typing_extensions; MLflow experiment names must be `/Users/...` workspace paths

If a Databricks section already exists, check for missing subsections and add them.

## After completion
Run `uv sync` to install any newly added dependencies.
Print a summary of what was created vs what already existed, including the new skills and agents.

## Known DBR 15+ Gotchas (reference for troubleshooting)
These issues were discovered during real Databricks runs and are baked into the scripts above:

1. **Workspace path `open()` fails** — `spark_python_task` cannot `open()` files at `/Workspace/Users/...` paths. Upload scripts to DBFS instead.
2. **DBFS library installs unsupported** — `compute.Library(whl="dbfs:...")` fails on DBR 15+. Instead, upload the wheel to DBFS and pip-install it from within the training script.
3. **Workspace upload rejects .whl files** — `w.workspace.upload()` treats `.whl` as zip and fails with "0 items or more than 1 items". Use `w.dbfs.upload()` for wheel files.
4. **Stale pydantic/typing_extensions** — Databricks pre-loads old system packages. After pip-installing upgraded deps, clear `sys.modules` entries for `pydantic*` and `typing_extensions*`, then call `site.main()`.
5. **MLflow experiment names** — Must be workspace paths (`/Users/user@company.com/name`), not bare names. Bare names cause `BAD_REQUEST: For input string: "None"`.
6. **`root_mean_squared_error`** — Not available in older scikit-learn on some DBR versions. Use `mean_squared_error(..., squared=False)` instead.
7. **`waiter.result()` raises on failure** — Wrap in try/except and fetch the run via `w.jobs.get_run(waiter.run_id)` to still capture logs.
8. **Status check** — `str(run.state.result_state)` returns `"RunResultState.SUCCESS"`, not `"SUCCESS"`. Use `"SUCCESS" in str(...)` for the check.
