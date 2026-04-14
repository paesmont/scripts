#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    # Garante que Go existe
    # Fedora usa o pacote "golang"
    ensure_package "golang"

    info "Instalando/atualizando gopls via 'go install'..."

    GOBIN="${GOBIN:-$HOME/go/bin}"
    mkdir -p "$GOBIN"

    if GO111MODULE=on GOBIN="$GOBIN" go install golang.org/x/tools/gopls@latest; then
        ok "gopls instalado/atualizado em $GOBIN."
    else
        fail "Falha ao instalar gopls via go install."
    fi
}

main "$@"
