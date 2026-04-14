#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando VLC via Flatpak (preferido no Fedora)"
    ensure_flatpak_package "org.videolan.VLC"
}

main "$@"
