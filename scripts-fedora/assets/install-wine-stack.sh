#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando Wine e componentes relacionados"

    packages=(
        "wine"
        "winetricks"
        "wine-mono"
        "wine-gecko"
    )

    for pkg in "${packages[@]}"; do
        ensure_package "$pkg"
    done

    ok "Wine stack instalada."
}

main "$@"
