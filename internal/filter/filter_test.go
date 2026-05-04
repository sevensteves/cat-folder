package filter_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/sevensteves/cat-folder/internal/filter"
)

func TestIgnored_ProfileWeb_NodeModules(t *testing.T) {
	f, _, _, err := filter.New([]string{"web"}, nil, t.TempDir(), false, false)
	if err != nil {
		t.Fatalf("New() error: %v", err)
	}

	cases := []struct {
		path string
		want bool
	}{
		{"node_modules/lodash/index.js", true},
		{"src/index.ts", false},
		{"yarn.lock", true},
		{"dist/bundle.js", true},
		{"README.md", false},
	}

	for _, tc := range cases {
		got := f.Ignored(tc.path)
		if got != tc.want {
			t.Errorf("Ignored(%q) = %v, want %v", tc.path, got, tc.want)
		}
	}
}

func TestIgnored_Catignore(t *testing.T) {
	dir := t.TempDir()
	catignore := filepath.Join(dir, ".catignore")
	if err := os.WriteFile(catignore, []byte("*.stories.tsx\n__tests__\n"), 0644); err != nil {
		t.Fatal(err)
	}

	f, count, _, err := filter.New([]string{"default"}, nil, dir, true, false)
	if err != nil {
		t.Fatalf("New() error: %v", err)
	}
	if count != 2 {
		t.Errorf("catignore pattern count = %d, want 2", count)
	}

	if !f.Ignored("Button.stories.tsx") {
		t.Error("expected Button.stories.tsx to be ignored")
	}
	if !f.Ignored("__tests__/button_test.ts") {
		t.Error("expected __tests__/button_test.ts to be ignored")
	}
	if f.Ignored("Button.tsx") {
		t.Error("expected Button.tsx not to be ignored")
	}
}

func TestUnknownProfile(t *testing.T) {
	_, _, _, err := filter.New([]string{"nonexistent"}, nil, t.TempDir(), false, false)
	if err == nil {
		t.Fatal("expected error for unknown profile, got nil")
	}
}

func TestIgnored_Gitignore(t *testing.T) {
	dir := t.TempDir()
	gitignore := filepath.Join(dir, ".gitignore")
	if err := os.WriteFile(gitignore, []byte("*.log\ndist\n"), 0644); err != nil {
		t.Fatal(err)
	}

	f, _, count, err := filter.New([]string{"default"}, nil, dir, false, true)
	if err != nil {
		t.Fatalf("New() error: %v", err)
	}
	if count != 2 {
		t.Errorf("gitignore pattern count = %d, want 2", count)
	}

	if !f.Ignored("app.log") {
		t.Error("expected app.log to be ignored")
	}
	if !f.Ignored("dist/bundle.js") {
		t.Error("expected dist/bundle.js to be ignored")
	}
	if f.Ignored("main.go") {
		t.Error("expected main.go not to be ignored")
	}
}
