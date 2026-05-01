# Branch strategy

## Long-lived branches

| Branch | Purpose |
|--------|---------|
| `main` | Always releasable. Tags cut from here trigger releases via GoReleaser. |

## Short-lived branches

| Prefix | Use for |
|--------|---------|
| `feature/*` | New functionality |
| `fix/*` | Bug fixes |
| `chore/*` | Deps, tooling, CI |
| `docs/*` | Documentation only |

Branch from `main`, keep focused on one concern, delete after merge.

## Naming examples

```
feature/homebrew-tap
fix/windows-path-separator
chore/add-golangci-lint
docs/contributing-setup
```

## Commit messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add --output flag
fix: normalize Windows path separators in filter
chore: add golangci-lint to CI
docs: add branch strategy
```

Prefixes `docs:`, `test:`, `chore:` are excluded from the release changelog automatically by GoReleaser.

## Merging

- Squash merge for `feature/*`, `fix/*`, `docs/*` — keeps `main` history linear
- Merge commit for `chore/*` when commit history is meaningful (e.g. dep bumps)
- Delete branch after merge

## Releases

Tag `main` with a semver tag to trigger a release:

```bash
git tag v0.2.0
git push origin v0.2.0
```

GoReleaser builds binaries for all platforms and publishes a GitHub Release automatically.
