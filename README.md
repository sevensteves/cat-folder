# cat-folder

`cat-folder` prints a directory tree and file contents to stdout so you can pipe a project snapshot into the clipboard and paste it into an LLM chat. It always ignores `.git`, respects `.gitignore` when present, and now supports reusable exclusion profiles, per-project `.catignore` rules, and optional file truncation.

## Features

- Shows a clean ASCII directory tree.
- Respects `.gitignore` when present by using `git ls-files`.
- Supports baked-in profiles with `--profile`.
- Loads project-specific ignore globs from `.catignore` by default.
- Lets you stack repeatable `--ignore` globs at runtime.
- Truncates long files with `--max-lines` instead of dropping them entirely.
- Prints a summary footer with shown, truncated, ignored, and skipped counts.

## Installation

You can install `cat-folder` with a single command:

```bash
curl -s https://raw.githubusercontent.com/sevensteves/cat-folder/main/install.sh | bash
```

The script will automatically:
- Install to `/opt/homebrew/bin` on macOS with Homebrew
- Install to `/usr/local/bin` on other macOS or Linux systems
- Fall back to `$HOME/.local/bin` if other locations aren't accessible

## Usage

```bash
cat-folder [OPTIONS] <path>
```

### Options

```bash
--profile <name>     web | default  (default: default)
--max-lines <n>      truncate files longer than n lines
--ignore <pattern>   extra glob to exclude (repeatable)
--no-catignore       skip .catignore even if present
-h, --help           print usage
```

### Profiles

`default` keeps the original behavior and adds no extra filtering.

`web` excludes common web-project noise:

- Directories: `node_modules`, `.next`, `.nuxt`, `dist`, `build`, `out`, `.output`, `.cache`, `.parcel-cache`, `.turbo`, `coverage`, `.nyc_output`, `__pycache__`, `.pytest_cache`, `.venv`, `venv`
- Lock files: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb`, `composer.lock`, `Gemfile.lock`, `Pipfile.lock`, `poetry.lock`
- Generated files: `*.min.js`, `*.min.css`, `*.map`
- Noise: `*.log`, `.DS_Store`, `Thumbs.db`, `.env.local`, `.env.*.local`

Example:

```bash
cat-folder --profile web /path/to/project
```

### `.catignore`

If the target directory contains a `.catignore` file, `cat-folder` loads it automatically on every run unless you pass `--no-catignore`.

Syntax matches the basics of `.gitignore`:

- Blank lines are ignored.
- Lines starting with `#` are treated as comments.
- Every other line is treated as a glob pattern.

Example `.catignore`:

```gitignore
# test and story noise
__tests__
*.stories.tsx
src/generated
```

The `.catignore` file itself is never printed.

### Extra one-off ignores

Use `--ignore` to add extra globs without changing the repo:

```bash
cat-folder --profile web --ignore "*.snap" --ignore "docs/generated" /path/to/project
```

### Truncating long files

Use `--max-lines` to keep the top of long files and append a truncation note:

```bash
cat-folder --profile web --max-lines 200 /path/to/project
```

For a file longer than the limit, the output ends with:

```text
... [truncated: showing N of TOTAL lines] ...
```

### Summary footer

After printing files, `cat-folder` reports:

- Active profile
- Number of `.catignore` patterns loaded, if any
- Files shown
- Files truncated, if `--max-lines` was used and truncation occurred
- Files ignored by profile or `.catignore` rules
- Binary files skipped

## Examples

```bash
cat-folder .
cat-folder --profile web .
cat-folder --profile web --max-lines 150 .
cat-folder --profile web --ignore "*.snap" --ignore "storybook-static" .
cat-folder --profile default --no-catignore .
```

## Example Output

```text
===== Directory Tree =====
README.md
src
|-- main.ts
`-- utils.ts
==========

----- FILE: README.md -----
# Example Project

----- FILE: src/main.ts -----
console.log('hello')

==========
Profile: web
.catignore patterns loaded: 2
Files shown: 2
Files ignored: 5
Binary files skipped: 0
```
