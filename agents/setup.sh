#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

AGENTS_DIR="${SCRIPT_DIR}"
CLAUDE_SRC_DIR="${AGENTS_DIR}/claude"
CLAUDE_HOME="${HOME}/.claude"
CODEX_SRC_DIR="${AGENTS_DIR}/codex"
CODEX_HOME="${HOME}/.codex"

symlink_item() {
  local src="$1"
  local dest="$2"

  if [ ! -e "$src" ]; then
    echo "  跳過: $(basename "$dest") (來源不存在)"
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

echo "=== agents/setup.sh ==="

echo "[claude] ~/.claude symlink"
mkdir -p "${CLAUDE_HOME}"

if [ ! -d "${CLAUDE_SRC_DIR}" ]; then
  echo "  跳過: claude (來源資料夾不存在: ${CLAUDE_SRC_DIR})"
else
  echo "  來源: ${CLAUDE_SRC_DIR}"
  echo "  目標: ${CLAUDE_HOME}"

  echo "  [CLAUDE.md]"
  symlink_item "${CLAUDE_SRC_DIR}/CLAUDE.md" "${CLAUDE_HOME}/CLAUDE.md"

  echo "  [skills]"
  mkdir -p "${CLAUDE_HOME}/skills"
  if [ -d "${CLAUDE_SRC_DIR}/skills" ] && [ "$(ls -A "${CLAUDE_SRC_DIR}/skills" 2>/dev/null)" ]; then
    for skill_dir in "${CLAUDE_SRC_DIR}/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      symlink_item "$skill_dir" "${CLAUDE_HOME}/skills/$(basename "$skill_dir")"
    done
  else
    echo "    (尚無 skills)"
  fi

  echo "  [commands]"
  mkdir -p "${CLAUDE_HOME}/commands"
  if [ -d "${CLAUDE_SRC_DIR}/commands" ] && [ "$(ls -A "${CLAUDE_SRC_DIR}/commands" 2>/dev/null)" ]; then
    for cmd_file in "${CLAUDE_SRC_DIR}/commands"/*; do
      [ -f "$cmd_file" ] || continue
      symlink_item "$cmd_file" "${CLAUDE_HOME}/commands/$(basename "$cmd_file")"
    done
  else
    echo "    (尚無 commands)"
  fi

  echo "  [settings.json]"
  symlink_item "${CLAUDE_SRC_DIR}/settings.json" "${CLAUDE_HOME}/settings.json"
fi

echo "[codex] ~/.codex symlink"
mkdir -p "${CODEX_HOME}"

if [ ! -d "${CODEX_SRC_DIR}" ]; then
  echo "  跳過: codex (來源資料夾不存在: ${CODEX_SRC_DIR})"
else
  echo "  來源: ${CODEX_SRC_DIR}"
  echo "  目標: ${CODEX_HOME}"

  echo "  [AGENTS.md]"
  symlink_item "${CODEX_SRC_DIR}/AGENTS.md" "${CODEX_HOME}/AGENTS.md"

  echo "  [skills]"
  mkdir -p "${CODEX_HOME}/skills"
  if [ -d "${CODEX_SRC_DIR}/skills" ] && [ "$(ls -A "${CODEX_SRC_DIR}/skills" 2>/dev/null)" ]; then
    for skill_dir in "${CODEX_SRC_DIR}/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      symlink_item "$skill_dir" "${CODEX_HOME}/skills/$(basename "$skill_dir")"
    done
  else
    echo "    (尚無 skills)"
  fi
fi

echo "完成"
