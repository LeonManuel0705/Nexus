#!/bin/bash
# Nexus for Linux
set -e

NEXUS_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$NEXUS_DIR"

echo ""
echo "  ╔══════════════════════════════════╗"
echo "  ║          Nexus for Linux         ║"
echo "  ╚══════════════════════════════════╝"
echo ""

# ─── Check Python ────────────────────────────────────────
PYTHON=""
if command -v python3 &>/dev/null; then
    PYTHON="python3"
elif command -v python &>/dev/null; then
    PYTHON="python"
else
    echo "  [ERROR] Python 3 wurde nicht gefunden."
    echo ""
    echo "  Installiere Python 3.9+:"
    echo "    Ubuntu/Debian: sudo apt install python3 python3-venv python3-pip"
    echo "    Fedora:        sudo dnf install python3"
    echo "    Arch:          sudo pacman -S python"
    echo ""
    exit 1
fi

echo "  Python: $($PYTHON --version)"

# ─── Setup venv ──────────────────────────────────────────
if [ ! -f "venv/bin/python" ]; then
    echo ""
    echo "  → Erstelle Python-Umgebung..."
    $PYTHON -m venv venv
fi

VENV_PYTHON="venv/bin/python"

# ─── Install dependencies ────────────────────────────────
HASH_FILE="venv/.req_hash"
CURRENT_HASH=$(sha256sum requirements.txt | awk '{print $1}')
SAVED_HASH=""
[ -f "$HASH_FILE" ] && SAVED_HASH=$(cat "$HASH_FILE")

if [ "$CURRENT_HASH" != "$SAVED_HASH" ]; then
    echo "  → Installiere Abhängigkeiten (kann 1-2 Minuten dauern)..."
    "$VENV_PYTHON" -m pip install --upgrade pip -q
    "$VENV_PYTHON" -m pip install -r requirements.txt -q
    echo "$CURRENT_HASH" > "$HASH_FILE"
    echo "  ✓ Abhängigkeiten installiert."
fi

# ─── Create data directory ───────────────────────────────
mkdir -p data

# ─── Start Flask server ──────────────────────────────────
echo ""
echo "  → Starte Nexus..."

# Kill any stale server on port 5050
lsof -ti:5050 2>/dev/null | xargs kill -9 2>/dev/null || true

export NEXUS_HOST=127.0.0.1
export FLASK_ENV=production

"$VENV_PYTHON" -m app.app &
SERVER_PID=$!

cleanup() {
    echo ""
    echo "  → Beende Nexus..."
    kill $SERVER_PID 2>/dev/null
    exit 0
}
trap cleanup INT TERM

# Wait for server
for i in $(seq 1 30); do
    if curl -s http://127.0.0.1:5050 >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

echo ""
echo "  ╔══════════════════════════════════╗"
echo "  ║   ✓ Nexus läuft!                ║"
echo "  ║   → http://localhost:5050/hub    ║"
echo "  ╚══════════════════════════════════╝"
echo ""
echo "  Zum Beenden: Ctrl+C"
echo ""

# Open browser
if command -v xdg-open &>/dev/null; then
    xdg-open "http://localhost:5050/hub" 2>/dev/null
elif command -v open &>/dev/null; then
    open "http://localhost:5050/hub"
fi

# Wait for server process
wait $SERVER_PID
