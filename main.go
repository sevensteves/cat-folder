package main

import (
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"

	"github.com/sevensteves/cat-folder/internal/filter"
	"github.com/sevensteves/cat-folder/internal/printer"
	"github.com/sevensteves/cat-folder/internal/walker"
)

var version = "dev"

func main() {
	args := os.Args[1:]

	var profiles []string
	var extraIgnores []string
	useCatignore := true
	var maxLines int
	var targetDir string

	for i := 0; i < len(args); i++ {
		arg := args[i]

		if arg == "--version" {
			fmt.Printf("cat-folder %s\n", version)
			os.Exit(0)
		}

		if arg == "-h" || arg == "--help" {
			printUsage(os.Stdout)
			os.Exit(0)
		}

		if strings.HasPrefix(arg, "--profile=") {
			profiles = append(profiles, strings.TrimPrefix(arg, "--profile="))
			continue
		}

		if arg == "--profile" {
			if i+1 >= len(args) {
				fmt.Fprintf(os.Stderr, "error: --profile requires a value\n")
				os.Exit(1)
			}
			i++
			profiles = append(profiles, args[i])
			continue
		}

		if strings.HasPrefix(arg, "--max-lines=") {
			n, err := strconv.Atoi(strings.TrimPrefix(arg, "--max-lines="))
			if err != nil || n <= 0 {
				fmt.Fprintf(os.Stderr, "error: --max-lines must be a positive integer\n")
				os.Exit(1)
			}
			maxLines = n
			continue
		}

		if arg == "--max-lines" {
			if i+1 >= len(args) {
				fmt.Fprintf(os.Stderr, "error: --max-lines requires a value\n")
				os.Exit(1)
			}
			i++
			n, err := strconv.Atoi(args[i])
			if err != nil || n <= 0 {
				fmt.Fprintf(os.Stderr, "error: --max-lines must be a positive integer\n")
				os.Exit(1)
			}
			maxLines = n
			continue
		}

		if strings.HasPrefix(arg, "--ignore=") {
			extraIgnores = append(extraIgnores, strings.TrimPrefix(arg, "--ignore="))
			continue
		}

		if arg == "--ignore" {
			if i+1 >= len(args) {
				fmt.Fprintf(os.Stderr, "error: --ignore requires a value\n")
				os.Exit(1)
			}
			i++
			extraIgnores = append(extraIgnores, args[i])
			continue
		}

		if arg == "--no-catignore" {
			useCatignore = false
			continue
		}

		if strings.HasPrefix(arg, "-") {
			fmt.Fprintf(os.Stderr, "error: unknown flag %s\n", arg)
			os.Exit(1)
		}

		if targetDir != "" {
			fmt.Fprintf(os.Stderr, "error: only one positional argument (target directory) allowed\n")
			os.Exit(1)
		}
		targetDir = arg
	}

	if targetDir == "" {
		printUsage(os.Stderr)
		os.Exit(1)
	}

	// Default to "default" profile if none specified
	if len(profiles) == 0 {
		profiles = []string{"default"}
	}

	// Create filter
	f, catignoreCount, err := filter.New(profiles, extraIgnores, targetDir, useCatignore)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	// Walk directory
	files, stats, err := walker.Walk(walker.Options{
		Root:     targetDir,
		Filter:   f,
		MaxLines: maxLines,
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	// Print output
	printerOpts := printer.Options{
		Root:           targetDir,
		Profiles:       profiles,
		CatignoreCount: catignoreCount,
		MaxLines:       maxLines,
		Out:            os.Stdout,
	}

	printer.Tree(files, printerOpts)
	printer.Files(files, printerOpts)
	printer.Summary(files, stats, printerOpts)

	os.Exit(0)
}

func printUsage(w io.Writer) {
	fmt.Fprintf(w, `Usage: cat-folder [OPTIONS] <path>

Options:
  --profile <name>     profile name (repeatable; default: default)
  --max-lines <n>      truncate files longer than n lines
  --ignore <pattern>   extra glob to exclude (repeatable)
  --no-catignore       skip .catignore even if present
  --version            print version
  -h, --help           print this message
`)
}
