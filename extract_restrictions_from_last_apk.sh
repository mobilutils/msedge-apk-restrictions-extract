# here we will find the file holding "restrictions" that can be managed via MDM
# this file is an xml file

# Capture script directory early (before any cd changes cwd)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

BASE_DIR="PlaystoreDL_MicrosoftEdge"

cd $BASE_DIR
# Find the latest downloaded version directory
LATEST_DIR=$(ls -d * 2>/dev/null | sort -V | tail -n 1)
cd "$LATEST_DIR"

APK_DIR=$(pwd)

# Idempotency: skip extraction if outputs already exist
if [[ -f "$APK_DIR/app_restrictions.xml" ]] && [[ -f "$APK_DIR/strings.xml" ]]; then
    echo "✓ app_restrictions.xml and strings.xml already exist in $APK_DIR — skipping extraction"
    exit 0
fi

# Extract base APK
APK_FILE=$(ls *.apk 2>/dev/null | head -1)
if [[ -z "$APK_FILE" ]]; then
    echo "Error: No APK file found in $APK_DIR" >&2
    exit 1
fi

cd /tmp
# extract file in apk under /tmp/decoded/
apktool d "$APK_DIR/$APK_FILE" -o decoded --no-src 2>/dev/null
cd decoded

# grep -rE "HomepageLocation|ScreenCaptureAllowedByOrigins|CopilotNewTabPageEnabled" ./
# the above grep command will give us the file that contain the strings "HomepageLocation", "ScreenCaptureAllowedByOrigins", "CopilotNewTabPageEnabled".
# search for the common file that contains these 3 strings, and that file is the one that holds the restrictions that can be managed via MDM.
# there is high probability that the file is under res/xml/ or res/values/ folder

# Find the file that contains ALL 3 strings (the MDM restrictions file)
RESTRICTIONS_FILE=$(grep -rlE "HomepageLocation" ./ | xargs grep -l "ScreenCaptureAllowedByOrigins" | xargs grep -l "CopilotNewTabPageEnabled" | head -1)

if [ -z "$RESTRICTIONS_FILE" ]; then
    echo "Error: Could not find a file containing all three MDM restriction strings."
    exit 1
fi

# Resolve to absolute path before changing directory
RESTRICTIONS_FILE="$(cd "$(dirname "$RESTRICTIONS_FILE")" && pwd)/$(basename "$RESTRICTIONS_FILE")"

# Copy RESTRICTIONS_FILE to APK_DIR for later use
cp "$RESTRICTIONS_FILE" "$APK_DIR/"

# Copy to app_restrictions.xml
cp "$RESTRICTIONS_FILE" "$APK_DIR/app_restrictions.xml"

# Find strings.xml and copy to APK_DIR (only if it doesn't already exist)
STRINGS_FILE=$(find ./ -name "strings.xml" | head -1)
if [ -n "$STRINGS_FILE" ]; then
    cp "$STRINGS_FILE" "$APK_DIR/"
fi

# CD $APK_DIR
cd "$APK_DIR"

# Show file path to user
echo "MDM restrictions file: $APK_DIR/app_restrictions.xml"
