#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando nodejs e npm"

    packages=(
        "nodejs"
        "npm"
    )

    for pkg in "${packages[@]}"; do
        ensure_package "$pkg"
    done

    ok "Node.js e npm instalados."
}

main "$@"
