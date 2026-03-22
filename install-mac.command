#!/bin/bash
# ============================================================
# PDF to Markdown Converter — macOS Installer
# Double-click this file to install everything you need.
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
LAUNCHER="$HOME/Desktop/PDF to Markdown.command"

echo ""
echo "=========================================="
echo "  PDF to Markdown — macOS Installer"
echo "=========================================="
echo ""

# --- 1. Homebrew ---
if ! command -v brew &>/dev/null; then
    echo "[1/5] Installing Homebrew (requires your Mac password)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for this session (Apple Silicon)
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "[1/5] Homebrew already installed. Skipping."
fi

# --- 2. Java ---
if ! command -v java &>/dev/null; then
    echo "[2/5] Installing Java (requires your Mac password)..."
    brew install --cask temurin
else
    echo "[2/5] Java already installed. Skipping."
fi

# --- 3. Python 3.12 + tkinter ---
if ! command -v python3.12 &>/dev/null; then
    echo "[3/5] Installing Python 3.12..."
    brew install python@3.12
else
    echo "[3/5] Python 3.12 already installed. Skipping."
fi

# Install tkinter support (idempotent)
brew install python-tk@3.12 2>/dev/null || true

# Locate python3.12
PYTHON="$(command -v python3.12 || echo /opt/homebrew/bin/python3.12)"

# --- 4. Virtual environment + dependencies ---
echo "[4/5] Setting up Python environment..."
if [ ! -d "$VENV_DIR" ]; then
    "$PYTHON" -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"
pip install --upgrade pip -q
pip install opendataloader-pdf tkmacosx -q
deactivate

# --- 5. Create Desktop launcher ---
echo "[5/5] Creating Desktop launcher..."
cat > "$LAUNCHER" << 'LAUNCHER_EOF'
#!/bin/bash
LAUNCHER_EOF

# Write the launcher with the actual path embedded
cat > "$LAUNCHER" << EOF
#!/bin/bash
cd "$SCRIPT_DIR"
source venv/bin/activate
python app.py
EOF

chmod +x "$LAUNCHER"

echo ""
echo "=========================================="
echo "  All set!"
echo ""
echo "  Double-click 'PDF to Markdown' on your"
echo "  Desktop to start converting PDFs."
echo "=========================================="
echo ""
read -p "Press Enter to close this window..."
