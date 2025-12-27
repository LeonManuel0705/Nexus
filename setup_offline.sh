#!/bin/bash

# Voice Notes - Offline Setup Script
# ===================================
# Downloads all required models and data for fully offline operation

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
VENV_DIR="$SCRIPT_DIR/venv"
MODELS_DIR="$SCRIPT_DIR/models"

echo ""
echo "=============================================="
echo "    Voice Notes - Offline Setup"
echo "=============================================="
echo ""
echo "This script will download all required models"
echo "for fully offline operation (~2GB total)."
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed."
    echo "   Please install Python 3 from https://www.python.org/downloads/"
    exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "⚠️  Warning: ffmpeg is not installed."
    echo "   Install it with: brew install ffmpeg"
    echo ""
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Install/upgrade dependencies
echo ""
echo "📦 Installing Python dependencies..."
pip install --quiet --upgrade pip
pip install --quiet -r "$APP_DIR/requirements.txt"

# Create models directory
mkdir -p "$MODELS_DIR"

echo ""
echo "=============================================="
echo "  Downloading Whisper Models"
echo "=============================================="
echo ""

# Pre-download Whisper models
python3 << 'EOF'
import sys
print("📥 Downloading Whisper 'base' model (~150MB)...")
sys.stdout.flush()
from faster_whisper import WhisperModel
model = WhisperModel("base", device="cpu", compute_type="int8")
del model
print("   ✅ Base model ready")

print("📥 Downloading Whisper 'small' model (~500MB)...")
sys.stdout.flush()
model = WhisperModel("small", device="cpu", compute_type="int8")
del model
print("   ✅ Small model ready")
print("")
EOF

echo ""
echo "=============================================="
echo "  Downloading LanguageTool Data"
echo "=============================================="
echo ""

# Pre-download LanguageTool data
python3 << 'EOF'
import sys
print("📥 Downloading LanguageTool for German (~200MB)...")
sys.stdout.flush()
try:
    import language_tool_python
    tool = language_tool_python.LanguageTool('de-DE')
    tool.check("Test")
    tool.close()
    print("   ✅ German language data ready")
except Exception as e:
    print(f"   ⚠️  German: {e}")

print("📥 Downloading LanguageTool for English (~150MB)...")
sys.stdout.flush()
try:
    tool = language_tool_python.LanguageTool('en-US')
    tool.check("Test")
    tool.close()
    print("   ✅ English language data ready")
except Exception as e:
    print(f"   ⚠️  English: {e}")
print("")
EOF

echo ""
echo "=============================================="
echo "  Downloading Speaker Diarization Model"
echo "=============================================="
echo ""

# Pre-download speaker diarization model
python3 << 'EOF'
import sys
print("📥 Downloading speaker embedding model (~80MB)...")
sys.stdout.flush()
try:
    from speechbrain.inference.speaker import EncoderClassifier
    classifier = EncoderClassifier.from_hparams(
        source="speechbrain/spkrec-ecapa-voxceleb",
        savedir="models/speaker_model"
    )
    print("   ✅ Speaker model ready")
except Exception as e:
    print(f"   ⚠️  Speaker model: {e}")
    print("   Installing speechbrain...")
    import subprocess
    subprocess.run([sys.executable, "-m", "pip", "install", "speechbrain", "--quiet"])
    try:
        from speechbrain.inference.speaker import EncoderClassifier
        classifier = EncoderClassifier.from_hparams(
            source="speechbrain/spkrec-ecapa-voxceleb",
            savedir="models/speaker_model"
        )
        print("   ✅ Speaker model ready (after install)")
    except Exception as e2:
        print(f"   ❌ Failed: {e2}")
print("")
EOF

echo ""
echo "=============================================="
echo "  Downloading Local AI Model (MLX)"
echo "=============================================="
echo ""

# Check if Apple Silicon
if [[ $(uname -m) == "arm64" ]]; then
    python3 << 'EOF'
import sys
print("📥 Setting up MLX for Apple Silicon...")
sys.stdout.flush()
try:
    import subprocess
    subprocess.run([sys.executable, "-m", "pip", "install", "mlx", "mlx-lm", "--quiet"])
    print("   ✅ MLX installed")

    print("📥 Downloading Qwen2.5-0.5B model (~500MB)...")
    sys.stdout.flush()
    from mlx_lm import load
    model, tokenizer = load("mlx-community/Qwen2.5-0.5B-Instruct-4bit")
    print("   ✅ Qwen2.5-0.5B ready (fast context-aware AI)")
except Exception as e:
    print(f"   ⚠️  MLX setup: {e}")
print("")
EOF
else
    echo "   ⚠️  Not Apple Silicon - using LanguageTool only"
    echo "   (MLX requires Apple Silicon for fast inference)"
fi

echo ""
echo "=============================================="
echo "  Setup Complete!"
echo "=============================================="
echo ""
echo "  All models downloaded for offline use."
echo ""
echo "  To start the app, run:"
echo "    ./start.sh"
echo ""
echo "  Features enabled:"
echo "    ✅ Offline speech-to-text (Whisper)"
echo "    ✅ Offline spelling correction (LanguageTool)"
echo "    ✅ Speaker diarization (teacher detection)"
if [[ $(uname -m) == "arm64" ]]; then
echo "    ✅ Context-aware AI correction (MLX/Qwen)"
else
echo "    ⚠️  AI correction requires Apple Silicon"
fi
echo ""
