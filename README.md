# PDF to Markdown Converter

**Convert PDFs to clean Markdown locally. Your files never leave your computer.**

Tax returns, medical records, legal documents — you shouldn't have to upload sensitive PDFs to some random website just to get usable text. This app runs 100% on your Mac. No cloud. No accounts. No data leaving your machine.

## What It Does

- Converts any PDF to clean, structured Markdown
- Handles tables, headings, multi-column layouts
- Batch convert multiple files at once
- Progress tracking with per-file status
- Output saved next to your original files (or wherever you choose)

## Install (one time, ~5 minutes)

Open **Terminal** (press `Cmd + Space`, type `Terminal`, hit Enter) and paste this:

```bash
curl -fsSL https://raw.githubusercontent.com/bhaveshlalwani/pdf-to-markdown-converter/main/install.sh | bash
```

Enter your Mac password when prompted (needed to install Java). When it's done, a **"PDF to Markdown"** shortcut appears on your Desktop. You can close Terminal — you won't need it again.

## How to Use

1. Double-click **"PDF to Markdown"** on your Desktop
2. Click **+ Add PDFs** to select files
3. Click **Convert All**
4. Click **Open Folder** to see your Markdown files

That's it. Your `.md` files are saved right next to your original PDFs.

## Why This Exists

I built this during tax season. I needed to convert tax documents (1040s, T1s, receipts) to text I could actually work with — but every online converter wants you to upload your files to their servers. For documents with your SSN, income, and bank details, that's a non-starter.

This converter runs entirely on your computer using [OpenDataLoader PDF](https://github.com/opendataloader-project/opendataloader-pdf), an open-source PDF parsing engine. Nothing is uploaded anywhere.

## Use Cases

- **Tax preparation** — Convert tax forms to Markdown, paste into Claude/ChatGPT for help without uploading PDFs directly
- **Legal documents** — Extract text from contracts and agreements locally
- **Medical records** — Keep health information private while making it searchable
- **Research papers** — Batch convert academic PDFs to Markdown for note-taking
- **Any sensitive document** — If you wouldn't email it to a stranger, don't upload it to a converter website

## Requirements

- macOS (Windows and Linux support planned)
- ~5 minutes for one-time setup
- No technical knowledge needed

## Troubleshooting

**App doesn't open / closes immediately**
Open Terminal and run:
```
~/Desktop/PDF\ to\ Markdown.command
```
This will show any error messages. Usually re-running the install command fixes it.

**Conversion is slow**
The first conversion takes longer (~10-15s) because Java needs to start up. Subsequent files in the same batch are faster (~2-5s each).

**Want to update to the latest version?**
Just run the install command again — it will download the latest version without reinstalling dependencies.

## How It Works

```
Your PDF → OpenDataLoader PDF (Java engine, runs locally) → Clean Markdown file
```

The app is a lightweight Python GUI that wraps [OpenDataLoader PDF](https://github.com/opendataloader-project/opendataloader-pdf), the #1 ranked open-source PDF parser. All processing happens on your machine via a local Java process. No API calls, no cloud services, no data transmission.

## Built With

- [OpenDataLoader PDF](https://github.com/opendataloader-project/opendataloader-pdf) — Open-source PDF parsing engine (#1 in extraction benchmarks)
- Python + tkinter — Cross-platform desktop GUI
- Homebrew — Dependency management for macOS

## License

Apache 2.0 — same as the underlying OpenDataLoader PDF project.
