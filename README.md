# cat-folder

Bash script to print directory tree and file contents, ignoring `.git` and respecting `.gitignore` rules.

## Features

- Shows a clean ASCII directory tree.
- Always ignores `.git` directories.
- Respects `.gitignore` if present (uses `git ls-files`).
- Prints the contents of all non-ignored files.

## Installation

You can install `cat-folder` system-wide with:

```bash
curl -s https://raw.githubusercontent.com/sevensteves/cat-folder/main/install.sh | bash
````

The script will place `cat-folder` into `/usr/local/bin` on Linux, or `/opt/homebrew/bin` on macOS if it exists.
Both of these locations are typically already on your `$PATH`.

## Usage

```bash
cat-folder /path/to/dir
```

## Example Output

```
===== Directory Tree for my-project =====
my-project
|-- README.md
|-- src
|   |-- main.py
|   `-- utils.py
`-- requirements.txt
==========================================

----- FILE: my-project/README.md -----
# My Project
This is an example repo.
```
