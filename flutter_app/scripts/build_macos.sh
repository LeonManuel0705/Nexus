#!/bin/bash

set -e
source "$(dirname "$0")/build_common.sh"

BUILD_MODE="${1:---release}"
prepare_build "build_macos.sh"

cd "$PROJECT_DIR"
flutter clean
flutter build macos $BUILD_MODE --build-number="$BUILD_NUM"

# --- Bundle backend into Nexus.app ---
NEXUS_ROOT="$(dirname "$PROJECT_DIR")"
APP_BUNDLE="$PROJECT_DIR/build/macos/Build/Products/Release/Nexus.app"
BACKEND_DEST="$APP_BUNDLE/Contents/Resources/backend"

echo "=== Bundling backend into app ==="
rm -rf "$BACKEND_DEST"
mkdir -p "$BACKEND_DEST"

# Copy Flask backend
cp -R "$NEXUS_ROOT/app" "$BACKEND_DEST/app"
cp "$NEXUS_ROOT/requirements.txt" "$BACKEND_DEST/requirements.txt"
cp "$NEXUS_ROOT/calendar_sync.py" "$BACKEND_DEST/calendar_sync.py" 2>/dev/null || true

echo "Backend bundled ($(du -sh "$BACKEND_DEST" | cut -f1))"

echo "=== Build complete: $VERSION_NAME Build $BUILD_NUM ==="
echo "Output: build/macos/Build/Products/Release/"
