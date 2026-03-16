package scripts

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
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
	Category     string
	Path         string
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
}

func defaultOverrides() Overrides {
	return Overrides{
		Interactive: map[string]bool{
			"install-postgresql.sh": true,
		},
		RequiresRoot: map[string]bool{},
	}
}

type overrideFile struct {
	Interactive  []string `json:"interactive"`
	RequiresRoot []string `json:"requires_root"`
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

	return overrides, nil
}
