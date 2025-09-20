#!/usr/bin/env bash
set -e

SCRIPT_NAME="cat-folder"
REPO_URL="https://raw.githubusercontent.com/sevensteves/cat-folder/main/${SCRIPT_NAME}.sh"

# Default install dir
INSTALL_DIR="/usr/local/bin"

# If on macOS with Homebrew prefix, prefer /opt/homebrew/bin
if [[ "$(uname)" == "Darwin" ]] && [ -d "/opt/homebrew/bin" ]; then
  INSTALL_DIR="/opt/homebrew/bin"
fi

# Ensure install dir exists
if [ ! -d "$INSTALL_DIR" ]; then
  echo "Creating $INSTALL_DIR (requires sudo)..."
  sudo mkdir -p "$INSTALL_DIR"
fi

echo "Installing $SCRIPT_NAME to $INSTALL_DIR..."

# Download script
sudo curl -sL "$REPO_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"

# Make it executable
sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

echo "Installed $SCRIPT_NAME to $INSTALL_DIR"
echo "Run '$SCRIPT_NAME /path/to/dir' to get started."
