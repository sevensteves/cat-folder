#!/bin/bash

set -e

REPO="sevensteves/cat-folder"
GITHUB_API="https://api.github.com/repos/$REPO/releases/latest"
RELEASES_PAGE="https://github.com/$REPO/releases"

BOLD="\033[1m"
GREEN="\033[0;32m"
TEAL="\033[0;36m"
GRAY="\033[0;90m"
RESET="\033[0m"

echo ""
echo -e "${BOLD}  cat-folder installer${RESET}"
echo -e "${GRAY}  github.com/$REPO${RESET}"
echo ""

# Detect OS
OS=$(uname -s)
case "$OS" in
  Linux)  OS_LOWER="linux" ;;
  Darwin) OS_LOWER="darwin" ;;
  *)
    echo "  Error: Unsupported OS: $OS"
    echo "  Download manually from: $RELEASES_PAGE"
    exit 1
    ;;
esac

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64)   ARCH_LOWER="amd64" ;;
  arm64|aarch64)  ARCH_LOWER="arm64" ;;
  *)
    echo "  Error: Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo -e "  ${GRAY}»${RESET} Detecting system...   ${TEAL}${OS_LOWER}/${ARCH_LOWER}${RESET}"

# Fetch latest release tag
TAG=$(curl -s "$GITHUB_API" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)

if [ -z "$TAG" ]; then
  echo "  Error: Could not determine latest release."
  echo "  Download manually from: $RELEASES_PAGE"
  exit 1
fi

echo -e "  ${GRAY}»${RESET} Fetching latest release... ${TEAL}${TAG}${RESET}"

# Construct download URL
ARCHIVE="cat-folder_${OS_LOWER}_${ARCH_LOWER}.tar.gz"
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/$ARCHIVE"

echo -e "  ${GRAY}»${RESET} Downloading ${ARCHIVE}..."

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

curl -sL "$DOWNLOAD_URL" -o "$TEMP_DIR/$ARCHIVE"

cd "$TEMP_DIR"
tar -xzf "$ARCHIVE"

if [ ! -f "cat-folder" ]; then
  echo "  Error: Binary not found after extraction."
  exit 1
fi

chmod +x cat-folder

# Determine install directory
INSTALL_DIR=""
if [ "$OS_LOWER" = "darwin" ] && [ -d "/opt/homebrew/bin" ]; then
  INSTALL_DIR="/opt/homebrew/bin"
elif [ -w "/usr/local/bin" ]; then
  INSTALL_DIR="/usr/local/bin"
elif [ -d "/usr/local/bin" ]; then
  INSTALL_DIR="/usr/local/bin"
elif [ -w "$HOME/.local/bin" ]; then
  INSTALL_DIR="$HOME/.local/bin"
else
  mkdir -p "$HOME/.local/bin"
  INSTALL_DIR="$HOME/.local/bin"
fi

echo -e "  ${GRAY}»${RESET} Installing to ${INSTALL_DIR}..."

if [ -w "$INSTALL_DIR" ]; then
  mv cat-folder "$INSTALL_DIR/"
else
  sudo mv cat-folder "$INSTALL_DIR/"
fi

# Verify
if ! "$INSTALL_DIR/cat-folder" --version > /dev/null 2>&1; then
  echo "  Error: Installation failed or binary is not executable."
  exit 1
fi

INSTALLED_VERSION=$("$INSTALL_DIR/cat-folder" --version 2>/dev/null || echo "$TAG")

echo ""
echo -e "  ${GREEN}✓ Installation successful!${RESET} ${GRAY}cat-folder ${INSTALLED_VERSION}${RESET}"
echo ""
echo -e "  ${GRAY}Quick start${RESET}"
echo -e "  ${TEAL}\$${RESET} cat-folder ."
echo -e "  ${TEAL}\$${RESET} cat-folder --profile web ."
echo -e "  ${TEAL}\$${RESET} cat-folder --profile web --max-lines 150 ."
echo -e "  ${TEAL}\$${RESET} cat-folder --profile web --ignore '*.snap' ."
echo ""
echo -e "  ${GRAY}Docs   → github.com/$REPO${RESET}"
echo -e "  ${GRAY}Issues → github.com/$REPO/issues${RESET}"
echo ""
