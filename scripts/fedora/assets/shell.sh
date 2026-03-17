#!/usr/bin/env bash
# =============================================================================
# install/shell.sh - Fish + Starship + configurações
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/utils.sh"

check_root

info "Instalando Fish..."
if ! has_command fish; then
    case "$PKG_MANAGER" in
        dnf)
            if ensure_pkg fish && ensure_pkg util-linux-user; then
                ok "Fish instalado"
            else
                log_error "Falha ao instalar Fish via dnf"
                exit 1
            fi
            ;;
        apt)
            if ensure_pkg fish; then
                ok "Fish instalado"
            else
                log_error "Falha ao instalar Fish via apt"
                exit 1
            fi
            ;;
    esac
else
    info "Fish já instalado"
fi

info "Instalando Starship..."
if ! has_command starship; then
    if ensure_pkg starship 2>/dev/null; then
        ok "Starship instalado via repositório"
    else
        mkdir -p "$HOME/.local/bin"
        if curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"; then
            ok "Starship instalado em $HOME/.local/bin"
        else
            log_error "Falha ao instalar Starship"
        fi
    fi
else
    info "Starship já instalado"
fi

mkdir -p ~/.config/fish/conf.d
if [[ ! -f ~/.config/fish/conf.d/local-bin.fish ]]; then
    cat >~/.config/fish/conf.d/local-bin.fish <<'EOF'
if test -d "$HOME/.local/bin"
  fish_add_path -g "$HOME/.local/bin"
end
EOF
fi

info "Instalando Fisher (gerenciador de plugins Fish)..."
if ! fish -c "type -q fisher" 2>/dev/null; then
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
    ok "Fisher instalado"
fi

info "Instalando plugins úteis do Fish..."
fish -c "fisher install jorgebucaran/nvm.fish" 2>/dev/null || true
fish -c "fisher install jethrokuan/z" 2>/dev/null || true
fish -c "fisher install PatrickF1/fzf.fish" 2>/dev/null || true

info "Criando diretório de configuração do Fish..."
mkdir -p ~/.config/fish

info "Shell configurado com sucesso!"
info "Reinicie o terminal ou execute 'fish' para começar a usar."

ok "Fish + Starship instalados!"
