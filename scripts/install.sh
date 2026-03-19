#! /usr/bin/env zsh

set -o ERR_EXIT
set -o NO_UNSET
set -o PIPE_FAIL

readonly SCRIPT_DIR="${0:a:h}"
readonly TARGET_DIR="/usr/local/bin"

if [[ ! -w "$TARGET_DIR" ]]; then
    echo "Need sudo access for $TARGET_DIR"
    exec sudo "$0" "$@"
fi

for script in "$SCRIPT_DIR"/*; do
    name="${script:t}"

    # Skip non-executable files and this script itself
    [[ -x "$script" && -f "$script" && "$name" != "install.sh" ]] || continue

    target="$TARGET_DIR/$name"

    if [[ -L "$target" || -e "$target" ]]; then
        echo "Removing existing $target"
        rm "$target"
    fi

    ln -s "$script" "$target"
    echo "Linked $name -> $target"
done

echo "✅ Done!"
