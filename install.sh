#!/bin/bash
# ============================================================
# PDF to Markdown Converter — Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/bhaveshlalwani/pdf-to-markdown-converter/main/install.sh | bash
#
# What this does:
#   1. Installs Homebrew, Java, Python (if needed)
#   2. Creates the converter app (~/.pdf-to-markdown/)
#   3. Puts a "PDF to Markdown" shortcut on your Desktop
# ============================================================

set -e

APP_DIR="$HOME/.pdf-to-markdown"
VENV_DIR="$APP_DIR/venv"
LAUNCHER="$HOME/Desktop/PDF to Markdown.command"
APP_URL="https://raw.githubusercontent.com/bhaveshlalwani/pdf-to-markdown-converter/main/app.py"

echo ""
echo "=========================================="
echo "  PDF to Markdown Converter — Installer"
echo "=========================================="
echo ""

# --- 1. Homebrew ---
if ! command -v brew &>/dev/null; then
    echo "[1/5] Installing Homebrew (requires your Mac password)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "[1/5] Homebrew found."
fi

# --- 2. Java ---
if ! command -v java &>/dev/null; then
    echo "[2/5] Installing Java (requires your Mac password)..."
    brew install --cask temurin
else
    echo "[2/5] Java found."
fi

# --- 3. Python 3.12 + tkinter ---
if ! command -v python3.12 &>/dev/null; then
    echo "[3/5] Installing Python 3.12..."
    brew install python@3.12
else
    echo "[3/5] Python 3.12 found."
fi
brew install python-tk@3.12 2>/dev/null || true

PYTHON="$(command -v python3.12 || echo /opt/homebrew/bin/python3.12)"

# --- 4. Download app + create venv ---
echo "[4/5] Setting up the converter app..."
mkdir -p "$APP_DIR"

# Download latest app.py from GitHub
curl -fsSL "$APP_URL" -o "$APP_DIR/app.py"

if [ ! -d "$VENV_DIR" ]; then
    "$PYTHON" -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"
pip install --upgrade pip -q
pip install opendataloader-pdf tkmacosx -q
deactivate

# --- 5. Create Desktop launcher ---
echo "[5/5] Creating Desktop launcher..."
cat > "$LAUNCHER" << EOF
#!/bin/bash
cd "$APP_DIR"
source venv/bin/activate
python app.py
EOF
chmod +x "$LAUNCHER"

echo ""
echo "=========================================="
echo ""
echo "  All set! You can close this window."
echo ""
echo "  Double-click 'PDF to Markdown' on your"
echo "  Desktop to start converting PDFs."
echo ""
echo "=========================================="
echo ""
