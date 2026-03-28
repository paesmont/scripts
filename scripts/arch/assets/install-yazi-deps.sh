#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando dependências para Yazi"

    packages=(
        "yazi" # This is already a script, but it is also a dependency
        "ffmpeg"
        "7zip"
        "jq"
        "poppler"
        "fd"
        "ripgrep"
        "fzf"
        "zoxide" # This is already a script, but it is also a dependency
        "resvg"
        "imagemagick"
    )

    for pkg in "${packages[@]}"; do
        ensure_package "$pkg"
    done

    ok "Dependências para Yazi instaladas."
}

main "$@"