---
name: codex-cli-review
description: "Code review via Codex CLI with full disk access. Use when: deep review needing full codebase read, uncommitted change review. Output: severity-grouped findings + merge gate."
allowed-tools: Bash(bash:*), Read, Grep, Glob
context: fork
---

# Codex CLI Review Skill

## Trigger

- Keywords: codex cli review, cli review, script review

## When to Use

- Need Codex to independently explore the entire project (full disk read)
- Want to use Codex CLI's native review format
- Deep review of uncommitted changes or branch diff

## Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: Check Changes                                           │
├─────────────────────────────────────────────────────────────────┤
│ git status --porcelain                                          │
│ No changes -> Early exit                                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: Execute Codex CLI                                       │
├─────────────────────────────────────────────────────────────────┤
│ codex review --uncommitted                                      │
│   -c 'sandbox_permissions=["disk-full-read-access"]'            │
│                                                                 │
│ Codex will independently:                                       │
│ - Read changed files                                            │
│ - Explore related dependencies                                  │
│ - Check existing tests                                          │
│ - Understand project structure                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 3: Output Review Results                                   │
├─────────────────────────────────────────────────────────────────┤
│ Codex native format:                                            │
│ - Summary                                                       │
│ - Issues (Critical/Major/Minor/Suggestion)                      │
│ - Recommendations                                               │
└─────────────────────────────────────────────────────────────────┘
```

## Script

```bash
bash "$HOME/.claude/skills/codex-cli-review/scripts/review.sh" [options]
```

### Options

| Parameter           | Description                |
| ------------------- | -------------------------- |
| `--base <branch>`   | Compare with specified branch |
| `--title "<text>"`  | Set review title           |
| `--prompt "<text>"` | Custom review instructions |

### I/O Contract

**Input:**

- Git working directory with changes

**Output:**

- Codex review report (stdout)
- Exit code: 0 = success, non-0 = failure

## Output

```markdown
## Codex CLI Review Report
### Findings
#### P0/P1/P2
- [file:line] Issue → Fix recommendation
### Merge Gate
✅ Ready / ⛔ Blocked
```

## Verification

- [ ] Script executes without errors
- [ ] Codex explored the project (file references visible in output)
- [ ] Output includes issue classification

## Examples

```bash
# Review uncommitted changes
/codex-cli-review

# Compare with main branch
/codex-cli-review --base main

# With title
/codex-cli-review --title "Feature: User Auth"

# Custom review instructions
/codex-cli-review --prompt "Focus on security and performance"
```
