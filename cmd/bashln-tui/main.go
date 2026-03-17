package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"golang.org/x/term"

	"bashln-scripts/internal/app"
	"bashln-scripts/internal/scripts"
)

func main() {
	rootFlag := flag.String("root", "", "Diretorio raiz do repositorio ou scripts/arch")
	noAltScreen := flag.Bool("no-alt-screen", false, "Desativa tela alternativa")
	maxLogs := flag.Int("max-logs", app.DefaultMaxLogs, "Numero maximo de logs a manter")
	maxAgeDays := flag.Int("max-age-days", app.DefaultMaxAgeDays, "Numero maximo de dias para manter logs")
	noCompress := flag.Bool("no-compress", false, "Desativar compressao de logs antigos")
	flag.Parse()

	if !term.IsTerminal(int(os.Stdin.Fd())) || !term.IsTerminal(int(os.Stdout.Fd())) {
		fmt.Fprintln(os.Stderr, "erro: bashln-tui requer TTY interativo (stdin/stdout)")
		os.Exit(1)
	}

	root := filepath.Clean(resolveRoot(*rootFlag))
	archDir, err := resolveArchDir(root)
	if err != nil {
		fmt.Fprintf(os.Stderr, "erro ao resolver scripts/arch: %v\n", err)
		os.Exit(1)
	}

	list, err := scripts.Discover(archDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "erro ao carregar scripts: %v\n", err)
		os.Exit(1)
	}

	logPath := filepath.Join(archDir, "install.log")
	config := app.LogRotateConfig{
		MaxLogs:    *maxLogs,
		MaxAgeDays: *maxAgeDays,
		Compress:   !*noCompress,
	}
	if err := app.RotateLogFileWithConfig(logPath, config); err != nil {
		fmt.Fprintf(os.Stderr, "erro ao rotacionar log: %v\n", err)
		// Continue anyway, as log rotation is not critical
	}

	model := app.NewModel(list, logPath)
	options := []tea.ProgramOption{tea.WithInputTTY(), tea.WithOutput(os.Stdout)}
	if !*noAltScreen {
		options = append(options, tea.WithAltScreen())
	}
	p := tea.NewProgram(model, options...)

	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "erro na TUI: %v\n", err)
		os.Exit(1)
	}
}

func resolveRoot(rootFlag string) string {
	if rootFlag != "" {
		return rootFlag
	}

	if fromEnv := os.Getenv("BASHLN_ROOT"); fromEnv != "" {
		return fromEnv
	}

	cwd, err := os.Getwd()
	if err != nil {
		return "."
	}

	return cwd
}

// detectSystemDistro reads /etc/os-release and returns the distro ID
func detectSystemDistro() string {
	data, err := os.ReadFile("/etc/os-release")
	if err != nil {
		return ""
	}

	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		if value, ok := osReleaseValue(line, "ID"); ok {
			return value
		}
	}

	return ""
}

// osReleaseValue extracts a value from /etc/os-release line
func osReleaseValue(line, key string) (string, bool) {
	prefix := key + "="
	if !strings.HasPrefix(line, prefix) {
		return "", false
	}

	value := strings.TrimPrefix(line, prefix)
	// Remove quotes if present
	if len(value) >= 2 && value[0] == '"' && value[len(value)-1] == '"' {
		value = value[1 : len(value)-1]
	}
	return value, true
}

func resolveArchDir(root string) (string, error) {
	// Se --root foi fornecido explicitamente, use como está
	if root != "" && root != "." {
		installPath := filepath.Join(root, "install.sh")
		assetsPath := filepath.Join(root, "assets")
		if fileExists(installPath) && dirExists(assetsPath) {
			return filepath.Abs(root)
		}
		// Se não for válido, tentar scripts/arch como fallback para compatibilidade
		root = filepath.Join(root, "scripts/arch")
	}

	// Detectar distro do sistema
	distroID := detectSystemDistro()

	// Mapear distro para diretório de scripts
	var scriptDir string
	switch distroID {
	case "fedora", "rhel", "centos", "rocky", "almalinux":
		scriptDir = "scripts/fedora"
	case "ubuntu", "debian", "linuxmint", "pop":
		scriptDir = "scripts/apt"
	case "arch", "manjaro", "endeavouros", "artix":
		scriptDir = "scripts/arch"
	default:
		// Fallback para scripts/arch (comportamento original)
		scriptDir = "scripts/arch"
	}

	// Se o diretório detectado existir, use-o
	dir := filepath.Join(root, scriptDir)
	if fileExists(filepath.Join(dir, "install.sh")) && dirExists(filepath.Join(dir, "assets")) {
		return filepath.Abs(dir)
	}

	// Tentar scripts/arch como fallback final
	dir = filepath.Join(root, "scripts/arch")
	if fileExists(filepath.Join(dir, "install.sh")) && dirExists(filepath.Join(dir, "assets")) {
		return filepath.Abs(dir)
	}

	// Tentar o root original
	if fileExists(filepath.Join(root, "install.sh")) && dirExists(filepath.Join(root, "assets")) {
		return filepath.Abs(root)
	}

	return "", fmt.Errorf("nenhum diretório de scripts válido encontrado (tentado: %s, scripts/arch, root)", scriptDir)
}

func fileExists(path string) bool {
	stat, err := os.Stat(path)
	return err == nil && !stat.IsDir()
}

func dirExists(path string) bool {
	stat, err := os.Stat(path)
	return err == nil && stat.IsDir()
}
