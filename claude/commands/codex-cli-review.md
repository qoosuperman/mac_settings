---
description: Review uncommitted changes using Codex CLI (not MCP). Codex autonomously explores the entire project.
argument-hint: [--base <branch>] [--title "<text>"] [--prompt "<text>"]
allowed-tools: Bash(bash:*)
---

⚠️ **Must read and follow the skill below before executing this command:**

@skills/codex-cli-review/SKILL.md

## Context

- Git status: !`bash -c 'git status -sb'`
- Changed files: !`bash -c 'git diff --name-only HEAD 2>/dev/null | head -10'`

## Task

Use Codex CLI to review uncommitted changes.

### Arguments

```
$ARGUMENTS
```

### Execute Script

```bash
bash "$HOME/.claude/skills/codex-cli-review/scripts/review.sh" $ARGUMENTS
```

## Output

Codex native review format:

- **Summary**: Change overview
- **Issues**: Critical / Major / Minor / Suggestion
- **Recommendations**: Improvement suggestions

## Examples

```bash
# Review uncommitted changes
/codex-cli-review

# Compare with main branch
/codex-cli-review --base main

# With title
/codex-cli-review --title "Feature: User Auth"

# Custom review prompt
/codex-cli-review --prompt "Focus on security and performance"
```
