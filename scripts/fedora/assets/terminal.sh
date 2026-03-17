#!/usr/bin/env bash
# =============================================================================
# install/terminal.sh - Terminais suportados (Alacritty, Kitty, Ghostty)
# TUI_PACKAGES: alacritty, kitty, ghostty
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/utils.sh"

check_root

configure_alacritty() {
    mkdir -p ~/.config/alacritty
    if [[ ! -f ~/.config/alacritty/alacritty.toml ]]; then
        cat >~/.config/alacritty/alacritty.toml <<'EOF'
[window]
decorations = "None"
startup_mode = "Windowed"
dynamic_title = true

[font]
normal = { family = "FiraCode Nerd Font", style = "Regular" }
size = 11.0

[colors]
primary = { background = "#1e1e2e", foreground = "#cdd6f4" }

[cursor]
style = { shape = "Beam", blinking = "On" }

[selection]
save_to_clipboard = true
EOF
        ok "Configuração inicial do Alacritty criada"
    fi
}

configure_kitty() {
    mkdir -p ~/.config/kitty
    if [[ ! -f ~/.config/kitty/kitty.conf ]]; then
        cat >~/.config/kitty/kitty.conf <<'EOF'
font_family FiraCode Nerd Font
font_size 11.0
cursor_shape beam
confirm_os_window_close 0
EOF
        ok "Configuração inicial do Kitty criada"
    fi
}

configure_ghostty() {
    mkdir -p ~/.config/ghostty
    if [[ ! -f ~/.config/ghostty/config ]]; then
        cat >~/.config/ghostty/config <<'EOF'
font-family = FiraCode Nerd Font
font-size = 11
theme = dark:catppuccin-mocha,light:catppuccin-latte
EOF
        ok "Configuração inicial do Ghostty criada"
    fi
}

install_terminal() {
    local pkg="$1"
    local command_name="$2"
    local label="$3"
    local configure_fn="$4"

    if is_skipped_pkg "$pkg"; then
        info "${label} marcado para ignorar; pulando."
        return 0
    fi

    info "Instalando ${label}..."
    ensure_pkg "$pkg" || true

    if ! has_command "$command_name"; then
        log_warn "${label} não disponível no repositório; pulando."
        return 0
    fi

    "$configure_fn"
    ok "${label} configurado!"
}

info "Configurando terminais..."
install_terminal alacritty alacritty Alacritty configure_alacritty
install_terminal kitty kitty Kitty configure_kitty
install_terminal ghostty ghostty Ghostty configure_ghostty

ok "Configuração de terminais concluída!"
