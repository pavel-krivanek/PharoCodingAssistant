#!/usr/bin/env sh
set -eu
if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
    echo "usage: $0 DESTINATION [SOURCE_ROOT] [--force]" >&2
    exit 2
fi
DEST=$1
SOURCE=${2:-"$HOME/.pharo-ca"}
FORCE=${3:-}
RUNTIME="$SOURCE/runtime.json"
[ -f "$RUNTIME" ] || { echo "No runtime.json found at $RUNTIME. Configure PCA provider/model first and save the runtime profile." >&2; exit 2; }
if [ -d "$DEST" ] && [ "$(find "$DEST" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    [ "$FORCE" = "--force" ] || { echo "Destination is not empty: $DEST (use --force to replace it)" >&2; exit 2; }
    rm -rf "$DEST"
fi
mkdir -p "$DEST"
cp "$RUNTIME" "$DEST/runtime.json"
[ -f "$SOURCE/settings.json" ] && cp "$SOURCE/settings.json" "$DEST/settings.json" || true
printf '%s\n' "$DEST"
