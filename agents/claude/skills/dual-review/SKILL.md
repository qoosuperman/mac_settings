---
name: dual-review
description: "Run two independent code reviews in Claude Code or Codex, then consolidate findings. Use for dual review, double review, 雙重審查, or two review perspectives on a PR, local changes, or branch diff. Not for single-reviewer requests (review-pr / codex-cli-review) or the pre-landing workflow (review)."
allowed-tools: Agent, Bash, Read, Grep, Glob
---

# Dual Review

以兩個獨立執行脈絡審查同一份變更：A 使用 `review-pr` 的審查方式，B 優先使用 Codex CLI。保留兩份報告，再整合結論。在 Codex 中，A 也可能使用 Codex 模型；這代表兩個獨立 reviewer，不保證是兩種不同模型。

## Host Adapter

依本次 session 實際提供的工具選擇，工具名稱與參數以目前 schema 為準。

| Host | 啟動與等待 | 呼叫範例 |
|------|------------|----------|
| Claude Code | 用 `Agent` 在同一回合啟動 A、B，收齊兩份完成結果 | `/dual-review 42` |
| Codex | 用 `spawn_agent` 啟動 A、B，再使用可用的等待工具收齊結果；若工具位於 `collaboration` namespace，使用 `collaboration.spawn_agent` / `collaboration.wait_agent` | `$dual-review 42` |

- 兩個 reviewer 都啟動後才等待，不能先等 A 完成才啟動 B。
- Codex 若支援 `fork_turns`，設為 `none`，以完整任務提示提供必要資訊；若支援 `task_name`，分別命名 `review_a`、`review_b`。保留 host 預設模型，不硬編碼模型或 reasoning 參數。
- Claude 的 `allowed-tools` 是 host metadata，不代表 Codex 具有同名工具。Codex 使用目前可用的檔案、shell、agent 工具。
- 沒有 subagent 工具時：主 agent 執行 A，另以獨立 Codex CLI process 執行 B；能平行就平行，否則註明序列執行。若連獨立 CLI 也無法使用，只交付 A 並標記 B 未完成，不得把主 agent 重讀一次冒充獨立 review。

## Dependencies and Paths

1. 從 session 的 skill 清單解析 `review-pr`、`codex-cli-review` 的實際位置，讀取各自的 `SKILL.md`。
2. 清單未提供位置時，先找本 skill 同層的 sibling skills，再找目前 host 的技能根目錄：Codex 使用 `${CODEX_HOME:-$HOME/.codex}/skills`，Claude Code 使用 `$HOME/.claude/skills`。先確認檔案存在，不假設 Claude 的目錄在 Codex 中也存在。
3. 把已解析的絕對路徑或必要的完整 skill 內容交給 subagent；不要假設它繼承 slash command 或父 agent 的技能內容。
4. `review-pr` 缺失時，A 依下方 fallback 審查。B 優先採 `codex-cli-review` 的審查與輸出契約；CLI 呼叫遵循下方 host-neutral 方式，不依賴其文件中寫死的安裝路徑。

## Default Follow-Through Policy

- PR 相關的 GitHub 操作沿用 `review-pr` 的 Follow-Through Policy；fetch、建立 worktree 比照 checkout，須先取得授權。
- 直接做：啟動獨立 reviewer，整合報告。
- 這是唯讀審查：不得修改程式、更新 CLAUDE.md / AGENTS.md / rules、commit、push 或自動修正。依賴 skill 的寫入步驟不屬於此次任務。
- 使用者限制（例如「不要做 Git 操作」）同樣傳給兩個 reviewer；無法讀取必要變更時，交代缺少的資料，不繞過限制。

## Workflow

### 1. Fix the Review Target

產生同一份 target brief 給 A、B，包含模式、repo 絕對路徑、變更範圍、可用資料、使用者限制、`--title` 和 `--prompt`。兩人不得收到對方的 findings。

| 輸入 | 審查範圍 |
|------|----------|
| PR URL / number | 依 `review-pr` 的 Determine the PR 取得 PR 資訊與 diff，另記錄 base/head SHA |
| 無指定 / `--uncommitted` | staged、unstaged、untracked 全部變更 |
| `--base <branch>` | merge-base 到目前 HEAD 的 committed changes；不混入工作目錄變更 |

- Local：分別取得 `git diff`、`git diff --cached` 和 `git ls-files --others --exclude-standard`，讀取 untracked 文字檔；不能只看 cached diff。記錄無法審查的 binary 或大型檔案。
- Branch：先解析 base commit 與 HEAD，使用 `git diff <base-sha>...<head-sha>`。不要用 two-dot diff 當成 PR 的 merge-base diff。
- PR：A 用 `review-pr` 流程。B 只有在確認本地 repo 與 PR 相符、HEAD 等於 PR head SHA 且 base commit 可用時，才能對該 checkout 執行 `--base <base-sha>`。不要默認目前 branch 就是指定 PR。
- PR checkout 不相符或 base 不可用時，將同一份 PR diff、metadata 及指定 SHA 的必要檔案內容提供給兩人；B 用下述 prompt-only CLI 模式審查這些資料，不審查當前 branch。若資料不足，註明限制；只有確實需要 checkout/fetch 時才依授權政策處理。
- 審查開始與完成時確認 target 未變動；若 HEAD、PR SHA 或 local diff/檔案內容有變動，標示結果已過期，不能合併成完整結論。Local 可比較前後 diff 與 untracked 內容快照。
- 沒有變更時直接回報，不啟動空的雙重審查。

### 2. Launch Independent Reviewers

兩個任務都附上以下共同限制：

```text
只做指定 target 的唯讀 review，不修改任何檔案或 Git 狀態，不發佈留言。
遵守 target brief 的使用者限制。不要呼叫 dual-review 或再啟動 reviewer。
只根據變更和相關上下文提出可驗證問題；提供 file:line、影響與修正建議。
報告要列出實際審查範圍、執行方式、未檢查部分與測試是否真的執行。
沒有發現時明寫 None，不為了填格式製造問題。
```

**Reviewer A — structured review**

- 附上 `review-pr/SKILL.md`，依其 Review workflow（含 Finding verification、Do not report）與 Output Contract 輸出，略過 Rules Update 與 Posting review comments。
- Local / Branch mode：跳過 workflow 1–3 與 `gh pr checks`，改讀 target brief 指定的 diff 與上下文，其餘步驟照用；Summary 的 Author 改寫成 target 描述。不得因為沒有 PR 而停止。
- 找不到 `review-pr` 時照樣審查，依 Critical / Major / Minor 分級、Critical / Major 附 failure scenario，並給 Merge Recommendation，標記 fallback。
- `--prompt` 的自訂焦點同樣適用於 A。

**Reviewer B — Codex CLI review**

- 先確認 `codex` 可用，讀取本機 `codex review --help`，依安裝版本支援的參數執行。
- 無自訂 prompt 且 checkout 已驗證：在 target repo 目錄使用 `codex review --uncommitted` 或 `codex review --base <resolved-base-sha>`，有 title 時加上 `--title`。
- 有 `--prompt` 或只能審查提供的 PR 資料：使用 `codex review -`，將完整任務（精確 target、唯讀限制、自訂焦點與必要 diff/context）透過 stdin 傳入。不要將 positional prompt / stdin `-` 和 `--base` / `--uncommitted` 混用；有些版本不接受這種組合。此模式必須在 prompt 明確指定範圍，不能讓 CLI 自行選擇當前變更。
- 保留 host 的權限邊界，不加 bypass approval 或擴大 sandbox 權限的旗標。用 shell argument array 與安全 stdin / 檔案傳遞，不能用 `eval` 或直接拼接使用者 prompt 到 shell 指令。
- CLI 尚在執行時，用回傳的 process/session handle 等待完成，不能把「已啟動」當作結果。保留 exit code 與完整輸出。
- CLI 不存在、登入失敗或執行錯誤時，不自動安裝、登入或無限重試。若 B 有自己的 subagent context，就在該 context 直接審查相同 target，輸出 Findings（P0/P1/P2/P3）及 Merge Gate，明標 `Independent agent fallback` 與失敗原因；不得稱作 CLI 成功。
- 若 B 沒有獨立 subagent context 且 CLI 失敗，回報 B 未完成。

### 3. Consolidate

收齊 A、B 的完成報告後再整合。核對 file:line 與 target，依根因去重；同一問題被兩人指出不代表已證實，只有一人指出也不代表不成立。

若 reviewer 失敗或資料不足，保留已完成報告並標記 Incomplete；不要將未完成誤寫成 None 或 Ready。Checklist 未驗證的項目維持未勾選。

## Output Contract

使用使用者語言，依序輸出：

```markdown
# Dual Review Report

Target: {mode, repo, SHA 或 local snapshot 範圍}
Execution: {host; parallel / sequential; A、B 的實際 backend 與 fallback}
Status: Complete / Incomplete / Stale

## Review A: Structured Review
{完整 A 報告；PR mode 註明 review-pr}

## Review B: Codex CLI Review
{完整 B 報告；fallback 時標題改為 Independent Agent Review；失敗時列原因}

## Consolidated Conclusion
### Agreement
{共同 findings，附 file:line；沒有則寫 None}
### Divergence
{單邊 findings 與實際分歧，附 file:line；沒有則寫 None}
### Combined Merge Recommendation
✅ Ready / ⚠️ Ready with minor fixes / ⛔ Blocked / ❔ Incomplete
{原因；過期或缺少一份審查不得給 Ready}
### Action Items
{按優先級排序，每項附來源 A / B / Both；沒有則寫 None}
```

完成條件：兩份獨立 review 審查相同 target，執行狀態與限制如實揭露，結論與 action items 可追溯至具體 findings。Fallback 完成代表雙 reviewer 完成，不代表 Codex CLI 已驗證成功。

## Arguments and Examples

| 參數 | 用途 |
|------|------|
| PR URL / number | 指定 GitHub PR；number 使用目前 repo |
| `--uncommitted` | 審查所有未提交變更，亦為未指定 target 時的預設 |
| `--base <branch>` | 審查 branch committed diff |
| `--title "text"` | 報告標題，傳給 CLI 支援的 title 選項 |
| `--prompt "text"` | 兩位 reviewer 共同採用的自訂焦點 |

Codex：

```text
$dual-review https://github.com/owner/repo/pull/123
$dual-review
$dual-review --base main
$dual-review 123 --prompt "Focus on SQL injection and auth bypass"
```

Claude Code 使用相同參數，把 `$dual-review` 換成 `/dual-review`。也可用自然語言要求「幫我對這些變更做 dual review」。
