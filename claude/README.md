# Claude Code 設定

此資料夾管理 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 的 user-scope 設定，方便在新電腦上快速還原。

## 目錄結構

```
claude/
├── CLAUDE.md      # User-scope 指令（全域生效）
├── commands/      # Slash commands（/command-name）
├── skills/        # Skills（自動觸發的技能）
├── settings.json  # 權限與偏好設定
├── setup.sh       # Symlink 安裝腳本
└── README.md
```

## 使用方式

在新電腦上 clone 此 repo 後執行：

```bash
./claude/setup.sh
```

腳本會將以下項目 symlink 到 `~/.claude/`：

| 來源 | 目標 | 說明 |
|------|------|------|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | 全域行為指令 |
| `skills/*` | `~/.claude/skills/*` | 各 skill 資料夾 |
| `commands/*` | `~/.claude/commands/*` | 各 command 檔案 |
| `settings.json` | `~/.claude/settings.json` | 權限與偏好設定 |

- 若目標位置已有同名檔案（非 symlink），會自動備份為 `*.backup.<timestamp>`
- 若 symlink 已指向正確來源，會跳過不重建
- 重複執行是安全的（idempotent）

## 新增 Skill / Command

- **Skill**：在 `skills/` 下建立子資料夾，內含 `SKILL.md`
- **Command**：在 `commands/` 下建立 `.md` 檔案

新增後重新執行 `setup.sh` 即可生效。
