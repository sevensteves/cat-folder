# Contributing to cat-folder

Thanks for your interest. Here's everything you need to get started.

## Dev setup

Requires Go 1.22+.

```bash
git clone https://github.com/sevensteves/cat-folder
cd cat-folder
go build -o cat-folder .
./cat-folder --profile web .
```

## Running tests

```bash
go test ./...
```

Tests live next to the package they cover (`filter_test.go`, `walker_test.go`). Table-driven tests are preferred.

## How profiles work

Profiles are defined in `internal/filter/filter.go` in the `Profiles` map. Each profile is a slice of glob patterns matched against relative file paths. Patterns are matched against the basename, the full relative path, and each path segment — so `node_modules` excludes at any depth.

To add a profile, add an entry to `Profiles` and add it to the `--profile` flag documentation in `main.go` and `README.md`.

## Submitting changes

1. Fork the repo and create a branch from `main`
2. Make your changes with tests where applicable
3. Run `go test ./...` and `go vet ./...`
4. Open a PR with a clear description of what changed and why

## Commit style

Conventional commits are preferred:

```
feat: add --output flag to write directly to file
fix: normalize Windows path separators in filter
docs: update profile table in README
```

Commits prefixed with `docs:`, `test:`, or `chore:` are excluded from the changelog automatically.
