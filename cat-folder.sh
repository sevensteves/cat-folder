#!/usr/bin/env bash

# Usage: ./cat_folder.sh /path/to/dir

if [ -z "$1" ]; then
  echo "Usage: $0 <path>"
  exit 1
fi

TARGET_DIR="$1"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: $TARGET_DIR is not a directory"
  exit 1
fi

echo "===== Directory Tree for $TARGET_DIR ====="
if command -v tree >/dev/null 2>&1; then
  if [ -f "$TARGET_DIR/.gitignore" ]; then
    (
      cd "$TARGET_DIR" || exit 1
      git ls-files --exclude-standard --others --cached | tree --fromfile -N --charset=ascii
    )
  else
    tree -N -a --charset=ascii -I ".git" "$TARGET_DIR"
  fi
else
  echo "(tree not installed, using find instead)"
  if [ -f "$TARGET_DIR/.gitignore" ]; then
    git -C "$TARGET_DIR" ls-files --exclude-standard --others --cached
  else
    find "$TARGET_DIR" -path "*/.git" -prune -o -print
  fi
fi
echo "=========================================="
echo

# Gather file list
if [ -f "$TARGET_DIR/.gitignore" ]; then
  FILES=$(git -C "$TARGET_DIR" ls-files --exclude-standard --others --cached)
else
  FILES=$(find "$TARGET_DIR" -type f -not -path "*/.git/*")
fi

# List of binary extensions to skip
BINARY_EXTS="png jpg jpeg gif bmp ico exe dll so bin pdf zip gz tar tgz xz 7z mp3 mp4 mov avi mkv webp"

for file in $FILES; do
  ext="${file##*.}"
  if echo "$BINARY_EXTS" | grep -wiq "$ext"; then
    echo "Skipping binary file (by extension): $file"
    continue
  fi

  # safer MIME-based check
  mime=$(file -b --mime-type -- "$file" 2>/dev/null)
  if [[ -z "$mime" || "$mime" != text/* && "$mime" != */json && "$mime" != */xml ]]; then
    echo "Skipping binary file (by mime: $mime): $file"
    continue
  fi

  echo "----- FILE: $file -----"
  # strip ANSI escape sequences just in case
  sed -r $'s/\x1B\\[[0-9;]*[A-Za-z]//g' -- "$file"
  echo
done
