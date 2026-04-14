#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando Dank Material Shell (via script remoto)..."

    if ! command -v curl >/dev/null 2>&1; then
        fail "curl não encontrado; não foi possível instalar Dank Material Shell."
        exit 1
    fi

    if curl -fsSL https://install.danklinux.com | sh; then
        ok "Dank Material Shell instalado com sucesso."
    else
        fail "Falha ao instalar Dank Material Shell."
    fi
}

main "$@"