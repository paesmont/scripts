#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando ferramentas Python (pylsp, black)"

    # Fedora: pacotes python3-*
    packages=(
        "python3-python-lsp-server"
        "python3-black"
    )

    for pkg in "${packages[@]}"; do
        ensure_package "$pkg"
    done

    ok "Ferramentas Python instaladas."
}

main "$@"
