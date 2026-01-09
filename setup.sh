#!/bin/bash

# ============================================
# Nexus Hub - Automatisches Setup
# ============================================
# Dieses Script installiert automatisch alle
# notwendigen Komponenten für Nexus Hub.
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
VENV_DIR="$SCRIPT_DIR/venv"
DATA_DIR="$SCRIPT_DIR/data"

# Status tracking
CHECKS_PASSED=0
CHECKS_TOTAL=0
INSTALLS_DONE=0

# Print functions
print_header() {
    echo ""
    echo -e "${PURPLE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║               🚀 NEXUS HUB - SETUP                          ║"
    echo "║                                                              ║"
    echo "║        Automatische Installation aller Komponenten          ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━ $1 ━━━${NC}"
    echo ""
}

print_check() {
    echo -e "  ${BLUE}[CHECK]${NC} $1"
}

print_ok() {
    echo -e "  ${GREEN}[  OK ]${NC} $1"
    ((CHECKS_PASSED++))
}

print_install() {
    echo -e "  ${YELLOW}[INST.]${NC} $1"
    ((INSTALLS_DONE++))
}

print_skip() {
    echo -e "  ${GREEN}[SKIP ]${NC} $1 (bereits installiert)"
}

print_warn() {
    echo -e "  ${YELLOW}[WARN ]${NC} $1"
}

print_error() {
    echo -e "  ${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "  ${BLUE}[INFO ]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# ============================================
# MAIN SETUP PROCESS
# ============================================

print_header

echo -e "${BOLD}Willkommen zum Nexus Hub Setup!${NC}"
echo ""
echo "Dieses Script prüft automatisch, was installiert werden muss"
echo "und führt alle notwendigen Installationen durch."
echo ""
read -p "Drücke Enter um zu starten (oder Ctrl+C zum Abbrechen)..."

# ============================================
# 1. SYSTEM REQUIREMENTS CHECK
# ============================================
print_section "1/5 - System-Anforderungen prüfen"

# Check Python 3
print_check "Python 3..."
((CHECKS_TOTAL++))
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    print_ok "Python $PYTHON_VERSION gefunden"
else
    print_error "Python 3 nicht gefunden!"
    echo ""
    echo -e "  ${BOLD}Installation:${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "    macOS: brew install python3"
        echo "    Oder: https://www.python.org/downloads/"
    else
        echo "    Linux: sudo apt install python3 python3-pip python3-venv"
        echo "    Oder: https://www.python.org/downloads/"
    fi
    echo ""
    exit 1
fi

# Check pip
print_check "pip..."
((CHECKS_TOTAL++))
if python3 -m pip --version &> /dev/null; then
    print_ok "pip verfügbar"
else
    print_install "pip wird installiert..."
    python3 -m ensurepip --upgrade
    print_ok "pip installiert"
fi

# Check Homebrew (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_check "Homebrew (macOS)..."
    ((CHECKS_TOTAL++))
    if command_exists brew; then
        print_ok "Homebrew gefunden"
        HAS_BREW=true
    else
        print_warn "Homebrew nicht gefunden (optional)"
        HAS_BREW=false
    fi
fi

# ============================================
# 2. VIRTUAL ENVIRONMENT
# ============================================
print_section "2/5 - Python Virtual Environment"

print_check "Virtual Environment..."
((CHECKS_TOTAL++))
if [ -d "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/activate" ]; then
    print_skip "Virtual Environment"
else
    print_install "Virtual Environment wird erstellt..."
    python3 -m venv "$VENV_DIR"
    print_ok "Virtual Environment erstellt"
fi

# Activate venv
source "$VENV_DIR/bin/activate"
print_ok "Virtual Environment aktiviert"

# Upgrade pip in venv
print_check "pip aktualisieren..."
pip install --quiet --upgrade pip

# ============================================
# 3. PYTHON PACKAGES
# ============================================
print_section "3/5 - Python Pakete installieren"

# Function to check and install package
install_if_missing() {
    local package=$1
    local pip_name=${2:-$1}  # Use second arg if provided, otherwise use first

    print_check "$package..."
    ((CHECKS_TOTAL++))

    if pip show "$package" &> /dev/null; then
        print_skip "$package"
    else
        print_install "$package wird installiert..."
        pip install --quiet "$pip_name"
        print_ok "$package installiert"
    fi
}

# Core Flask packages
install_if_missing "flask" "flask>=3.0.0"
install_if_missing "flask-cors" "flask-cors>=4.0.0"
install_if_missing "flask-socketio" "flask-socketio>=5.3.0"
install_if_missing "flask-login" "flask-login>=0.6.0"

# Server packages
install_if_missing "gunicorn" "gunicorn>=21.0.0"
install_if_missing "gevent" "gevent>=23.0.0"
install_if_missing "gevent-websocket" "gevent-websocket>=0.10.0"

# Database
install_if_missing "psycopg2-binary" "psycopg2-binary>=2.9.0"

# Google API packages
install_if_missing "google-api-python-client" "google-api-python-client>=2.100.0"
install_if_missing "google-auth" "google-auth>=2.23.0"
install_if_missing "google-auth-oauthlib" "google-auth-oauthlib>=1.1.0"
install_if_missing "google-auth-httplib2" "google-auth-httplib2>=0.1.0"

# Utilities
install_if_missing "python-dotenv" "python-dotenv>=1.0.0"
install_if_missing "requests" "requests>=2.31.0"

# IServ API and dependencies
install_if_missing "beautifulsoup4" "beautifulsoup4"
install_if_missing "IServAPI" "IServAPI"

# ============================================
# 4. CONFIGURATION FILES
# ============================================
print_section "4/5 - Konfiguration"

# Create data directory
print_check "Data Verzeichnis..."
((CHECKS_TOTAL++))
if [ -d "$DATA_DIR" ]; then
    print_skip "Data Verzeichnis"
else
    print_install "Data Verzeichnis wird erstellt..."
    mkdir -p "$DATA_DIR"
    print_ok "Data Verzeichnis erstellt"
fi

# Create .env file from example if it doesn't exist
print_check ".env Konfiguration..."
((CHECKS_TOTAL++))
if [ -f "$SCRIPT_DIR/.env" ]; then
    print_skip ".env Datei"
else
    if [ -f "$SCRIPT_DIR/.env.example" ]; then
        print_install ".env wird aus Vorlage erstellt..."
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        print_ok ".env erstellt (bitte API-Keys eintragen!)"
        print_warn "Vergiss nicht, deine API-Keys in .env einzutragen!"
    else
        print_install ".env wird erstellt..."
        cat > "$SCRIPT_DIR/.env" << 'EOF'
SECRET_KEY=nexus-hub-secret-key-change-me
FLASK_ENV=development

# Google API (optional - für Kalender & Email)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_PROJECT_ID=
EOF
        print_ok ".env erstellt"
    fi
fi

# ============================================
# 5. DATABASE INITIALIZATION
# ============================================
print_section "5/5 - Datenbank initialisieren"

print_check "SQLite Datenbank..."
((CHECKS_TOTAL++))

# Initialize database by importing the module
cd "$APP_DIR"
print_install "Datenbank wird initialisiert..."
python3 -c "import database; print('Database initialized')" 2>/dev/null && print_ok "Datenbank initialisiert" || print_warn "Datenbank-Check übersprungen"

# ============================================
# SETUP COMPLETE
# ============================================
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║              ✅ SETUP ERFOLGREICH ABGESCHLOSSEN!             ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${BOLD}Zusammenfassung:${NC}"
echo -e "  • Checks bestanden: ${GREEN}$CHECKS_PASSED/$CHECKS_TOTAL${NC}"
echo -e "  • Neue Installationen: ${YELLOW}$INSTALLS_DONE${NC}"
echo ""

echo -e "${BOLD}Nächste Schritte:${NC}"
echo ""
echo "  1. Nexus Hub starten:"
echo -e "     ${CYAN}./start.sh${NC}"
echo ""
echo "  2. Im Browser öffnen:"
echo -e "     ${CYAN}http://localhost:5050${NC}"
echo ""

if [ ! -s "$SCRIPT_DIR/.env" ] || grep -q "GOOGLE_CLIENT_ID=$" "$SCRIPT_DIR/.env"; then
    echo -e "${YELLOW}${BOLD}Optionale Konfiguration:${NC}"
    echo ""
    echo "  Für Google Kalender & Email Integration:"
    echo "  • Öffne die Datei .env"
    echo "  • Trage deine Google API Credentials ein"
    echo "  • Anleitung: https://console.cloud.google.com/"
    echo ""
fi

echo -e "${BOLD}Viel Spaß mit Nexus Hub! 🎉${NC}"
echo ""
