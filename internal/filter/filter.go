package filter

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

var Profiles = map[string][]string{
	"default": {},
	"web": {
		"node_modules", ".next", ".nuxt", "dist", "build", "out", ".output", ".cache",
		".parcel-cache", ".turbo", "coverage", ".nyc_output", "__pycache__",
		".pytest_cache", ".venv", "venv",
		"package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb",
		"composer.lock", "Gemfile.lock", "Pipfile.lock", "poetry.lock",
		"*.min.js", "*.min.css", "*.map",
		"*.log", ".DS_Store", "Thumbs.db", ".env.local", ".env.*.local",
		"*.tsbuildinfo",
	},
	"boilerplate": {
		"next-env.d.ts",
		"db/migrations/meta", "*/migrations/meta",
		"*.snap",
		"*.generated.ts", "*.generated.tsx",
		"__generated__",
		"storybook-static",
		"public/next.svg", "public/vercel.svg", "public/file.svg", "public/globe.svg", "public/window.svg",
	},
}

type Filter struct {
	patterns []string
}

type UnknownProfileError struct {
	Name string
}

func (e UnknownProfileError) Error() string {
	var names []string
	for name := range Profiles {
		names = append(names, name)
	}
	sort.Strings(names)
	return fmt.Sprintf("unknown profile %q; available: %s", e.Name, strings.Join(names, ", "))
}

func New(profiles []string, extra []string, root string, useCatignore bool, useGitignore bool) (*Filter, int, int, error) {
	var allPatterns []string

	// Accumulate patterns from all profiles
	for _, profile := range profiles {
		patterns, ok := Profiles[profile]
		if !ok {
			return nil, 0, 0, UnknownProfileError{Name: profile}
		}
		allPatterns = append(allPatterns, patterns...)
	}

	// Append patterns from extra ignores
	allPatterns = append(allPatterns, extra...)

	catignoreCount := 0
	if useCatignore {
		catignorePatterns, err := loadCatignore(filepath.Join(root, ".catignore"))
		if err == nil {
			catignoreCount = len(catignorePatterns)
			allPatterns = append(allPatterns, catignorePatterns...)
		} else if !os.IsNotExist(err) {
			return nil, 0, 0, err
		}
	}

	gitignoreCount := 0
	if useGitignore {
		gitignorePatterns, err := loadCatignore(filepath.Join(root, ".gitignore"))
		if err == nil {
			gitignoreCount = len(gitignorePatterns)
			allPatterns = append(allPatterns, gitignorePatterns...)
		} else if !os.IsNotExist(err) {
			return nil, 0, 0, err
		}
	}

	return &Filter{patterns: allPatterns}, catignoreCount, gitignoreCount, nil
}

func (f *Filter) Ignored(relPath string) bool {
	// Normalize to forward slashes
	relPath = filepath.ToSlash(relPath)

	for _, pattern := range f.patterns {
		// Handle directory-only patterns (ending with /)
		if strings.HasSuffix(pattern, "/") {
			dirPattern := strings.TrimSuffix(pattern, "/")

			// Basename match for directory pattern
			if match, _ := filepath.Match(dirPattern, filepath.Base(relPath)); match {
				return true
			}

			// Full path match for directory pattern
			if match, _ := filepath.Match(dirPattern, relPath); match {
				return true
			}

			// Any path segment match for directory pattern
			parts := strings.Split(relPath, "/")
			for _, part := range parts {
				if match, _ := filepath.Match(dirPattern, part); match {
					return true
				}
			}

			continue
		}

		// Basename match
		if match, _ := filepath.Match(pattern, filepath.Base(relPath)); match {
			return true
		}

		// Full path match
		if match, _ := filepath.Match(pattern, relPath); match {
			return true
		}

		// Any path segment match
		parts := strings.Split(relPath, "/")
		for _, part := range parts {
			if match, _ := filepath.Match(pattern, part); match {
				return true
			}
		}
	}

	return false
}

func loadCatignore(path string) ([]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var patterns []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		patterns = append(patterns, line)
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return patterns, nil
}
