#!/usr/bin/env bash
#
# 將 repo 中的 Claude 設定 symlink 到 ~/.claude (user scope)
# 支援: CLAUDE.md, skills/, commands/
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"

# 確保 ~/.claude 目錄存在
mkdir -p "${CLAUDE_HOME}"

symlink_item() {
  local src="$1"
  local dest="$2"

  if [ ! -e "$src" ]; then
    echo "  跳過: $(basename "$src") (來源不存在)"
    return
  fi

  if [ -L "$dest" ]; then
    local current_target
    current_target="$(readlink "$dest")"
    if [ "$current_target" = "$src" ]; then
      echo "  已連結: $(basename "$dest")"
      return
    fi
    echo "  更新 symlink: $(basename "$dest")"
    rm "$dest"
  elif [ -e "$dest" ]; then
    local backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
    echo "  備份既有檔案: $(basename "$dest") -> $(basename "$backup")"
    mv "$dest" "$backup"
  fi

  ln -s "$src" "$dest"
  echo "  已建立: $(basename "$dest") -> $src"
}

echo "=== Claude Code 設定 symlink 工具 ==="
echo "來源: ${SCRIPT_DIR}"
echo "目標: ${CLAUDE_HOME}"
echo ""

# 1. CLAUDE.md
echo "[CLAUDE.md]"
symlink_item "${SCRIPT_DIR}/CLAUDE.md" "${CLAUDE_HOME}/CLAUDE.md"

# 2. skills/ 下的每個 skill 資料夾
echo "[skills]"
mkdir -p "${CLAUDE_HOME}/skills"
if [ -d "${SCRIPT_DIR}/skills" ] && [ "$(ls -A "${SCRIPT_DIR}/skills" 2>/dev/null)" ]; then
  for skill_dir in "${SCRIPT_DIR}/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    symlink_item "$skill_dir" "${CLAUDE_HOME}/skills/${skill_name}"
  done
else
  echo "  (尚無 skills)"
fi

# 3. commands/ 下的每個 command 檔案
echo "[commands]"
mkdir -p "${CLAUDE_HOME}/commands"
if [ -d "${SCRIPT_DIR}/commands" ] && [ "$(ls -A "${SCRIPT_DIR}/commands" 2>/dev/null)" ]; then
  for cmd_file in "${SCRIPT_DIR}/commands"/*; do
    [ -f "$cmd_file" ] || continue
    cmd_name="$(basename "$cmd_file")"
    symlink_item "$cmd_file" "${CLAUDE_HOME}/commands/${cmd_name}"
  done
else
  echo "  (尚無 commands)"
fi

# 4. settings.json
echo "[settings.json]"
symlink_item "${SCRIPT_DIR}/settings.json" "${CLAUDE_HOME}/settings.json"

echo ""
echo "完成！"
