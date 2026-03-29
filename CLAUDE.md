# claude-code-databricks-ml

This repository contains Claude Code skills, agents, commands, and scripts for ML workflows on Databricks.

## Structure
- `skills/` — Each subdirectory contains a `SKILL.md` file (Claude Code skill format)
- `agents/` — Agent definition markdown files
- `commands/` — Custom slash commands
- `scripts/` — Utility scripts (status bar)
- `settings/` — Example `settings.json` configurations
- `setup.sh` — Installation script

## Rules
- Skills must not contain hardcoded user paths or credentials
- Skills reference project-relative paths (`mlflow_results/`, `scripts/`, `src/`)
- Environment-specific values come from `.env` or environment variables
- The `init-databricks-ml` skill is the most comprehensive — it scaffolds everything else
- Keep skill descriptions accurate — they determine when Claude triggers the skill
