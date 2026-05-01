package walker_test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/sevensteves/cat-folder/internal/filter"
	"github.com/sevensteves/cat-folder/internal/walker"
)

func newFilter(t *testing.T) *filter.Filter {
	t.Helper()
	f, _, err := filter.New([]string{"default"}, nil, t.TempDir(), false)
	if err != nil {
		t.Fatalf("filter.New() error: %v", err)
	}
	return f
}

func TestWalk_BasicFiles(t *testing.T) {
	dir := t.TempDir()
	write(t, filepath.Join(dir, "main.go"), "package main\n")
	write(t, filepath.Join(dir, "README.md"), "# hello\n")

	files, stats, err := walker.Walk(walker.Options{Root: dir, Filter: newFilter(t)})
	if err != nil {
		t.Fatalf("Walk() error: %v", err)
	}
	if stats.Shown != 2 {
		t.Errorf("Shown = %d, want 2", stats.Shown)
	}
	if len(files) != 2 {
		t.Errorf("len(files) = %d, want 2", len(files))
	}
}

func TestWalk_SkipsGitDir(t *testing.T) {
	dir := t.TempDir()
	write(t, filepath.Join(dir, "main.go"), "package main\n")
	if err := os.MkdirAll(filepath.Join(dir, ".git"), 0755); err != nil {
		t.Fatal(err)
	}
	write(t, filepath.Join(dir, ".git", "config"), "[core]\n")

	files, _, err := walker.Walk(walker.Options{Root: dir, Filter: newFilter(t)})
	if err != nil {
		t.Fatalf("Walk() error: %v", err)
	}
	for _, f := range files {
		if strings.HasPrefix(f.RelPath, ".git") {
			t.Errorf("Walk() included .git file: %s", f.RelPath)
		}
	}
}

func TestWalk_Truncation(t *testing.T) {
	dir := t.TempDir()
	content := ""
	for i := 0; i < 100; i++ {
		content += "line\n"
	}
	write(t, filepath.Join(dir, "big.go"), content)

	files, stats, err := walker.Walk(walker.Options{Root: dir, Filter: newFilter(t), MaxLines: 10})
	if err != nil {
		t.Fatalf("Walk() error: %v", err)
	}
	if stats.Truncated != 1 {
		t.Errorf("Truncated = %d, want 1", stats.Truncated)
	}
	if len(files[0].Lines) != 10 {
		t.Errorf("lines after truncation = %d, want 10", len(files[0].Lines))
	}
	if !files[0].Truncated {
		t.Error("expected file.Truncated = true")
	}
}

func write(t *testing.T, path, content string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		t.Fatal(err)
	}
}
