#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

error_exit() {
  echo -e "${RED}ERROR: $1${NC}" >&2
  exit 1
}

print_success() {
  echo -e "${GREEN}$1${NC}"
}

print_warning() {
  echo -e "${YELLOW}WARNING: $1${NC}"
}

command -v curl >/dev/null 2>&1 || error_exit "curl is required but not installed. Please install curl first."

SCRIPT_NAME="cat-folder"
REPO_URL="https://raw.githubusercontent.com/sevensteves/cat-folder/main/${SCRIPT_NAME}.sh"

determine_install_dir() {
  local possible_dirs=("/usr/local/bin" "/opt/homebrew/bin" "$HOME/.local/bin" "/bin")
  
  if [[ "$(uname)" == "Darwin" ]]; then
    if [ -d "/opt/homebrew/bin" ]; then
      INSTALL_DIR="/opt/homebrew/bin"
      return
    elif [ -d "/usr/local/bin" ]; then
      INSTALL_DIR="/usr/local/bin"
      return
    fi
  fi
  
  for dir in "${possible_dirs[@]}"; do
    if [ -d "$dir" ]; then
      INSTALL_DIR="$dir"
      return
    fi
  done
  
  INSTALL_DIR="$HOME/.local/bin"
  print_warning "No standard binary directories found. Installing to $INSTALL_DIR"
  print_warning "You may need to add $INSTALL_DIR to your PATH manually."
}

determine_install_dir

if [ ! -d "$INSTALL_DIR" ]; then
  echo "Creating directory $INSTALL_DIR..."
  
  if [ -w "$(dirname "$INSTALL_DIR")" ]; then
    mkdir -p "$INSTALL_DIR" || error_exit "Failed to create directory $INSTALL_DIR"
  else
    echo "This requires sudo privileges to create $INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR" || error_exit "Failed to create directory $INSTALL_DIR"
  fi
fi

echo "Installing $SCRIPT_NAME to $INSTALL_DIR..."

NEED_SUDO=0
if [ ! -w "$INSTALL_DIR" ]; then
  NEED_SUDO=1
  print_warning "Installing to $INSTALL_DIR requires sudo privileges"
fi

if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
  echo "Updating existing installation of $SCRIPT_NAME"
fi

TEMP_FILE=$(mktemp)
echo "Downloading $SCRIPT_NAME from repository..."
curl -sL "$REPO_URL" -o "$TEMP_FILE" || error_exit "Failed to download $SCRIPT_NAME"

if [ ! -s "$TEMP_FILE" ]; then
  rm -f "$TEMP_FILE"
  error_exit "Downloaded file is empty. Check your internet connection or repository URL."
fi


if [ $NEED_SUDO -eq 1 ]; then
  sudo mv "$TEMP_FILE" "$INSTALL_DIR/$SCRIPT_NAME" || error_exit "Failed to install $SCRIPT_NAME"
  sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME" || error_exit "Failed to make $SCRIPT_NAME executable"
else
  mv "$TEMP_FILE" "$INSTALL_DIR/$SCRIPT_NAME" || error_exit "Failed to install $SCRIPT_NAME"
  chmod +x "$INSTALL_DIR/$SCRIPT_NAME" || error_exit "Failed to make $SCRIPT_NAME executable"
fi

if [ -x "$INSTALL_DIR/$SCRIPT_NAME" ]; then
  print_success "Successfully installed $SCRIPT_NAME to $INSTALL_DIR"

  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    print_warning "$INSTALL_DIR is not in your PATH. You may need to add it."
    echo "Suggested command to add to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
  fi
  
  print_success "Run '$SCRIPT_NAME /path/to/dir' to get started."
else
  error_exit "Installation verification failed. Please check permissions and try again."
fi
