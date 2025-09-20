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
      git ls-files --exclude-standard --others --cached \
        | tree --fromfile -N --charset=ascii
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

# Walk through files and show contents
if [ -f "$TARGET_DIR/.gitignore" ]; then
  FILES=$(git -C "$TARGET_DIR" ls-files --exclude-standard --others --cached)
else
  FILES=$(find "$TARGET_DIR" -type f -not -path "*/.git/*")
fi

for file in $FILES; do
  echo "----- FILE: $file -----"
  cat "$file"
  echo
done
