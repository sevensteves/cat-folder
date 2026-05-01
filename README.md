# cat-folder

Dump any codebase into your clipboard — ready to paste into an LLM.

One command. Clean tree + file contents. Noise filtered out automatically so the model sees signal, not lock files.

---

## Why cat-folder?

You already copy-paste code into ChatGPT or Claude. `cat-folder` makes that instant — and smart.

**No lock files.** The `web` profile strips `node_modules`, lock files, and build output automatically.

**No context blown on noise.** `--max-lines` keeps huge files in view without eating your token budget.

**No setup per project.** Drop a `.catignore` next to `.gitignore` and it just works, every run.

**Always accurate.** Walks the real filesystem — no stale snapshots, no git staging surprises.

---

## Installation

macOS and Linux — one line:

```bash
curl -s https://raw.githubusercontent.com/sevensteves/cat-folder/main/install.sh | bash
```

Installs to the right place automatically — Homebrew on macOS, `/usr/local/bin` on Linux.

Prefer manual? Grab a binary from the [Releases page](https://github.com/sevensteves/cat-folder/releases) or:

```bash
go install github.com/sevensteves/cat-folder@latest
```

Then run it:

```bash
cat-folder --profile web .
```

---

## Usage

```bash
cat-folder [OPTIONS] <path>
```

### Options

| Flag | Description |
|------|-------------|
| `--profile <name>` | `web` \| `boilerplate` \| `default` (repeatable) |
| `--max-lines <n>` | Truncate files longer than n lines |
| `--ignore <pattern>` | Extra glob to exclude (repeatable) |
| `--no-catignore` | Skip `.catignore` even if present |
| `--version` | Print version |
| `-h, --help` | Print usage |

---

## Profiles

`default` — no extra filtering, original behavior.

`web` — strips common web project noise:

- **Directories:** `node_modules`, `.next`, `.nuxt`, `dist`, `build`, `out`, `.output`, `.cache`, `.turbo`, `coverage`, `__pycache__`, `.venv`, `venv`
- **Lock files:** `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb`, `poetry.lock`, and more
- **Generated:** `*.min.js`, `*.min.css`, `*.map`, `*.tsbuildinfo`
- **Noise:** `*.log`, `.DS_Store`, `.env.local`

`boilerplate` — strips Next.js and framework boilerplate:

- `next-env.d.ts`, `*.snap`, `*.generated.ts`, `*.generated.tsx`, `__generated__`, `storybook-static`
- Default framework SVGs (`public/next.svg`, `public/vercel.svg`, etc.)

Profiles are composable — stack them:

```bash
cat-folder --profile web --profile boilerplate .
```

---

## .catignore

Drop a `.catignore` in your project root to define reusable per-project exclusions. Loaded automatically on every run unless you pass `--no-catignore`.

Syntax follows `.gitignore` basics — blank lines and `#` comments are ignored, every other line is a glob pattern.

```gitignore
# test and story noise
__tests__
*.stories.tsx
src/generated
```

---

## Examples

```bash
# Paste a whole project into Claude
cat-folder --profile web . | pbcopy

# Keep huge files without blowing context
cat-folder --profile web --max-lines 200 .

# One-off exclusions without touching the repo
cat-folder --profile web --ignore "*.snap" --ignore "storybook-static" .

# Combine profiles and truncation
cat-folder --profile web --profile boilerplate --max-lines 150 .

# Skip .catignore for a clean run
cat-folder --profile default --no-catignore .
```

---

## Example output

```
===== Directory Tree for . =====
|-- src
|   |-- main.ts
|   `-- utils.ts
`-- README.md
==========================================

----- FILE: README.md -----
# Example Project

----- FILE: src/main.ts -----
console.log('hello')

==========================================
Summary:
  Profiles : web
  Shown    : 2 file(s)
  Ignored  : 5 file(s) (profile/catignore rules)
  Binary   : 0 file(s) skipped
==========================================
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Bug reports and PRs are welcome.
