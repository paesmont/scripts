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
            if sudo dnf install -y fish util-linux-user; then
                ok "Fish instalado"
            else
                log_error "Falha ao instalar Fish via dnf"
                exit 1
            fi
            ;;
        apt)
            if sudo apt-get install -y fish; then
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
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    ok "Starship instalado"
else
    info "Starship já instalado"
fi

info "Configurando Fish como shell padrão..."
if [[ "$SHELL" != *"fish"* ]]; then
    FISH_PATH="$(which fish 2>/dev/null)"
    if [[ -n "$FISH_PATH" ]]; then
        if chsh -s "$FISH_PATH"; then
            ok "Fish configurado como shell padrão"
        else
            log_warn "Não foi possível alterar o shell padrão"
        fi
    else
        log_warn "Caminho do Fish não encontrado"
    fi
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
