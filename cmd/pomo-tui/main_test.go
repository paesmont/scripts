package main

import (
	"testing"
)

func TestOsReleaseValue(t *testing.T) {
	tests := []struct {
		line  string
		key   string
		want  string
		found bool
	}{
		{`ID=fedora`, "ID", "fedora", true},
		{`ID="fedora"`, "ID", "fedora", true},
		{`VARIANT_ID="silverblue"`, "VARIANT_ID", "silverblue", true},
		{`NAME="Fedora Silverblue"`, "NAME", "Fedora Silverblue", true},
		{`ID=`, "ID", "", true},
		{`NAME=fedora`, "ID", "", false},
		{`VERSION_ID="41"`, "VERSION_ID", "41", true},
		{`  ID=fedora`, "ID", "", false},
	}

	for _, tt := range tests {
		t.Run(tt.key+"_"+tt.line, func(t *testing.T) {
			got, found := osReleaseValue(tt.line, tt.key)
			if found != tt.found {
				t.Errorf("osReleaseValue(%q, %q) found = %v, want %v", tt.line, tt.key, found, tt.found)
			}
			if found && got != tt.want {
				t.Errorf("osReleaseValue(%q, %q) = %q, want %q", tt.line, tt.key, got, tt.want)
			}
		})
	}
}

func TestResolveScriptsDirWithVariant(t *testing.T) {
	tests := []struct {
		name          string
		distroID      string
		variantID     string
		wantScriptDir string
	}{
		{
			name:          "fedora silverblue",
			distroID:      "fedora",
			variantID:     "silverblue",
			wantScriptDir: "scripts/fedora-atomic",
		},
		{
			name:          "fedora bazzite",
			distroID:      "fedora",
			variantID:     "bazzite",
			wantScriptDir: "scripts/fedora-atomic",
		},
		{
			name:          "fedora kinoite",
			distroID:      "fedora",
			variantID:     "kinoite",
			wantScriptDir: "scripts/fedora-atomic",
		},
		{
			name:          "fedora nordic",
			distroID:      "fedora",
			variantID:     "nordic",
			wantScriptDir: "scripts/fedora-atomic",
		},
		{
			name:          "regular fedora",
			distroID:      "fedora",
			variantID:     "",
			wantScriptDir: "scripts/fedora",
		},
		{
			name:          "fedora workstation",
			distroID:      "fedora",
			variantID:     "workstation",
			wantScriptDir: "scripts/fedora",
		},
		{
			name:          "arch linux",
			distroID:      "arch",
			variantID:     "",
			wantScriptDir: "scripts/arch",
		},
		{
			name:          "ubuntu",
			distroID:      "ubuntu",
			variantID:     "",
			wantScriptDir: "scripts/apt",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := resolveDistroToScriptDir(tt.distroID, tt.variantID)
			if got != tt.wantScriptDir {
				t.Errorf("resolveDistroToScriptDir(%q, %q) = %q, want %q",
					tt.distroID, tt.variantID, got, tt.wantScriptDir)
			}
		})
	}
}

func resolveDistroToScriptDir(distroID, variantID string) string {
	var scriptDir string
	switch distroID {
	case "fedora", "rhel", "centos", "rocky", "almalinux":
		switch variantID {
		case "bazzite", "silverblue", "kinoite", "nordic":
			scriptDir = "scripts/fedora-atomic"
		default:
			scriptDir = "scripts/fedora"
		}
	case "ubuntu", "debian", "linuxmint", "pop":
		scriptDir = "scripts/apt"
	case "arch", "manjaro", "endeavouros", "artix":
		scriptDir = "scripts/arch"
	default:
		scriptDir = "scripts/arch"
	}
	return scriptDir
}
