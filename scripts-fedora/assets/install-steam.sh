#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando Steam via Flatpak (preferido no Fedora)"
    ensure_flatpak_package "com.valvesoftware.Steam"
}

main "$@"
