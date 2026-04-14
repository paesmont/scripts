#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Iniciando instalação das ferramentas de formatação..."

    local packages=(
        "ruff"
        "nodejs-prettier"
        "shfmt"
        "shellcheck"
        "ripgrep"
        "fd-find"
    )

    for pkg in "${packages[@]}"; do
        ensure_package "$pkg"
    done

    ok "Script concluído! O Doom Emacs agora tem superpoderes de formatação."
}

main "$@"
