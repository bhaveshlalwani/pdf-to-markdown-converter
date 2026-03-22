#!/bin/bash
# ============================================================
# PDF to Markdown Converter — All-in-One Installer
#
# WHAT THIS DOES:
#   1. Installs Java + Python (if needed)
#   2. Creates the converter app on your computer
#   3. Puts a "PDF to Markdown" shortcut on your Desktop
#
# Just double-click this file. You'll need your Mac password
# once during setup (for installing Java).
# ============================================================

set -e

APP_DIR="$HOME/.pdf-to-markdown"
VENV_DIR="$APP_DIR/venv"
LAUNCHER="$HOME/Desktop/PDF to Markdown.command"
APP_FILE="$APP_DIR/app.py"

echo ""
echo "=========================================="
echo "  PDF to Markdown — Installer"
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

# --- 4. Create app + venv ---
echo "[4/5] Setting up the converter app..."
mkdir -p "$APP_DIR"

# Write the app.py file
cat > "$APP_FILE" << 'APPEOF'
#!/usr/bin/env python3
"""PDF to Markdown Converter — cross-platform desktop GUI."""

import os
import platform
import subprocess
import threading
import tkinter as tk
from tkinter import filedialog, ttk
from pathlib import Path

# --- OS detection & conditional imports ---
SYSTEM = platform.system()
IS_MAC = SYSTEM == "Darwin"
IS_WIN = SYSTEM == "Windows"

if IS_MAC:
    from tkmacosx import Button as _MacButton
else:
    _MacButton = None

FALLBACK_OUTPUT_DIR = Path.home() / "Desktop" / "Markdown Outputs"

# --- Theme ---
BG = "#1a1a2e"
SURFACE = "#242440"
SURFACE_ALT = "#1e1e36"
BORDER = "#333355"
TEXT = "#e0e0ee"
MUTED = "#7777a0"
ACCENT = "#6c63ff"
ACCENT_HOVER = "#5a52e0"
GREEN = "#4ade80"
RED = "#f07070"


def make_button(parent, **kwargs):
    """Create a Button that works on all platforms."""
    if IS_MAC and _MacButton:
        return _MacButton(parent, **kwargs)
    else:
        kwargs.pop("borderless", None)
        return tk.Button(parent, **kwargs)


def open_folder(path: Path):
    """Open a folder in the OS file manager."""
    p = str(path)
    if IS_MAC:
        subprocess.Popen(["open", p])
    elif IS_WIN:
        os.startfile(p)
    else:
        subprocess.Popen(["xdg-open", p])


def short_path(p: Path) -> str:
    """Shorten a path for display (~/...)."""
    try:
        return "~/" + str(p.relative_to(Path.home()))
    except ValueError:
        return str(p)


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("PDF to Markdown Converter")
        self.geometry("600x720")
        self.configure(bg=BG)
        self.resizable(False, False)

        self.queue_files: list[Path] = []
        self.done_files: list[dict] = []  # {name, path, status}
        self.is_converting = False
        self.output_dir: Path | None = None  # None = auto (same as input)
        self.last_output_dir: Path | None = None  # tracks where files were actually saved

        self._build_ui()

    def _resolve_output_dir(self) -> Path:
        """Determine output dir: user override > same-as-input > fallback."""
        if self.output_dir:
            return self.output_dir

        if not self.queue_files:
            return FALLBACK_OUTPUT_DIR

        # Check if all inputs are in the same folder
        parents = {f.parent for f in self.queue_files}
        if len(parents) == 1:
            return parents.pop()
        else:
            FALLBACK_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
            return FALLBACK_OUTPUT_DIR

    def _build_ui(self):
        # --- Header ---
        header = tk.Frame(self, bg=BG)
        header.pack(fill="x", padx=28, pady=(20, 0))

        tk.Label(header, text="PDF to Markdown", font=("Helvetica", 22, "bold"),
                 bg=BG, fg="#ffffff", anchor="w").pack(side="left")

        self.add_btn = make_button(header, text="+ Add PDFs", font=("Helvetica", 13, "bold"),
                                   bg=ACCENT, fg="#ffffff", activebackground=ACCENT_HOVER,
                                   activeforeground="#fff", borderless=True,
                                   padx=18, pady=6, command=self.add_files)
        self.add_btn.pack(side="right")

        tk.Label(self, text="Convert PDF files to clean Markdown",
                 font=("Helvetica", 12), bg=BG, fg=MUTED, anchor="w").pack(
            fill="x", padx=28, pady=(2, 16))

        # --- Queue Section ---
        q_header = tk.Frame(self, bg=BG)
        q_header.pack(fill="x", padx=28)
        tk.Label(q_header, text="QUEUE", font=("Helvetica", 11, "bold"),
                 bg=BG, fg=MUTED).pack(side="left")
        self.queue_count = tk.Label(q_header, text="0 files", font=("Helvetica", 11),
                                    bg=BG, fg=MUTED)
        self.queue_count.pack(side="right")

        queue_border = tk.Frame(self, bg=BORDER, bd=0)
        queue_border.pack(fill="both", padx=28, pady=(4, 0), expand=True)
        self.queue_frame_outer = tk.Frame(queue_border, bg=SURFACE)
        self.queue_frame_outer.pack(fill="both", expand=True, padx=1, pady=1)

        self.queue_canvas = tk.Canvas(self.queue_frame_outer, bg=SURFACE,
                                      highlightthickness=0, bd=0)
        self.queue_scroll = tk.Frame(self.queue_canvas, bg=SURFACE)
        self.queue_canvas.pack(fill="both", expand=True)
        self.queue_canvas_window = self.queue_canvas.create_window(
            (0, 0), window=self.queue_scroll, anchor="nw")
        self.queue_scroll.bind("<Configure>",
                               lambda e: self.queue_canvas.configure(scrollregion=self.queue_canvas.bbox("all")))
        self.queue_canvas.bind("<Configure>",
                               lambda e: self.queue_canvas.itemconfig(self.queue_canvas_window, width=e.width))

        self.queue_placeholder = tk.Label(self.queue_frame_outer,
                                          text="Click '+ Add PDFs' to select files",
                                          font=("Helvetica", 12), bg=SURFACE, fg=MUTED)
        self.queue_placeholder.place(relx=0.5, rely=0.5, anchor="center")

        # --- Convert Button + Progress ---
        action_frame = tk.Frame(self, bg=BG)
        action_frame.pack(fill="x", padx=28, pady=(12, 0))

        self.convert_btn = make_button(action_frame, text="Convert All",
                                       font=("Helvetica", 14, "bold"),
                                       bg=ACCENT, fg="#ffffff", activebackground=ACCENT_HOVER,
                                       activeforeground="#fff", borderless=True,
                                       pady=10, command=self.convert)
        self.convert_btn.pack(fill="x")
        self.convert_btn.configure(state="disabled")

        # Progress bar
        style = ttk.Style()
        style.theme_use("default")
        style.configure("Custom.Horizontal.TProgressbar",
                        troughcolor=SURFACE, background=ACCENT,
                        darkcolor=ACCENT, lightcolor=ACCENT,
                        bordercolor=BG, thickness=6)
        self.progress = ttk.Progressbar(action_frame, style="Custom.Horizontal.TProgressbar",
                                        mode="determinate", maximum=100)

        self.progress_label = tk.Label(action_frame, text="", font=("Helvetica", 11),
                                       bg=BG, fg=MUTED)

        # --- Completed Section ---
        d_header = tk.Frame(self, bg=BG)
        d_header.pack(fill="x", padx=28, pady=(14, 0))
        tk.Label(d_header, text="COMPLETED", font=("Helvetica", 11, "bold"),
                 bg=BG, fg=MUTED).pack(side="left")
        self.done_count = tk.Label(d_header, text="", font=("Helvetica", 11),
                                   bg=BG, fg=MUTED)
        self.done_count.pack(side="right")

        done_border = tk.Frame(self, bg=BORDER, bd=0)
        done_border.pack(fill="both", padx=28, pady=(4, 0), expand=True)
        self.done_frame_outer = tk.Frame(done_border, bg=SURFACE_ALT)
        self.done_frame_outer.pack(fill="both", expand=True, padx=1, pady=1)

        self.done_canvas = tk.Canvas(self.done_frame_outer, bg=SURFACE_ALT,
                                     highlightthickness=0, bd=0)
        self.done_scroll = tk.Frame(self.done_canvas, bg=SURFACE_ALT)
        self.done_canvas.pack(fill="both", expand=True)
        self.done_canvas_window = self.done_canvas.create_window(
            (0, 0), window=self.done_scroll, anchor="nw")
        self.done_scroll.bind("<Configure>",
                              lambda e: self.done_canvas.configure(scrollregion=self.done_canvas.bbox("all")))
        self.done_canvas.bind("<Configure>",
                              lambda e: self.done_canvas.itemconfig(self.done_canvas_window, width=e.width))

        self.done_placeholder = tk.Label(self.done_frame_outer,
                                         text="Converted files will appear here",
                                         font=("Helvetica", 12), bg=SURFACE_ALT, fg=MUTED)
        self.done_placeholder.place(relx=0.5, rely=0.5, anchor="center")

        # --- Status bar with Open Folder button ---
        status_frame = tk.Frame(self, bg=BG)
        status_frame.pack(fill="x", padx=28, pady=(8, 12))

        self.status_var = tk.StringVar(value="")
        self.status_label = tk.Label(status_frame, textvariable=self.status_var,
                                     font=("Helvetica", 11), bg=BG, fg=GREEN,
                                     anchor="w")
        self.status_label.pack(side="left", fill="x", expand=True)

        self.open_folder_btn = make_button(status_frame, text="Open Folder",
                                           font=("Helvetica", 11, "bold"),
                                           bg=GREEN, fg="#1a1a2e",
                                           activebackground="#3abe70",
                                           activeforeground="#1a1a2e",
                                           borderless=True, padx=12, pady=4,
                                           command=self._click_status)
        # Hidden until conversion completes
        self.open_folder_btn.pack_forget()

    # --- File list rendering ---

    def _render_queue(self):
        for w in self.queue_scroll.winfo_children():
            w.destroy()

        if not self.queue_files:
            self.queue_placeholder.place(relx=0.5, rely=0.5, anchor="center")
        else:
            self.queue_placeholder.place_forget()

        for i, f in enumerate(self.queue_files):
            row = tk.Frame(self.queue_scroll, bg=SURFACE, pady=6, padx=12)
            row.pack(fill="x")

            tk.Label(row, text="   " + f.name, font=("Helvetica", 12),
                     bg=SURFACE, fg=TEXT, anchor="w").pack(side="left", fill="x", expand=True)

            size_mb = f.stat().st_size / 1024 / 1024
            tk.Label(row, text=f"{size_mb:.1f} MB", font=("Helvetica", 10),
                     bg=SURFACE, fg=MUTED).pack(side="right", padx=(0, 8))

            idx = i
            remove = make_button(row, text="x", font=("Helvetica", 11),
                                 bg=SURFACE, fg="#ff6b6b", activebackground=SURFACE,
                                 activeforeground=RED, borderless=True,
                                 padx=4, pady=0,
                                 command=lambda j=idx: self.remove_file(j))
            remove.pack(side="right")

            if i < len(self.queue_files) - 1:
                sep = tk.Frame(self.queue_scroll, bg=BORDER, height=1)
                sep.pack(fill="x", padx=12)

        self.queue_count.configure(text=f"{len(self.queue_files)} file{'s' if len(self.queue_files) != 1 else ''}")
        can_convert = len(self.queue_files) > 0 and not self.is_converting
        self.convert_btn.configure(state="normal" if can_convert else "disabled")

    def _render_done(self):
        for w in self.done_scroll.winfo_children():
            w.destroy()

        if not self.done_files:
            self.done_placeholder.place(relx=0.5, rely=0.5, anchor="center")
            self.done_count.configure(text="")
        else:
            self.done_placeholder.place_forget()
            self.done_count.configure(text=f"{len(self.done_files)} file{'s' if len(self.done_files) != 1 else ''}")

        for i, entry in enumerate(self.done_files):
            row = tk.Frame(self.done_scroll, bg=SURFACE_ALT, pady=6, padx=12)
            row.pack(fill="x")

            if entry["status"] == "success":
                icon = "\u2705"
                color = GREEN
            else:
                icon = "\u274c"
                color = RED

            tk.Label(row, text=icon, font=("Helvetica", 13),
                     bg=SURFACE_ALT, fg=color).pack(side="left")
            tk.Label(row, text=" " + entry["name"], font=("Helvetica", 12),
                     bg=SURFACE_ALT, fg=TEXT, anchor="w").pack(side="left", fill="x", expand=True)
            tk.Label(row, text=entry["status"].upper(), font=("Helvetica", 10, "bold"),
                     bg=SURFACE_ALT, fg=color).pack(side="right")

            if i < len(self.done_files) - 1:
                sep = tk.Frame(self.done_scroll, bg=BORDER, height=1)
                sep.pack(fill="x", padx=12)

    # --- Actions ---

    def _click_status(self):
        """Click the status label to open the last output folder."""
        if self.last_output_dir and self.last_output_dir.exists():
            open_folder(self.last_output_dir)

    def add_files(self):
        if self.is_converting:
            return
        paths = filedialog.askopenfilenames(
            title="Select PDF files",
            filetypes=[("PDF files", "*.pdf")],
        )
        existing = {str(f) for f in self.queue_files}
        for p in paths:
            if p not in existing:
                self.queue_files.append(Path(p))
        self._render_queue()

    def remove_file(self, idx):
        if self.is_converting:
            return
        self.queue_files.pop(idx)
        self._render_queue()

    def convert(self):
        if not self.queue_files or self.is_converting:
            return
        self.is_converting = True
        self.convert_btn.configure(state="disabled", text="Converting...")
        self.add_btn.configure(state="disabled")
        self.status_var.set("")

        self.progress.pack(fill="x", pady=(8, 0))
        self.progress_label.pack(anchor="w", pady=(4, 0))
        self.progress["value"] = 0

        threading.Thread(target=self._do_convert, daemon=True).start()

    def _do_convert(self):
        import opendataloader_pdf

        out = self._resolve_output_dir()
        out.mkdir(parents=True, exist_ok=True)
        self.last_output_dir = out

        total = len(self.queue_files)
        files_to_process = list(self.queue_files)

        for i, f in enumerate(files_to_process):
            self.after(0, self._update_progress, i, total, f.name)
            try:
                opendataloader_pdf.convert(
                    input_path=[str(f)],
                    output_dir=str(out),
                    format="markdown",
                    image_output="off",
                )
                self.after(0, self._file_done, f, "success")
            except Exception as e:
                self.after(0, self._file_done, f, "failed")

        self.after(0, self._all_done, total, out)

    def _update_progress(self, index, total, name):
        pct = int((index / total) * 100)
        self.progress["value"] = pct
        self.progress_label.configure(text=f"Converting {index + 1}/{total}: {name}")

    def _file_done(self, f, status):
        self.done_files.insert(0, {"name": f.name, "path": f, "status": status})
        if f in self.queue_files:
            self.queue_files.remove(f)
        self._render_queue()
        self._render_done()

    def _all_done(self, count, out_dir):
        self.is_converting = False
        self.progress["value"] = 100
        self.progress_label.configure(text="All done!")
        self.convert_btn.configure(state="normal" if self.queue_files else "disabled",
                                   text="Convert All")
        self.add_btn.configure(state="normal")

        success_count = sum(1 for d in self.done_files if d["status"] == "success")
        path_str = short_path(out_dir)
        self.status_var.set(f"Done! {success_count} file(s) saved to {path_str}")
        self.status_label.configure(fg=GREEN)
        self.open_folder_btn.pack(side="right")

        self.after(3000, self._hide_progress)

    def _hide_progress(self):
        if not self.is_converting:
            self.progress.pack_forget()
            self.progress_label.pack_forget()


if __name__ == "__main__":
    App().mainloop()
APPEOF

# Create venv and install dependencies
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
echo "  All set!"
echo ""
echo "  Double-click 'PDF to Markdown' on your"
echo "  Desktop to start converting PDFs."
echo "=========================================="
echo ""
read -p "Press Enter to close this window..."
