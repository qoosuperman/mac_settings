---
name: review-pr
description: "Use this skill when the user wants to review a PR, check PR comments, view PR diff, read PR reviews, or inspect any GitHub pull request. Triggers: review PR, check PR, PR comments, look at this PR, or a GitHub PR URL. Not for: creating/merging PRs, pre-landing diff review (use /review), local-only code review (use /codex-cli-review). Output: structured review notes with verified, severity-classified findings and checklist."
allowed-tools: Bash(git:*), Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh pr checks:*), Bash(gh api:*), Read, Grep, Glob
---

# Review PR

Always use the `gh` CLI to interact with GitHub pull requests. Never use the
GitHub MCP server tools for these tasks.

## Follow-Through Policy

- **Auto-allowed**: `gh pr view`, `gh pr diff`, `gh pr checks`, `gh api` **GET** endpoints, `git log` / `git blame` / `git show`, reading local files
- **Ask first**: `gh pr checkout` or any other command that changes local branch state, posting review comments (any `gh api` call with `-X POST/PATCH/PUT/DELETE` or `-f`/`-F` fields)
- **Never without explicit request**: merge PR, close PR, approve PR, editing files (including CLAUDE.md / rules)

`gh api` is allowed without a prompt, so its read-only use is enforced by this
policy, not by permissions: never send a write request without asking.

## Prerequisites

- `gh` CLI must be installed and authenticated (`gh auth status`).
- If `gh` is not available or not logged in, stop and tell the user to run `gh auth login`.

## Determine the PR

- If the user provides a PR URL like `https://github.com/owner/repo/pull/123`,
  extract `owner/repo` and the PR number.
- If the user provides just a number, assume it's for the current repo.
- If no PR is specified, ask the user which PR to review.

## Common operations

```bash
# Summary (structured)
gh pr view <number> --repo <owner/repo> --json title,body,author,baseRefName,headRefName,headRefOid,additions,deletions,changedFiles

# Diff / changed files
gh pr diff <number> --repo <owner/repo>
gh pr diff <number> --repo <owner/repo> --name-only

# Inline review comments / conversation comments / reviews
gh api repos/<owner>/<repo>/pulls/<number>/comments --paginate
gh api repos/<owner>/<repo>/issues/<number>/comments --paginate
gh api repos/<owner>/<repo>/pulls/<number>/reviews --paginate

# CI status
gh pr checks <number> --repo <owner/repo>

# File content at PR head (when the repo is not checked out locally)
gh api "repos/<owner>/<repo>/contents/<path>?ref=<headRefOid>" --jq .content | base64 -d
```

## Review workflow

1. **Context**: run `gh pr view --json ...` for title, description, author, base/head, and `headRefOid`.
2. **Diff**: run `gh pr diff`. If the PR has more than 20 changed files or 800 changed lines, run `--name-only` first and review file by file.
3. **Existing discussion**: fetch review comments, conversation comments, and reviews. Do not re-raise issues already raised or resolved there; reference them instead if still unaddressed.
4. **Rules**: read the root `CLAUDE.md` and any `CLAUDE.md` / `.claude/rules/` in directories containing modified files (local checkout or `gh api .../contents`). Also note constraints stated in code comments of modified files.
5. **Review** the changed lines across these dimensions, each mapped to an Output Contract section:

   | Dimension | What to look for | Goes to |
   |---|---|---|
   | Correctness | logic errors, wrong conditions, missed edge cases, broken callers | Findings |
   | Security | injection, authz/authn gaps, secret exposure, unsafe input handling | Findings + Checklist |
   | Performance | N+1, unbounded loops/queries, hot-path regressions | Findings |
   | Rule compliance | violations of CLAUDE.md / rules / code-comment constraints from step 4 | Findings (quote the rule) |
   | Tests | changed behavior lacks tests, tests don't assert the change | Checklist |
   | Compatibility & rollout | API/schema/interface breaks, migration order, feature flags | Checklist |

6. **Verify** each candidate finding (see below) before writing it down.
7. **Optional history check** (only for suspicious or high-risk hunks, or when the user asks for a deep review): `git blame` / `git log -L` on the region, and comments on previous PRs that touched the same files. Use it to confirm intent, not to widen scope.
8. **Rules Update**: if the review reveals a recurring pattern not covered by existing rules, propose a patch in the output. Do not edit files.

### Finding verification

For every Critical / Major candidate:

- Re-read the surrounding code (callers, types, related tests), not just the diff hunk.
- Write a concrete failure scenario: which input or state → which wrong result.
- If you cannot confirm it, downgrade to Minor or mark it `(unverified)`. Never put an unverified item under Critical.

### Do not report

- Issues that existed before this PR, or on lines the PR did not change
- Anything a linter, type checker, compiler, or CI would catch (check `gh pr checks` instead)
- Behavior changes that are clearly intentional per the PR description
- Rules explicitly silenced in code (lint-ignore comments, etc.)
- Pedantic nitpicks or style preferences not backed by a project rule

## Output Contract

Output the following sections in order. Omit "Rules Update" if no new rules were discovered.

```markdown
## Summary

- **What**: one-sentence summary of what the PR does
- **Author**: PR author
- **Scope**: number of files changed, additions, deletions

## Findings

### Critical (blocks merge)
- [file:line] Issue description — failure scenario: <input/state> → <wrong result>

### Major (should fix before merge)
- [file:line] Issue description — failure scenario: <input/state> → <wrong result>

### Minor / Suggestions
- [file:line] Issue description

(If no findings in a severity level, write "None.")

## PR Checklist

- [ ] Tests cover changed behavior
- [ ] No security concerns (injection, auth, secrets)
- [ ] No breaking API/interface changes (or documented)
- [ ] Error handling for edge cases
- [ ] Complies with project rules (CLAUDE.md / .claude/rules/)

## Merge Recommendation

One of: ✅ Ready / ⚠️ Ready with minor fixes / ⛔ Blocked (state reason)

## Rules Update (if any)

- Proposed CLAUDE.md or .claude/rules/ patch (not applied)
```

- `[file:line]` may instead be a GitHub permalink with the full head SHA and a
  line range including one line of context:
  `https://github.com/<owner>/<repo>/blob/<headRefOid>/<path>#L<start>-L<end>`.
- Rule-compliance findings must quote the violated rule and name its file.

**Done when**: all sections above are filled, every Critical/Major finding references a specific file and line and states a failure scenario.

See `references/example_review.md` for a worked example.

## Posting review comments (ask first)

Only after the user approves. Submit findings as one review with inline comments:

```bash
gh api repos/<owner>/<repo>/pulls/<number>/reviews -X POST --input - <<'EOF'
{
  "commit_id": "<headRefOid>",
  "event": "COMMENT",
  "body": "<overall summary>",
  "comments": [
    { "path": "src/foo.ts", "line": 42, "side": "RIGHT", "body": "<finding>" }
  ]
}
EOF
```

- Use `"event": "COMMENT"`; never `APPROVE` or `REQUEST_CHANGES` unless the user explicitly asks.
- `line` must be a line present in the diff on the given `side`, or the API rejects the review.

## Notes

- For large diffs, reading full files from a local checkout is easier. Checking
  out the PR (`gh pr checkout <number>`) changes local branch state, so ask first;
  otherwise read files at the PR head via `gh api .../contents?ref=<headRefOid>`.
