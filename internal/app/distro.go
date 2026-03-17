package app

import (
	"log"
	"os"
	"path/filepath"
)

// Distro represents a supported OS/distribution with its scripts directory.
type Distro struct {
	Name        string
	Description string
	Label       string
	Dir         string
}

var knownDistros = []struct {
	subdir string
	name   string
	desc   string
	label  string
}{
	{"scripts/arch", "Arch Linux", "pacman + AUR (CachyOS)", "arch"},
	{"scripts/apt", "Ubuntu / Pop!_OS", "APT — Debian/Ubuntu", "apt"},
	{"scripts/fedora", "Fedora", "DNF — Fedora Linux", "fedora"},
}

// DetectDistros scans root for all supported distro script directories.
func DetectDistros(root string) []Distro {
	if root == "" {
		return nil
	}
	var distros []Distro
	for _, c := range knownDistros {
		dir := filepath.Join(root, c.subdir)
		if !isValidScriptsDir(dir) {
			continue
		}
		abs, err := filepath.Abs(dir)
		if err != nil {
			log.Printf("warning: failed to get absolute path for %s: %v", dir, err)
			abs = dir
		}
		distros = append(distros, Distro{
			Name:        c.name,
			Description: c.desc,
			Label:       c.label,
			Dir:         abs,
		})
	}
	return distros
}

// isValidScriptsDir returns true if dir has install.sh plus an assets/ or install/ subdirectory.
func isValidScriptsDir(dir string) bool {
	if _, err := os.Stat(filepath.Join(dir, "install.sh")); err != nil {
		return false
	}
	for _, sub := range []string{"assets", "install"} {
		info, err := os.Stat(filepath.Join(dir, sub))
		if err == nil && info.IsDir() {
			return true
		}
	}
	return false
}
