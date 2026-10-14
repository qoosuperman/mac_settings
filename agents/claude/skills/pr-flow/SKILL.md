---
name: pr-flow
description: "把一個 Spectra change 從實作一路推到開 PR：以最新 origin/main 開新分支 → spectra-apply 實作 → dual-review → 修正 → 重跑 dual-review 直到沒有 blocking → 發 PR。Use for pr-flow, 實作並發 PR, apply 完自動 review 再開 PR。Not for 只實作不開 PR（spectra-apply）、只做 review（dual-review）、或已存在 PR 的後續修改。"
argument-hint: <change-name>
allowed-tools: Skill, Agent, Bash, Read, Edit, Write, Grep, Glob, AskUserQuestion
---

# PR Flow

輸入一個 Spectra change 名稱，完成「開分支 → 實作 → 雙重審查迴圈 → 開 PR」。第一個參數就是 change 名稱，全程沿用，不另外推測。

```text
/pr-flow <change-name>
```

沒給參數時，執行 `spectra list --json` 列出 active changes，用 AskUserQuestion 讓使用者選，不要自己挑。

## 0. Preflight

全部通過才進入下一步，任一失敗就停下來回報：

- `git status --porcelain` 必須為空。有未提交變更時停下來問使用者，不要 stash、不要丟棄。
- `spectra`、`gh`、`git` 可用；`gh auth status` 已登入。
- 記下目前分支名稱，最後回報時告訴使用者原本在哪。

## 1. 以最新 origin/main 開新分支

```bash
git fetch origin main
git switch -c <type>/<change-name> origin/main
```

- 分支名稱 = `<type>/<change-name>`，`<change-name>` 原樣使用（Spectra change 已是 kebab-case）。`<type>` 依 change 的 `proposal.md` 判斷：新功能 `feat`、修 bug `fix`、純重構 `refactor`、純文件 `docs`；判斷不出來用 `feat`。
- 同名分支已存在（本地或 `origin`）時停下來問使用者：沿用、換名、或取消。不要覆蓋、不要 `-C` / `--force`。
- 切過去後確認 `openspec/changes/<change-name>/` 存在（`spectra list --parked --json` 裡的 parked change 也算）。不存在代表 proposal 還沒進 `origin/main`——停下來告訴使用者先把 proposal 合進 main，或改用含 proposal 的分支當 base；不要從舊分支把檔案複製過來。

## 2. 實作：spectra-apply

以 Skill tool 呼叫 `spectra-apply`，args 帶 `<change-name>`，照它的流程完成所有 tasks。

- spectra-apply 中途因 blocker 暫停、或要求使用者決策時，pr-flow 也跟著暫停，把問題交給使用者；不要自己跳過 task 硬往下走。
- 完成後跑專案的測試 / lint / typecheck（依 `AGENTS.md`、`CLAUDE.md`、`package.json` 等實際存在的指令），失敗就先修到綠燈。
- Commit 實作。專案有 `conventional-commit` 或 `spectra-commit` skill 就依它寫 commit message；遵守專案對 commit 語言與格式的規定。dual-review 的 `--base` 模式只看已 commit 的變更，所以 review 前一定要 commit。

## 3. 雙重審查：dual-review

以 Skill tool 呼叫 `dual-review`，args：

```text
--base <origin/main 的 merge-base SHA> --title "pr-flow: <change-name> round <N>"
```

用 `git merge-base origin/main HEAD` 解析 SHA，每輪都用同一個 base，不要中途 fetch 讓 base 漂移。

拿到報告後，**合併兩位 reviewer 的意見**寫成一份給使用者看的摘要：

```markdown
## Round <N> Review Summary

Merge Recommendation: ✅ / ⚠️ / ⛔ / ❔（取自 Combined Merge Recommendation）

### Blocking
- [A/B/Both] file:line — 問題 → 預計修法

### Non-blocking
- [A/B/Both] file:line — 問題 → 修 / 不修（理由）

### Dismissed
- [A/B] file:line — reviewer 的主張 → 為什麼不成立（附證據）
```

### Blocking 的判定

符合任一項就是 blocking：

- Combined Merge Recommendation 為 ⛔ Blocked
- Reviewer A 的 Critical / Major，或 Reviewer B 的 P0 / P1，且經驗證成立
- Status 為 Incomplete 或 Stale——審查本身沒完成，不能當成通過；先排除原因（例如重新 commit 後再跑），仍無法完成就停下來問使用者

### 驗證每一條 finding

不要照單全收。每條 finding 都回到程式碼確認：file:line 是否存在、描述的 failure scenario 是否真的會發生。

- 成立 → 放進 Blocking 或 Non-blocking。
- 不成立 → 放進 Dismissed，寫出反證（相關程式碼、測試、呼叫端）。只有一位 reviewer 提出不代表它錯，兩位都提出也不代表它對。
- 無法判斷（涉及產品決策、需求取捨）→ 問使用者，不要自己決定。

## 4. 根據 review 修改

- Blocking 全部修。
- Non-blocking 中修法明確、範圍小、不改變需求的也一起修；其餘保留，稍後寫進 PR 的注意事項。
- 修改若偏離 change 的 spec / design，先回頭更新 Spectra artifacts（依專案慣例走 `spectra-ingest`），不要讓程式碼和 spec 分岔。
- 修完跑測試 / lint / typecheck，綠燈後 commit（一輪修正一個或數個有意義的 commit，message 說明修了哪些 finding）。

## 5. 重跑 dual-review，直到沒有 blocking

回到步驟 3，round 編號 +1。迴圈規則：

- 該輪沒有 blocking → 進入步驟 6。
- 仍有 blocking → 回到步驟 4。
- **最多 3 輪**。第 3 輪後仍有 blocking，停下來把歷輪摘要交給使用者決定，不要繼續改、不要開 PR。
- 同一條 blocking 在修過之後又原樣出現，或上一輪 Dismissed 的 finding 下一輪再被列為 blocking → 停下來問使用者，不要自己來回拉鋸。

## 6. 發 PR

```bash
git push -u origin <branch>
gh pr create --base main --head <branch> --title "<title>" --body-file <tmp file>
```

- Title 沿用專案 commit 慣例（例如 conventional commit 格式的第一行）。
- Body：專案有 `pr-description` skill 就依它產生；沒有就寫「做了什麼 / 內容 / 注意事項」。注意事項裡附上：
  - review 共跑了幾輪、最後一輪的 Merge Recommendation
  - 保留未修的 Non-blocking 項目與理由
  - Dismissed 的 finding 與理由（讓人類 reviewer 能複核）
- Body 結尾加上目前 host 要求的 attribution。
- 不要 merge、不要 `--force` push、不要自動 request reviewer。
- 專案若規定 `spectra-archive` 的時機（例如「合併前、review 定案後」），照專案規定，pr-flow 不自動 archive。

## 完成回報

```markdown
# PR Flow: <change-name>

Branch: <branch>（base: origin/main @ <sha>；原本在 <original branch>）
PR: <url>
Review rounds: <N>，最終 <Merge Recommendation>

## 每輪摘要
- Round 1: <blocking 數> blocking → 修了什麼
- Round 2: ...

## 留給人類 reviewer
- Non-blocking（未修）/ Dismissed 各項，附 file:line

## Review 導覽
（見下方「Review 導覽」規則）
```

### Review 導覽

完成回報最後附一段導覽，幫人類 reviewer 決定先看哪裡、看懂複雜的部分。

**1. 重要檔案清單**：依建議閱讀順序列出 3–8 個檔案，每個一行：

```markdown
- `path/to/file.ts` — 這個檔案做什麼（一句話）→ review 時注意什麼
```

挑選依據：新增的核心邏輯、對外介面 / schema / migration 變動、錯誤處理與資料一致性、review 迴圈中修過 blocking 的位置。純機械性的改動（rename、型別補齊、測試 fixture、設定檔）不列。

**2. 複雜流程深入說明**：清單中流程較複雜的檔案（跨模組呼叫、資料形狀轉換、多條件分支 / 規則表、非顯而易見的錯誤處理），各寫一段深入說明。一行講得完的檔案不要硬畫圖。格式：

- **開頭一兩句**：這個檔案做什麼、**不**做什麼（例如「本身不碰資料庫」），先講清楚邊界。
- **在整條流程的位置**：用樹狀 call chain 從入口（排程、CLI、API route）畫到這個檔案，標出 `← 在這裡`。
- **資料怎麼變**：縱向資料流圖，每一步都寫出**真實的範例值**（真實欄位名、日期、數字，取自測試或實際回應），不要只寫抽象型別。
- **規則 / 分支**：有多種 case 就畫成表格（條件 × 輸入 × 處理方式），並為每種非直覺的 case 各舉一個實際算例。
- **失敗時**：把多個失敗條件匯流到同一個結果的圖；若做法和相鄰模組不同，說明原因。
- **對外介面**：列出 export 的函式加一行註解，並交代非顯而易見的設計取捨。

圖一律用 code block 內的 ASCII（`└─`、`──►`、`▼`、框線表格），在終端機和 PR 都能直接閱讀。各小節只在有內容時才寫，不要為了湊格式留空殼。範例骨架：

````markdown
### `src/fx/taifex.ts`

抓期交所每日匯率，換算成「1 單位外幣 = 多少台幣」交給 orchestrator 寫入 `FxRate`。本身不碰資料庫。

#### 在整條流程的位置
```
排程 us / CLI refresh us
  └─ runQuoteJob("us")
       └─ sourcesFor("us") ──► createTaifexSource()   ← 在這裡
            └─ refreshQuotes 呼叫 source.fetchRates() ──► upsert FxRate
```

#### 資料怎麼變
```
期交所 API：[{Date:"20260930", "USD/NTD":"31.852", "USD/JPY":"156.96", ...}, ...]
      ▼ pickLatestRow：挑 Date 最大的一列
      ▼ 套用 CURRENCY_RULES（9 條）
[{currency:"USD", rateToTwd:31.852}, {currency:"JPY", rateToTwd:0.202931}, ...]
```

#### 失敗時整批不寫
```
回應不是非空陣列 ──┐
欄位缺漏 ─────────┼──► throw ──► status: failed，舊匯率保留
欄位非正數 ───────┘
```
股價來源是單檔略過；匯率全從同一列換算，部分寫入會造成新舊值混雜，所以整批不寫。
````

任何步驟中途停下時，同樣用這個格式回報到目前為止的進度，並清楚寫出卡在哪一步、需要使用者決定什麼。
