package scripts

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

var (
	stepEnabledRe     = regexp.MustCompile(`^\s*["']?([a-zA-Z0-9._-]+\.sh)["']?\s*(?:#.*)?$`)
	stepDisabledRe    = regexp.MustCompile(`^\s*#\s*["']?([a-zA-Z0-9._-]+\.sh)["']?\s*(?:#.*)?$`)
	requiresRootRe    = regexp.MustCompile(`(?m)^REQUIRES_ROOT=1\s*$`)
	sudoUsageRe       = regexp.MustCompile(`(?m)\bsudo\b`)
	ensureRootCallRe  = regexp.MustCompile(`(?m)\b(ensure_package|ensure_aur_package|ensure_copr_package|ensure_group|ensure_rpmfusion)\b`)
	checkRootCallRe   = regexp.MustCompile(`(?m)\bcheck_root\b`)
	ensurePkgCallRe   = regexp.MustCompile(`\bensure_pkg\s+([a-zA-Z0-9+._-]+)\b`)
	packagesMetaRe    = regexp.MustCompile(`^\s*#\s*TUI_PACKAGES\s*:\s*(.+?)\s*$`)
	interactiveHint   = regexp.MustCompile(`(?m)(\bread\b|--interactive|gum\s+(input|confirm|choose|filter|file)|\bfzf\b|\bwhiptail\b|\bdialog\b|\bselect\s+)`)
	metaInteractiveRe = regexp.MustCompile(`(?m)^\s*#\s*TUI_INTERACTIVE\s*:\s*true\s*$`)
	metaRootRe        = regexp.MustCompile(`(?m)^\s*#\s*TUI_REQUIRES_ROOT\s*:\s*true\s*$`)
)

var categoryPriority = map[string]int{
	"Base do Sistema":       0,
	"Linguagens & Runtimes": 1,
	"Graficos & Multimedia": 2,
	"Terminais & Shell":     3,
	"Rede & Armazenamento":  4,
	"Navegadores":           5,
	"Ferramentas Dev":       6,
	"Aplicacoes":            7,
	"Flatpak":               8,
	"Desktop & Hyprland":    9,
	"Outros":                10,
}

func Discover(archDir string) ([]Script, error) {
	installPath := filepath.Join(archDir, "install.sh")
	orderMap, enabledMap, err := parseSteps(installPath)
	if err != nil {
		return nil, err
	}

	overrides, err := loadOverrides(filepath.Join(archDir, "tui-overrides.json"))
	if err != nil {
		return nil, err
	}

	assetsDir := filepath.Join(archDir, "assets")
	entries, err := os.ReadDir(assetsDir)
	if err != nil {
		return nil, fmt.Errorf("erro lendo assets: %w", err)
	}

	items := make([]Script, 0, len(entries))
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".sh" {
			continue
		}

		fullPath := filepath.Join(assetsDir, entry.Name())
		body, readErr := os.ReadFile(fullPath)
		if readErr != nil {
			return nil, fmt.Errorf("erro lendo script %s: %w", entry.Name(), readErr)
		}

		order, found := orderMap[entry.Name()]
		if !found {
			order = 10000
		}

		requiresRoot := detectRequiresRoot(entry.Name(), body, overrides)
		interactive := interactiveHint.Match(body) || metaInteractiveRe.Match(body)
		packages := extractPackages(body)

		script := Script{
			ID:           strings.TrimSuffix(entry.Name(), ".sh"),
			Name:         defaultName(entry.Name()),
			Description:  extractDescription(entry.Name(), body),
			Category:     defaultCategory(entry.Name()),
			Path:         fullPath,
			Packages:     packages,
			Enabled:      enabledMap[entry.Name()],
			RequiresRoot: requiresRoot,
			Interactive:  interactive,
			Status:       StatusIdle,
			Order:        order,
		}
		applyOverrides(&script, overrides)
		items = append(items, script)
	}

	sort.Slice(items, func(i, j int) bool {
		leftCategory := categorySortOrder(items[i].Category)
		rightCategory := categorySortOrder(items[j].Category)
		if leftCategory != rightCategory {
			return leftCategory < rightCategory
		}
		leftName := strings.ToLower(items[i].Name)
		rightName := strings.ToLower(items[j].Name)
		if leftName != rightName {
			return leftName < rightName
		}
		return filepath.Base(items[i].Path) < filepath.Base(items[j].Path)
	})

	return items, nil
}

func categorySortOrder(category string) int {
	order, ok := categoryPriority[category]
	if !ok {
		return categoryPriority["Outros"]
	}
	return order
}

func defaultCategory(fileName string) string {
	switch fileName {
	case "install-gum.sh", "install-base-devel.sh", "install-dev-tools.sh", "install-git.sh", "install-stow.sh", "install-yay.sh", "install-curl.sh", "install-unzip.sh", "install-jq.sh", "install-eza.sh", "install-zoxide.sh", "install-linux-toys.sh":
		return "Base do Sistema"
	case "base.sh", "cli-tools.sh":
		return "Base do Sistema"
	case "install-go-tools.sh", "install-python.sh", "install-python-tools.sh", "install-ruby.sh", "install-rust.sh":
		return "Linguagens & Runtimes"
	case "install-fonts.sh", "install-mesa-radeon.sh", "install-vulkan-stack.sh", "install-lib32-libs.sh", "install-libva-utils.sh", "install-gvfs.sh":
		return "Graficos & Multimedia"
	case "install-alacritty.sh", "install-kitty.sh", "install-ghostty.sh", "install-tmux.sh", "install-zsh-env.sh", "install-ohmybash-starship.sh", "install-dank-material-shell.sh", "set-shell.sh":
		return "Terminais & Shell"
	case "shell.sh", "shell-default-fish.sh", "terminal.sh":
		return "Terminais & Shell"
	case "install-ntfs-3g.sh", "install-samba.sh", "autofs.sh", "install-wl-clipboard.sh", "fix-services.sh":
		return "Rede & Armazenamento"
	case "install-brave.sh", "install-vivaldi.sh":
		return "Navegadores"
	case "install-asdf.sh", "install-cmake.sh", "install-nodejs.sh", "install-npm-global.sh", "install-lsps.sh", "install-lazygit.sh", "install-emacs.sh", "install-neovim.sh", "install-vscode.sh", "install-dotfiles.sh", "configure-git.sh", "install-postgresql.sh":
		return "Ferramentas Dev"
	case "dev-tools.sh", "dotfiles.sh":
		return "Ferramentas Dev"
	case "install-remmina.sh", "install-vlc.sh", "install-yazi-deps.sh", "install-yazi.sh", "install-steam.sh", "install-wine-stack.sh":
		return "Aplicacoes"
	case "install-flatpak-flathub.sh", "install-flatpak-pupgui2.sh", "install-flatpak-spotify.sh", "install-flatpak-microsoft-edge.sh":
		return "Flatpak"
	case "install-hyprland-overrides.sh", "install-hyprland-autostart.sh":
		return "Desktop & Hyprland"
	default:
		return "Outros"
	}
}

func detectRequiresRoot(scriptName string, body []byte, overrides Overrides) bool {
	if overrides.RequiresRoot[scriptName] {
		return true
	}

	if metaRootRe.Match(body) {
		return true
	}

	bodyWithoutComments := stripCommentOnlyLines(body)

	// Scripts that explicitly call check_root are designed to run as normal user
	// and escalate specific commands with sudo when needed.
	if checkRootCallRe.Match(bodyWithoutComments) {
		return false
	}

	if sudoUsageRe.Match(bodyWithoutComments) {
		return true
	}

	if ensureRootCallRe.Match(bodyWithoutComments) {
		return true
	}

	return requiresRootRe.Match(body)
}

func extractDescription(fileName string, body []byte) string {
	lines := strings.Split(string(body), "\n")
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if !strings.HasPrefix(trimmed, "#") {
			continue
		}
		trimmed = strings.TrimSpace(strings.TrimPrefix(trimmed, "#"))
		if strings.Contains(trimmed, " - ") {
			parts := strings.SplitN(trimmed, " - ", 2)
			if len(parts) == 2 {
				desc := strings.TrimSpace(parts[1])
				if desc != "" {
					return desc
				}
			}
		}
	}

	return defaultName(fileName)
}

func extractPackages(body []byte) []string {
	lines := strings.Split(string(body), "\n")
	seen := map[string]bool{}
	packages := make([]string, 0, 16)

	addPkg := func(pkg string) {
		pkg = strings.TrimSpace(pkg)
		pkg = strings.Trim(pkg, "\"'")
		if pkg == "" || strings.HasPrefix(pkg, "$") || seen[pkg] {
			return
		}
		seen[pkg] = true
		packages = append(packages, pkg)
	}

	collectFromInstallList := false
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			continue
		}

		if meta := packagesMetaRe.FindStringSubmatch(trimmed); len(meta) == 2 {
			for _, pkg := range strings.Split(meta[1], ",") {
				addPkg(pkg)
			}
			continue
		}

		if strings.HasPrefix(trimmed, "#") {
			continue
		}

		if strings.HasPrefix(trimmed, "install_list") {
			collectFromInstallList = true
			rest := strings.TrimSpace(strings.TrimPrefix(trimmed, "install_list"))
			rest = strings.TrimSuffix(rest, "\\")
			if rest != "" {
				for _, token := range strings.Fields(rest) {
					addPkg(token)
				}
			}
			continue
		}

		if collectFromInstallList {
			if strings.HasPrefix(trimmed, ";;") || strings.HasPrefix(trimmed, "fi") || strings.Contains(trimmed, "(") {
				collectFromInstallList = false
				continue
			}
			t := strings.TrimSuffix(trimmed, "\\")
			for _, token := range strings.Fields(t) {
				addPkg(token)
			}
			if !strings.HasSuffix(trimmed, "\\") {
				collectFromInstallList = false
			}
			continue
		}

		for _, match := range ensurePkgCallRe.FindAllStringSubmatch(trimmed, -1) {
			if len(match) == 2 {
				addPkg(match[1])
			}
		}
	}

	return packages
}

func stripCommentOnlyLines(body []byte) []byte {
	lines := strings.Split(string(body), "\n")
	filtered := make([]string, 0, len(lines))
	for _, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), "#") {
			continue
		}
		filtered = append(filtered, line)
	}

	return []byte(strings.Join(filtered, "\n"))
}

func parseSteps(installPath string) (map[string]int, map[string]bool, error) {
	file, err := os.Open(installPath)
	if err != nil {
		return nil, nil, fmt.Errorf("erro abrindo install.sh: %w", err)
	}
	defer file.Close()

	order := map[string]int{}
	enabled := map[string]bool{}

	index := 0
	insideSteps := false
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		if strings.HasPrefix(line, "STEPS=(") {
			insideSteps = true
			continue
		}

		if insideSteps && line == ")" {
			break
		}

		if !insideSteps || line == "" {
			continue
		}

		if disabled := stepDisabledRe.FindStringSubmatch(line); len(disabled) == 2 {
			name := disabled[1]
			if _, exists := order[name]; !exists {
				order[name] = index
				enabled[name] = false
				index++
			}
			continue
		}

		match := stepEnabledRe.FindStringSubmatch(line)
		if len(match) != 2 {
			continue
		}

		name := match[1]
		if _, exists := order[name]; !exists {
			order[name] = index
			enabled[name] = true
			index++
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, nil, fmt.Errorf("erro ao ler install.sh: %w", err)
	}

	return order, enabled, nil
}
