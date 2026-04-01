---
name: review-pr
description: "Use this skill when the user wants to review a PR, check PR comments, view PR diff, read PR reviews, or inspect any GitHub pull request. Triggers: review PR, check PR, PR comments, look at this PR, or a GitHub PR URL. Not for: creating/merging PRs, pre-landing diff review (use /review), local-only code review (use /codex-cli-review). Output: structured review notes with severity-classified findings and checklist."
allowed-tools: Bash(git:*), Read, Grep, Glob, Edit
---

# Review PR

Always use the `gh` CLI to interact with GitHub pull requests. Never use the
GitHub MCP server tools for these tasks.

## Follow-Through Policy

- **Auto-allowed**: `gh pr view`, `gh pr diff`, `gh api` read endpoints, reading local files
- **Ask first**: `gh pr checkout` (changes local branch state), posting review comments
- **Never without explicit request**: merge PR, close PR, approve PR

## Prerequisites

- `gh` CLI must be installed and authenticated (`gh auth status`).
- If `gh` is not available or not logged in, stop and tell the user to run `gh auth login`.

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

## Output Contract

Output the following sections in order. Omit "Rules Update" if no new rules were discovered.

```markdown
## Summary

- **What**: one-sentence summary of what the PR does
- **Author**: PR author
- **Scope**: number of files changed, additions, deletions

## Findings

### Critical (blocks merge)
- [file:line] Issue description

### Major (should fix before merge)
- [file:line] Issue description

### Minor / Suggestions
- [file:line] Issue description

(If no findings in a severity level, write "None.")

## PR Checklist

- [ ] Tests cover changed behavior
- [ ] No security concerns (injection, auth, secrets)
- [ ] No breaking API/interface changes (or documented)
- [ ] Error handling for edge cases

## Merge Recommendation

One of: ✅ Ready / ⚠️ Ready with minor fixes / ⛔ Blocked (state reason)

## Rules Update (if any)

- Proposed CLAUDE.md or .claude/rules/ patch
```

**Done when**: all sections above are filled, every Critical/Major finding references a specific file and line.

## Notes

- Prefer `gh` CLI over MCP GitHub tools for all PR operations.
- For large diffs, consider reading changed files directly from the local checkout
  after running `gh pr checkout <number>` if the repo is available locally.
- Use `--json` flag with `gh pr view` when you need structured data:
  ```bash
  gh pr view <number> --repo <owner/repo> --json title,body,author,baseRefName,headRefName,additions,deletions,changedFiles
  ```
