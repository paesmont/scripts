#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando Vulkan stack (ICD loaders, vkd3d, 32-bit libs)"

    packages=(
        "vulkan-loader"
        "vulkan-loader.i686"
        "vkd3d"
        "vkd3d.i686"
    )

    for pkg in "${packages[@]}"; do
        ensure_package "$pkg"
    done

    ok "Vulkan stack instalada."
}

main "$@"
