#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando Spotify (com.spotify.Client) via Flathub..."
    ensure_flatpak_package "com.spotify.Client"
}

main "$@"
