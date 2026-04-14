#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando PupGUI2 (net.davidotek.pupgui2) via Flathub..."
    ensure_flatpak_package "net.davidotek.pupgui2"
}

main "$@"
