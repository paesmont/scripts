#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando asdf-vm"

    ASDF_DIR="${HOME}/.asdf"

    if [ -d "$ASDF_DIR" ]; then
        info "asdf ja esta instalado em $ASDF_DIR. Atualizando..."
        cd "$ASDF_DIR" && git pull origin master 2>/dev/null || warn "Falha ao atualizar asdf."
        ok "asdf atualizado."
        return 0
    fi

    info "Clonando asdf..."
    git clone --depth=1 https://github.com/asdf-vm/asdf.git "$ASDF_DIR" --branch v0.14.1

    # Configura no bashrc se necessario
    if ! grep -q 'asdf.sh' "$HOME/.bashrc" 2>/dev/null; then
        info "Adicionando asdf ao .bashrc..."
        echo '' >> "$HOME/.bashrc"
        echo '# asdf version manager' >> "$HOME/.bashrc"
        echo '. "$HOME/.asdf/asdf.sh"' >> "$HOME/.bashrc"
        echo '. "$HOME/.asdf/completions/asdf.bash"' >> "$HOME/.bashrc"
    fi

    ok "asdf-vm instalado. Reinicie o shell ou execute: source ~/.bashrc"
}

main "$@"
