---
name: review-pr
description: >
  Use this skill when the user wants to review code, review a PR, check PR comments,
  view PR diff, read PR reviews, or any GitHub pull request related inspection task.
  Triggers on phrases like "review PR", "review code", "check PR", "PR comments",
  "look at this PR", or when the user provides a GitHub PR URL.
argument-hint: [--base <branch>]
allowed-tools: Bash(git:*), Read, Grep, Glob, Edit
---

# Review PR

Always use the `gh` CLI to interact with GitHub pull requests. Never use the
GitHub MCP server tools for these tasks.

## Context

- Status: !`git status -sb`
- Diff: !`git diff --stat origin/main...HEAD || git diff --stat HEAD~1`
- Commits: !`git log --oneline -10`

## Determine the PR

- If the user provides a PR URL like `https://github.com/owner/repo/pull/123`,
  extract `owner/repo` and the PR number.
- If the user provides just a number, assume it's for the current repo.
- If no PR is specified, ask the user which PR to review.

## Common operations

### View PR summary

```bash
gh pr view <number> --repo <owner/repo>
```

### View PR diff

```bash
gh pr diff <number> --repo <owner/repo>
```

### View PR comments (review comments on code)

```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments --paginate
```

### View PR issue-level comments (conversation)

```bash
gh api repos/<owner>/<repo>/issues/<number>/comments --paginate
```

### View PR reviews

```bash
gh api repos/<owner>/<repo>/pulls/<number>/reviews --paginate
```

### View PR changed files list

```bash
gh pr diff <number> --repo <owner/repo> --name-only
```

### View PR checks / CI status

```bash
gh pr checks <number> --repo <owner/repo>
```

## Review workflow

1. Start by running `gh pr view` to understand the PR context (title, description, author, base branch).
2. Run `gh pr diff` to read the full diff.
3. If the diff is large, use `--name-only` first to see which files changed, then review the diff file by file.
4. If the user asks about comments or feedback, fetch the relevant comments using the API endpoints above.
5. Provide a clear, structured review covering:
   - What the PR does (summary)
   - Potential issues or concerns
   - Suggestions for improvement
   - Overall assessment
6. Review: correctness, security, perf
7. PR checklist: tests, rollout, compat
8. Discover new rules -> update CLAUDE.md or .claude/rules/

## Output

```markdown
## Review Notes

- <findings>

## PR Checklist

- [ ] Tests pass
- [ ] No breaking changes
- [ ] Docs updated

## Rules Update (if any)

- <proposed patch>
```

## Notes

- Prefer `gh` CLI over MCP GitHub tools for all PR operations.
- For large diffs, consider reading changed files directly from the local checkout
  after running `gh pr checkout <number>` if the repo is available locally.
- Use `--json` flag with `gh pr view` when you need structured data:
  ```bash
  gh pr view <number> --repo <owner/repo> --json title,body,author,baseRefName,headRefName,additions,deletions,changedFiles
  ```
