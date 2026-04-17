# Agents 設定

此資料夾集中管理各 AI agent 的設定檔與安裝腳本。

## 目錄結構

```text
agents/
├── claude/      # Claude Code user-scope 設定
├── codex/       # Codex 設定（你後續會再補）
├── setup.sh     # 安裝入口（目前含 Claude）
└── README.md
```

## 使用方式

在 repo 根目錄執行：

```bash
./agents/setup.sh
```

- 會將 `agents/claude` 內的設定 symlink 到 `~/.claude/`
- 若未來新增 `agents/codex/setup.sh`，也會一併執行

## Claude

`agents/claude/` 管理 Claude Code 的 user-scope 設定，主要透過 symlink 方式安裝到 `~/.claude/`。

### 內容

```text
agents/claude/
├── CLAUDE.md      # User-scope 指令（全域生效）
├── commands/      # Slash commands（/command-name）
├── skills/        # Skills（自動觸發的技能）
└── settings.json  # 權限與偏好設定
```

### 會建立的 symlink

| 來源 | 目標 | 說明 |
|------|------|------|
| `agents/claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | 全域行為指令 |
| `agents/claude/skills/*` | `~/.claude/skills/*` | 各 skill 資料夾 |
| `agents/claude/commands/*` | `~/.claude/commands/*` | 各 command 檔案 |
| `agents/claude/settings.json` | `~/.claude/settings.json` | 權限與偏好設定 |

- 若目標位置已有同名檔案（非 symlink），會自動備份為 `*.backup.<timestamp>`
- 若 symlink 已指向正確來源，會跳過不重建
- 重複執行是安全的（idempotent）

## Codex

`agents/codex/` 目前會安裝兩個東西到 `~/.codex/`：

| 來源 | 目標 | 說明 |
|------|------|------|
| `agents/codex/AGENTS.md` | `~/.codex/AGENTS.md` | 目前是 symlink 到 `agents/claude/CLAUDE.md` |
| `agents/codex/skills/*` | `~/.codex/skills/*` | 目前是 symlink 到 `agents/claude/skills/*` |
