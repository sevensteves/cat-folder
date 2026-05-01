#!/bin/bash

set -e

REPO="sevensteves/cat-folder"
GITHUB_API="https://api.github.com/repos/$REPO/releases/latest"
RELEASES_PAGE="https://github.com/$REPO/releases"

# Detect OS
OS=$(uname -s)
case "$OS" in
  Linux)
    OS_LOWER="linux"
    ;;
  Darwin)
    OS_LOWER="darwin"
    ;;
  *)
    echo "Error: Unsupported OS: $OS"
    echo "Please download the binary manually from: $RELEASES_PAGE"
    exit 1
    ;;
esac

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64)
    ARCH_LOWER="amd64"
    ;;
  arm64|aarch64)
    ARCH_LOWER="arm64"
    ;;
  *)
    echo "Error: Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# Fetch latest release tag
echo "Fetching latest release..."
TAG=$(curl -s "$GITHUB_API" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)

if [ -z "$TAG" ]; then
  echo "Error: Could not determine latest release"
  echo "Please download manually from: $RELEASES_PAGE"
  exit 1
fi

# Construct download URL
if [ "$OS_LOWER" = "windows" ]; then
  ARCHIVE="cat-folder_${OS_LOWER}_${ARCH_LOWER}.zip"
else
  ARCHIVE="cat-folder_${OS_LOWER}_${ARCH_LOWER}.tar.gz"
fi
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/$ARCHIVE"

# Create temp directory and set up cleanup
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Downloading $ARCHIVE..."
curl -sL "$DOWNLOAD_URL" -o "$TEMP_DIR/$ARCHIVE"

# Extract
cd "$TEMP_DIR"
if [ "$OS_LOWER" = "windows" ]; then
  unzip -q "$ARCHIVE"
else
  tar -xzf "$ARCHIVE"
fi

# Verify binary exists
if [ ! -x "cat-folder" ]; then
  echo "Error: Binary not found after extraction"
  exit 1
fi

chmod +x cat-folder

# Determine install directory
INSTALL_DIR=""

# Check if on macOS with Homebrew
if [ "$OS_LOWER" = "darwin" ] && [ -d "/opt/homebrew/bin" ]; then
  INSTALL_DIR="/opt/homebrew/bin"
elif [ -w "/usr/local/bin" ]; then
  INSTALL_DIR="/usr/local/bin"
elif [ -d "/usr/local/bin" ]; then
  INSTALL_DIR="/usr/local/bin"
elif [ -w "$HOME/.local/bin" ]; then
  INSTALL_DIR="$HOME/.local/bin"
elif [ -d "$HOME/.local/bin" ]; then
  mkdir -p "$HOME/.local/bin"
  INSTALL_DIR="$HOME/.local/bin"
else
  echo "Error: No suitable installation directory found"
  exit 1
fi

# Install binary
echo "Installing to $INSTALL_DIR..."
if [ -w "$INSTALL_DIR" ]; then
  mv cat-folder "$INSTALL_DIR/"
else
  sudo mv cat-folder "$INSTALL_DIR/"
fi

# Verify installation
if $INSTALL_DIR/cat-folder --version > /dev/null 2>&1; then
  echo "✓ Installation successful!"
  echo ""
  echo "Usage examples:"
  echo "  cat-folder ."
  echo "  cat-folder --profile web ."
  echo "  cat-folder --profile web --max-lines 150 ."
  echo "  cat-folder --profile web --ignore '*.snap' --ignore 'storybook-static' ."
else
  echo "Error: Installation failed or binary is not executable"
  exit 1
fi
