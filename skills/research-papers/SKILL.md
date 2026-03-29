---
name: research-papers
description: Research ML techniques, architectures, or papers relevant to the current task and summarize actionable insights. Use when the user asks "is there a better way to do X", "what are state-of-the-art methods for Y", "find papers on Z", "how do others solve this problem", or wants to understand recent advances in a technique.
context: fork
agent: research-agent
allowed-tools: WebSearch, WebFetch, Read, Write(research/**)
---

# ML research task

Topic: $ARGUMENTS

## Context to read first
- Read `CLAUDE.md` to understand the current model type, dataset, and problem (classification, regression, time series, etc.)
- Read `mlflow_results/latest_run.json` to understand current performance — this defines what "improvement" means

## Research steps

1. Search for recent papers (2022–2025) on the topic. Use queries like:
   - "[topic] survey 2024"
   - "[topic] state of the art benchmark"
   - "[topic] practical improvements"
   - "arxiv [topic] [current model family]"

2. For each relevant paper/technique found, extract:
   - Core idea in 2-3 sentences
   - Performance gain reported on benchmarks similar to the current task
   - Implementation complexity (drop-in change, requires new architecture, needs more data)
   - Whether it's compatible with the current training stack (PyTorch, MLflow, Databricks)

3. Look for:
   - Data augmentation strategies for the current data type
   - Learning rate schedulers that outperform the current setup
   - Regularization techniques (label smoothing, mixup, stochastic depth, etc.)
   - Architecture modifications relevant to the current model
   - Loss function alternatives if the task is classification/detection

4. Save the full research summary to `research/<topic>_<date>.md`

## Output format

Write a structured report with sections:
- **TL;DR**: one paragraph, the single most impactful thing to try
- **Top 3 recommendations**: each with a concrete code snippet or config change
- **Why it should work**: connect the paper's claims to the current experiment's results
- **Implementation steps**: what to change in scripts/train.py or configs/

ultrathink
