#! /usr/bin/env zsh

set -o ERR_EXIT
set -o NO_UNSET
set -o PIPE_FAIL

readonly SCRIPT_DIR="${0:a:h}"
readonly EXTRAS_FILE="$SCRIPT_DIR/references/zshrc_extras.zsh"
readonly ZSHRC="$HOME/.zshrc"
readonly MARKER_BEGIN="# >>> mac-settings >>>"
readonly MARKER_END="# <<< mac-settings <<<"

if [[ ! -f "$EXTRAS_FILE" ]]; then
    echo "Error: $EXTRAS_FILE not found"
    exit 1
fi

readonly BLOCK="${MARKER_BEGIN}
$(<"$EXTRAS_FILE")
${MARKER_END}"

if grep -q "$MARKER_BEGIN" "$ZSHRC"; then
    # Replace existing block between markers
    perl -i -0777 -pe "s/\Q${MARKER_BEGIN}\E.*?\Q${MARKER_END}\E/${BLOCK}/s" "$ZSHRC"
    echo "Updated mac-settings block in $ZSHRC"
else
    printf '\n%s\n' "$BLOCK" >> "$ZSHRC"
    echo "Added mac-settings block to $ZSHRC"
fi
