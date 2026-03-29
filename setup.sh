#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
MODE="copy"
FORCE=false

usage() {
    echo "Usage: setup.sh [--symlink] [--force]"
    echo ""
    echo "Install Claude Code skills, agents, commands, and scripts to ~/.claude/"
    echo ""
    echo "Options:"
    echo "  --symlink  Create symlinks instead of copies (auto-updates when you git pull)"
    echo "  --force    Overwrite existing files without prompting"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --symlink) MODE="symlink"; shift ;;
        --force) FORCE=true; shift ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

installed=0
skipped=0

install_file() {
    local src="$1" dst="$2"
    if [[ -e "$dst" ]] && [[ "$FORCE" != true ]]; then
        read -rp "  $dst exists. Overwrite? [y/N] " answer
        if [[ "$answer" != [yY] ]]; then
            echo "  Skipped."
            ((skipped++))
            return
        fi
    fi
    mkdir -p "$(dirname "$dst")"
    if [[ "$MODE" == "symlink" ]]; then
        ln -sf "$src" "$dst"
    else
        cp "$src" "$dst"
    fi
    ((installed++))
}

echo "Installing Claude Code Databricks ML Toolkit..."
echo "Mode: $MODE"
echo ""

# Skills
echo "Skills:"
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
    name=$(basename "$skill_dir")
    install_file "$skill_dir/SKILL.md" "$CLAUDE_DIR/skills/$name/SKILL.md"
    echo "  $name"
done
echo ""

# Agents
echo "Agents:"
for agent in "$SCRIPT_DIR"/agents/*.md; do
    name=$(basename "$agent")
    install_file "$agent" "$CLAUDE_DIR/agents/$name"
    echo "  ${name%.md}"
done
echo ""

# Commands
echo "Commands:"
for cmd in "$SCRIPT_DIR"/commands/*.md; do
    name=$(basename "$cmd")
    install_file "$cmd" "$CLAUDE_DIR/commands/$name"
    echo "  ${name%.md}"
done
echo ""

# Scripts
echo "Scripts:"
install_file "$SCRIPT_DIR/scripts/context-bar.sh" "$CLAUDE_DIR/scripts/context-bar.sh"
chmod +x "$CLAUDE_DIR/scripts/context-bar.sh"
echo "  context-bar.sh"
echo ""

# Summary
echo "---"
echo "Installed: $installed files"
echo "Skipped:   $skipped files"
echo ""
echo "To enable the status bar, add to ~/.claude/settings.json:"
echo ""
echo '  "statusLine": {'
echo '    "type": "command",'
echo '    "command": "~/.claude/scripts/context-bar.sh"'
echo '  }'
echo ""
echo "Done."
