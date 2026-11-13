#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

symlink_item() {
  local src="$1"
  local dest="$2"

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

echo "=== vim/setup.sh ==="
symlink_item "${SCRIPT_DIR}" "${HOME}/.vim"
symlink_item "${HOME}/.vim/.vimrc" "${HOME}/.vimrc"
echo "完成"
