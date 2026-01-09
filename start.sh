#!/bin/bash

# ============================================
# Nexus Hub - Start Script
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
VENV_DIR="$SCRIPT_DIR/venv"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${CYAN}${BOLD}"
echo "╔════════════════════════════════════════════╗"
echo "║                NEXUS HUB                   ║"
echo "║            Dein persönlicher Hub           ║"
echo "║               Developer: Leon              ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if setup has been run
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}⚠️  Nexus Hub ist noch nicht eingerichtet!${NC}"
    echo ""
    echo "   Bitte führe zuerst das Setup aus:"
    echo -e "   ${CYAN}./setup.sh${NC}"
    echo ""
    exit 1
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Quick dependency check (silent)
pip install --quiet -r "$SCRIPT_DIR/requirements.txt" 2>/dev/null

echo -e "🚀 ${BOLD}Server wird gestartet...${NC}"
echo ""

# Get local IP for mobile access
LOCAL_IP=$(python3 -c "import socket; s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.connect(('8.8.8.8',80)); print(s.getsockname()[0]); s.close()" 2>/dev/null)

echo -e "   ${BOLD}Desktop:${NC}  ${GREEN}http://localhost:5050${NC}"
if [ -n "$LOCAL_IP" ]; then
    echo -e "   ${BOLD}Mobile:${NC}   ${GREEN}http://${LOCAL_IP}:5050${NC}"
    echo ""
    echo -e "   📱 ${CYAN}Auf Android/iOS: URL im Browser eingeben${NC}"
    echo -e "      ${CYAN}und 'Zum Home-Bildschirm hinzufügen'${NC}"
fi
echo ""
echo -e "   ${YELLOW}Ctrl+C${NC} zum Beenden"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run the app as a module (required for relative imports)
cd "$SCRIPT_DIR"
python3 -m app.app
