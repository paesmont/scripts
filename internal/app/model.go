package app

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"bashln-scripts/internal/runner"
	"bashln-scripts/internal/scripts"
)

type mode string

const (
	modeMainMenu mode = "main-menu"
	modeList     mode = "list"
	modeSettings mode = "settings"
	modeRunning  mode = "running"
	modeDone     mode = "done"
	modePkgEdit  mode = "pkg-edit"
)

const (
	mainMenuInstall = iota
	mainMenuSettings
	mainMenuQuit
)

const (
	catppuccinBase    = "#1e1e2e"
	catppuccinMantle  = "#181825"
	catppuccinPeach   = "#fab387"
	catppuccinGreen   = "#a6e3a1"
	catppuccinRed     = "#f38ba8"
	catppuccinYellow  = "#f9e2af"
	catppuccinBlue    = "#89b4fa"
	catppuccinOverlay = "#6c7086"
)

type uiStyles struct {
	mono           bool
	header         lipgloss.Style
	footer         lipgloss.Style
	muted          lipgloss.Style
	cursor         lipgloss.Style
	selected       lipgloss.Style
	statusOK       lipgloss.Style
	statusFailed   lipgloss.Style
	statusWarn     lipgloss.Style
	statusInfo     lipgloss.Style
	statusDefault  lipgloss.Style
	tagInteractive lipgloss.Style
	tagRoot        lipgloss.Style
	categoryHeader lipgloss.Style
	selectedPanel  lipgloss.Style
	menuItem       lipgloss.Style
	menuSelected   lipgloss.Style
}

type Model struct {
	scripts         []scripts.Script
	menuCursor      int
	cursor          int
	width           int
	height          int
	listHeight      int
	mode            mode
	logPath         string
	queue           []int
	queuePos        int
	current         int
	output          []string
	outputLimit     int
	events          <-chan runner.Event
	runCancel       context.CancelFunc
	cancelRequested bool
	lastMessage     string
	successCount    int
	failureCount    int
	canceledCount   int
	quitting        bool
	styles          uiStyles
	archPath        string
	distroName      string
	overridePath    string
	overrides       scripts.Overrides
	packageCursor   int
}

type streamEventMsg struct {
	event runner.Event
	ok    bool
}

type interactiveDoneMsg struct {
	idx int
	err error
}

type runDoneMsg struct{}

type listRow struct {
	category    string
	scriptIndex int
	isHeader    bool
	count       int
}

func NewModel(list []scripts.Script, logPath string) Model {
	cloned := make([]scripts.Script, len(list))
	copy(cloned, list)

	colorEnabled := supportsColor()

	archPath := filepath.Dir(logPath)
	overridePath := filepath.Join(archPath, "tui-overrides.json")
	overrides, err := scripts.LoadOverrides(overridePath)
	if err != nil {
		overrides = scripts.Overrides{
			Interactive:  map[string]bool{},
			RequiresRoot: map[string]bool{},
			SkipPackages: map[string][]string{},
		}
	}

	return Model{
		scripts:         cloned,
		mode:            modeMainMenu,
		menuCursor:      0,
		listHeight:      18,
		logPath:         logPath,
		current:         -1,
		output:          []string{},
		outputLimit:     outputLimitFromEnv(),
		cancelRequested: false,
		styles:          newUIStyles(colorEnabled),
		archPath:        archPath,
		distroName:      detectDistro(),
		overridePath:    overridePath,
		overrides:       overrides,
	}
}

func supportsColor() bool {
	if os.Getenv("NO_COLOR") != "" || os.Getenv("CLICOLOR") == "0" {
		return false
	}

	term := strings.ToLower(strings.TrimSpace(os.Getenv("TERM")))
	return term != "" && term != "dumb"
}

func newUIStyles(colorEnabled bool) uiStyles {
	if !colorEnabled {
		return uiStyles{
			mono:           true,
			header:         lipgloss.NewStyle().Bold(true),
			footer:         lipgloss.NewStyle().Bold(true),
			muted:          lipgloss.NewStyle(),
			cursor:         lipgloss.NewStyle().Bold(true),
			selected:       lipgloss.NewStyle().Bold(true),
			statusOK:       lipgloss.NewStyle().Bold(true),
			statusFailed:   lipgloss.NewStyle().Bold(true),
			statusWarn:     lipgloss.NewStyle().Bold(true),
			statusInfo:     lipgloss.NewStyle().Bold(true),
			statusDefault:  lipgloss.NewStyle(),
			categoryHeader: lipgloss.NewStyle().Bold(true),
			selectedPanel:  lipgloss.NewStyle().Bold(true),
			menuItem:       lipgloss.NewStyle(),
			menuSelected:   lipgloss.NewStyle().Bold(true),
		}
	}

	return uiStyles{
		mono:          false,
		header:        lipgloss.NewStyle().Background(lipgloss.Color(catppuccinMantle)).Foreground(lipgloss.Color(catppuccinPeach)).Bold(true).Padding(0, 1),
		footer:        lipgloss.NewStyle().Background(lipgloss.Color(catppuccinMantle)).Foreground(lipgloss.Color(catppuccinOverlay)).Padding(0, 1),
		muted:         lipgloss.NewStyle().Foreground(lipgloss.Color(catppuccinOverlay)),
		cursor:        lipgloss.NewStyle().Foreground(lipgloss.Color(catppuccinPeach)).Bold(true),
		selected:      lipgloss.NewStyle().Background(lipgloss.Color(catppuccinMantle)),
		statusOK:      lipgloss.NewStyle().Foreground(lipgloss.Color(catppuccinGreen)).Bold(true),
		statusFailed:  lipgloss.NewStyle().Foreground(lipgloss.Color(catppuccinRed)).Bold(true),
		statusWarn:    lipgloss.NewStyle().Foreground(lipgloss.Color(catppuccinYellow)).Bold(true),
		statusInfo:    lipgloss.NewStyle().Foreground(lipgloss.Color(catppuccinBlue)).Bold(true),
		statusDefault: lipgloss.NewStyle().Foreground(lipgloss.Color(catppuccinOverlay)),
		tagInteractive: lipgloss.NewStyle().
			Foreground(lipgloss.Color(catppuccinBase)).
			Background(lipgloss.Color(catppuccinPeach)).
			Padding(0, 1),
		tagRoot: lipgloss.NewStyle().
			Foreground(lipgloss.Color(catppuccinBase)).
			Background(lipgloss.Color(catppuccinBlue)).
			Padding(0, 1),
		categoryHeader: lipgloss.NewStyle().
			Foreground(lipgloss.Color(catppuccinYellow)).
			Bold(true),
		selectedPanel: lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color(catppuccinOverlay)).
			Padding(0, 1),
		menuItem: lipgloss.NewStyle().Foreground(lipgloss.Color(catppuccinOverlay)),
		menuSelected: lipgloss.NewStyle().
			Foreground(lipgloss.Color(catppuccinPeach)).
			Bold(true),
	}
}

func detectDistro() string {
	data, err := os.ReadFile("/etc/os-release")
	if err != nil {
		return "desconhecida"
	}

	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		if value, ok := osReleaseValue(line, "PRETTY_NAME"); ok {
			return value
		}
	}

	for _, line := range lines {
		if value, ok := osReleaseValue(line, "NAME"); ok {
			return value
		}
	}

	return "desconhecida"
}

func osReleaseValue(line, key string) (string, bool) {
	prefix := key + "="
	if !strings.HasPrefix(line, prefix) {
		return "", false
	}

	value := strings.TrimPrefix(line, prefix)
	value = strings.Trim(value, `"`)
	value = strings.TrimSpace(value)
	if value == "" {
		return "", false
	}

	return value, true
}

func outputLimitFromEnv() int {
	const defaultLimit = 500
	raw := strings.TrimSpace(os.Getenv("BASHLN_TUI_OUTPUT_LINES"))
	if raw == "" {
		return defaultLimit
	}

	parsed, err := strconv.Atoi(raw)
	if err != nil || parsed < 50 {
		return defaultLimit
	}

	if parsed > 5000 {
		return 5000
	}

	return parsed
}

func (m Model) Init() tea.Cmd {
	return func() tea.Msg {
		return modeMainMenu
	}
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch m.mode {
		case modeMainMenu:
			return m.handleMainMenuKeys(msg)
		case modeList, modeDone:
			return m.handleListKeys(msg)
		case modePkgEdit:
			return m.handlePackageKeys(msg)
		case modeSettings:
			return m.handleSettingsKeys(msg)
		case modeRunning:
			return m.handleRunningKeys(msg)
		}

	case mode:
		if msg == modeMainMenu {
			m.mode = modeMainMenu
			return m, nil
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		available := msg.Height - 10
		if available < 6 {
			available = 6
		}
		m.listHeight = available
		return m, nil

	case streamEventMsg:
		if !msg.ok {
			if m.current >= 0 && m.scripts[m.current].Status == scripts.StatusRunning {
				m.scripts[m.current].Status = scripts.StatusFailed
				m.scripts[m.current].LastError = "canal de eventos encerrado sem status final"
				m.failureCount++
				m.pushOutput(fmt.Sprintf("%s: stream encerrada inesperadamente", m.scripts[m.current].ID))
			}
			m.markRemainingSkipped()
			m.mode = modeMainMenu
			m.current = -1
			m.lastMessage = "Execucao encerrada com erro de stream."
			return m, nil
		}

		e := msg.event
		switch e.Type {
		case runner.EventOutput:
			m.pushOutput(fmt.Sprintf("%s: %s", e.Script.ID, e.Line))
			return m, waitStreamEvent(m.events)
		case runner.EventDone:
			idx := m.current
			if idx >= 0 {
				if e.Err != nil {
					if errors.Is(e.Err, context.Canceled) {
						m.scripts[idx].Status = scripts.StatusCanceled
						m.scripts[idx].LastError = "cancelado"
						m.canceledCount++
						m.pushOutput(fmt.Sprintf("%s: cancelado", e.Script.ID))
					} else {
						m.scripts[idx].Status = scripts.StatusFailed
						m.scripts[idx].LastError = e.Err.Error()
						m.failureCount++
						m.pushOutput(fmt.Sprintf("%s: falhou (%v)", e.Script.ID, e.Err))
					}
				} else {
					m.scripts[idx].Status = scripts.StatusOK
					m.scripts[idx].LastError = ""
					m.successCount++
					m.pushOutput(fmt.Sprintf("%s: concluido com sucesso", e.Script.ID))
				}
			}

			cmd := m.startNext()
			return m, cmd
		}

	case interactiveDoneMsg:
		idx := msg.idx
		if msg.err != nil {
			if m.cancelRequested || errors.Is(msg.err, context.Canceled) {
				m.scripts[idx].Status = scripts.StatusCanceled
				m.scripts[idx].LastError = "cancelado"
				m.canceledCount++
				m.pushOutput(fmt.Sprintf("%s: interativo cancelado", m.scripts[idx].ID))
			} else {
				m.scripts[idx].Status = scripts.StatusFailed
				m.scripts[idx].LastError = msg.err.Error()
				m.failureCount++
				m.pushOutput(fmt.Sprintf("%s: interativo falhou (%v)", m.scripts[idx].ID, msg.err))
			}
		} else {
			m.scripts[idx].Status = scripts.StatusOK
			m.scripts[idx].LastError = ""
			m.successCount++
			m.pushOutput(fmt.Sprintf("%s: interativo concluido", m.scripts[idx].ID))
		}
		m.runCancel = nil

		cmd := m.startNext()
		return m, cmd

	case runDoneMsg:
		m.mode = modeMainMenu
		m.current = -1
		m.runCancel = nil
		m.cancelRequested = false
		m.lastMessage = fmt.Sprintf("Execucao finalizada: %d sucesso(s), %d falha(s), %d cancelado(s).", m.successCount, m.failureCount, m.canceledCount)
		return m, nil
	}

	return m, nil
}

func (m Model) View() string {
	var b strings.Builder

	b.WriteString(m.styles.header.Render("pomo-tui (MVP)") + "\n")

	switch m.mode {
	case modeMainMenu:
		b.WriteString(m.styles.muted.Render("Controles: j/k/setas navegar | enter selecionar | esc/q sair") + "\n")
		if m.lastMessage != "" {
			b.WriteString(m.styles.statusInfo.Render("Mensagem: "+m.lastMessage) + "\n")
		}
		b.WriteString("\n")

		items := []string{"Instalar pacotes", "Configuracoes", "Sair"}
		for i, item := range items {
			cursor := "  "
			style := m.styles.menuItem
			if i == m.menuCursor {
				cursor = "> "
				style = m.styles.menuSelected
			}
			b.WriteString(style.Render(cursor + item))
			b.WriteString("\n")
		}

	case modeSettings:
		b.WriteString(m.styles.header.Render("Configuracoes") + "\n")
		b.WriteString(m.styles.muted.Render("Controles: esc voltar | q sair") + "\n\n")
		b.WriteString("Path scripts ativo: " + m.archPath + "\n")
		b.WriteString("Distro detectada: " + m.distroName + "\n")
		b.WriteString("Overrides: " + m.overridePath + "\n")

	case modeList, modeDone:
		b.WriteString(m.styles.muted.Render("Controles: j/k/setas navegar | pgup/b pgdown/f paginar | home/g end/G topo/fim") + "\n")
		b.WriteString(m.styles.muted.Render("Acoes: espaco/enter toggle | a toggle all | p pacotes | r executar | q sair") + "\n")
		b.WriteString(m.styles.muted.Render("Voltar: esc menu inicial") + "\n")
		if m.lastMessage != "" {
			b.WriteString(m.styles.statusInfo.Render("Mensagem: "+m.lastMessage) + "\n")
		}
		b.WriteString("\n")
		rows := m.listRows()
		start, end := m.visibleRange(rows)
		enabledCount := 0
		for _, s := range m.scripts {
			if s.Enabled {
				enabledCount++
			}
		}
		categoryCount := len(rows) - len(m.scripts)
		b.WriteString(m.styles.footer.Render(fmt.Sprintf("Scripts habilitados: %d/%d | Categorias: %d", enabledCount, len(m.scripts), categoryCount)) + "\n")
		if len(rows) > 0 {
			b.WriteString(m.styles.muted.Render(fmt.Sprintf("Mostrando linhas: %d-%d de %d", start+1, end, len(rows))) + "\n")
		}
		b.WriteString("\n")

		for _, row := range rows[start:end] {
			b.WriteString(m.renderListRow(row) + "\n")
		}

		if selected := m.selectedScript(); selected != nil {
			b.WriteString("\n")
			b.WriteString(m.renderSelectedPanel(*selected) + "\n")
		}

		if m.mode == modeDone {
			b.WriteString("\n")
			b.WriteString(m.styles.footer.Render(fmt.Sprintf("Resultado: %d sucesso(s), %d falha(s), %d cancelado(s)", m.successCount, m.failureCount, m.canceledCount)) + "\n")
		}

	case modePkgEdit:
		b.WriteString(m.styles.header.Render("Editar Pacotes") + "\n")
		b.WriteString(m.styles.muted.Render("Controles: j/k navegar | espaco/enter alternar pacote | a alternar todos | esc voltar") + "\n")
		if m.lastMessage != "" {
			b.WriteString(m.styles.statusInfo.Render("Mensagem: "+m.lastMessage) + "\n")
		}
		b.WriteString("\n")
		b.WriteString(m.renderPackageEditor() + "\n")

	case modeRunning:
		b.WriteString(m.styles.header.Render("Executando fila") + "\n")
		b.WriteString(m.styles.muted.Render("Controles: esc/ctrl+c cancelar | q aviso | r ignorado") + "\n")
		if m.lastMessage != "" {
			b.WriteString(m.styles.statusInfo.Render("Mensagem: "+m.lastMessage) + "\n")
		}
		if m.current >= 0 {
			b.WriteString(fmt.Sprintf("Atual: %s\n", m.scripts[m.current].ID))
			if m.scripts[m.current].Interactive {
				b.WriteString(m.styles.statusWarn.Render("Modo interativo anexado ao terminal: responda ao prompt no shell atual.") + "\n")
			}
		}
		b.WriteString(m.styles.footer.Render(fmt.Sprintf("Progresso: %d/%d", m.queuePos, len(m.queue))) + "\n")
		b.WriteString("\n" + m.styles.muted.Render("Saida recente:") + "\n")

		start := 0
		if len(m.output) > 20 {
			start = len(m.output) - 20
		}
		for _, line := range m.output[start:] {
			b.WriteString(line + "\n")
		}
	}

	return b.String()
}

func (m Model) renderScriptLine(index int, s scripts.Script) string {
	cursor := " "
	if index == m.cursor {
		if m.styles.mono {
			cursor = ">>"
		} else {
			cursor = m.styles.cursor.Render(">")
		}
	}

	enabled := "[ ]"
	if s.Enabled {
		enabled = "[x]"
	}

	line := fmt.Sprintf("%-2s %s %-28s (%s)%s", cursor, enabled, s.Name, m.renderStatus(s.Status), m.renderTags(s))
	if index == m.cursor {
		return m.styles.selected.Render(line)
	}

	return line
}

func (m Model) renderListRow(row listRow) string {
	if row.isHeader {
		label := fmt.Sprintf(" %s (%d) ", row.category, row.count)
		if m.styles.mono {
			return strings.ToUpper(label)
		}
		return m.styles.categoryHeader.Render(label)
	}

	return m.renderScriptLine(row.scriptIndex, m.scripts[row.scriptIndex])
}

func (m Model) renderStatus(status scripts.Status) string {
	label := string(status)
	switch status {
	case scripts.StatusQueued, scripts.StatusRunning:
		return m.styles.statusWarn.Render(label)
	case scripts.StatusOK:
		return m.styles.statusOK.Render(label)
	case scripts.StatusFailed:
		return m.styles.statusFailed.Render(label)
	case scripts.StatusCanceled:
		return m.styles.statusInfo.Render(label)
	case scripts.StatusSkipped:
		return m.styles.muted.Render(label)
	default:
		return m.styles.statusDefault.Render(label)
	}
}

func (m Model) renderTags(s scripts.Script) string {
	tags := []string{}
	if s.RequiresRoot {
		tags = append(tags, "root")
	}
	if s.Interactive {
		tags = append(tags, "interactive")
	}

	if len(tags) == 0 {
		return ""
	}

	if m.styles.mono {
		return " [" + strings.Join(tags, ",") + "]"
	}

	rendered := make([]string, 0, len(tags))
	for _, tag := range tags {
		switch tag {
		case "root":
			rendered = append(rendered, m.styles.tagRoot.Render(tag))
		case "interactive":
			rendered = append(rendered, m.styles.tagInteractive.Render(tag))
		default:
			rendered = append(rendered, tag)
		}
	}

	return " " + strings.Join(rendered, " ")
}

func (m Model) renderSelectedPanel(s scripts.Script) string {
	enabledStr := "[ ] Não"
	if s.Enabled {
		enabledStr = "[x] Sim"
	}
	lines := []string{
		fmt.Sprintf("Selecionado: %s", s.Name),
		fmt.Sprintf("Categoria: %s", s.Category),
		fmt.Sprintf("Script: %s", s.ID),
		fmt.Sprintf("Descricao: %s", s.Description),
		fmt.Sprintf("Estado: %s", m.renderStatus(s.Status)),
		fmt.Sprintf("Habilitado: %s", enabledStr),
	}
	if len(s.Packages) > 0 {
		preview := strings.Join(s.Packages, ", ")
		if len(preview) > 90 {
			preview = preview[:90] + "..."
		}
		lines = append(lines, fmt.Sprintf("Pacotes (%d): %s", len(s.Packages), preview))
	}
	if len(s.SkipPackages) > 0 {
		lines = append(lines, "Ignorados: "+strings.Join(s.SkipPackages, ", "))
	}
	if s.RequiresRoot || s.Interactive {
		lines = append(lines, "Tags:"+m.renderTags(s))
	}
	if len(s.Packages) > 0 {
		lines = append(lines, "Dica: pressione 'p' para personalizar pacotes")
	}
	content := strings.Join(lines, "\n")
	if m.styles.mono {
		return content
	}
	return m.styles.selectedPanel.Render(content)
}

func (m Model) renderPackageEditor() string {
	if len(m.scripts) == 0 || m.cursor < 0 || m.cursor >= len(m.scripts) {
		return "Nenhum script selecionado."
	}

	s := m.scripts[m.cursor]
	if len(s.Packages) == 0 {
		return fmt.Sprintf("Script %s nao expoe pacotes detectaveis.", s.Name)
	}

	if m.packageCursor < 0 {
		m.packageCursor = 0
	}
	if m.packageCursor >= len(s.Packages) {
		m.packageCursor = len(s.Packages) - 1
	}

	skipped := map[string]bool{}
	for _, pkg := range s.SkipPackages {
		skipped[pkg] = true
	}

	var b strings.Builder
	b.WriteString(fmt.Sprintf("Script: %s\n", s.Name))
	b.WriteString(fmt.Sprintf("Arquivo: %s\n", filepath.Base(s.Path)))
	b.WriteString("\n")

	for i, pkg := range s.Packages {
		cursor := "  "
		if i == m.packageCursor {
			cursor = "> "
		}
		status := "[x] instalar"
		if skipped[pkg] {
			status = "[ ] ignorar"
		}
		line := fmt.Sprintf("%s%-18s %s", cursor, pkg, status)
		if i == m.packageCursor {
			line = m.styles.selected.Render(line)
		}
		b.WriteString(line + "\n")
	}

	return strings.TrimRight(b.String(), "\n")
}

func (m Model) selectedScript() *scripts.Script {
	if len(m.scripts) == 0 || m.cursor < 0 || m.cursor >= len(m.scripts) {
		return nil
	}
	return &m.scripts[m.cursor]
}

func (m Model) listRows() []listRow {
	if len(m.scripts) == 0 {
		return nil
	}

	counts := map[string]int{}
	for _, s := range m.scripts {
		counts[s.Category]++
	}

	rows := make([]listRow, 0, len(m.scripts)+10)
	current := ""
	for i, s := range m.scripts {
		if s.Category != current {
			current = s.Category
			rows = append(rows, listRow{category: current, isHeader: true, count: counts[current]})
		}
		rows = append(rows, listRow{category: current, scriptIndex: i})
	}
	return rows
}

func (m Model) currentRowIndex(rows []listRow) int {
	if len(rows) == 0 {
		return 0
	}
	for i, row := range rows {
		if !row.isHeader && row.scriptIndex == m.cursor {
			return i
		}
	}
	return 0
}

func (m Model) handleListKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	if m.mode == modeDone {
		switch msg.String() {
		case "esc", "enter":
			m.mode = modeMainMenu
			return m, nil
		}
	}

	switch msg.String() {
	case "ctrl+c", "q":
		m.quitting = true
		return m, tea.Quit
	case "esc":
		m.mode = modeMainMenu
		return m, nil
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
	case "down", "j":
		if m.cursor < len(m.scripts)-1 {
			m.cursor++
		}
	case "pgup", "b":
		m.cursor -= m.listHeight
		if m.cursor < 0 {
			m.cursor = 0
		}
	case "pgdown", "f":
		m.cursor += m.listHeight
		if m.cursor >= len(m.scripts) {
			m.cursor = len(m.scripts) - 1
		}
	case "home", "g":
		m.cursor = 0
	case "end", "G":
		if len(m.scripts) > 0 {
			m.cursor = len(m.scripts) - 1
		}
	case " ", "enter":
		if len(m.scripts) > 0 {
			m.scripts[m.cursor].Enabled = !m.scripts[m.cursor].Enabled
		}
	case "a":
		allEnabled := true
		for _, s := range m.scripts {
			if !s.Enabled {
				allEnabled = false
				break
			}
		}
		for i := range m.scripts {
			m.scripts[i].Enabled = !allEnabled
		}
	case "r":
		return m.startRun()
	case "p":
		if len(m.scripts) == 0 {
			m.lastMessage = "Nenhum script selecionado."
			return m, nil
		}
		if len(m.scripts[m.cursor].Packages) == 0 {
			m.lastMessage = "Script selecionado nao possui lista de pacotes detectavel."
			return m, nil
		}
		m.packageCursor = 0
		m.mode = modePkgEdit
		return m, nil
	}

	return m, nil
}

func (m Model) handlePackageKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	if len(m.scripts) == 0 || m.cursor < 0 || m.cursor >= len(m.scripts) {
		m.mode = modeList
		return m, nil
	}

	s := &m.scripts[m.cursor]
	if len(s.Packages) == 0 {
		m.mode = modeList
		return m, nil
	}

	switch msg.String() {
	case "ctrl+c", "q":
		m.quitting = true
		return m, tea.Quit
	case "esc":
		m.mode = modeList
		m.lastMessage = "Editor de pacotes fechado."
		return m, nil
	case "up", "k":
		if m.packageCursor > 0 {
			m.packageCursor--
		}
	case "down", "j":
		if m.packageCursor < len(s.Packages)-1 {
			m.packageCursor++
		}
	case "home", "g":
		m.packageCursor = 0
	case "end", "G":
		m.packageCursor = len(s.Packages) - 1
	case " ", "enter":
		pkg := s.Packages[m.packageCursor]
		toggleSkipPackage(s, pkg)
		if err := m.persistScriptSkips(s); err != nil {
			m.lastMessage = fmt.Sprintf("erro salvando overrides: %v", err)
		} else {
			m.lastMessage = fmt.Sprintf("Pacote atualizado: %s", pkg)
		}
	case "a":
		allSkipped := len(s.SkipPackages) == len(s.Packages)
		if allSkipped {
			s.SkipPackages = nil
			m.lastMessage = "Todos os pacotes marcados para instalar."
		} else {
			s.SkipPackages = append([]string{}, s.Packages...)
			m.lastMessage = "Todos os pacotes marcados para ignorar."
		}
		if err := m.persistScriptSkips(s); err != nil {
			m.lastMessage = fmt.Sprintf("erro salvando overrides: %v", err)
		}
	}

	return m, nil
}

func toggleSkipPackage(s *scripts.Script, pkg string) {
	for i, current := range s.SkipPackages {
		if current != pkg {
			continue
		}
		s.SkipPackages = append(s.SkipPackages[:i], s.SkipPackages[i+1:]...)
		return
	}
	s.SkipPackages = append(s.SkipPackages, pkg)
}

func (m *Model) persistScriptSkips(s *scripts.Script) error {
	if m.overrides.Interactive == nil {
		m.overrides.Interactive = map[string]bool{}
	}
	if m.overrides.RequiresRoot == nil {
		m.overrides.RequiresRoot = map[string]bool{}
	}
	if m.overrides.SkipPackages == nil {
		m.overrides.SkipPackages = map[string][]string{}
	}

	key := filepath.Base(s.Path)
	if len(s.SkipPackages) == 0 {
		delete(m.overrides.SkipPackages, key)
	} else {
		clean := make([]string, 0, len(s.SkipPackages))
		seen := map[string]bool{}
		for _, pkg := range s.SkipPackages {
			pkg = strings.TrimSpace(pkg)
			if pkg == "" || seen[pkg] {
				continue
			}
			seen[pkg] = true
			clean = append(clean, pkg)
		}
		m.overrides.SkipPackages[key] = clean
		s.SkipPackages = clean
	}

	return scripts.SaveOverrides(m.overridePath, m.overrides)
}

func (m Model) handleMainMenuKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c", "q", "esc":
		m.quitting = true
		return m, tea.Quit
	case "up", "k":
		if m.menuCursor > 0 {
			m.menuCursor--
		}
		return m, nil
	case "down", "j":
		if m.menuCursor < mainMenuQuit {
			m.menuCursor++
		}
		return m, nil
	case "enter":
		switch m.menuCursor {
		case mainMenuInstall:
			m.mode = modeList
			return m, nil
		case mainMenuSettings:
			m.mode = modeSettings
			return m, nil
		case mainMenuQuit:
			m.quitting = true
			return m, tea.Quit
		}
	}

	return m, nil
}

func (m Model) handleSettingsKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c", "q":
		m.quitting = true
		return m, tea.Quit
	case "esc":
		m.mode = modeMainMenu
		return m, nil
	}

	return m, nil
}

func (m Model) handleRunningKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "esc", "ctrl+c":
		if m.cancelRequested {
			return m, nil
		}

		m.cancelRequested = true
		m.markRemainingSkipped()
		if m.runCancel != nil {
			m.runCancel()
			if m.current >= 0 && m.current < len(m.scripts) && m.scripts[m.current].Interactive {
				m.lastMessage = "Cancelamento solicitado. Se o prompt interativo ainda estiver aberto, finalize-o para voltar ao TUI."
			} else {
				m.lastMessage = "Cancelamento solicitado."
			}
		} else {
			m.lastMessage = "Script interativo em foreground; finalize-o para continuar."
		}
		return m, nil
	case "q":
		m.lastMessage = "Execucao em andamento; use esc/ctrl+c para cancelar."
		return m, nil
	case "r":
		m.lastMessage = "Execucao ja em andamento."
		return m, nil
	}

	return m, nil
}

func (m Model) startRun() (tea.Model, tea.Cmd) {
	if m.mode == modeRunning {
		m.lastMessage = "Execucao ja em andamento."
		return m, nil
	}

	m.queue = m.queue[:0]
	m.queuePos = 0
	m.successCount = 0
	m.failureCount = 0
	m.canceledCount = 0
	m.cancelRequested = false
	m.output = m.output[:0]
	m.current = -1

	for i := range m.scripts {
		m.scripts[i].LastError = ""
		if m.scripts[i].Enabled {
			m.scripts[i].Status = scripts.StatusQueued
			m.queue = append(m.queue, i)
		} else {
			m.scripts[i].Status = scripts.StatusIdle
		}
	}

	if len(m.queue) == 0 {
		m.lastMessage = "Nenhum script habilitado para executar."
		return m, nil
	}

	m.mode = modeRunning
	m.lastMessage = ""

	if err := os.MkdirAll(filepath.Dir(m.logPath), 0o755); err != nil {
		m.lastMessage = fmt.Sprintf("aviso: falha ao preparar diretório de logs: %v", err)
	}

	cmd := m.startNext()
	return m, cmd
}

func (m *Model) startNext() tea.Cmd {
	if m.queuePos >= len(m.queue) {
		return func() tea.Msg { return runDoneMsg{} }
	}

	idx := m.queue[m.queuePos]
	m.queuePos++
	m.current = idx
	m.scripts[idx].Status = scripts.StatusRunning

	script := m.scripts[idx]
	if script.Interactive {
		ctx, cancel := context.WithCancel(context.Background())
		m.runCancel = cancel
		m.lastMessage = "Modo interativo anexado ao terminal. Responda ao prompt abaixo; ao finalizar, a TUI retorna automaticamente."
		m.pushOutput(fmt.Sprintf("%s: iniciando modo interativo (attach)", script.ID))

		cmd, err := runner.BuildCommandWithContext(ctx, script, m.logPath)
		if err != nil {
			m.runCancel = nil
			m.scripts[idx].Status = scripts.StatusFailed
			m.scripts[idx].LastError = err.Error()
			m.failureCount++
			m.pushOutput(fmt.Sprintf("%s: erro de execucao (%v)", script.ID, err))
			return m.startNext()
		}

		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr

		return tea.ExecProcess(cmd, func(err error) tea.Msg {
			return interactiveDoneMsg{idx: idx, err: err}
		})
	}

	ctx, cancel := context.WithCancel(context.Background())
	m.runCancel = cancel
	m.events = runner.StartStream(ctx, script, m.logPath)
	return waitStreamEvent(m.events)
}

func waitStreamEvent(ch <-chan runner.Event) tea.Cmd {
	return func() tea.Msg {
		e, ok := <-ch
		return streamEventMsg{event: e, ok: ok}
	}
}

func (m *Model) markRemainingSkipped() {
	current := m.current
	if current >= 0 && m.scripts[current].Status == scripts.StatusQueued {
		m.scripts[current].Status = scripts.StatusRunning
	}

	for i := m.queuePos; i < len(m.queue); i++ {
		idx := m.queue[i]
		if idx == current {
			continue
		}
		if m.scripts[idx].Status == scripts.StatusQueued {
			m.scripts[idx].Status = scripts.StatusSkipped
			m.scripts[idx].LastError = ""
		}
	}
	m.queuePos = len(m.queue)
}

func (m *Model) pushOutput(line string) {
	m.output = append(m.output, line)
	if len(m.output) > m.outputLimit {
		m.output = m.output[len(m.output)-m.outputLimit:]
	}
}

func (m Model) visibleRange(rows []listRow) (int, int) {
	total := len(rows)
	if total == 0 {
		return 0, 0
	}

	window := m.listHeight
	if window < 1 {
		window = 1
	}
	if window > total {
		window = total
	}

	currentRow := m.currentRowIndex(rows)
	start := currentRow - (window / 2)
	if start < 0 {
		start = 0
	}
	if start+window > total {
		start = total - window
	}
	if start < 0 {
		start = 0
	}

	end := start + window
	if end > total {
		end = total
	}

	return start, end
}
