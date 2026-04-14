#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando Mesa e drivers Vulkan para Radeon"

    # Fedora: drivers Mesa/Vulkan são separados e usam pacotes .i686 para 32-bit
    packages=(
        "mesa-dri-drivers"
        "mesa-vulkan-drivers"
        "mesa-dri-drivers.i686"
        "mesa-vulkan-drivers.i686"
    )

    for pkg in "${packages[@]}"; do
        ensure_package "$pkg"
    done

    ok "Mesa + Radeon stack instaladas."
}

main "$@"
