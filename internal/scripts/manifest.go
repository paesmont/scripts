package scripts

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type Status string

const (
	StatusIdle     Status = "idle"
	StatusQueued   Status = "queued"
	StatusRunning  Status = "running"
	StatusOK       Status = "ok"
	StatusFailed   Status = "failed"
	StatusCanceled Status = "canceled"
	StatusSkipped  Status = "skipped"
)

type Script struct {
	ID           string
	Name         string
	Description  string
	Category     string
	Path         string
	Packages     []string
	SkipPackages []string
	Enabled      bool
	RequiresRoot bool
	Interactive  bool
	Status       Status
	LastError    string
	Order        int
}

type Overrides struct {
	Interactive  map[string]bool
	RequiresRoot map[string]bool
	SkipPackages map[string][]string
}

func defaultName(fileName string) string {
	base := strings.TrimSuffix(fileName, filepath.Ext(fileName))
	base = strings.TrimPrefix(base, "install-")
	base = strings.ReplaceAll(base, "-", " ")
	if base == "" {
		return fileName
	}

	parts := strings.Fields(base)
	for i := range parts {
		if len(parts[i]) == 0 {
			continue
		}
		parts[i] = strings.ToUpper(parts[i][:1]) + parts[i][1:]
	}

	return strings.Join(parts, " ")
}

func applyOverrides(script *Script, overrides Overrides) {
	if overrides.Interactive[filepath.Base(script.Path)] {
		script.Interactive = true
	}

	if overrides.RequiresRoot[filepath.Base(script.Path)] {
		script.RequiresRoot = true
	}

	if pkgs, ok := overrides.SkipPackages[filepath.Base(script.Path)]; ok {
		script.SkipPackages = append([]string{}, pkgs...)
	}
}

func defaultOverrides() Overrides {
	return Overrides{
		Interactive: map[string]bool{
			"install-postgresql.sh": true,
		},
		RequiresRoot: map[string]bool{},
		SkipPackages: map[string][]string{},
	}
}

type overrideFile struct {
	Interactive  []string            `json:"interactive"`
	RequiresRoot []string            `json:"requires_root"`
	SkipPackages map[string][]string `json:"skip_packages"`
}

func loadOverrides(path string) (Overrides, error) {
	overrides := defaultOverrides()
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return overrides, nil
		}
		return Overrides{}, fmt.Errorf("erro lendo overrides: %w", err)
	}

	var file overrideFile
	if err := json.Unmarshal(data, &file); err != nil {
		return Overrides{}, fmt.Errorf("erro parseando overrides: %w", err)
	}

	for _, name := range file.Interactive {
		if name != "" {
			overrides.Interactive[name] = true
		}
	}

	for _, name := range file.RequiresRoot {
		if name != "" {
			overrides.RequiresRoot[name] = true
		}
	}

	for scriptName, pkgs := range file.SkipPackages {
		if scriptName == "" || len(pkgs) == 0 {
			continue
		}
		filtered := make([]string, 0, len(pkgs))
		for _, pkg := range pkgs {
			pkg = strings.TrimSpace(pkg)
			if pkg != "" {
				filtered = append(filtered, pkg)
			}
		}
		if len(filtered) > 0 {
			overrides.SkipPackages[scriptName] = filtered
		}
	}

	return overrides, nil
}

func LoadOverrides(path string) (Overrides, error) {
	return loadOverrides(path)
}

func SaveOverrides(path string, overrides Overrides) error {
	file := overrideFile{
		Interactive:  mapKeysTrue(overrides.Interactive),
		RequiresRoot: mapKeysTrue(overrides.RequiresRoot),
		SkipPackages: map[string][]string{},
	}

	for scriptName, pkgs := range overrides.SkipPackages {
		if scriptName == "" || len(pkgs) == 0 {
			continue
		}
		clean := make([]string, 0, len(pkgs))
		seen := map[string]bool{}
		for _, pkg := range pkgs {
			pkg = strings.TrimSpace(pkg)
			if pkg == "" || seen[pkg] {
				continue
			}
			seen[pkg] = true
			clean = append(clean, pkg)
		}
		if len(clean) == 0 {
			continue
		}
		sort.Strings(clean)
		file.SkipPackages[scriptName] = clean
	}

	data, err := json.MarshalIndent(file, "", "  ")
	if err != nil {
		return fmt.Errorf("erro serializando overrides: %w", err)
	}

	if err := os.WriteFile(path, append(data, '\n'), 0o644); err != nil {
		return fmt.Errorf("erro salvando overrides: %w", err)
	}

	return nil
}

func mapKeysTrue(values map[string]bool) []string {
	items := make([]string, 0, len(values))
	for key, enabled := range values {
		if key != "" && enabled {
			items = append(items, key)
		}
	}
	sort.Strings(items)
	return items
}
