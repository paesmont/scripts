#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando tmux"
    ensure_package "tmux"

    if ! command -v tmux &>/dev/null; then
        fail "Instalacao do tmux falhou."
        exit 1
    fi

    TPM_DIR="$HOME/.tmux/plugins/tpm"

    if [ -d "$TPM_DIR" ]; then
        ok "TPM ja esta instalado em $TPM_DIR"
    else
        info "Instalando Tmux Plugin Manager (TPM)..."
        git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
    fi

    ok "TPM instalado com sucesso!"
}

main "$@"
