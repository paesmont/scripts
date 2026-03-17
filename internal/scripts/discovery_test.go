package scripts

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseStepsSupportsEnabledAndDisabledLines(t *testing.T) {
	tmp := t.TempDir()
	installPath := filepath.Join(tmp, "install.sh")
	body := `#!/bin/bash
STEPS=(
  "install-a.sh"
  # "install-b.sh"
  'install-c.sh' # inline comment
  #install-d.sh
)
`

	if err := os.WriteFile(installPath, []byte(body), 0o644); err != nil {
		t.Fatalf("failed writing install.sh: %v", err)
	}

	order, enabled, err := parseSteps(installPath)
	if err != nil {
		t.Fatalf("unexpected parse error: %v", err)
	}

	if got := order["install-a.sh"]; got != 0 {
		t.Fatalf("expected install-a.sh order 0, got %d", got)
	}
	if !enabled["install-a.sh"] {
		t.Fatal("expected install-a.sh enabled")
	}

	if got := order["install-b.sh"]; got != 1 {
		t.Fatalf("expected install-b.sh order 1, got %d", got)
	}
	if enabled["install-b.sh"] {
		t.Fatal("expected install-b.sh disabled")
	}

	if got := order["install-c.sh"]; got != 2 {
		t.Fatalf("expected install-c.sh order 2, got %d", got)
	}
	if !enabled["install-c.sh"] {
		t.Fatal("expected install-c.sh enabled")
	}

	if got := order["install-d.sh"]; got != 3 {
		t.Fatalf("expected install-d.sh order 3, got %d", got)
	}
	if enabled["install-d.sh"] {
		t.Fatal("expected install-d.sh disabled")
	}
}

func TestParseStepsHandlesDuplicatesAndEmptyEntries(t *testing.T) {
	tmp := t.TempDir()
	installPath := filepath.Join(tmp, "install.sh")
	body := `#!/bin/bash
STEPS=(

  "install-a.sh"
  "install-a.sh"
  # "install-b.sh"
  install-b.sh
  # comment without script name
)
`

	if err := os.WriteFile(installPath, []byte(body), 0o644); err != nil {
		t.Fatalf("failed writing install.sh: %v", err)
	}

	order, enabled, err := parseSteps(installPath)
	if err != nil {
		t.Fatalf("unexpected parse error: %v", err)
	}

	if len(order) != 2 {
		t.Fatalf("expected 2 unique scripts, got %d", len(order))
	}

	if got := order["install-a.sh"]; got != 0 {
		t.Fatalf("expected install-a.sh order 0, got %d", got)
	}
	if !enabled["install-a.sh"] {
		t.Fatal("expected install-a.sh enabled from first occurrence")
	}

	if got := order["install-b.sh"]; got != 1 {
		t.Fatalf("expected install-b.sh order 1, got %d", got)
	}
	if enabled["install-b.sh"] {
		t.Fatal("expected install-b.sh to remain disabled due to first occurrence")
	}
}

func TestParseStepsEmptyWhenNoStepsBlock(t *testing.T) {
	tmp := t.TempDir()
	installPath := filepath.Join(tmp, "install.sh")
	body := "#!/bin/bash\necho no-steps\n"

	if err := os.WriteFile(installPath, []byte(body), 0o644); err != nil {
		t.Fatalf("failed writing install.sh: %v", err)
	}

	order, enabled, err := parseSteps(installPath)
	if err != nil {
		t.Fatalf("unexpected parse error: %v", err)
	}

	if len(order) != 0 || len(enabled) != 0 {
		t.Fatalf("expected empty maps, got order=%d enabled=%d", len(order), len(enabled))
	}
}

func TestDiscoverParsesOrderFlagsAndOverrides(t *testing.T) {
	tmp := t.TempDir()
	assetsDir := filepath.Join(tmp, "assets")
	if err := os.MkdirAll(assetsDir, 0o755); err != nil {
		t.Fatalf("failed creating assets dir: %v", err)
	}

	installBody := `#!/bin/bash
STEPS=(
  "install-zeta.sh"
  # "install-beta.sh"
  "install-alpha.sh"
)
`
	if err := os.WriteFile(filepath.Join(tmp, "install.sh"), []byte(installBody), 0o644); err != nil {
		t.Fatalf("failed writing install.sh: %v", err)
	}

	overridesBody := `{
  "interactive": ["install-extra.sh"],
  "requires_root": ["install-extra.sh"]
}`
	if err := os.WriteFile(filepath.Join(tmp, "tui-overrides.json"), []byte(overridesBody), 0o644); err != nil {
		t.Fatalf("failed writing overrides file: %v", err)
	}

	files := map[string]string{
		"install-zeta.sh":  "#!/bin/bash\necho zeta\n",
		"install-beta.sh":  "#!/bin/bash\n# TUI_INTERACTIVE: true\n",
		"install-alpha.sh": "#!/bin/bash\nREQUIRES_ROOT=1\n",
		"install-extra.sh": "#!/bin/bash\necho extra\n",
	}
	for name, body := range files {
		if err := os.WriteFile(filepath.Join(assetsDir, name), []byte(body), 0o755); err != nil {
			t.Fatalf("failed writing asset %s: %v", name, err)
		}
	}

	list, err := Discover(tmp)
	if err != nil {
		t.Fatalf("unexpected discover error: %v", err)
	}

	if len(list) != 4 {
		t.Fatalf("expected 4 scripts, got %d", len(list))
	}

	if got := filepath.Base(list[0].Path); got != "install-alpha.sh" {
		t.Fatalf("expected first script install-alpha.sh, got %s", got)
	}
	if got := filepath.Base(list[1].Path); got != "install-beta.sh" {
		t.Fatalf("expected second script install-beta.sh, got %s", got)
	}
	if got := filepath.Base(list[2].Path); got != "install-extra.sh" {
		t.Fatalf("expected third script install-extra.sh, got %s", got)
	}
	if got := filepath.Base(list[3].Path); got != "install-zeta.sh" {
		t.Fatalf("expected fourth script install-zeta.sh, got %s", got)
	}

	byName := map[string]Script{}
	for _, s := range list {
		byName[filepath.Base(s.Path)] = s
	}

	if !byName["install-zeta.sh"].Enabled {
		t.Fatal("expected install-zeta.sh enabled")
	}
	if byName["install-beta.sh"].Enabled {
		t.Fatal("expected install-beta.sh disabled")
	}
	if !byName["install-alpha.sh"].RequiresRoot {
		t.Fatal("expected install-alpha.sh requires root")
	}
	if !byName["install-beta.sh"].Interactive {
		t.Fatal("expected install-beta.sh interactive from metadata")
	}
	if !byName["install-extra.sh"].Interactive || !byName["install-extra.sh"].RequiresRoot {
		t.Fatal("expected install-extra.sh flags from overrides")
	}
	if byName["install-extra.sh"].Category != "Outros" {
		t.Fatalf("expected install-extra.sh category Outros, got %q", byName["install-extra.sh"].Category)
	}
	if byName["install-zeta.sh"].Category != "Outros" {
		t.Fatalf("expected install-zeta.sh category Outros, got %q", byName["install-zeta.sh"].Category)
	}
}

func TestDiscoverDetectsRequiresRootByPriority(t *testing.T) {
	tmp := t.TempDir()
	assetsDir := filepath.Join(tmp, "assets")
	if err := os.MkdirAll(assetsDir, 0o755); err != nil {
		t.Fatalf("failed creating assets dir: %v", err)
	}

	installBody := `#!/bin/bash
STEPS=(
  "install-meta.sh"
  "install-python-tools.sh"
  "install-sudo-selfcheck.sh"
  "install-ensure.sh"
  "install-requires-root.sh"
  "install-user-space.sh"
  "install-override-only.sh"
)
`
	if err := os.WriteFile(filepath.Join(tmp, "install.sh"), []byte(installBody), 0o644); err != nil {
		t.Fatalf("failed writing install.sh: %v", err)
	}

	overridesBody := `{
  "requires_root": ["install-override-only.sh"]
}`
	if err := os.WriteFile(filepath.Join(tmp, "tui-overrides.json"), []byte(overridesBody), 0o644); err != nil {
		t.Fatalf("failed writing overrides file: %v", err)
	}

	files := map[string]string{
		"install-meta.sh":           "#!/bin/bash\n# TUI_REQUIRES_ROOT: true\n",
		"install-python-tools.sh":   "#!/bin/bash\nsudo pacman -Syy\n",
		"install-sudo-selfcheck.sh": "#!/bin/bash\ncheck_root\nsudo dnf install -y fish\n",
		"install-ensure.sh":         "#!/bin/bash\nensure_package git\n",
		"install-requires-root.sh":  "#!/bin/bash\nREQUIRES_ROOT=1\n",
		"install-user-space.sh":     "#!/bin/bash\n# npm -g funciona sem sudo aqui\npipx ensurepath\n",
		"install-override-only.sh":  "#!/bin/bash\necho no-root-hint\n",
	}
	for name, body := range files {
		if err := os.WriteFile(filepath.Join(assetsDir, name), []byte(body), 0o755); err != nil {
			t.Fatalf("failed writing asset %s: %v", name, err)
		}
	}

	list, err := Discover(tmp)
	if err != nil {
		t.Fatalf("unexpected discover error: %v", err)
	}

	byName := map[string]Script{}
	for _, s := range list {
		byName[filepath.Base(s.Path)] = s
	}

	if !byName["install-meta.sh"].RequiresRoot {
		t.Fatal("expected install-meta.sh requires root from metadata")
	}
	if !byName["install-python-tools.sh"].RequiresRoot {
		t.Fatal("expected install-python-tools.sh requires root from sudo detection")
	}
	if !byName["install-ensure.sh"].RequiresRoot {
		t.Fatal("expected install-ensure.sh requires root from ensure_* detection")
	}
	if !byName["install-requires-root.sh"].RequiresRoot {
		t.Fatal("expected install-requires-root.sh requires root from REQUIRES_ROOT=1")
	}
	if !byName["install-override-only.sh"].RequiresRoot {
		t.Fatal("expected install-override-only.sh requires root from overrides")
	}
	if byName["install-user-space.sh"].RequiresRoot {
		t.Fatal("expected install-user-space.sh to remain user-space")
	}
	if byName["install-sudo-selfcheck.sh"].RequiresRoot {
		t.Fatal("expected install-sudo-selfcheck.sh to remain user-space due to check_root")
	}
}

func TestDiscoverMarksReadPromptsAsInteractive(t *testing.T) {
	tmp := t.TempDir()
	assetsDir := filepath.Join(tmp, "assets")
	if err := os.MkdirAll(assetsDir, 0o755); err != nil {
		t.Fatalf("failed creating assets dir: %v", err)
	}

	installBody := `#!/bin/bash
STEPS=(
  "configure-git.sh"
)
`
	if err := os.WriteFile(filepath.Join(tmp, "install.sh"), []byte(installBody), 0o644); err != nil {
		t.Fatalf("failed writing install.sh: %v", err)
	}

	scriptBody := `#!/bin/bash
read -rp "Digite seu email para Git: " git_email
`
	if err := os.WriteFile(filepath.Join(assetsDir, "configure-git.sh"), []byte(scriptBody), 0o755); err != nil {
		t.Fatalf("failed writing asset: %v", err)
	}

	list, err := Discover(tmp)
	if err != nil {
		t.Fatalf("unexpected discover error: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 script, got %d", len(list))
	}
	if !list[0].Interactive {
		t.Fatal("expected configure-git.sh to be interactive from read prompt detection")
	}
}
