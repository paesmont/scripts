#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando ghostty"
    warn "TODO: Ghostty não está empacotado oficialmente no Fedora. Defina se será via COPR ou Flatpak."
}

main "$@"
