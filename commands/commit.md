---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*)
description: Create a git commit following Conventional Commits 1.0.0
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes, create a single git commit following the **Conventional Commits 1.0.0** specification.

### Commit message format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Rules

1. **Choose the correct type** based on the nature of the changes:
   - `feat` — a new feature (correlates with MINOR in SemVer)
   - `fix` — a bug fix (correlates with PATCH in SemVer)
   - `build` — changes to build system or external dependencies
   - `chore` — maintenance tasks that don't modify src or test files
   - `ci` — CI configuration changes
   - `docs` — documentation only changes
   - `style` — formatting, whitespace, semicolons (no code logic change)
   - `refactor` — code change that neither fixes a bug nor adds a feature
   - `perf` — performance improvement
   - `test` — adding or correcting tests
   - `revert` — reverting a previous commit

2. **Scope** (optional): a noun in parentheses describing the section of the codebase, e.g., `feat(parser):`, `fix(api):`.

3. **Description**: immediately after the colon and space. Short summary of the changes in imperative mood, lowercase, no period at end.

4. **Body** (optional): one blank line after the description. Free-form, may consist of multiple paragraphs. Explain the **why**, not the **what**.

5. **Footer** (optional): one blank line after the body. Use `BREAKING CHANGE: <description>` for breaking API changes. Other footers follow git trailer format (`Reviewed-by:`, `Refs: #123`, etc.).

6. **Breaking changes**: append `!` after the type/scope AND/OR add a `BREAKING CHANGE:` footer. Example: `feat!: drop support for Node 6` or `feat(api)!: rename endpoint`.

7. **Keep the first line under 72 characters.**

8. **Match the commit style** of recent commits in the repository when choosing scope granularity.

### Procedure

1. Analyze the diff to determine the correct type, optional scope, and description.
2. Stage the relevant changed files (prefer specific files over `git add -A`).
3. Create the commit. Use a HEREDOC for the message to ensure proper formatting:
   ```
   git commit -m "$(cat <<'EOF'
   <type>[scope]: <description>

   [optional body]

   [optional footer(s)]
   EOF
   )"
   ```
4. Do NOT push. Only stage and commit.
5. Do not send any other text or messages besides the tool calls.
