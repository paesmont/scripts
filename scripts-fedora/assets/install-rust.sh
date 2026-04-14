#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando Rust e rust-analyzer"

    packages=(
        "rust"
        "rust-analyzer"
    )

    for pkg in "${packages[@]}"; do
        ensure_package "$pkg"
    done

    ok "Rust instalado."
}

main "$@"
