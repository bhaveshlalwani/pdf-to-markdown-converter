#!/bin/bash
# ============================================================
# PDF to Markdown Converter — Installer
#
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bhaveshlalwani/pdf-to-markdown-converter/main/install.sh)"
#
# What this does:
#   1. Installs Xcode CLT, Homebrew, Java, Python (if needed)
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
echo "  This will install everything you need."
echo "  You may be asked for your Mac password."
echo ""

# --- 1. Xcode Command Line Tools ---
if ! xcode-select -p &>/dev/null; then
    echo "[1/6] Installing Xcode Command Line Tools..."
    echo "      A popup may appear — click 'Install' and wait."
    xcode-select --install 2>/dev/null || true
    # Wait for installation to complete
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    echo "      Done."
else
    echo "[1/6] Xcode Command Line Tools found."
fi

# --- 2. Homebrew ---
if ! command -v brew &>/dev/null; then
    echo "[2/6] Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        # Also add to shell profile so it persists
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile" 2>/dev/null || true
    fi
else
    echo "[2/6] Homebrew found."
fi

# --- 3. Java ---
if ! command -v java &>/dev/null; then
    echo "[3/6] Installing Java (may require your Mac password)..."
    brew install --cask temurin
else
    echo "[3/6] Java found."
fi

# --- 4. Python 3.12 + tkinter ---
if ! command -v python3.12 &>/dev/null; then
    echo "[4/6] Installing Python 3.12..."
    brew install python@3.12
else
    echo "[4/6] Python 3.12 found."
fi
brew install python-tk@3.12 2>/dev/null || true

PYTHON="$(command -v python3.12 || echo /opt/homebrew/bin/python3.12)"

# --- 5. Download app + create venv ---
echo "[5/6] Setting up the converter app..."
mkdir -p "$APP_DIR"

curl -fsSL "$APP_URL" -o "$APP_DIR/app.py"

if [ ! -d "$VENV_DIR" ]; then
    "$PYTHON" -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"
pip install --upgrade pip -q
pip install opendataloader-pdf tkmacosx -q
deactivate

# --- 6. Create Desktop launcher ---
echo "[6/6] Creating Desktop launcher..."
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
