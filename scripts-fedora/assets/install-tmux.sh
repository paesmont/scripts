#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando tmux"
    ensure_package "tmux"

    # Check if tmux is installed
    if ! command -v tmux &>/dev/null; then
        fail "Instalação do tmux falhou."
        exit 1
    fi

    TPM_DIR="$HOME/.tmux/plugins/tpm"

    # Check if TPM is already installed
    if [ -d "$TPM_DIR" ]; then
        ok "TPM já está instalado em $TPM_DIR"
    else
        info "Instalando Tmux Plugin Manager (TPM)..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    fi

    ok "TPM instalado com sucesso!"
}

main "$@"
