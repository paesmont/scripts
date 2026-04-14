#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando Vivaldi via Flatpak (preferido no Fedora)"
    ensure_flatpak_package "com.vivaldi.Vivaldi"
}

main "$@"
