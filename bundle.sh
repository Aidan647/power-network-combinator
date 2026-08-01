#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Read name and version from info.json
NAME=$(jq -r '.name' src/info.json)
VERSION=$(jq -r '.version' src/info.json)
OUTPUT="${NAME}_${VERSION}.zip"
OUT_DIR="./out"

mkdir -p "$OUT_DIR" ./tmp

if [[ -f "$OUT_DIR/$OUTPUT" ]]; then
    echo "Warning: $OUT_DIR/$OUTPUT already exists — will be overwritten" >&2
fi

echo "Bundling $NAME v$VERSION -> $OUT_DIR/$OUTPUT"

# Build exclusion flags from .luaignore
EXCLUDE=()
if [[ -f ".luaignore" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        trimmed="${line%%#*}"
        trimmed="${trimmed## }"
        trimmed="${trimmed%% }"
        [[ -z "$trimmed" ]] && continue
        [[ "$trimmed" == '!'* ]] && continue
        pat="${trimmed#./}"
        EXCLUDE+=("--exclude=$pat")
    done < ".luaignore"
fi

# Stage files into tmp/$NAME/ so the zip has the right prefix
rm -rf ./tmp
mkdir -p "./tmp/$NAME"
rsync -a --info=none \
    "${EXCLUDE[@]}" \
    "./src/" "./tmp/$NAME/"

# Run pre-zip processing script
bun start "./tmp/$NAME"

# Single zip pass into tmp, then move to out
cd "./tmp"
zip -9 -r "$OUTPUT" "$NAME"
mv -f "$OUTPUT" "$SCRIPT_DIR/$OUT_DIR/"
cd "$SCRIPT_DIR"
rm -rf ./tmp

# Display file info
FULL_PATH="$SCRIPT_DIR/$OUT_DIR/$OUTPUT"
BYTES=$(stat -c%s "$FULL_PATH")

if [[ $BYTES -ge 1073741824 ]]; then
    SIZE="$(awk "BEGIN { printf \"%.2f\", $BYTES/1073741824 }") GiB"
elif [[ $BYTES -ge 1048576 ]]; then
    SIZE="$(awk "BEGIN { printf \"%.2f\", $BYTES/1048576 }") MiB"
elif [[ $BYTES -ge 1024 ]]; then
    SIZE="$(awk "BEGIN { printf \"%.2f\", $BYTES/1024 }") KiB"
else
    SIZE="${BYTES} B"
fi

SHA256=$(sha256sum "$FULL_PATH" | cut -d' ' -f1)

echo "Done: $OUT_DIR/$OUTPUT"
echo "Size: $SIZE ($BYTES bytes)"
echo "SHA256: $SHA256"
