#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando VSCode via Flatpak (Fedora-friendly)..."
    ensure_flatpak_package "com.visualstudio.code"
}

main "$@"
