# cat-folder

Bash script to print directory tree and file contents, ignoring `.git` and respecting `.gitignore` rules.

## Features

- Shows a clean ASCII directory tree.
- Always ignores `.git` directories.
- Respects `.gitignore` if present (uses `git ls-files`).
- Prints the contents of all non-ignored files.

## Installation

Quick install to your `~/bin` directory:

```bash
curl -s https://raw.githubusercontent.com/sevensteves/cat-folder/main/cat-folder.sh -o ~/bin/cat-folder
chmod +x ~/bin/cat-folder
````

Make sure `~/bin` is on your `$PATH`. If not, add this to your shell config (`~/.bashrc` or `~/.zshrc`):

```bash
export PATH="$HOME/bin:$PATH"
```

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
