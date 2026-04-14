#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Verificando e reiniciando systemd-binfmt se necessário"
    if systemctl list-unit-files | grep -q '^systemd-binfmt'; then
        info "Reiniciando systemd-binfmt..."
        if sudo systemctl restart systemd-binfmt; then
            ok "systemd-binfmt reiniciado."
        else
            warn "Falha ao reiniciar systemd-binfmt."
        fi
    else
        warn "systemd-binfmt não encontrado entre as units."
    fi
}

main "$@"
