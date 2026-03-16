#!/bin/bash

set -e
source "$(dirname "$0")/build_common.sh"

BUILD_MODE="${1:---release}"
prepare_build "build_android.sh"

cd "$PROJECT_DIR"
flutter build apk $BUILD_MODE --build-number="$BUILD_NUM"

echo "=== Build complete: $VERSION_NAME Build $BUILD_NUM ==="
