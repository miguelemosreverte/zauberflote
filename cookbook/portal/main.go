package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

type Entry struct {
	Title      string `json:"title"`
	URL        string `json:"url"`
	HtmlPath   string `json:"html_path,omitempty"`
	ElixirPath string `json:"elixir_path,omitempty"`
}

type Chapter struct {
	Title   string  `json:"title"`
	Entries []Entry `json:"entries"`
}

type RefDoc struct {
	Title string `json:"title"`
	ID    string `json:"id"`
}

// extractChapterNum extracts the chapter number from a directory name like "chapter-10-realtime"
// Returns -1 if no valid chapter number is found
func extractChapterNum(name string) int {
	if !strings.HasPrefix(name, "chapter-") {
		return -1
	}
	// Remove "chapter-" prefix
	rest := strings.TrimPrefix(name, "chapter-")
	// Find where the number ends (at the next hyphen or end of string)
	numStr := rest
	if idx := strings.Index(rest, "-"); idx != -1 {
		numStr = rest[:idx]
	}
	num, err := strconv.Atoi(numStr)
	if err != nil {
		return -1
	}
	return num
}

func main() {
	// We are in cookbook/portal, root is ..
	root, _ := filepath.Abs("..")
	repoRoot, _ := filepath.Abs("../..")

	mux := http.NewServeMux()

	// API: Get reference docs list
	mux.HandleFunc("/api/docs", func(w http.ResponseWriter, r *http.Request) {
		docs := []RefDoc{
			{Title: "UI Reference (Frontend)", ID: "ui"},
			{Title: "Backend Reference (Elixir)", ID: "backend"},
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{"docs": docs})
	})

	// API: Get markdown content as HTML
	mux.HandleFunc("/api/docs/", func(w http.ResponseWriter, r *http.Request) {
		docID := strings.TrimPrefix(r.URL.Path, "/api/docs/")
		var filePath string
		switch docID {
		case "ui":
			filePath = filepath.Join(repoRoot, "UI_REFERENCE.md")
		case "backend":
			filePath = filepath.Join(repoRoot, "BACKEND_REFERENCE.md")
		default:
			http.Error(w, "Not found", 404)
			return
		}

		content, err := os.ReadFile(filePath)
		if err != nil {
			http.Error(w, "File not found", 404)
			return
		}

		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.Write(content)
	})

	// API: Dynamically scan for chapters
	mux.HandleFunc("/api/index", func(w http.ResponseWriter, r *http.Request) {
		var chapters []Chapter
		// Find all directories matching "chapter-*"
		dirs, _ := filepath.Glob(filepath.Join(root, "chapter-*"))

		// Sort numerically by chapter number (chapter-1, chapter-2, ..., chapter-10)
		sort.Slice(dirs, func(i, j int) bool {
			baseI := filepath.Base(dirs[i])
			baseJ := filepath.Base(dirs[j])
			// Extract chapter number: "chapter-N-..." -> N
			numI := extractChapterNum(baseI)
			numJ := extractChapterNum(baseJ)
			if numI != -1 && numJ != -1 {
				return numI < numJ
			}
			return dirs[i] < dirs[j]
		})

		for _, d := range dirs {
			chapter := Chapter{Title: filepath.Base(d)}
			// Find all subdirectories with a mix.exs (apps)
			filepath.Walk(d, func(path string, info os.FileInfo, err error) error {
				if filepath.Base(path) == "mix.exs" {
					appDir := filepath.Dir(path)
					readme, _ := os.ReadFile(filepath.Join(appDir, "README.md"))

					// Extract Port from README
					portMatch := regexp.MustCompile(`Port:\s*(\d+)`).FindStringSubmatch(string(readme))
					if len(portMatch) > 1 {
						// Find HTML source
						htmlPath := filepath.Join(appDir, "priv", "static", "index.html")
						if _, err := os.Stat(htmlPath); os.IsNotExist(err) {
							htmlPath = ""
						}

						// Find Elixir source (typically lib/<app_name>/app.ex or similar)
						elixirPath := ""
						libDir := filepath.Join(appDir, "lib")
						filepath.Walk(libDir, func(p string, info os.FileInfo, err error) error {
							if elixirPath == "" && filepath.Ext(p) == ".ex" {
								elixirPath = p
								return filepath.SkipAll
							}
							return nil
						})

						chapter.Entries = append(chapter.Entries, Entry{
							Title:      filepath.Base(appDir),
							URL:        fmt.Sprintf("http://localhost:%s", portMatch[1]),
							HtmlPath:   htmlPath,
							ElixirPath: elixirPath,
						})
					}
				}
				return nil
			})
			// Sort entries numerically (e.g., 10-1, 10-2, ..., 10-10)
			entryNumRe := regexp.MustCompile(`(\d+)-(\d+)`)
			sort.Slice(chapter.Entries, func(i, j int) bool {
				matchI := entryNumRe.FindStringSubmatch(chapter.Entries[i].Title)
				matchJ := entryNumRe.FindStringSubmatch(chapter.Entries[j].Title)
				if len(matchI) > 2 && len(matchJ) > 2 {
					majorI, _ := strconv.Atoi(matchI[1])
					majorJ, _ := strconv.Atoi(matchJ[1])
					if majorI != majorJ {
						return majorI < majorJ
					}
					minorI, _ := strconv.Atoi(matchI[2])
					minorJ, _ := strconv.Atoi(matchJ[2])
					return minorI < minorJ
				}
				return chapter.Entries[i].Title < chapter.Entries[j].Title
			})
			if len(chapter.Entries) > 0 {
				chapters = append(chapters, chapter)
			}
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{"chapters": chapters})
	})

	// Serve source files
	mux.HandleFunc("/api/file", func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Query().Get("path")
		if path == "" {
			http.Error(w, "Missing path parameter", http.StatusBadRequest)
			return
		}
		// Security: ensure path is absolute and within our cookbook directory
		absPath, err := filepath.Abs(path)
		if err != nil || !filepath.IsAbs(absPath) {
			http.Error(w, "Invalid path", http.StatusBadRequest)
			return
		}
		// Read and serve the file
		content, err := os.ReadFile(absPath)
		if err != nil {
			http.Error(w, "File not found", http.StatusNotFound)
			return
		}
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.Write(content)
	})

	// Serve UI.js directly from the source in the repo root
	mux.HandleFunc("/ui.js", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		http.ServeFile(w, r, filepath.Join(root, "..", "ui", "src", "ui.js"))
	})

	// Serve Static Files (Portal UI)
	mux.Handle("/", http.FileServer(http.Dir("static")))

	fmt.Println("🚀 Cookbook Portal running on http://localhost:1990")
	http.ListenAndServe(":1990", mux)
}