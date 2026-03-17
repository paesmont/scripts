#!/usr/bin/env bash
# =============================================================================
# install/cli-tools.sh - Ferramentas CLI modernas
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/utils.sh"

check_root

info "Instalando ferramentas CLI..."

case "$PKG_MANAGER" in
    dnf)
        install_list \
            ripgrep \
            fd-find \
            bat \
            zoxide \
            fzf \
            jq \
            btop \
            tmux
        ;;
    apt)
        install_list \
            ripgrep \
            fd-find \
            bat \
            zoxide \
            fzf \
            jq \
            btop \
            tmux
        ;;
esac

if has_command fdfind && ! has_command fd; then
    FD_PATH="$(command -v fdfind 2>/dev/null)"
    if [[ -n "$FD_PATH" ]]; then
        info "Criando symlink fd -> fdfind"
        sudo ln -sf "$FD_PATH" /usr/local/bin/fd
    fi
fi

info "Instalando eza..."
if ! has_command eza; then
    case "$PKG_MANAGER" in
        dnf) sudo dnf install -y eza 2>/dev/null && ok "eza instalado via dnf" ;;
        apt) sudo apt-get install -y eza 2>/dev/null && ok "eza instalado via apt" ;;
    esac
    
    if ! has_command eza; then
        eza_version="0.18.0"
        arch="$(uname -m)"
        eza_arch="${arch}-unknown-linux-gnu"
        
        if wget -q "https://github.com/eza-community/eza/releases/download/v${eza_version}/eza_${eza_arch}.tar.gz" -O /tmp/eza.tar.gz; then
            if sudo tar -xzf /tmp/eza.tar.gz -C /usr/local/bin; then
                rm /tmp/eza.tar.gz
                ok "eza instalado"
            else
                log_error "Falha ao extrair eza"
            fi
        fi
    fi
fi

info "Instalando yazi..."
if ! has_command yazi; then
    yazi_version="0.3.0"
    arch="$(uname -m)"
    yazi_arch="${arch}-unknown-linux-gnu"

    yazi_tmp="$(mktemp -d /tmp/yazi.XXXXXX)"
    if wget -q "https://github.com/sxyazi/yazi/releases/download/v${yazi_version}/yazi-${yazi_arch}.zip" -O "${yazi_tmp}/yazi.zip"; then
        if unzip -q "${yazi_tmp}/yazi.zip" -d "${yazi_tmp}"; then
            shopt -s nullglob globstar
            yazi_candidates=("${yazi_tmp}"/**/yazi)
            ya_candidates=("${yazi_tmp}"/**/ya)
            shopt -u nullglob globstar

            if [[ ${#yazi_candidates[@]} -gt 0 && ${#ya_candidates[@]} -gt 0 ]]; then
                if sudo install -m 0755 "${yazi_candidates[0]}" /usr/local/bin/yazi && sudo install -m 0755 "${ya_candidates[0]}" /usr/local/bin/ya; then
                    ok "yazi instalado"
                else
                    log_error "Falha ao instalar binários do yazi em /usr/local/bin"
                fi
            else
                log_error "Binários do yazi não encontrados no zip baixado"
            fi
        else
            log_error "Falha ao extrair yazi"
        fi
    else
        log_error "Falha ao baixar yazi"
    fi
    rm -rf "${yazi_tmp}"
fi

info "Instalando lazygit..."
if ! has_command lazygit; then
    lazygit_version="0.43.1"
    arch="$(uname -m)"
    
    if wget -q "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/lazygit_${lazygit_version}_Linux_${arch}.tar.gz" -O /tmp/lazygit.tar.gz; then
        if sudo tar -xzf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit; then
            rm /tmp/lazygit.tar.gz
            ok "lazygit instalado"
        fi
    fi
fi

ok "Todas as ferramentas CLI instaladas!"
