#!/bin/bash

# Voice Notes App Startup Script
# ==============================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
VENV_DIR="$SCRIPT_DIR/venv"

echo ""
echo "=============================================="
echo "          Voice Notes App"
echo "=============================================="
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed."
    echo "   Please install Python 3 from https://www.python.org/downloads/"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Install/upgrade dependencies
echo "📦 Checking dependencies..."
pip install --quiet --upgrade pip
pip install --quiet -r "$APP_DIR/requirements.txt"

# Check if ffmpeg is installed (required for Whisper)
if ! command -v ffmpeg &> /dev/null; then
    echo ""
    echo "⚠️  Warning: ffmpeg is not installed."
    echo "   Whisper requires ffmpeg for audio processing."
    echo ""
    echo "   Install it with Homebrew:"
    echo "   brew install ffmpeg"
    echo ""
    read -p "   Press Enter to continue anyway, or Ctrl+C to exit..."
fi

echo ""
echo "🚀 Starting Voice Notes server..."
echo ""
echo "   Open your browser at: http://localhost:5050"
echo ""
echo "   Press Ctrl+C to stop the server"
echo ""
echo "=============================================="
echo ""

# Run the app
cd "$APP_DIR"
python3 app.py
