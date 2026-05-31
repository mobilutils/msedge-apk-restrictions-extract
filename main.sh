#!/bin/bash
# edge-monitor.sh

set -euo pipefail

PACKAGE="com.microsoft.emmx"
BASE_DIR="PlaystoreDL_MicrosoftEdge"
STATE_FILE="$(cd "$(dirname "$0")" && pwd)/$BASE_DIR/.last_version"

# 1. Get current version from Play Store
CURRENT_VERSION=$(python3 -c "
from google_play_scraper import app
result = app('$PACKAGE', lang='en', country='us')
print(result['version'])
")   # [[43]]

# 2. Check if we already have this version
mkdir -p "$BASE_DIR"
if [[ -f "$STATE_FILE" ]] && grep -q "^$CURRENT_VERSION$" "$STATE_FILE"; then
    echo "✓ Version $CURRENT_VERSION already downloaded"
    TARGET_DIR="$(cd "$(dirname "$0")" && pwd)/$BASE_DIR/PlaystoreDL_MicrosoftEdge_${CURRENT_VERSION}"
else
    # 3. Download APK via gplaydl [[2]]
    TARGET_DIR="$(cd "$(dirname "$0")" && pwd)/$BASE_DIR/PlaystoreDL_MicrosoftEdge_${CURRENT_VERSION}"
    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR"

    # First-time auth (anonymous via Aurora Store)
    gplaydl auth 2>/dev/null || true

    # Download base APK + splits
    gplaydl download "$PACKAGE" -o . --no-extras --no-splits

    # 4. Extract restrictions.xml
    APK_FILE=$(ls *.apk 2>/dev/null | head -1)
    if [[ -n "$APK_FILE" ]]; then
        # Method 1: Simple unzip (fast, but XML may be binary-encoded)
        unzip -j "$APK_FILE" 'res/xml/restrictions.xml' -d . 2>/dev/null || \
        # Method 2: apktool for decoded XML [[34]]
        apktool d "$APK_FILE" -o decoded --no-src 2>/dev/null && \
        find decoded -name 'restrictions.xml' -exec cp {} . \;

        echo "✓ Extracted restrictions.xml to $(pwd)"

        # Update state
        echo "$CURRENT_VERSION" > "$(dirname "$TARGET_DIR")/.last_version"
    else
        echo "✗ Failed to download APK" >&2
        exit 1
    fi
fi

# 5. Extract if needed (skip if both XML files already exist)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXTRACTED=false
if [[ ! -f "$TARGET_DIR/app_restrictions.xml" ]] || [[ ! -f "$TARGET_DIR/strings.xml" ]]; then
    bash "$SCRIPT_DIR/extract_restrictions_from_last_apk.sh" 2>/dev/null
    EXTRACTED=true
else
    echo "✓ app_restrictions.xml and strings.xml already exist — skipping extraction"
fi

# 6. Consolidate if needed (skip if outputs already exist and weren't just extracted)
if [[ "$EXTRACTED" == "true" ]] || [[ ! -f "$TARGET_DIR/app_restrictions_consolidated.csv" ]] || [[ ! -f "$TARGET_DIR/app_restrictions.json" ]]; then
    python3 "$SCRIPT_DIR/consolidate_restrictions.py" "$TARGET_DIR"
else
    echo "✓ app_restrictions.json and app_restrictions_consolidated.csv already exist — skipping consolidation"
fi

echo "✓ Done — outputs in $TARGET_DIR"
