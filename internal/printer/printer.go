package printer

import (
	"fmt"
	"io"
	"sort"
	"strings"

	"github.com/sevensteves/cat-folder/internal/walker"
)

type Options struct {
	Root           string
	Profiles       []string
	CatignoreCount int
	MaxLines       int
	Out            io.Writer
}

type treeNode struct {
	name     string
	isFile   bool
	children map[string]*treeNode
}

func Tree(files []walker.File, opts Options) {
	fmt.Fprintf(opts.Out, "===== Directory Tree for %s =====\n", opts.Root)

	// Build tree from file paths
	root := &treeNode{
		name:     opts.Root,
		isFile:   false,
		children: make(map[string]*treeNode),
	}

	for _, file := range files {
		parts := strings.Split(file.RelPath, "/")
		current := root
		for i, part := range parts {
			if current.children[part] == nil {
				current.children[part] = &treeNode{
					name:     part,
					isFile:   i == len(parts)-1,
					children: make(map[string]*treeNode),
				}
			}
			current = current.children[part]
		}
	}

	// Render tree
	renderNode(opts.Out, root, "", true)

	fmt.Fprintf(opts.Out, "==========================================\n\n")
}

func renderNode(w io.Writer, node *treeNode, prefix string, isRoot bool) {
	if !isRoot {
		fmt.Fprintf(w, "%s\n", node.name)
	}

	// Sort children: directories first, then files
	var dirs []string
	var fileNames []string
	for name, child := range node.children {
		if child.isFile {
			fileNames = append(fileNames, name)
		} else {
			dirs = append(dirs, name)
		}
	}
	sort.Strings(dirs)
	sort.Strings(fileNames)

	allKeys := append(dirs, fileNames...)

	for i, key := range allKeys {
		child := node.children[key]
		isLast := i == len(allKeys)-1

		var connector string
		var newPrefix string
		if isLast {
			connector = "`-- "
			newPrefix = prefix + "    "
		} else {
			connector = "|-- "
			newPrefix = prefix + "|   "
		}

		fmt.Fprintf(w, "%s%s", prefix, connector)

		if !child.isFile && len(child.children) > 0 {
			renderNode(w, child, newPrefix, false)
		} else {
			fmt.Fprintf(w, "%s\n", child.name)
		}
	}
}

func Files(files []walker.File, opts Options) {
	for _, file := range files {
		fmt.Fprintf(opts.Out, "----- FILE: %s -----\n", file.RelPath)
		for _, line := range file.Lines {
			fmt.Fprintf(opts.Out, "%s\n", line)
		}
		if file.Truncated {
			fmt.Fprintf(opts.Out, "... [truncated: showing %d of %d lines] ...\n", len(file.Lines), file.TotalLines)
		}
		fmt.Fprintf(opts.Out, "\n")
	}
}

func Summary(files []walker.File, stats walker.Stats, opts Options) {
	fmt.Fprintf(opts.Out, "==========================================\n")
	fmt.Fprintf(opts.Out, "Summary:\n")
	fmt.Fprintf(opts.Out, "  Profiles : %s\n", strings.Join(opts.Profiles, ", "))
	if opts.CatignoreCount > 0 {
		fmt.Fprintf(opts.Out, "  .catignore: %d pattern(s) loaded\n", opts.CatignoreCount)
	}
	fmt.Fprintf(opts.Out, "  Shown    : %d file(s)\n", stats.Shown)
	if opts.MaxLines > 0 && stats.Truncated > 0 {
		fmt.Fprintf(opts.Out, "  Truncated: %d file(s) at %d lines\n", stats.Truncated, opts.MaxLines)
	}
	fmt.Fprintf(opts.Out, "  Ignored  : %d file(s) (profile/catignore rules)\n", stats.Ignored)
	if stats.Binary > 0 {
		fmt.Fprintf(opts.Out, "  Binary   : %d file(s) skipped\n", stats.Binary)
	}
	fmt.Fprintf(opts.Out, "==========================================\n")
}
