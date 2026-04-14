#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    # 1. Garanta que o binário existe
    ensure_package "flatpak"

    # 2. Adiciona o repositório (Isso falha se o usuário não tiver permissão ou internet)
    info "Adicionando repositório Flathub..."
    
    # O comando remote-add --if-not-exists é seguro para rodar várias vezes
    # Usamos sudo se for instalação global (system-wide)
    if sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        ok "Flathub adicionado."
    else
        fail "Erro ao adicionar Flathub. Verifique internet ou DNS."
        exit 1
    fi
}

main "$@"