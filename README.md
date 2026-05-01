# cat-folder

**Dump your codebase into your clipboard — filtered, truncated, and ready for LLMs.**

```bash
# Install, then copy your web project in one go
curl -s https://raw.githubusercontent.com/sevensteves/cat-folder/main/install.sh | bash
cat-folder --profile web . | pbcopy
```

`cat-folder` bridges the gap between your local files and ChatGPT/Claude. It generates a clean ASCII tree followed by file contents, automatically stripping noise like `node_modules` or lock files so you don't waste tokens.

---

## Quick start

### 1. Install

```bash
curl -s https://raw.githubusercontent.com/sevensteves/cat-folder/main/install.sh | bash
```

Installs to the right place automatically — Homebrew on macOS, `/usr/local/bin` on Linux. Prefer manual? Grab a binary from the [Releases page](https://github.com/sevensteves/cat-folder/releases) or `go install github.com/sevensteves/cat-folder@latest`.

### 2. Run it

| Goal | Command |
| :--- | :--- |
| Copy everything | `cat-folder . \| pbcopy` |
| Web project (strips noise) | `cat-folder --profile web . \| pbcopy` |
| Keep huge files in view | `cat-folder --profile web --max-lines 200 .` |
| One-off exclusions | `cat-folder --profile web --ignore "*.snap" .` |
| Combine profiles | `cat-folder --profile web --profile boilerplate .` |

---

## Options

```
cat-folder [OPTIONS] <path>
```

| Flag | Description |
|------|-------------|
| `--profile <name>` | `web` \| `boilerplate` \| `default` — repeatable |
| `--max-lines <n>` | Truncate files longer than n lines |
| `--ignore <pattern>` | Extra glob to exclude — repeatable |
| `--no-catignore` | Skip `.catignore` even if present |
| `--version` | Print version |
| `-h, --help` | Print usage |

---

## Profiles

| Profile | What it strips |
|---------|---------------|
| `default` | Nothing — original behavior |
| `web` | `node_modules`, lock files, build output, generated assets |
| `boilerplate` | Next.js boilerplate, snapshots, generated types, Storybook |

Profiles are composable: `cat-folder --profile web --profile boilerplate .`

<details>
<summary><code>web</code> — full pattern list</summary>

**Directories:** `node_modules`, `.next`, `.nuxt`, `dist`, `build`, `out`, `.output`, `.cache`, `.turbo`, `coverage`, `__pycache__`, `.venv`, `venv`

**Lock files:** `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb`, `poetry.lock`, and more

**Generated:** `*.min.js`, `*.min.css`, `*.map`, `*.tsbuildinfo`

**Noise:** `*.log`, `.DS_Store`, `.env.local`

</details>

<details>
<summary><code>boilerplate</code> — full pattern list</summary>

`next-env.d.ts`, `*.snap`, `*.generated.ts`, `*.generated.tsx`, `__generated__`, `storybook-static`, `public/next.svg`, `public/vercel.svg`, and other default framework SVGs

</details>

---

## .catignore

Drop a `.catignore` in your project root for per-project exclusions. Loaded automatically every run unless you pass `--no-catignore`. Syntax follows `.gitignore` — blank lines and `#` comments are ignored.

```gitignore
# test and story noise
__tests__
*.stories.tsx
src/generated
```

---

## Examples

```bash
# Paste a whole project into Claude (macOS)
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

----- FILE: src/main.ts -----
console.log('hello')
# ... rest of file

==========================================
Summary:
  Profiles : web
  Shown    : 2 file(s)
  Ignored  : 5 file(s) (profile/catignore rules)
==========================================
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Bug reports and PRs are welcome.
