#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    # --- Oh My Bash -----------------------------------------------------------
    info "Instalando Oh My Bash..."

    if [ -d "$HOME/.oh-my-bash" ]; then
        ok "Oh My Bash já está instalado."
    else
        if bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"; then
            ok "Oh My Bash instalado."
        else
            fail "Falha ao instalar Oh My Bash."
        fi
    fi

    # --- Starship -------------------------------------------------------------
    info "Instalando Starship..."

    if command -v starship >/dev/null 2>&1; then
        ok "Starship já instalado."
    else
        if ensure_package "starship"; then
            ok "Starship instalado via dnf/rpm-ostree."
        else
            warn "Falha ao instalar Starship via gerenciador, tentando via script oficial..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y || warn "Falha ao instalar Starship via script."
        fi
    fi

    # --- Configuração no Bash -------------------------------------------------
    if ! grep -q 'eval "$(starship init bash)"' "$HOME/.bashrc"; then
        info "Configurando Starship no Bash..."
        echo '' >> "$HOME/.bashrc"
        echo '# Inicialização do Starship prompt' >> "$HOME/.bashrc"
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
        ok "Starship configurado no Bash."
    else
        ok "Starship já configurado no Bash."
    fi

    ok "Oh My Bash + Starship prontos para uso."
}

main "$@"
