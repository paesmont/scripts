#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando wl-clipboard"
    ensure_package "wl-clipboard"
}

main "$@"
