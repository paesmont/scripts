#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando dependências para Yazi"

    packages=(
        "yazi" # TODO: confirmar se o pacote existe no Fedora oficial
        "ffmpeg"
        "p7zip"
        "jq"
        "poppler-utils"
        "fd-find"
        "ripgrep"
        "fzf"
        "zoxide"
        "resvg" # TODO: confirmar se o pacote existe no Fedora oficial
        "imagemagick"
    )

    for pkg in "${packages[@]}"; do
        ensure_package "$pkg"
    done

    ok "Dependências para Yazi instaladas."
}

main "$@"
