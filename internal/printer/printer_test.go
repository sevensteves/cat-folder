package printer_test

import (
	"bytes"
	"strings"
	"testing"

	"github.com/sevensteves/cat-folder/internal/printer"
	"github.com/sevensteves/cat-folder/internal/walker"
)

func files(paths ...string) []walker.File {
	out := make([]walker.File, len(paths))
	for i, p := range paths {
		out[i] = walker.File{RelPath: p, Lines: []string{"line1", "line2"}}
	}
	return out
}

func TestTree_ContainsPaths(t *testing.T) {
	var buf bytes.Buffer
	opts := printer.Options{Root: ".", Out: &buf}
	printer.Tree(files("src/main.go", "README.md"), opts)

	out := buf.String()
	for _, want := range []string{"src", "main.go", "README.md"} {
		if !strings.Contains(out, want) {
			t.Errorf("Tree() output missing %q", want)
		}
	}
}

func TestFiles_ContentsAndPaths(t *testing.T) {
	var buf bytes.Buffer
	opts := printer.Options{Root: ".", Out: &buf}
	printer.Files(files("main.go"), opts)

	out := buf.String()
	if !strings.Contains(out, "main.go") {
		t.Error("Files() output missing filename")
	}
	if !strings.Contains(out, "line1") {
		t.Error("Files() output missing file content")
	}
}

func TestFiles_TruncationNote(t *testing.T) {
	var buf bytes.Buffer
	opts := printer.Options{Root: ".", MaxLines: 5, Out: &buf}
	f := walker.File{RelPath: "big.go", Lines: []string{"a"}, Truncated: true, TotalLines: 100}
	printer.Files([]walker.File{f}, opts)

	if !strings.Contains(buf.String(), "truncated") {
		t.Error("Files() did not print truncation note")
	}
}

func TestSummary_ShowsStats(t *testing.T) {
	var buf bytes.Buffer
	opts := printer.Options{Root: ".", Profiles: []string{"web"}, Out: &buf}
	stats := walker.Stats{Shown: 3, Ignored: 5, Binary: 1}
	printer.Summary(files("a.go", "b.go", "c.go"), stats, opts)

	out := buf.String()
	for _, want := range []string{"web", "3 file(s)", "5 file(s)", "1 file(s)"} {
		if !strings.Contains(out, want) {
			t.Errorf("Summary() output missing %q", want)
		}
	}
}
