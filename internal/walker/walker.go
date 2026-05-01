package walker

import (
	"bytes"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"github.com/sevensteves/cat-folder/internal/filter"
)

type File struct {
	RelPath    string
	Lines      []string
	Truncated  bool
	TotalLines int
}

type Stats struct {
	Shown     int
	Ignored   int
	Binary    int
	Truncated int
}

type Options struct {
	Root     string
	Filter   *filter.Filter
	MaxLines int // 0 = unlimited
}

var binaryExtensions = map[string]bool{
	".png": true, ".jpg": true, ".jpeg": true, ".gif": true, ".bmp": true, ".ico": true, ".webp": true,
	".exe": true, ".dll": true, ".so": true, ".bin": true,
	".pdf": true, ".zip": true, ".gz": true, ".tar": true, ".tgz": true, ".xz": true, ".7z": true,
	".mp3": true, ".mp4": true, ".mov": true, ".avi": true, ".mkv": true,
	".woff": true, ".woff2": true, ".ttf": true, ".otf": true, ".eot": true,
	".pyc": true, ".pyo": true,
}

func Walk(opts Options) ([]File, Stats, error) {
	var files []File
	stats := Stats{}

	err := filepath.WalkDir(opts.Root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		rel, err := filepath.Rel(opts.Root, path)
		if err != nil {
			return err
		}

		// Skip .git directories
		if d.IsDir() && d.Name() == ".git" {
			return filepath.SkipDir
		}

		// Never print .catignore file
		if !d.IsDir() && d.Name() == ".catignore" {
			stats.Ignored++
			return nil
		}

		if d.IsDir() {
			// Check if directory should be ignored
			if opts.Filter.Ignored(rel) {
				stats.Ignored++
				return filepath.SkipDir
			}
			return nil
		}

		// It's a file
		if opts.Filter.Ignored(rel) {
			stats.Ignored++
			return nil
		}

		// Check if binary by extension
		if isBinaryByExtension(d.Name()) {
			stats.Binary++
			return nil
		}

		// Read file content
		content, err := os.ReadFile(path)
		if err != nil {
			fmt.Fprintf(os.Stderr, "warning: could not read %s: %v\n", rel, err)
			stats.Binary++
			return nil
		}

		// Check if binary by content
		if isBinaryByContent(content) {
			stats.Binary++
			return nil
		}

		// Split lines: normalize \r\n to \n first
		contentStr := string(content)
		contentStr = strings.ReplaceAll(contentStr, "\r\n", "\n")
		lines := strings.Split(contentStr, "\n")

		// Remove trailing empty line if file ends with newline
		if len(lines) > 0 && lines[len(lines)-1] == "" {
			lines = lines[:len(lines)-1]
		}

		truncated := false
		totalLines := len(lines)
		if opts.MaxLines > 0 && len(lines) > opts.MaxLines {
			lines = lines[:opts.MaxLines]
			truncated = true
			stats.Truncated++
		}

		files = append(files, File{
			RelPath:    filepath.ToSlash(rel),
			Lines:      lines,
			Truncated:  truncated,
			TotalLines: totalLines,
		})
		stats.Shown++

		return nil
	})

	if err != nil {
		return nil, stats, err
	}

	return files, stats, nil
}

func isBinaryByExtension(filename string) bool {
	ext := strings.ToLower(filepath.Ext(filename))
	return binaryExtensions[ext]
}

func isBinaryByContent(content []byte) bool {
	// Read first 8192 bytes
	buf := content
	if len(buf) > 8192 {
		buf = buf[:8192]
	}
	// Check for null byte
	return bytes.IndexByte(buf, 0) != -1
}
