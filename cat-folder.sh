#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: cat-folder [OPTIONS] <path>

Options:
  --profile <name>     web | default  (default: default)
  --max-lines <n>      truncate files longer than n lines
  --ignore <pattern>   extra glob to exclude (repeatable)
  --no-catignore       skip .catignore even if present
  -h, --help           print usage
EOF
}

error_exit() {
  echo "$1" >&2
  exit 1
}

join_by_pipe() {
  local joined=""
  local value

  for value in "$@"; do
    [[ -z "$value" ]] && continue

    if [[ -n "$joined" ]]; then
      joined+="|"
    fi

    joined+="$value"
  done

  printf '%s' "$joined"
}

trim_whitespace() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  printf '%s' "$value"
}

is_ignored() {
  local rel_path="$1"
  local base_name="${rel_path##*/}"
  local pattern

  for pattern in "${ACTIVE_IGNORES[@]}"; do
    [[ -z "$pattern" ]] && continue

    case "$rel_path" in
      $pattern|*/$pattern|$pattern/*|*/$pattern/*)
        return 0
        ;;
    esac

    case "$base_name" in
      $pattern)
        return 0
        ;;
    esac
  done

  return 1
}

build_find_display_args() {
  local pattern

  FIND_DISPLAY_ARGS=(find . -path './.git' -prune -o)

  for pattern in "${ACTIVE_IGNORES[@]}"; do
    [[ -z "$pattern" ]] && continue
    FIND_DISPLAY_ARGS+=(
      -not -path "./$pattern"
      -not -path "./$pattern/*"
      -not -path "*/$pattern"
      -not -path "*/$pattern/*"
      -not -name "$pattern"
    )
  done

  FIND_DISPLAY_ARGS+=(-print)
}

profile_default=()
profile_web=(
  "node_modules"
  ".next"
  ".nuxt"
  "dist"
  "build"
  "out"
  ".output"
  ".cache"
  ".parcel-cache"
  ".turbo"
  "coverage"
  ".nyc_output"
  "__pycache__"
  ".pytest_cache"
  ".venv"
  "venv"
  "package-lock.json"
  "yarn.lock"
  "pnpm-lock.yaml"
  "bun.lockb"
  "composer.lock"
  "Gemfile.lock"
  "Pipfile.lock"
  "poetry.lock"
  "*.min.js"
  "*.min.css"
  "*.map"
  "*.log"
  ".DS_Store"
  "Thumbs.db"
  ".env.local"
  ".env.*.local"
)

PROFILE_NAME="default"
MAX_LINES=""
USE_CATIGNORE=1
TARGET_DIR=""
CATIGNORE_COUNT=0

declare -a EXTRA_IGNORES=()
declare -a PROFILE_IGNORES=()
declare -a CATIGNORE_PATTERNS=()
declare -a ACTIVE_IGNORES=()
declare -a CANDIDATE_FILES=()
declare -a FILTERED_FILES=()
declare -a FIND_DISPLAY_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      shift
      [[ $# -gt 0 ]] || error_exit "Missing value for --profile"
      PROFILE_NAME="$1"
      ;;
    --max-lines)
      shift
      [[ $# -gt 0 ]] || error_exit "Missing value for --max-lines"
      [[ "$1" =~ ^[0-9]+$ ]] || error_exit "--max-lines expects a non-negative integer"
      MAX_LINES="$1"
      ;;
    --ignore)
      shift
      [[ $# -gt 0 ]] || error_exit "Missing value for --ignore"
      EXTRA_IGNORES+=("$1")
      ;;
    --no-catignore)
      USE_CATIGNORE=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      error_exit "Unknown option: $1"
      ;;
    *)
      [[ -z "$TARGET_DIR" ]] || error_exit "Path must be the final argument"
      TARGET_DIR="$1"
      ;;
  esac
  shift
done

[[ -n "$TARGET_DIR" ]] || {
  usage
  exit 1
}

[[ -d "$TARGET_DIR" ]] || error_exit "Error: $TARGET_DIR is not a directory"

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
cd "$TARGET_DIR"

case "$PROFILE_NAME" in
  default)
    PROFILE_IGNORES=("${profile_default[@]}")
    ;;
  web)
    PROFILE_IGNORES=("${profile_web[@]}")
    ;;
  *)
    error_exit "Unknown profile: $PROFILE_NAME"
    ;;
esac

if [[ $USE_CATIGNORE -eq 1 && -f .catignore ]]; then
  while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line="$(trim_whitespace "$raw_line")"
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue
    CATIGNORE_PATTERNS+=("$line")
  done < .catignore
fi

CATIGNORE_COUNT=${#CATIGNORE_PATTERNS[@]}
ACTIVE_IGNORES=("${PROFILE_IGNORES[@]}" "${CATIGNORE_PATTERNS[@]}" "${EXTRA_IGNORES[@]}" ".catignore")

if [[ -f .gitignore ]]; then
  mapfile -t CANDIDATE_FILES < <(git ls-files --exclude-standard --others --cached)
else
  mapfile -t CANDIDATE_FILES < <(find . -type f -not -path './.git/*' | sed 's#^\./##' | sort)
fi

ignored_files=0
binary_files_skipped=0
files_shown=0
files_truncated=0

for file in "${CANDIDATE_FILES[@]}"; do
  if is_ignored "$file"; then
    ((ignored_files+=1))
    continue
  fi

  FILTERED_FILES+=("$file")
done

echo "===== Directory Tree ====="
if command -v tree >/dev/null 2>&1; then
  if [[ -f .gitignore ]]; then
    if [[ ${#FILTERED_FILES[@]} -gt 0 ]]; then
      printf '%s\n' "${FILTERED_FILES[@]}" | tree --fromfile -N --charset=ascii
    fi
  else
    tree_ignore_pattern="$(join_by_pipe ".git" "${ACTIVE_IGNORES[@]}")"
    if [[ -n "$tree_ignore_pattern" ]]; then
      tree -N -a --charset=ascii -I "$tree_ignore_pattern" .
    else
      tree -N -a --charset=ascii .
    fi
  fi
else
  echo "(tree not installed, using find instead)"
  if [[ -f .gitignore ]]; then
    if [[ ${#FILTERED_FILES[@]} -gt 0 ]]; then
      printf '%s\n' "${FILTERED_FILES[@]}"
    fi
  else
    build_find_display_args
    "${FIND_DISPLAY_ARGS[@]}" | sed 's#^\./##'
  fi
fi
echo "=========="
echo

# List of binary extensions to skip
BINARY_EXTS="png jpg jpeg gif bmp ico exe dll so bin pdf zip gz tar tgz xz 7z mp3 mp4 mov avi mkv webp woff woff2 ttf otf eot"

for file in "${FILTERED_FILES[@]}"; do
  ext="${file##*.}"
  if echo "$BINARY_EXTS" | grep -wiq "$ext"; then
    ((binary_files_skipped+=1))
    continue
  fi

  if ! grep -Iq . "$file"; then
    ((binary_files_skipped+=1))
    continue
  fi

  echo "----- FILE: $file -----"
  if [[ -n "$MAX_LINES" ]]; then
    total_lines=$(wc -l < "$file")
    if (( total_lines > MAX_LINES )); then
      head -n "$MAX_LINES" "$file"
      echo "... [truncated: showing $MAX_LINES of $total_lines lines] ..."
      ((files_truncated+=1))
    else
      cat "$file"
    fi
  else
    cat "$file"
  fi
  echo
  ((files_shown+=1))
done

echo "=========="
echo "Profile: $PROFILE_NAME"
if (( CATIGNORE_COUNT > 0 )); then
  echo ".catignore patterns loaded: $CATIGNORE_COUNT"
fi
echo "Files shown: $files_shown"
if [[ -n "$MAX_LINES" ]] && (( files_truncated > 0 )); then
  echo "Files truncated: $files_truncated"
fi
echo "Files ignored: $ignored_files"
echo "Binary files skipped: $binary_files_skipped"
