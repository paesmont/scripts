#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando bibliotecas 32-bit auxiliares"

    # Fedora: multilib usa sufixo .i686
    packages=(
        "giflib.i686"
        "gnutls.i686"
        "v4l-utils.i686"
        "libpulse.i686"
        "alsa-lib.i686"
        "libXcomposite.i686"
        "libXinerama.i686"
        "ocl-icd.i686"
        "gstreamer1-plugins-base.i686"
        "SDL2.i686"
    )

    for pkg in "${packages[@]}"; do
        ensure_package "$pkg"
    done

    ok "Bibliotecas 32-bit instaladas."
}

main "$@"
