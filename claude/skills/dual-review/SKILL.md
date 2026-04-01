---
name: dual-review
description: "Parallel code review using both review-pr and codex-cli-review. Spawns two independent subagents, collects findings, outputs side-by-side reports with consolidated conclusion. Triggers: dual review, double review, full review, review with codex. Not for: single-tool review (use /review-pr or /codex-cli-review), pre-landing diff review (use /review)."
allowed-tools: Agent, Bash(git:*), Bash(gh:*), Read, Grep, Glob
---

# Dual Review

平行啟動 `review-pr` 和 `codex-cli-review` 兩個獨立 reviewer，收集結果後整合成一份報告。

## Decision Boundary

- **何時用**: 想同時拿到兩種視角的 code review（GitHub PR review + Codex CLI review）
- **何時不用**: 只需要單一 review → 用 `/review-pr` 或 `/codex-cli-review`；pre-landing diff → 用 `/review`
- **成功輸出**: 並列兩份獨立報告 + 一段綜合結論

## Default Follow-Through Policy

- **直接做**: 讀取 PR 資訊、讀取 diff、啟動 subagent、整合報告
- **先問**: checkout 到其他 branch、posting review comments
- **不做除非明確要求**: merge PR、approve PR、close PR

## Workflow

### Step 1: Determine Review Target

讀取使用者輸入，判斷 review 對象：

| 輸入 | 模式 | review-pr 參數 | codex-cli-review 參數 |
|------|------|----------------|----------------------|
| PR URL 或 PR number | PR mode | `gh pr diff <number>` | `--base <base-branch>` |
| 無指定（有 uncommitted changes） | Local mode | 跳過（無 PR 可 review） | `--uncommitted` |
| `--base <branch>` | Branch mode | 跳過（無 PR 可 review） | `--base <branch>` |

**PR mode 時**，兩個 reviewer 都啟動。
**Local / Branch mode 時**，只有 codex-cli-review 可用；review-pr 需要 PR，因此改為由 subagent 直接讀取 diff 並按 review-pr 的 output contract 格式產出報告。

### Step 2: Spawn Two Subagents in Parallel

用 Agent tool 在**同一個 message** 中啟動兩個 subagent，確保平行執行。

#### Subagent A: review-pr reviewer

Prompt 模板（PR mode）：

```
你是 code reviewer。請按照以下 skill 定義來 review PR。

Review 對象: {PR_URL_OR_NUMBER}
Repo: {OWNER/REPO}

{貼入 review-pr/SKILL.md 的完整內容}

完成後輸出完整的 review report，嚴格遵循 Output Contract 格式。
```

Prompt 模板（Local/Branch mode）：

```
你是 code reviewer。請讀取當前 git diff 並按照以下格式產出 review report。

Review 對象: {uncommitted changes / diff vs <branch>}

先執行:
- git diff {--cached 或 <branch>..HEAD} 取得完整 diff
- 讀取相關檔案以理解上下文

然後按照以下 Output Contract 產出報告：

## Summary
- **What**: one-sentence summary
- **Scope**: files changed, additions, deletions

## Findings
### Critical (blocks merge)
### Major (should fix before merge)
### Minor / Suggestions

## PR Checklist
- [ ] Tests cover changed behavior
- [ ] No security concerns
- [ ] No breaking API/interface changes
- [ ] Error handling for edge cases

## Merge Recommendation
✅ Ready / ⚠️ Ready with minor fixes / ⛔ Blocked
```

#### Subagent B: codex-cli-review reviewer

Prompt 模板：

```
你是 code reviewer，使用 Codex CLI 進行審核。

Review 對象: {uncommitted / --base <branch>}

請執行以下腳本：
bash "$HOME/.claude/skills/codex-cli-review/scripts/review.sh" {options}

{若有額外 options 如 --title、--prompt，加在這裡}

執行完畢後，把 codex 的完整輸出作為你的回覆。若 codex CLI 不可用，改用 git diff 手動 review 並按以下格式輸出：

## Codex CLI Review Report
### Findings
#### P0/P1/P2
- [file:line] Issue → Fix recommendation
### Merge Gate
✅ Ready / ⛔ Blocked
```

### Step 3: Consolidate Results

收到兩個 subagent 的回覆後，按 Output Contract 整合。

## Output Contract

嚴格按以下順序輸出，不可省略任何 section：

```markdown
# Dual Review Report

## Review A: GitHub PR Review (review-pr)

{Subagent A 的完整報告，保持原始格式}

---

## Review B: Codex CLI Review (codex-cli-review)

{Subagent B 的完整報告，保持原始格式}

---

## Consolidated Conclusion

### Agreement
- 兩邊都指出的問題（高信心）

### Divergence
- 只有一邊指出的問題（需人工判斷）

### Combined Merge Recommendation
✅ Ready / ⚠️ Ready with minor fixes / ⛔ Blocked (state reason)

### Action Items
1. [Priority] Action description — source: Review A / Review B / Both
```

**Done when**: 三個 section 都填完，Agreement/Divergence 有具體 file:line 引用，Action Items 按優先級排序。

## Arguments

| Parameter | Description | Example |
|-----------|-------------|---------|
| PR URL or number | GitHub PR to review | `https://github.com/owner/repo/pull/123` or `123` |
| `--base <branch>` | Compare with branch (no PR) | `--base main` |
| `--title "<text>"` | Pass title to codex-cli-review | `--title "Feature: Auth"` |
| `--prompt "<text>"` | Custom review instructions for both reviewers | `--prompt "Focus on security"` |

## Examples

```bash
# Review a PR with dual reviewers
/dual-review https://github.com/owner/repo/pull/123

# Review a PR by number (current repo)
/dual-review 42

# Review uncommitted changes (codex-cli-review + manual diff review)
/dual-review

# Review branch diff
/dual-review --base main

# With custom focus
/dual-review 123 --prompt "Focus on SQL injection and auth bypass"
```
