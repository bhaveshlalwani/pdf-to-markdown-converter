# PDF to Markdown Converter — Desktop App

A simple desktop app that converts PDF files into clean Markdown. No terminal skills needed.

## What You Need

- A Mac (Windows and Linux support coming soon)
- About 5 minutes for the one-time setup
- Your Mac password (for installing Java)

## How to Install (one time)

1. Download or clone this repository
2. Open the `desktop-app` folder
3. Double-click **`install-mac.command`**
4. If macOS says "can't be opened because it's from an unidentified developer":
   - Go to **System Settings > Privacy & Security**
   - Scroll down and click **Open Anyway**
5. Enter your Mac password when prompted (needed for Java installation)
6. Wait for the install to finish (~3-5 minutes)
7. A **"PDF to Markdown"** shortcut will appear on your Desktop

## How to Use

1. Double-click **"PDF to Markdown"** on your Desktop
2. Click **+ Add PDFs** to select your PDF files
3. (Optional) Click **Change** to pick a different output folder — by default, Markdown files are saved next to your original PDFs
4. Click **Convert All**
5. Watch files move from the Queue to the Completed section
6. When done, click the green status message to open the output folder

## Where Are My Files?

By default, the converted `.md` files are saved in the **same folder as your original PDFs**. If your PDFs come from different folders, they're saved to `~/Desktop/Markdown Outputs`.

You can change this anytime with the **Change** button before converting.

## Troubleshooting

**"Can't be opened because it is from an unidentified developer"**
Go to System Settings > Privacy & Security > click "Open Anyway"

**App doesn't open / closes immediately**
Open Terminal and run:
```
~/Desktop/PDF\ to\ Markdown.command
```
This will show any error messages.

**"java: command not found"**
Re-run the installer (`install-mac.command`) — it will install Java.

## Built With

- [OpenDataLoader PDF](https://github.com/opendataloader-project/opendataloader-pdf) — PDF parsing engine
- Python + tkinter — desktop GUI
