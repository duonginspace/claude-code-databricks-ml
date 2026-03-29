# Claude Code Databricks ML Toolkit

A collection of **Claude Code skills, agents, and tools** for running ML experiments on Databricks. If you use Claude Code for machine learning and your compute is on Databricks, this toolkit gives you a complete workflow out of the box.

## What's Inside

### Status Bar (`scripts/context-bar.sh`)

A rich status line that replaces Claude Code's default, showing:
- Model name + effort level
- Current directory and git branch
- Uncommitted file count (or filename if just one)
- Git sync status (ahead/behind upstream, last fetch time)
- Context window usage as a color-coded progress bar
- Rate limit usage (5-hour and 7-day)
- Your last message (truncated to fit)

> Add a screenshot to `assets/` and uncomment the line below:
<!-- ![Status bar](assets/statusbar.png) -->

### Skills (11)

#### Databricks ML Workflow

| Skill | Trigger phrases | Description |
|-------|----------------|-------------|
| `/run-on-databricks` | "run on Databricks", "train on GPU", "submit job" | Submit a training job to the Databricks GPU cluster, wait for results, pull MLflow metrics back locally |
| `/run-training-on-databricks` | "run training on databricks" | Lighter alternative: submit training and pull results |
| `/check-results-on-databricks` | "check results", "how did it do" | Fetch and analyze MLflow experiment results |
| `/compare-runs` | "compare runs", "best model so far", "what improved" | Rank experiment runs by metric, analyze what helped/hurt, recommend next steps |
| `/init-databricks-ml` | "initialize project", "add databricks" | Scaffold a complete Databricks + MLflow + Claude Code project from scratch |
| `/iterate` | "try X", "implement Y and test it", "iterate on the model" | Full cycle: implement a change, run on Databricks, compare results, suggest next step |
| `/train-local` | "test locally", "smoke test", "debug training" | Quick local CPU/MPS training for fast iteration before submitting to Databricks |
| `/explore-data` | "look at the data", "check for missing values" | Dataset EDA with distribution plots, correlation matrices, data quality checks |
| `/research-papers` | "find papers on X", "state of the art for Y" | Search recent ML papers, extract key findings, produce actionable recommendations |

#### General Purpose

| Skill | Description |
|-------|-------------|
| `/explain-code` | Explain code with ASCII diagrams and analogies |
| `/handoff` | Write a context handoff document so the next agent can pick up where you left off |

### Agents (3)

Skills that involve heavy lifting fork work to specialized agents:

| Agent | Used by | Role |
|-------|---------|------|
| `experiment-runner` | `/run-on-databricks` | Submits Databricks jobs and fetches results |
| `data-analyst` | `/explore-data` | Read-only EDA with pandas/matplotlib |
| `research-agent` | `/research-papers` | Autonomous web search for ML papers and techniques |

### Commands (1)

| Command | Description |
|---------|-------------|
| `/commit` | Create a git commit following Conventional Commits 1.0.0 |

## How the Skills Work Together

```
/explore-data          Understand your dataset
       |
/train-local           Smoke test locally (CPU)
       |
/run-on-databricks     Submit to Databricks GPU cluster
       |
/check-results         Pull MLflow metrics
       |
/compare-runs          Rank runs, find what works
       |
/iterate               Implement next idea and repeat
       |
/research-papers       Search for better approaches when stuck
```

## Installation

### Quick Install

```bash
git clone https://github.com/duonginspace/claude-code-databricks-ml.git
cd claude-code-databricks-ml
bash setup.sh
```

The setup script copies skills, agents, commands, and the status bar script to `~/.claude/`. It will prompt before overwriting existing files. Use `--force` to skip prompts, or `--symlink` to create symlinks instead of copies.

### Manual Install

Copy individual files to the corresponding `~/.claude/` directories:

```bash
# Example: install just one skill
cp -r skills/run-on-databricks ~/.claude/skills/

# Example: install just the status bar
cp scripts/context-bar.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/context-bar.sh
```

### Enable the Status Bar

Add to your `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/context-bar.sh"
  }
}
```

See `settings/settings-example.json` for a complete example.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- A Databricks workspace with a GPU cluster (or use ephemeral job clusters)
- [databricks-mcp](https://github.com/databricks/databricks-mcp) for MCP integration
- Python 3.10+ and [uv](https://docs.astral.sh/uv/)
- `jq` (used by the status bar script)

## Starting a New Project

Run `/init-databricks-ml` in any directory to scaffold:
- `scripts/submit_to_databricks.py` and `scripts/pull_results_on_databricks.py`
- `Makefile` with `make train`, `make pull`, `make results`, `make check`
- `.env.example` with Databricks/MLflow config
- `.mcp.json` for the Databricks MCP server
- Project-level skills, agents, and permission settings
- `CLAUDE.md` with workflow documentation

This is the fastest way to go from zero to a working Databricks ML project with Claude Code.

## License

MIT
