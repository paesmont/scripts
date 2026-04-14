#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando ntfs-3g"
    ensure_package "ntfs-3g"
}

main "$@"
