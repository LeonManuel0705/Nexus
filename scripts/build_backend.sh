#!/bin/bash
#
# build_backend.sh — freeze the Flask backend into a standalone `nexus-backend`
# executable so desktop shells (Electron / Flutter macOS) can run it without a
# system Python installation.
#
# Output: dist/nexus-backend/  (onedir bundle; the launcher runs
#         dist/nexus-backend/nexus-backend and sets NEXUS_DATA_DIR for storage).
#
# Requires a Python venv with the backend deps + pyinstaller installed. Run from
# the repo root or anywhere — paths are resolved relative to this script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Pick a Python: prefer the repo venv, else system python3.
if [ -x "$PROJECT_ROOT/venv/bin/python" ]; then
  PY="$PROJECT_ROOT/venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PY="python3"
else
  echo "ERROR: no Python found (expected venv/bin/python or python3 on PATH)." >&2
  exit 1
fi

echo "=== Ensuring build deps (pyinstaller + lean desktop requirements) ==="
"$PY" -m pip install --quiet --upgrade pyinstaller
# Use the lean desktop subset (no llama-cpp/gunicorn/gevent/psycopg2) so the
# freeze is fast and small; those are excluded in nexus-backend.spec anyway.
if [ -f "$PROJECT_ROOT/requirements-desktop.txt" ]; then
  "$PY" -m pip install --quiet -r requirements-desktop.txt
else
  "$PY" -m pip install --quiet -r requirements.txt
fi

echo "=== Freezing backend with PyInstaller ==="
"$PY" -m PyInstaller nexus-backend.spec --noconfirm --clean

echo "=== Done: $PROJECT_ROOT/dist/nexus-backend/nexus-backend ==="
ls -la "$PROJECT_ROOT/dist/nexus-backend/nexus-backend" || {
  echo "ERROR: expected frozen binary not found" >&2
  exit 1
}
