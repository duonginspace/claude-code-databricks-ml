---
name: explore-data
description: Analyze a dataset. Use when the user wants to explore data, understand distributions, check quality, find correlations, profile a DataFrame, or generate EDA plots. Triggers on phrases like "look at the data", "what does the dataset look like", "check for missing values", "understand this dataset".
context: fork
agent: data-analyst
allowed-tools: Bash(uv run python *), Bash(head *), Bash(cat *), Read
---

# Data exploration task

Dataset or path: $ARGUMENTS

## Steps

1. Load the data using pandas. Infer the format (csv, parquet, delta) from the path or CLAUDE.md context.
2. Run `df.info()`, `df.describe()`, `df.isnull().sum()` — save output to `eda_results/summary.txt`.
3. Identify column types: numeric, categorical, datetime, text.
4. For each numeric column: plot distribution histogram and boxplot.
5. For categorical columns: show value counts for columns with <50 unique values.
6. Compute a correlation matrix for numeric features — save as `eda_results/correlations.csv`.
7. Flag data quality issues: duplicates, high-cardinality categoricals, columns with >20% missing, suspicious outliers (>4σ).
8. Save all plots to `eda_results/plots/`.
9. Write a concise narrative to `eda_results/report.md`: dataset shape, key distributions, top correlations, and data quality issues to address before modeling.

## Output
Return a 3-5 sentence summary of the most important findings and what they imply for feature engineering or modeling.
