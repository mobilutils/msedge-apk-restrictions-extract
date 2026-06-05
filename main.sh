#!/bin/bash
# edge-monitor.sh

source mvenv/bin/activate
#set -euo pipefail

START_DIR="$(pwd)"
PACKAGE="com.microsoft.emmx"
BASE_DIR="PlaystoreDL_MicrosoftEdge"
STATE_FILE="$BASE_DIR/.last_version"
LOG_FILE="$BASE_DIR/logs.txt"

# Record start time
START_EPOCH=$(date +%s)
START_DATE=$(date +%Y/%m/%d)
START_TIME=$(date +%H:%M:%S)

# Create the base directory if it doesn't exist
mkdir -p "$BASE_DIR"

# If log file doesn't exist, create it and add header
if [[ ! -f "$LOG_FILE" ]]; then
    echo "date,time,version,is_new,elapsed_seconds,result" > "$LOG_FILE"
fi

# 1. Get current version from Play Store
CURRENT_VERSION=$(python3 -c "
from google_play_scraper import app
result = app('$PACKAGE', lang='en', country='us')
print(result['version'])
")

TARGET_DIR="$BASE_DIR/${PACKAGE}_${CURRENT_VERSION}"

# 2. Check if we already have this version
#if [[ -f "$STATE_FILE" ]] && grep -q "^$CURRENT_VERSION$" "$STATE_FILE"; then
if [[ -d "${TARGET_DIR}" ]]; then
    echo "✓ Version $CURRENT_VERSION already downloaded"

    cd "$TARGET_DIR"
    IS_NEW=false
else
    # 3. Download APK via gplaydl [[2]]

    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR"

    # First-time auth (anonymous via Aurora Store)
    gplaydl auth 2>/dev/null || true

     # Download base APK + splits
    gplaydl download "$PACKAGE" -o . --no-extras --no-splits
    APK_FILE=$(ls *.apk 2>/dev/null | head -1)
    

    # 4. Extract restrictions.xml
   if [[ ! -f "$APK_FILE" ]]; then
       cd -
       rm -rf "$TARGET_DIR"  # Clean up failed download directory
       echo "✗ Failed to download APK" >&2
       END_EPOCH=$(date +%s)
       ELAPSED=$((END_EPOCH - START_EPOCH))
       echo "${START_DATE},${START_TIME},${CURRENT_VERSION},true,${ELAPSED},FAILURE (Failed to download APK)" >> "$LOG_FILE"
       exit 1
   fi
    IS_NEW=true
fi

cd "$START_DIR"
# 4. Extract if needed (skip if both XML files already exist)
#SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#echo "==== > $(pwd)  ...  <===="
EXTRACTED=false
if [[ ! -f "${TARGET_DIR}/app_restrictions.xml" ]] || [[ ! -f "${TARGET_DIR}/strings.xml" ]]; then
    echo "Extracting restrictions from APK version $CURRENT_VERSION..."
    bash extract_restrictions_from_last_apk.sh 2>/dev/null
    EXTRACTED=true
else
    echo "✓ app_restrictions.xml and strings.xml already exist — skipping extraction"
fi

# 6. Consolidate if needed (skip if outputs already exist and weren't just extracted)
if [[ "$EXTRACTED" == "true" ]] || [[ ! -f "${TARGET_DIR}/app_restrictions_consolidated.csv" ]] || [[ ! -f "${TARGET_DIR}/app_restrictions_consolidated_consolidated.json" ]]; then
    python3 "consolidate_restrictions.py" "${TARGET_DIR}"
else
    echo "✓ app_restrictions_consolidated.json and app_restrictions_consolidated.csv already exist — skipping consolidation"
fi

# Log success
END_EPOCH=$(date +%s)
ELAPSED=$((END_EPOCH - START_EPOCH))
echo "${START_DATE},${START_TIME},${CURRENT_VERSION},${IS_NEW},${ELAPSED},SUCCESS" >> "$LOG_FILE"

echo "✓ Done — outputs in $TARGET_DIR"
